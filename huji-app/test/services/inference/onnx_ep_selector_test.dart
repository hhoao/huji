import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/onnx_ep_selector.dart';

void main() {
  group('OnnxEpSelector.selectProviders', () {
    test('prefers CUDA over CPU when both available', () {
      expect(
        OnnxEpSelector.selectProviders(const [
          OrtProvider.CPU,
          OrtProvider.CUDA,
        ]),
        [OrtProvider.CUDA, OrtProvider.CPU],
      );
    });

    test('falls back to CPU only', () {
      expect(
        OnnxEpSelector.selectProviders(const [OrtProvider.CPU]),
        [OrtProvider.CPU],
      );
    });

    test('prefers TENSOR_RT before CUDA but only selects one accelerator', () {
      expect(
        OnnxEpSelector.selectProviders(const [
          OrtProvider.CPU,
          OrtProvider.CUDA,
          OrtProvider.TENSOR_RT,
        ]),
        [OrtProvider.TENSOR_RT, OrtProvider.CPU],
      );
    });

    test('adds CPU fallback even if missing from available list', () {
      expect(
        OnnxEpSelector.selectProviders(const [OrtProvider.CUDA]),
        [OrtProvider.CUDA, OrtProvider.CPU],
      );
    });

    test('uses CUDA when TensorRT is absent', () {
      expect(
        OnnxEpSelector.selectProviders(const [
          OrtProvider.CPU,
          OrtProvider.CUDA,
        ]),
        [OrtProvider.CUDA, OrtProvider.CPU],
      );
    });
  });
}
