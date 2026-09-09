/// ncnn (Vulkan) inference bindings for huji.
///
/// Loads YOLO classify models exported to ncnn format
/// (`model.ncnn.param` + `model.ncnn.bin`) and runs single-frame
/// classification on CPU or any Vulkan-capable GPU.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/bindings.g.dart' as native;

export 'src/bindings.g.dart' show HnGpuDevice, hnMaxGpu, hnNameMax;

/// A Vulkan device reported by [NcnnRuntime.gpuDevices].
class NcnnGpuDevice {
  const NcnnGpuDevice({
    required this.index,
    required this.type,
    required this.score,
    required this.vendorId,
    required this.name,
  });

  /// ncnn device index to pass to [NcnnNet.load].
  final int index;

  /// 0=discrete, 1=integrated, 2=virtual, 3=cpu.
  final int type;

  /// ncnn rough_score heuristic — higher is faster.
  final int score;

  /// PCI vendor id (0x10DE NVIDIA, 0x8086 Intel, 0x1002/0x1022 AMD).
  final int vendorId;

  /// Human-readable device name.
  final String name;

  bool get isDiscrete => type == 0;
}

/// Process-wide ncnn runtime — resolves the native library once.
class NcnnRuntime {
  NcnnRuntime._();

  static NcnnRuntime? _instance;

  static String? _overriddenLibDir;

  /// Test/CI bootstrap: pin the directory holding the plugin library
  /// (huji_ncnn_plugin.dll / libhuji_ncnn_plugin.so) before any
  /// [NcnnRuntime] use. On macOS, where the plugin is statically linked
  /// into the app, pin the built app bundle's `Contents/MacOS` dir — the
  /// app's `<product>.debug.dylib` is opened from there.
  ///
  /// Resolution priority on Windows/Linux: this override >
  /// HUJI_NCNN_LIB_DIR env > marker file > bare name (app bundle rpath).
  ///
  /// The pin is also persisted to a marker file in the system temp dir so
  /// it survives isolate boundaries: Dart statics are isolate-local, and
  /// spawned workers (e.g. the detection isolate) start with the override
  /// unset. [_pluginPath] re-reads the marker on every call, so a pin
  /// written by the main isolate is picked up by workers. The marker is
  /// test-VM-only — [_readLibDirMarker] refuses to consult it outside
  /// `flutter test`, so production always resolves via the env var or the
  /// app bundle's bare name/rpath.
  ///
  /// Repeated calls with the same dir are no-ops. A different dir after
  /// the native library has been opened throws [StateError] (the process
  /// already holds the old library). Pinning a different directory before
  /// first use simply replaces the pin.
  static void overrideLibraryDirectory(String dir) {
    final current = _overriddenLibDir;
    if (current == dir) return;
    if (_instance != null) {
      throw StateError(
        'ncnn native library already opened from "$current"; '
        'cannot override to "$dir"',
      );
    }
    _overriddenLibDir = dir;
    _writeLibDirMarker(dir);
  }

  /// Marker file under the system temp dir that carries the pinned lib
  /// dir across isolate boundaries (statics are isolate-local).
  static File get _libDirMarker =>
      File('${Directory.systemTemp.path}${Platform.pathSeparator}'
          'huji_ncnn_lib_dir.txt');

  static void _writeLibDirMarker(String dir) {
    try {
      _libDirMarker.writeAsStringSync(dir);
    } catch (_) {
      // Marker is best-effort: env var and in-isolate override still work.
    }
  }

  /// Read fresh on every call — a worker isolate's marker may have been
  /// written by the main isolate after this isolate started.
  ///
  /// TEST VM ONLY: the marker is consulted exclusively when the process
  /// runs under `flutter test` (FLUTTER_TEST=true, process-wide env —
  /// worker isolates see it too). Packaged/production apps never read
  /// it, so a leftover or maliciously planted temp file cannot redirect
  /// library resolution. Same convention as GpuDeviceSelector
  /// (gpu_device_selector.dart).
  ///
  /// The pinned dir is validated before use: it must still contain the
  /// plugin library. A stale marker (e.g. left behind by a build dir that
  /// `flutter clean` removed) is ignored so the bare-name fallback keeps
  /// working. It is deliberately NOT deleted — another concurrent test VM
  /// may own a valid pin in the same file.
  static String? _readLibDirMarker() {
    if (Platform.environment['FLUTTER_TEST'] != 'true') return null;
    try {
      final dir = _libDirMarker.readAsStringSync().trim();
      if (dir.isEmpty) return null;
      if (_findPluginLibraryIn(dir) == null) return null;
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// Absolute path of the plugin library inside [dir], or null when [dir]
  /// does not hold one.
  ///
  /// Windows/Linux use fixed file names. On macOS the hn_* symbols are
  /// statically linked into the app, so the test VM opens the app's debug
  /// dylib (`<product>.debug.dylib`) instead — its name varies with the
  /// product name, hence the directory scan.
  static String? _findPluginLibraryIn(String dir) {
    final name = _pluginLibraryName;
    if (name != null) {
      final file = File('$dir${Platform.pathSeparator}$name');
      return file.existsSync() ? file.path : null;
    }
    final abi = Abi.current();
    if (abi == Abi.macosX64 || abi == Abi.macosArm64) {
      try {
        for (final entry in Directory(dir).listSync()) {
          if (entry is File && entry.path.endsWith('.debug.dylib')) {
            return entry.path;
          }
        }
      } catch (_) {
        // Unreadable dir — treated as "no plugin here".
      }
    }
    return null;
  }

  /// Plugin library file name for the current ABI, or null where the
  /// library is not resolved from a directory (Android: bundled in the
  /// APK with a bare name; iOS/macOS: statically linked into the app).
  static String? get _pluginLibraryName {
    final abi = Abi.current();
    if (abi == Abi.windowsX64 || abi == Abi.windowsArm64) {
      return 'huji_ncnn_plugin.dll';
    }
    if (abi == Abi.linuxX64 || abi == Abi.linuxArm64) {
      return 'libhuji_ncnn_plugin.so';
    }
    return null;
  }

  /// Shared singleton.
  static NcnnRuntime get instance => _instance ??= NcnnRuntime._();

  /// Resolved C entry points.
  final native.HujiNcnnNative lib = native.HujiNcnnNative.fromLibrary(_openLibrary());

  static DynamicLibrary _openLibrary() {
    final abi = Abi.current();
    if (abi == Abi.windowsX64 || abi == Abi.windowsArm64) {
      final dir = _resolveLibDir();
      if (dir != null && dir.isNotEmpty) {
        _applyIntelIcdWorkaround();
        // Pre-load ncnn.dll by absolute path so the shim's dependency
        // resolution finds it in the process cache (LoadLibrary doesn't
        // search the shim's own directory).
        try {
          DynamicLibrary.open('$dir\\ncnn.dll');
        } catch (_) {
          // Fall through — the shim load below reports the real error.
        }
        return DynamicLibrary.open('$dir\\huji_ncnn_plugin.dll');
      }
      // In the app bundle both dlls sit next to the exe — default search.
      _applyIntelIcdWorkaround();
      return DynamicLibrary.open('huji_ncnn_plugin.dll');
    }
    if (abi == Abi.androidX64 ||
        abi == Abi.androidArm64 ||
        abi == Abi.androidIA32 ||
        abi == Abi.androidRiscv64) {
      return DynamicLibrary.open('libhuji_ncnn_plugin.so');
    }
    if (abi == Abi.linuxX64 || abi == Abi.linuxArm64) {
      return DynamicLibrary.open(_pluginPath('libhuji_ncnn_plugin.so'));
    }
    if (abi == Abi.macosX64 || abi == Abi.macosArm64) {
      // Test VM: the hn_* symbols are not in this process — they are
      // statically linked into the built app. Pin the app bundle's
      // Contents/MacOS dir via the usual override/env/marker chain and
      // open the debug dylib by absolute path.
      final dir = _resolveLibDir();
      if (dir != null && dir.isNotEmpty) {
        final lib = _findPluginLibraryIn(dir);
        if (lib != null) {
          _ensureMacosFrameworksRpath(dir);
          return DynamicLibrary.open(lib);
        }
      }
      // Production: statically registered via podspec (symbols in the app
      // binary — DynamicLibrary.process()).
      return DynamicLibrary.process();
    }
    // iOS: statically registered via podspec (symbols in the app
    // binary — DynamicLibrary.process()).
    return DynamicLibrary.process();
  }

  /// The app's debug dylib resolves its @rpath dependencies through
  /// `@loader_path/Frameworks`, but Xcode places frameworks one level up
  /// (`Contents/Frameworks`); the app's own launcher reaches them via
  /// `@executable_path/../Frameworks` instead. When the dylib is opened
  /// from outside the app (test VM), that rpath misses — create the
  /// missing `<MacosDir>/Frameworks -> ../Frameworks` symlink so dyld
  /// finds them. Best-effort; an existing entry is never touched.
  static void _ensureMacosFrameworksRpath(String macosDir) {
    try {
      final link = Link('$macosDir${Platform.pathSeparator}Frameworks');
      if (link.existsSync()) return;
      final frameworks = Directory(
        '$macosDir${Platform.pathSeparator}..'
        '${Platform.pathSeparator}Frameworks',
      );
      if (!frameworks.existsSync()) return;
      link.createSync('../Frameworks');
    } catch (_) {
      // Best effort — failure surfaces as a dlopen error with dyld's full
      // candidate list, which is more actionable than this context.
    }
  }

  /// Windows Intel Arc workaround: some Intel iGPU drivers crash ncnn's
  /// Vulkan init inside Flutter engine processes. Setting VK_ICD_FILENAMES
  /// BEFORE ncnn.dll is loaded hides the Intel ICD from the loader.
  /// No-op when the user/CI already set an ICD override or opted out.
  static void _applyIntelIcdWorkaround() {
    _applyIntelIcdWorkaroundGuard ??= () {
      try {
        final env = Platform.environment;
        if (env.containsKey('HUJI_NCNN_VK_ICD') ||
            env.containsKey('HUJI_NCNN_ALLOW_INTEL_VK') ||
            env.containsKey('VK_ICD_FILENAMES')) {
          return;
        }
        final driverStore = Directory(
          'C:\\Windows\\System32\\DriverStore\\FileRepository',
        );
        if (!driverStore.existsSync()) return;
        final keep = <String>[];
        for (final infDir in driverStore.listSync()) {
          if (infDir is! Directory) continue;
          for (final entry in infDir.listSync()) {
            if (entry is! File) continue;
            final name = entry.uri.pathSegments.last;
            if (!name.contains('vk') || !name.endsWith('.json')) continue;
            if (name.contains('igvk')) continue; // Intel iGPU
            if (name.contains('vk_swiftshader')) continue;
            if (name.contains('vksc')) continue; // Vulkan SC (headless)
            keep.add(entry.path);
          }
        }
        if (keep.isEmpty) return;
        // NOTE: Dart has no setenv; the plugin's C side re-checks and
        // applies the same filter at DLL load (see apply_intel_icd_workaround
        // in the shim) — this Dart-side walk documents the intent and
        // covers HUJI_NCNN_LIB_DIR test setups by calling the shim early.
      } catch (_) {
        // Best effort only — the native side is authoritative.
      }
    }();
  }

  static void Function()? _applyIntelIcdWorkaroundGuard;

  /// Override pin > HUJI_NCNN_LIB_DIR env > marker file (validated —
  /// see [_readLibDirMarker]) > bare name.
  ///
  /// The marker file is only consulted when the in-isolate override and
  /// env var are both unset — i.e. in worker isolates spawned after the
  /// main isolate pinned the dir — and only inside the test VM
  /// (FLUTTER_TEST=true). Production resolution stops at the env var or
  /// falls through to the bare name.
  static String? _resolveLibDir() => _overriddenLibDir ??
      Platform.environment['HUJI_NCNN_LIB_DIR'] ??
      _readLibDirMarker();

  static String _pluginPath(String name) {
    final dir = _resolveLibDir();
    if (dir == null || dir.isEmpty) return name;
    return '$dir${Platform.pathSeparator}$name';
  }

  List<NcnnGpuDevice>? _gpuDevices;
  bool _gpuProbed = false;

  /// Enumerate Vulkan devices. Empty when Vulkan is unavailable — callers
  /// fall back to CPU. Cached after the first probe.
  List<NcnnGpuDevice> get gpuDevices {
    if (_gpuProbed) return _gpuDevices ?? const <NcnnGpuDevice>[];

    _gpuProbed = true;
    final rt = lib;
    const int maxGpu = native.hnMaxGpu;
    final count = rt.hnGpuCount();
    if (count <= 0) return const <NcnnGpuDevice>[];

    final n = count.clamp(0, maxGpu);
    final Pointer<native.HnGpuDevice> devices =
        calloc<native.HnGpuDevice>(maxGpu);
    // C ABI: char (*names)[hnNameMax] — inline fixed-size rows, NOT a
    // pointer array. Allocate a flat buffer of maxGpu rows and index
    // with row stride; a Pointer<Pointer<Char>> here made the shim
    // overflow this allocation (writing 128 bytes per device) and made
    // Dart dereference the first 8 name bytes as a pointer → SIGSEGV.
    final names = calloc<Uint8>(maxGpu * native.hnNameMax);
    try {
      final written = rt.hnGpuDevices(devices, names.cast(), n);
      final result = <NcnnGpuDevice>[];
      for (var i = 0; i < written; i++) {
        final d = devices[i];
        result.add(NcnnGpuDevice(
          index: d.index,
          type: d.type,
          score: d.score,
          vendorId: d.vendorId,
          name: (names + i * native.hnNameMax).cast<Utf8>().toDartString(),
        ));
      }
      _gpuDevices = List.unmodifiable(result);
      return _gpuDevices!;
    } finally {
      calloc.free(devices);
      calloc.free(names);
    }
  }
}

/// A loaded ncnn network. Not thread-safe: one [predict] call at a time
/// (the app serializes access per instance).
class NcnnNet {
  NcnnNet._(this._handle);

  Pointer<Void>? _handle;
  bool _loaded = false;

  /// Loads a model and, when [deviceIndex] >= 0, enables Vulkan on that
  /// device. Throws on any failure — caller decides whether to retry on CPU.
  static Future<NcnnNet> load({
    required String paramPath,
    required String binPath,
    int deviceIndex = -1,
  }) async {
    final useVulkan = deviceIndex >= 0 ? 1 : 0;
    final handle = NcnnRuntime.instance.lib.hnCreate(useVulkan, deviceIndex);
    if (handle == nullptr) {
      throw StateError('hn_create failed (OOM?)');
    }
    final net = NcnnNet._(handle);
    try {
      net._loadFrom(paramPath, binPath);
    } catch (_) {
      net.dispose();
      rethrow;
    }
    return net;
  }

  void _loadFrom(String paramPath, String binPath) {
    final rt = NcnnRuntime.instance.lib;
    final paramPtr = paramPath.toNativeUtf8();
    final binPtr = binPath.toNativeUtf8();
    try {
      final status = rt.hnLoad(_handle!, paramPtr.cast(), binPtr.cast());
      if (status != 0) {
        throw StateError('hn_load failed with status $status');
      }
    } finally {
      calloc.free(paramPtr);
      calloc.free(binPtr);
    }
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// Classifies an RGB24 letterboxed frame (w*h*3 bytes).
  /// Returns class scores; length = model class count.
  Float32List predict(Uint8List rgb, int width, int height) {
    if (!_loaded) {
      throw StateError('NcnnNet not loaded');
    }
    const maxClasses = 64;
    final rgbPtr = calloc<Uint8>(rgb.length);
    final outPtr = calloc<Float>(maxClasses);
    try {
      rgbPtr.asTypedList(rgb.length).setAll(0, rgb);
      final written = NcnnRuntime.instance.lib.hnPredict(
        _handle!,
        rgbPtr,
        width,
        height,
        outPtr,
        maxClasses,
      );
      if (written <= 0) {
        throw StateError('hn_predict failed with status $written');
      }
      return Float32List.fromList(outPtr.asTypedList(written));
    } finally {
      calloc.free(rgbPtr);
      calloc.free(outPtr);
    }
  }

  void dispose() {
    final handle = _handle;
    _handle = null;
    _loaded = false;
    if (handle != null) {
      NcnnRuntime.instance.lib.hnDestroy(handle);
    }
  }
}

/// Parses YOLO class names out of ultralytics ncnn `metadata.yaml`.
///
/// Layout: `names:\n  0: fireball\n  1: pickball\n...`
class NcnnMetadata {
  NcnnMetadata._();

  static List<String>? tryParseClassNames(String yaml) {
    final lines = const LineSplitter().convert(yaml);
    String? namesHeader;
    final entries = <int, String>{};
    for (final line in lines) {
      if (namesHeader == null) {
        if (line.trim() == 'names:') namesHeader = line;
        continue;
      }
      final match = RegExp(r'^\s+(\d+):\s*(\S+)\s*$').firstMatch(line);
      if (match == null) break; // names block ended
      entries[int.parse(match.group(1)!)] = match.group(2)!;
    }
    if (entries.isEmpty) return null;
    final indices = entries.keys.toList()..sort();
    return indices.map((i) => entries[i]!).toList();
  }
}
