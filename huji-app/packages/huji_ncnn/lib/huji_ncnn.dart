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

export 'src/bindings.g.dart' show HnGpuDevice, hnMaxGpu;

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

  /// Shared singleton.
  static NcnnRuntime get instance => _instance ??= NcnnRuntime._();

  /// Resolved C entry points.
  final native.HujiNcnnNative lib = native.HujiNcnnNative.fromLibrary(_openLibrary());

  static DynamicLibrary _openLibrary() {
    final abi = Abi.current();
    if (abi == Abi.windowsX64 || abi == Abi.windowsArm64) {
      final dir = Platform.environment['HUJI_NCNN_LIB_DIR'];
      if (dir != null && dir.isNotEmpty) {
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
    // iOS/macOS: statically registered via podspec (symbols in the app
    // binary — DynamicLibrary.process()).
    return DynamicLibrary.process();
  }

  /// Bare name normally; `HUJI_NCNN_LIB_DIR` lets tests/CI point at a
  /// built plugin library outside the app bundle.
  static String _pluginPath(String name) {
    final dir = Platform.environment['HUJI_NCNN_LIB_DIR'];
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
    try {
      final count = rt.hnGpuCount();
      if (count <= 0) return const <NcnnGpuDevice>[];

      final n = count.clamp(0, maxGpu);
      final Pointer<native.HnGpuDevice> devices =
          calloc<native.HnGpuDevice>(maxGpu);
      final Pointer<Pointer<Char>> names = calloc<Pointer<Char>>(maxGpu);
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
            name: names[i].cast<Utf8>().toDartString(),
          ));
        }
        _gpuDevices = List.unmodifiable(result);
        return _gpuDevices!;
      } finally {
        calloc.free(devices);
        for (var i = 0; i < n; i++) {
          calloc.free(names[i]);
        }
        calloc.free(names);
      }
    } catch (_) {
      // Vulkan probe must never be fatal — CPU path still works.
      return const <NcnnGpuDevice>[];
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
