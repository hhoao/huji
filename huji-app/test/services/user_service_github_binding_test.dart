import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/api/models/member/social_user_models.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';

void main() {
  test('SocialLoginParams 序列化字段名与服务端契约一致（AppAuthSocialLoginReqVO.type）', () {
    final json = SocialLoginParams(
      socialType: GithubOAuthConfig.socialType,
      code: 'c',
      state: 's',
    ).toJson();
    // 服务端 /member/auth/social-login 的 VO 字段是 `type`，
    // 不是 `socialType`，否则 400「社交平台的类型不能为空」。
    expect(json, {'type': 40, 'code': 'c', 'state': 's'});
  });

  test('SocialLoginParams 反序列化读取 type 键', () {
    final params = SocialLoginParams.fromJson({
      'type': 40,
      'code': 'c',
      'state': 's',
    });
    expect(params.socialType, 40);
    expect(params.code, 'c');
    expect(params.state, 's');
  });

  test('SocialUserBindParams 序列化字段名与服务端契约一致', () {
    final json = SocialUserBindParams(
      type: GithubOAuthConfig.socialType,
      code: 'c',
      state: 's',
    ).toJson();
    expect(json, {'type': 40, 'code': 'c', 'state': 's'});
  });

  test('SocialUserUnbindParams 序列化字段名与服务端契约一致', () {
    final json = SocialUserUnbindParams(
      type: GithubOAuthConfig.socialType,
      openid: 'o',
    ).toJson();
    expect(json, {'type': 40, 'openid': 'o'});
  });

  test('SocialUserInfo 反序列化', () {
    final info = SocialUserInfo.fromJson({
      'openid': 'o',
      'nickname': 'octocat',
      'avatar': 'https://github.com/octocat.png',
    });
    expect(info.openid, 'o');
    expect(info.nickname, 'octocat');
    expect(info.avatar, 'https://github.com/octocat.png');
  });
}
