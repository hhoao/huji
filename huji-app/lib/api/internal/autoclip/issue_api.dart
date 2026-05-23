import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/autoclip/issue_models.dart';

part 'issue_api.g.dart';

@RestApi()
abstract class IssueApi {
  factory IssueApi(Dio dio, {String? baseUrl}) = _IssueApi;

  // 创建问题反馈
  @POST('/autoclip/issue/create')
  Future<int> createIssue(@Body() IssueCreateReqVO data);

  // 获取我的问题反馈列表
  @GET('/autoclip/issue/list')
  Future<PageResult<IssueRespVO>> getMyIssues(
    @Queries() Map<String, dynamic> params,
  );

  // 获取问题反馈详情
  @GET('/autoclip/issue/{id}')
  Future<IssueRespVO> getIssue(@Path('id') int id);
}
