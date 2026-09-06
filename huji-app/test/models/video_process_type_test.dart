import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';

void main() {
  test('enum values are stable and backward compatible', () {
    // 老数据 0/1/2 不变；新值 3/4。
    expect(VideoProcessType.raw.value, 0);
    expect(VideoProcessType.greatMatch.value, 1);
    expect(VideoProcessType.allMatchMerged.value, 2);
    expect(VideoProcessType.compressed.value, 3);
    expect(VideoProcessType.exported.value, 4);
    expect(VideoProcessType.values.length, 5);
  });
}
