import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/autoclip/clip_models.dart';
import '../../models/autoclip/video_models.dart';
import '../../models/common/page.dart';

part 'clip_api.g.dart';

// 视频剪辑相关API
@RestApi()
abstract class ClipApi {
  factory ClipApi(Dio dio, {String? baseUrl}) = _ClipApi;

  // 自动剪辑视频（参考前端auto_pingpong_clip_video）
  @POST('/autoclip/clip/ping_pong')
  Future<int> autoPingpongClipVideo(@Body() PingPongAutoClipParams data);

  // 羽毛球视频自动剪辑
  @POST('/autoclip/clip/badminton')
  Future<int> processBadmintonClip(@Body() BadmintonAutoClipParams data);

  // 获取视频处理记录列表
  @GET('/autoclip/clip/records')
  Future<BasicFetchPageResult<VideoProcessRecordVO>> getVideoProcessRecords(
    @Queries() VideoProcessRecordFilterParam? filterParam,
  );

  // 获取视频处理进度列表
  @GET('/autoclip/clip/progresses')
  Future<BasicFetchPageResult<VideoProcessProgressVO>>
  getVideoProcessProgresses(
    @Queries() VideoProcessProgressFilterParam? filterParam,
  );

  // 获取单个视频处理进度
  @GET('/autoclip/clip/progress')
  Future<VideoProcessProgressVO> getVideoProcessProgress(
    @Queries() VideoProgressQueryParams params,
  );
}
