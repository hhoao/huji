import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:huji_app/config/environment.dart';

/// GitHub OAuth 回调结果。
class OAuthCallback {
  final String code;
  final String state;

  const OAuthCallback({required this.code, required this.state});
}

/// GitHub OAuth 相关常量。
class GithubOAuthConfig {
  static const int socialType = 40;

  /// web-front 中转页固定地址（GitHub OAuth App 注册的 callback URL）。
  static String get webCallbackUrl =>
      '${EnvironmentConfig.webBaseUrl}/oauth/github/callback';
}

/// 识别 OAuth 回调 URI（deep link 或 loopback 请求均可）。
///
/// 匹配 `huji://oauth/github?code=..&state=..` 与
/// `http(s)://127.0.0.1:<port>/oauth/github?code=..&state=..`。
///
/// 注意：`huji` 是非特殊 scheme，`Uri.parse('huji://oauth/github')` 会把
/// `oauth` 解析为 host、`github` 为首段 path，因此两种形态分别校验。
/// 只接受 `huji` scheme 与 loopback host，避免任意网页通过
/// `https://evil.com/oauth/github?code=..&state=..` 注入伪造回调。
OAuthCallback? parseGithubCallback(Uri uri) {
  final path = uri.pathSegments;
  final bool isGithubPath;
  if (uri.scheme == 'huji') {
    isGithubPath =
        uri.host == 'oauth' && path.isNotEmpty && path.first == 'github';
  } else if ((uri.host == '127.0.0.1' || uri.host == 'localhost') &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    isGithubPath = path.length >= 2 && path[0] == 'oauth' && path[1] == 'github';
  } else {
    isGithubPath = false;
  }
  if (!isGithubPath) {
    return null;
  }
  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  if (code == null || code.isEmpty || state == null || state.isEmpty) {
    return null;
  }
  return OAuthCallback(code: code, state: state);
}

/// OAuth 回调捕获层：负责拿到授权码后把结果交给调用方。
abstract class OAuthCallbackCapture {
  /// 启动捕获，返回要传给服务端 `social-auth-redirect` 的 redirectUri。
  Future<String> start();

  /// 收到合法回调后完成。
  Future<OAuthCallback> get callback;

  /// 停止捕获（关闭 loopback server / 取消 deep link 订阅）。幂等。
  Future<void> stop();
}

/// 桌面端：登录期间在本机随机端口起临时 HTTP server。
class LoopbackCallbackCapture implements OAuthCallbackCapture {
  HttpServer? _server;
  final Completer<OAuthCallback> _completer = Completer<OAuthCallback>();

  @override
  Future<OAuthCallback> get callback => _completer.future;

  @override
  Future<String> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((request) async {
      final callback = parseGithubCallback(request.requestedUri);
      if (callback != null) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<!DOCTYPE html><html lang="zh"><body style="font-family:sans-serif;'
          'text-align:center;padding-top:40vh"><h3>授权成功，请回到应用</h3></body></html>',
        );
        await request.response.close();
        if (!_completer.isCompleted) {
          _completer.complete(callback);
          await stop();
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });
    return '${GithubOAuthConfig.webCallbackUrl}?port=${server.port}';
  }

  @override
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

/// 移动端：捕获 `huji://` deep link（含冷启动 initial link）。
class DeepLinkCallbackCapture implements OAuthCallbackCapture {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  final Completer<OAuthCallback> _completer = Completer<OAuthCallback>();

  @override
  Future<OAuthCallback> get callback => _completer.future;

  @override
  Future<String> start() async {
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _accept(uri);
    });
    // 冷启动场景：App 被杀后 deep link 重新拉起，取初始 link。
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _accept(initial);
    }
    return GithubOAuthConfig.webCallbackUrl;
  }

  void _accept(Uri uri) {
    final callback = parseGithubCallback(uri);
    if (callback != null && !_completer.isCompleted) {
      _completer.complete(callback);
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
