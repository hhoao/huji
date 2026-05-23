import 'package:json_annotation/json_annotation.dart';

part 'notify_models.g.dart';

@JsonSerializable()
class NotifyMessageVO {
  final int id;
  final int userId;
  final int userType;
  final int templateId;
  final String templateCode;
  final String templateNickname;
  final String templateContent;
  final int templateType;
  final Map<String, Object> templateParams;
  final bool readStatus;
  final int? readTime;
  final int createTime;

  NotifyMessageVO({
    required this.id,
    required this.userId,
    required this.userType,
    required this.templateId,
    required this.templateCode,
    required this.templateNickname,
    required this.templateContent,
    required this.templateType,
    required this.templateParams,
    required this.readStatus,
    this.readTime,
    required this.createTime,
  });

  factory NotifyMessageVO.fromJson(Map<String, dynamic> json) =>
      _$NotifyMessageVOFromJson(json);
  Map<String, dynamic> toJson() => _$NotifyMessageVOToJson(this);
}

@JsonSerializable()
class UnreadCountResponse {
  final int count;

  UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UnreadCountResponseToJson(this);
}
