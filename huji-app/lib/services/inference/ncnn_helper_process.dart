import 'dart:async';
import 'dart:io';
import 'dart:typed_data';



/// A Vulkan device reported by [NcnnHelperProcess.gpuDevices].
class NcnnHelperGpuDevice {
  const NcnnHelperGpuDevice({
    required this.index,
    required this.type,
    required this.score,
    required this.vendorId,
    required this.name,
  });

  final int index;
  final int type;
  final int score;
  final int vendorId;
  final String name;
}

/// Runs ncnn inference in the standalone `huji_ncnn_helper` child process.
///
/// Windows: ncnn's Vulkan device init crashes inside Flutter engine
/// processes (NVIDIA nvoglv64 access violation caused by the engine's
/// GL/D3D rendering stack — reproduced and dump-verified 2026-09). The
/// same shim runs flawlessly in a plain process, so on Windows GPU
/// inference goes through this helper; requests are framed little-endian
/// over stdin/stdout (see huji_ncnn_helper_main.cpp).
class NcnnHelperProcess {
  NcnnHelperProcess._(this._process);

  final Process _process;

  /// Outstanding stdout data waiting for the next response — pipe chunks
  /// don't respect message boundaries.
  final List<Uint8List> _chunks = <Uint8List>[];
  int _chunkOffset = 0;
  Completer<void>? _drained;

  bool _disposed = false;

  /// Spawn the helper exe bundled next to the app binary.
  static Future<NcnnHelperProcess> start() async {
    final exe = Platform.resolvedExecutable;
    final dir = File(exe).parent.path;
    final helperPath = '$dir${Platform.pathSeparator}huji_ncnn_helper.exe';
    if (!File(helperPath).existsSync()) {
      throw StateError('huji_ncnn_helper.exe not found next to the app: $helperPath');
    }

    final process = await Process.start(
      helperPath,
      const [],
      // The helper restricts itself to the NVIDIA ICD unless overridden.
      environment: Platform.environment,
    );
    final helper = NcnnHelperProcess._(process);
    // Single long-lived subscription: every response read goes through the
    // chunk queue instead of re-listening (a stream allows one listener).
    process.stdout.listen(
      (chunk) {
        helper._chunks.add(chunk as Uint8List);
        helper._drained?.complete();
      },
      onDone: () {
        helper._drained?.completeError(
          StateError('helper closed the pipe'),
        );
      },
      onError: (Object e) {
        helper._drained?.completeError(e);
      },
    );
    return helper;
  }

  // === protocol primitives ===

  void _putU32(BytesBuilder b, int v) {
    b.add([
      v & 0xFF,
      (v >> 8) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 24) & 0xFF,
    ]);
  }

  /// Fills [out] with the next [out.length] bytes from the stdout queue,
  /// pulling more chunks from the single stdout subscription as needed.
  Future<Uint8List> _readExact(int len) async {
    final result = Uint8List(len);
    var copied = 0;
    while (copied < len) {
      while (_chunks.isEmpty) {
        // Wait for the subscription to deliver a chunk.
        final done = Completer<void>();
        _drained = done;
        await done.future;
        _drained = null;
      }
      final chunk = _chunks.first;
      final take = (chunk.length - _chunkOffset).clamp(0, len - copied);
      result.setRange(copied, copied + take, chunk, _chunkOffset);
      copied += take;
      _chunkOffset += take;
      if (_chunkOffset >= chunk.length) {
        _chunks.removeAt(0);
        _chunkOffset = 0;
      }
    }
    return result;
  }

  int _u32(Uint8List b, int off) =>
      b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] << 24);

  // === commands ===

  /// Enumerate Vulkan devices (helper-side; safe in the child process).
  Future<List<NcnnHelperGpuDevice>> gpuDevices() async {
    final b = BytesBuilder(copy: false);
    _putU32(b, 3); // cmd: gpu
    _process.stdin.add(b.takeBytes());

    final head = await _readExact(8);
    final status = _u32(head, 0);
    final count = _u32(head, 4);
    if (status != 0 || count == 0) return const [];

    final result = <NcnnHelperGpuDevice>[];
    for (var i = 0; i < count; i++) {
      final meta = await _readExact(20);
      final nameLen = _u32(meta, 16);
      final nameBytes = await _readExact(nameLen);
      result.add(NcnnHelperGpuDevice(
        index: _u32(meta, 0),
        type: _u32(meta, 4),
        score: _u32(meta, 8),
        vendorId: _u32(meta, 12),
        name: String.fromCharCodes(nameBytes),
      ));
    }
    return result;
  }

  /// Load a model; [gpuIndex] < 0 selects CPU.
  Future<void> load({
    required String paramPath,
    required String binPath,
    int gpuIndex = -1,
  }) async {
    final payload = utf8Bytes('$paramPath\n$binPath\n$gpuIndex');
    final b = BytesBuilder(copy: false);
    _putU32(b, 1); // cmd: load
    _putU32(b, payload.length);
    b.add(payload);
    _process.stdin.add(b.takeBytes());

    final statusBytes = await _readExact(4);
    final status = _u32(statusBytes, 0);
    if (status != 0) {
      throw StateError('helper load failed with status $status');
    }
  }

  /// Run one prediction on an RGB24 frame.
  Future<Float32List> predict(Uint8List rgb, int width, int height) async {
    final b = BytesBuilder(copy: false);
    _putU32(b, 2); // cmd: predict
    _putU32(b, width);
    _putU32(b, height);
    _putU32(b, rgb.length);
    b.add(rgb);
    _process.stdin.add(b.takeBytes());

    final head = await _readExact(8);
    final status = _u32(head, 0);
    final count = _u32(head, 4);
    if (status != 0) {
      throw StateError('helper predict failed with status $status');
    }
    final out = await _readExact(count * 4);
    final view = ByteData.sublistView(out);
    return Float32List.view(
      view.buffer,
      view.offsetInBytes,
      count,
    );
  }

  /// Kill the helper. The helper's ncnn atexit cleanup crashes on exit
  /// (known NVIDIA driver issue), so terminate hard — the OS reclaims
  /// everything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _process.stdin.close();
    // Don't await exit — terminate synchronously; the exit code is
    // irrelevant (atexit crash in ncnn is expected).
    _process.kill();
  }

  static Uint8List utf8Bytes(String s) {
    final units = s.codeUnits;
    final bytes = Uint8List(units.length);
    for (var i = 0; i < units.length; i++) {
      bytes[i] = units[i] & 0xFF;
    }
    return bytes;
  }
}
