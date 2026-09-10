import 'dart:async';
import 'dart:io';

import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';
import 'package:url_launcher/url_launcher.dart';

/// GitHub OAuth 流程中可替换的网络边界（测试注入点）。
abstract class GithubOAuthGateway {
  /// 调服务端 social-auth-redirect，返回带 state 的 GitHub 授权 URL。
  Future<String> getAuthorizeUrl(String redirectUri);
}

class ApiGithubOAuthGateway implements GithubOAuthGateway {
  @override
  Future<String> getAuthorizeUrl(String redirectUri) =>
      ApiManager.instance.authApi.socialAuthRedirect(
        GithubOAuthConfig.socialType,
        redirectUri,
      );
}

/// OAuth 流程失败（浏览器打不开等）。
class GithubOAuthException implements Exception {
  final String message;
  const GithubOAuthException(this.message);

  @override
  String toString() => message;
}

/// GitHub OAuth 授权流程：捕获回调并返回授权码。
///
/// 登录/绑定的 API 调用由调用方（`UserService` / 绑定 UI）完成，
/// 本类只负责「拿到 code + state」。
class GithubOAuthService {
  GithubOAuthService({
    GithubOAuthGateway? gateway,
    OAuthCallbackCapture? capture,
    Duration? timeout,
    Future<bool> Function(Uri url)? launch,
  }) : _gateway = gateway ?? ApiGithubOAuthGateway(),
       _captureOverride = capture,
       _timeout = timeout ?? const Duration(minutes: 5),
       _launch = launch ?? _defaultLaunch;

  final GithubOAuthGateway _gateway;
  final OAuthCallbackCapture? _captureOverride;
  final Duration _timeout;
  final Future<bool> Function(Uri url) _launch;

  static Future<bool> _defaultLaunch(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  OAuthCallbackCapture? _activeCapture;

  /// 默认捕获层：移动端 deep link，其余 loopback。
  static OAuthCallbackCapture _defaultCapture() {
    if (Platform.isAndroid || Platform.isIOS) {
      return DeepLinkCallbackCapture();
    }
    return LoopbackCallbackCapture();
  }

  /// 走完授权流程，拿到 code/state。
  Future<OAuthCallback> authorize() async {
    final capture = _captureOverride ?? _defaultCapture();
    _activeCapture = capture;
    try {
      final redirectUri = await capture.start();
      final authorizeUrl = await _gateway.getAuthorizeUrl(redirectUri);
      final launched = await _launch(Uri.parse(authorizeUrl));
      if (!launched) {
        throw const GithubOAuthException('无法打开浏览器');
      }
      return await capture.callback.timeout(_timeout);
    } finally {
      await capture.stop();
      if (identical(_activeCapture, capture)) {
        _activeCapture = null;
      }
    }
  }

  /// 用户关闭登录框等场景下提前终止（停捕获层）。
  /// 挂起的 authorize() future 由超时兜底收尾，不会泄漏资源。
  void abort() {
    _activeCapture?.stop();
  }
}
