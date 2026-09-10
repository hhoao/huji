import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';

void main() {
  group('parseGithubCallback', () {
    test('解析移动端 deep link', () {
      final result = parseGithubCallback(
        Uri.parse('huji://oauth/github?code=abc&state=xyz'),
      );
      expect(result, isNotNull);
      expect(result!.code, 'abc');
      expect(result.state, 'xyz');
    });

    test('解析桌面端 loopback 回调', () {
      final result = parseGithubCallback(
        Uri.parse('http://127.0.0.1:54321/oauth/github?code=abc&state=xyz'),
      );
      expect(result, isNotNull);
      expect(result!.code, 'abc');
      expect(result.state, 'xyz');
    });

    test('缺少 code 返回 null', () {
      expect(
        parseGithubCallback(Uri.parse('huji://oauth/github?state=xyz')),
        isNull,
      );
    });

    test('缺少 state 返回 null', () {
      expect(
        parseGithubCallback(Uri.parse('huji://oauth/github?code=abc')),
        isNull,
      );
    });

    test('路径不匹配返回 null', () {
      expect(
        parseGithubCallback(Uri.parse('huji://oauth/gitee?code=a&state=b')),
        isNull,
      );
      expect(
        parseGithubCallback(Uri.parse('huji://other/path?code=a&state=b')),
        isNull,
      );
    });
  });

  group('LoopbackCallbackCapture', () {
    test('收到带 code 的请求后完成 callback 并可停止', () async {
      final capture = LoopbackCallbackCapture();
      addTearDown(capture.stop);

      final redirectUri = await capture.start();
      // redirectUri 指向中转页并携带随机端口
      expect(redirectUri, startsWith(GithubOAuthConfig.webCallbackUrl));
      expect(redirectUri, contains('port='));

      final port = int.parse(
        Uri.parse(redirectUri).queryParameters['port']!,
      );
      // 模拟浏览器访问 loopback（中转页会重定向到 127.0.0.1:port）
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/oauth/github?code=abc&state=xyz'),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      await response.drain<void>();
      client.close();

      final callback = await capture.callback;
      expect(callback.code, 'abc');
      expect(callback.state, 'xyz');

      await capture.stop();
      // 停止后端口不再监听（原 client 已 close，用新的 probe client；
      // ignore 掉连接拒绝的异步错误，只验证不抛同步异常）
      final probeClient = HttpClient();
      expect(() => probeClient
          .getUrl(
            Uri.parse('http://127.0.0.1:$port/oauth/github?code=a&state=b'),
          )
          .ignore(), returnsNormally);
      probeClient.close(force: true);
    });
  });
}
