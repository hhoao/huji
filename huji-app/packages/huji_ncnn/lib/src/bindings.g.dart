// AUTO-GENERATED? No — hand-maintained minimal bindings for src/huji_ncnn_api.h.
// The C surface is tiny (6 functions, 1 struct); regenerate with ffigen
// (dart run ffigen --config ffigen.yaml, needs LLVM/libclang) if the header
// changes.
// ignore_for_file: always_specify_types, constant_identifier_names

library;

import 'dart:ffi';

/// Opaque handle to a loaded ncnn network.
typedef HnNet = Pointer<Void>;

/// int32 fields — C struct is 4*int + uint32 = 20 bytes, aligned.
final class HnGpuDevice extends Struct {
  @Int32()
  external int index;
  @Int32()
  external int type;
  @Int32()
  external int score;
  @Uint32()
  external int vendorId;
}

const int hnMaxGpu = 8;
const int hnNameMax = 128;

typedef HnCreateNative = Pointer<Void> Function(Int32, Int32);
typedef HnCreateDart = Pointer<Void> Function(int, int);
typedef HnLoadNative = Int32 Function(Pointer<Void>, Pointer<Char>, Pointer<Char>);
typedef HnLoadDart = int Function(Pointer<Void>, Pointer<Char>, Pointer<Char>);
typedef HnPredictNative = Int32 Function(
    Pointer<Void>, Pointer<Uint8>, Int32, Int32, Pointer<Float>, Int32);
typedef HnPredictDart = int Function(
    Pointer<Void>, Pointer<Uint8>, int, int, Pointer<Float>, int);
typedef HnDestroyNative = Void Function(Pointer<Void>);
typedef HnDestroyDart = void Function(Pointer<Void>);
typedef HnGpuCountNative = Int32 Function();
typedef HnGpuCountDart = int Function();
// names is char (*)[hnNameMax] — inline fixed-size rows, not pointers.
typedef HnGpuDevicesNative = Int32 Function(
    Pointer<HnGpuDevice>, Pointer<Uint8>, Int32);
typedef HnGpuDevicesDart = int Function(
    Pointer<HnGpuDevice>, Pointer<Uint8>, int);

/// Looked-up C entry points of the huji_ncnn shim.
class HujiNcnnNative {
  HujiNcnnNative._();

  late final HnCreateDart hnCreate;
  late final HnLoadDart hnLoad;
  late final HnPredictDart hnPredict;
  late final HnDestroyDart hnDestroy;
  late final HnGpuCountDart hnGpuCount;
  late final HnGpuDevicesDart hnGpuDevices;

  /// Resolves all shim symbols from [lib].
  factory HujiNcnnNative.fromLibrary(DynamicLibrary lib) {
    final n = HujiNcnnNative._();
    n.hnCreate = lib.lookupFunction<HnCreateNative, HnCreateDart>('hn_create');
    n.hnLoad = lib.lookupFunction<HnLoadNative, HnLoadDart>('hn_load');
    n.hnPredict =
        lib.lookupFunction<HnPredictNative, HnPredictDart>('hn_predict');
    n.hnDestroy =
        lib.lookupFunction<HnDestroyNative, HnDestroyDart>('hn_destroy');
    n.hnGpuCount =
        lib.lookupFunction<HnGpuCountNative, HnGpuCountDart>('hn_gpu_count');
    n.hnGpuDevices =
        lib.lookupFunction<HnGpuDevicesNative, HnGpuDevicesDart>('hn_gpu_devices');
    return n;
  }
}
