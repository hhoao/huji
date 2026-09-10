import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/member/social_user_models.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';

void main() {
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
