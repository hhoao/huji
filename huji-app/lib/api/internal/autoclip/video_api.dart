import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/api/models/common/page.dart';

part 'video_api.g.dart';

// 视频相关API
@RestApi()
abstract class VideoApi {
  factory VideoApi(Dio dio, {String? baseUrl}) = _VideoApi;

  // 获取预签名URL
  @GET('/autoclip/video/presigned-url')
  Future<PresignedUrlResponse> getFilePresignedUrl(
    @Queries() PresignedUrlRequest request,
  );

  // 获取视频列表
  @GET('/autoclip/video/list')
  Future<BasicFetchPageResult<VideoInfoRespVO>> getVideoList(
    @Queries() VideoListFilterParam? filterParam,
  );

  // 获取单个视频信息
  @GET('/autoclip/video/{videoId}')
  Future<VideoInfoRespVO> getVideoInfo(@Path('videoId') int videoId);

  // 上传文件
  @POST('/upload')
  Future<String> uploadFile(@Part() File file);

  // 分片上传相关API

  // 创建分片上传会话
  @POST('/autoclip/video/multipart/create')
  Future<FilePresignedUrlRespVO> createMultipartUpload(
    @Body() MultipartUploadReqVO request,
  );

  // 获取分片上传预签名URL
  @POST('/autoclip/video/multipart/upload-part')
  Future<FilePresignedUrlRespVO> getUploadPartPresignedUrl(
    @Body() MultipartUploadPartReqVO request,
  );

  // 完成分片上传
  @POST('/autoclip/video/multipart/complete')
  Future<FilePresignedUrlRespVO> getCompleteMultipartUploadPresignedUrl(
    @Body() MultipartCompleteReqVO request,
  );

  // 中止分片上传
  @POST('/autoclip/video/multipart/abort')
  Future<FilePresignedUrlRespVO> getAbortMultipartUploadPresignedUrl(
    @Body() MultipartAbortReqVO request,
  );
}
