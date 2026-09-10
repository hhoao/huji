import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/auth/github_oauth_service.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';

class _FakeGateway implements GithubOAuthGateway {
  String? requestedRedirectUri;

  @override
  Future<String> getAuthorizeUrl(String redirectUri) async {
    requestedRedirectUri = redirectUri;
    return 'https://github.com/login/oauth/authorize?client_id=x';
  }
}

class _FakeCapture implements OAuthCallbackCapture {
  final Completer<OAuthCallback> _completer = Completer<OAuthCallback>();
  bool stopped = false;
  String redirectUri = 'https://restcut.com/oauth/github/callback?port=4321';

  void deliver(String code, String state) {
    if (!_completer.isCompleted) {
      _completer.complete(OAuthCallback(code: code, state: state));
    }
  }

  @override
  Future<OAuthCallback> get callback => _completer.future;

  @override
  Future<String> start() async => redirectUri;

  @override
  Future<void> stop() async => stopped = true;
}

void main() {
  test('authorize 走完整流程：捕获层 redirectUri → 授权 URL → 浏览器 → 回调', () async {
    final gateway = _FakeGateway();
    final capture = _FakeCapture();
    final launchedUrls = <Uri>[];
    final service = GithubOAuthService(
      gateway: gateway,
      capture: capture,
      timeout: const Duration(seconds: 5),
      launch: (uri) async {
        launchedUrls.add(uri);
        return true;
      },
    );

    final future = service.authorize();
    // 模拟浏览器回调到达
    capture.deliver('the-code', 'the-state');
    final result = await future;

    expect(result.code, 'the-code');
    expect(result.state, 'the-state');
    expect(gateway.requestedRedirectUri, capture.redirectUri);
    expect(launchedUrls.single.toString(),
        'https://github.com/login/oauth/authorize?client_id=x');
    expect(capture.stopped, isTrue, reason: '流程结束后必须停止捕获层');
  });

  test('浏览器打开失败时抛 GithubOAuthException 并停止捕获层', () async {
    final capture = _FakeCapture();
    final service = GithubOAuthService(
      gateway: _FakeGateway(),
      capture: capture,
      timeout: const Duration(seconds: 5),
      launch: (uri) async => false,
    );

    await expectLater(
      service.authorize(),
      throwsA(isA<GithubOAuthException>()),
    );
    expect(capture.stopped, isTrue);
  });

  test('超时后抛 TimeoutException 并停止捕获层', () async {
    final capture = _FakeCapture();
    final service = GithubOAuthService(
      gateway: _FakeGateway(),
      capture: capture,
      timeout: const Duration(milliseconds: 50),
      launch: (uri) async => true,
    );

    await expectLater(service.authorize(), throwsA(isA<TimeoutException>()));
    expect(capture.stopped, isTrue);
  });
}
