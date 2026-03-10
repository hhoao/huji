import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:restcut/api/internal/autoclip/video_api.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

class MultipartUploadService {
  final VideoApi _videoApi;
  final Dio _dio;

  MultipartUploadService(this._videoApi, this._dio);

  /// 执行完整的分片上传流程
  Future<String> uploadFileWithMultipart({
    required File file,
    required String fileName,
    String? directory,
    String? contentType,
    int chunkSize = 5 * 1024 * 1024, // 5MB chunks
    Function(double progress)? onProgress,
  }) async {
    String? uploadId;
    String? path;

    try {
      // 1. 创建分片上传会话
      final createResponse = await _videoApi.createMultipartUpload(
        MultipartUploadReqVO(
          name: fileName,
          directory: directory,
          contentType: contentType,
        ),
      );

      uploadId = createResponse.uploadId;
      path = createResponse.path;

      if (path == null) {
        throw Exception('Failed to create multipart upload session');
      }

      // 2. 计算分片数量
      final fileSize = await file.length();
      final totalChunks = (fileSize / chunkSize).ceil();
      final List<CompletedPart> completedParts = [];

      // 3. 上传每个分片
      for (int partNumber = 1; partNumber <= totalChunks; partNumber++) {
        // 获取分片上传预签名URL
        final partResponse = await _videoApi.getUploadPartPresignedUrl(
          MultipartUploadPartReqVO(
            uploadId: uploadId!,
            path: path,
            partNumber: partNumber,
          ),
        );

        // 读取分片数据
        final start = (partNumber - 1) * chunkSize;
        final end = partNumber == totalChunks ? fileSize : start + chunkSize;
        final chunk = await file
            .openRead(start, end)
            .toList()
            .then((list) => Uint8List.fromList(list.expand((e) => e).toList()));

        // 上传分片
        final uploadResponse = await _dio.put(
          partResponse.uploadUrl,
          data: chunk,
          options: Options(
            headers: {'Content-Type': 'application/octet-stream'},
          ),
        );

        // 获取ETag
        final eTag = uploadResponse.headers.value('ETag')?.replaceAll('"', '');
        if (eTag == null) {
          throw Exception('Failed to get ETag for part $partNumber');
        }

        completedParts.add(CompletedPart(partNumber: partNumber, eTag: eTag));

        // 更新进度
        final progress = partNumber / totalChunks;
        onProgress?.call(progress);
      }

      // 4. 完成分片上传
      final completeResponse = await _videoApi
          .getCompleteMultipartUploadPresignedUrl(
            MultipartCompleteReqVO(
              uploadId: uploadId!,
              path: path,
              parts: completedParts,
            ),
          );

      // 调用完成API
      await _dio.post(completeResponse.uploadUrl);

      return path;
    } catch (e) {
      // 如果出错，尝试中止上传
      if (uploadId != null && path != null) {
        try {
          await _abortUpload(uploadId, path);
        } catch (abortError) {
          // 忽略中止错误
        }
      }
      rethrow;
    }
  }

  /// 中止分片上传
  Future<void> _abortUpload(String uploadId, String path) async {
    try {
      final abortResponse = await _videoApi.getAbortMultipartUploadPresignedUrl(
        MultipartAbortReqVO(uploadId: uploadId, path: path),
      );

      await _dio.delete(abortResponse.uploadUrl);
    } catch (e) {
      // 忽略中止错误
    }
  }
}
