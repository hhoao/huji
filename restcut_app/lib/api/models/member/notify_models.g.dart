// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifyMessageVO _$NotifyMessageVOFromJson(Map<String, dynamic> json) =>
    NotifyMessageVO(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userType: (json['userType'] as num).toInt(),
      templateId: (json['templateId'] as num).toInt(),
      templateCode: json['templateCode'] as String,
      templateNickname: json['templateNickname'] as String,
      templateContent: json['templateContent'] as String,
      templateType: (json['templateType'] as num).toInt(),
      templateParams: (json['templateParams'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as Object),
      ),
      readStatus: json['readStatus'] as bool,
      readTime: (json['readTime'] as num?)?.toInt(),
      createTime: (json['createTime'] as num).toInt(),
    );

Map<String, dynamic> _$NotifyMessageVOToJson(NotifyMessageVO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userType': instance.userType,
      'templateId': instance.templateId,
      'templateCode': instance.templateCode,
      'templateNickname': instance.templateNickname,
      'templateContent': instance.templateContent,
      'templateType': instance.templateType,
      'templateParams': instance.templateParams,
      'readStatus': instance.readStatus,
      'readTime': instance.readTime,
      'createTime': instance.createTime,
    };

UnreadCountResponse _$UnreadCountResponseFromJson(Map<String, dynamic> json) =>
    UnreadCountResponse(count: (json['count'] as num).toInt());

Map<String, dynamic> _$UnreadCountResponseToJson(
  UnreadCountResponse instance,
) => <String, dynamic>{'count': instance.count};
