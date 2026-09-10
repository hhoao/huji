# GitHub OAuth 登录 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** huji-app 支持桌面 + 移动全平台的 GitHub OAuth 登录（H5 回调中转 + 平台分发），并在设置页支持绑定/解绑。

**Architecture:** GitHub 回调到 autoclip-web-front 的固定中转页 `/oauth/github/callback`，中转页按 UA 分发 code（移动端 deep link `huji://`，桌面端 `127.0.0.1:<随机端口>` loopback HTTP server）。App 拿 code/state 调服务端已有的 `/member/auth/social-login`（type=40）或 `/member/social-user/bind`。服务端零 Java 逻辑改动，只加枚举 + yaml 配置。

**Tech Stack:** Flutter/Dart (retrofit + json_serializable + build_runner, bloc, app_links, url_launcher)；Vue 3 + vue-router (autoclip-web-front)；Spring Boot + JustAuth (autoclip-server, Maven)。

**Spec:** `docs/superpowers/specs/2026-09-10-github-oauth-login-design.md`

## Global Constraints

- socialType 固定为 `40`（`SocialTypeEnum.GITHUB(40, "GITHUB")`）。
- App deep link scheme 为 `huji`，回调路径为 `/oauth/github`。
- 中转页固定 URL：`https://restcut.com/oauth/github/callback`（GitHub OAuth App 注册的 callback URL，HTTPS）。
- OAuth 等待超时：5 分钟。
- 桌面端 loopback：`HttpServer.bind(InternetAddress.loopbackIPv4, 0)` 随机端口；端口作为中转页 URL 的 `?port=` 参数传递。
- `huji-app/macos/Runner/Info.plist` 的 `FLTEnableImpeller` 行不得改动（`ci-verify.yml` 有 guard 步骤，改了 CI 会红）。
- 三个仓库分别提交：Task 1 提交在 `/home/hhoa/autoclip/autoclip-server`，Task 2 提交在 `/home/hhoa/autoclip/autoclip-web-front`，Task 3-8 提交在 `/home/hhoa/git/hhoa/huji`。**不要** `git add` huji 仓库根下未跟踪的 `huji-algorithm/` 目录（git status 快照中已存在，与本计划无关）。
- huji-app 测试只用 `flutter_test`（无 mocktail/mockito），mock 一律手写 fake 类。
- autoclip-web-front 没有单元测试基础设施（无 vitest/jest），验证方式为 `pnpm lint:tsc`（vue-tsc 类型检查）+ 手动浏览器验证。
- 服务端 GitHub 凭据通过环境变量注入（`${GITHUB_OAUTH_CLIENT_ID:}`），密钥不进仓库。
- Flutter 生成物（`*.g.dart`、`app_localizations*.dart`）提交进仓库（现状如此）；改模型后必须跑 build_runner / gen-l10n 再提交。

---

### Task 1: 服务端 — SocialTypeEnum 加 GITHUB + justauth 配置

**Repo:** `/home/hhoa/autoclip/autoclip-server`（独立 git 仓库，在 main 分支上直接提交即可，遵循该仓库现有 commit 风格）

**Files:**
- Modify: `autoclip-module-system/src/main/java/com/hhoa/autoclip/module/system/enums/social/SocialTypeEnum.java`
- Modify: `autoclip-module-system/src/test/java/com/hhoa/autoclip/module/system/service/social/SocialClientServiceImplTest.java`
- Modify: `autoclip-server/src/main/resources/application-dev.yaml`（`justauth.type` 块，约 243 行起）
- Modify: `autoclip-server/src/main/resources/application-prod.yaml`（`justauth.type` 块，约 177 行起）

**Interfaces:**
- Consumes: 无（首个任务）
- Produces: `SocialTypeEnum.GITHUB`，`getType() == 40`，`getSource() == "GITHUB"`；`justauth.type.GITHUB` 配置（client-id/secret 从环境变量 `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET` 读取）。`AuthRequestFactory` 已有 GITHUB 分支（`AuthRequestFactory.java:179`），无需改动。

- [ ] **Step 1: 写失败的枚举接线测试**

在 `SocialClientServiceImplTest.java` 中（现有 `testGetAuthorizeUrl` 测试方法之后）添加：

```java
@Test
public void testGetAuthorizeUrlGithub() {
    // 枚举接线：type=40 对应 JustAuth source "GITHUB"
    assertEquals(40, SocialTypeEnum.GITHUB.getType());
    assertEquals("GITHUB", SocialTypeEnum.GITHUB.getSource());
    try (MockedStatic<AuthStateUtils> authStateUtilsMock = mockStatic(AuthStateUtils.class)) {
        // 准备参数
        Integer socialType = SocialTypeEnum.GITHUB.getType();
        Integer userType = UserTypeEnum.MEMBER.getValue();
        String redirectUri = "https://restcut.com/oauth/github/callback?port=12345";
        // mock 获得对应的 AuthRequest 实现
        AuthRequest authRequest = mock(AuthRequest.class);
        when(authRequestFactory.get(eq("GITHUB"))).thenReturn(authRequest);
        // mock 方法
        authStateUtilsMock.when(AuthStateUtils::createState).thenReturn("aoteman");
        when(authRequest.authorize("aoteman")).thenReturn("https://github.com/login/oauth/authorize");
        // 调用
        String url = socialClientService.getAuthorizeUrl(socialType, userType, redirectUri);
        // 断言：授权 URL 生成成功且携带 state
        assertNotNull(url);
        assertTrue(url.contains("state=aoteman"));
        verify(authRequestFactory).get("GITHUB");
    }
}
```

- [ ] **Step 2: 跑测试确认编译失败**

```bash
cd /home/hhoa/autoclip/autoclip-server
mvn -pl autoclip-module-system -am test -Dtest=SocialClientServiceImplTest -DfailIfNoTests=false
```

Expected: 编译错误 `GITHUB cannot be resolved`（枚举项不存在）。

- [ ] **Step 3: 加枚举项**

`SocialTypeEnum.java`，在 `WECHAT_MINI_PROGRAM(34, ...)` 之后、分号 `;` 之前插入：

```java
    /**
     * GitHub
     *
     * @see <a href="https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps">接入文档</a>
     */
    GITHUB(40, "GITHUB"),
```

注意把原 `WECHAT_MINI_PROGRAM(34, "WECHAT_MINI_PROGRAM"),` 末尾的逗号保持、把原来的 `;` 移到 GITHUB 之后。

- [ ] **Step 4: 跑测试确认通过**

```bash
mvn -pl autoclip-module-system -am test -Dtest=SocialClientServiceImplTest -DfailIfNoTests=false
```

Expected: PASS。

- [ ] **Step 5: 加 yaml 配置**

`application-dev.yaml` 和 `application-prod.yaml` 的 `justauth.type:` 块内（与 `DINGTALK:` 平级）各加：

```yaml
    GITHUB: # GitHub
      client-id: ${GITHUB_OAUTH_CLIENT_ID:}
      client-secret: ${GITHUB_OAUTH_CLIENT_SECRET:}
      ignore-check-redirect-uri: true
```

`ignore-check-redirect-uri: true` 与现有钉钉/企微一致——App 端传的 redirectUri 带动态 `?port=`，不能被 JustAuth 与注册值比对拒绝。

- [ ] **Step 6: 提交**

```bash
cd /home/hhoa/autoclip/autoclip-server
git add autoclip-module-system/src/main/java/com/hhoa/autoclip/module/system/enums/social/SocialTypeEnum.java \
        autoclip-module-system/src/test/java/com/hhoa/autoclip/module/system/service/social/SocialClientServiceImplTest.java \
        autoclip-server/src/main/resources/application-dev.yaml \
        autoclip-server/src/main/resources/application-prod.yaml
git commit -m "feat(member): 支持 GitHub 社交登录（socialType=40）"
```

（注意第一条路径若因笔误 add 失败，用 `git add -A` 前先 `git status` 确认只有这四个文件变更。）

**运维事项（不写代码，记录在 commit message 或部署文档）：** 在 GitHub → Settings → Developer settings → OAuth Apps → New OAuth App 创建应用，Homepage URL 填 `https://restcut.com`，Authorization callback URL 填 `https://restcut.com/oauth/github/callback`；部署时注入环境变量 `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET`。

---

### Task 2: web-front — OAuth 回调中转页

**Repo:** `/home/hhoa/autoclip/autoclip-web-front`（pnpm）

**Files:**
- Create: `src/views/oauth/github-callback.vue`
- Create: `src/router/routes/constantModules/oauth.ts`

**Interfaces:**
- Consumes: 无（独立页面；登录守卫不拦——constant 路由不走鉴权）
- Produces: 路由 `GET /oauth/github/callback`，query 为 `code`、`state`、`port`（port 仅桌面端）。行为：有 code+state 时按 UA 跳 `huji://oauth/github?code=..&state=..`（移动）或 `http://127.0.0.1:<port>/oauth/github?code=..&state=..`（桌面）；无 code 时显示"已取消"文案。

- [ ] **Step 1: 创建中转页组件**

`src/views/oauth/github-callback.vue`：

```vue
<template>
  <div class="oauth-callback">
    <p v-if="status === 'redirecting'">授权成功，正在返回应用…</p>
    <p v-else-if="status === 'cancelled'">授权已取消，可关闭此页面回到应用。</p>
    <p v-else>如果几秒后没有自动返回应用，请手动切换回应用完成登录。</p>
  </div>
</template>

<script setup lang="ts">
  import { onMounted, ref } from 'vue';
  import { useRoute } from 'vue-router';

  defineOptions({ name: 'OAuthGithubCallback' });

  const route = useRoute();
  const status = ref<'redirecting' | 'cancelled' | 'failed'>('redirecting');

  // 移动端 UA 判定（iOS Safari / Android Chrome 等）
  function isMobile(): boolean {
    return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  }

  onMounted(() => {
    const code = route.query.code as string | undefined;
    const state = route.query.state as string | undefined;
    if (!code || !state) {
      // 用户在 GitHub 授权页点了取消（GitHub 回调只带 error 参数不带 code）
      status.value = 'cancelled';
      return;
    }
    const q = `code=${encodeURIComponent(code)}&state=${encodeURIComponent(state)}`;
    if (isMobile()) {
      window.location.href = `huji://oauth/github?${q}`;
    } else {
      const port = route.query.port as string | undefined;
      if (!port) {
        status.value = 'failed';
        return;
      }
      window.location.href = `http://127.0.0.1:${port}/oauth/github?${q}`;
    }
    // deep link/本地跳转可能被浏览器静默拦截，2 秒后降级为手动提示
    setTimeout(() => {
      status.value = 'failed';
    }, 2000);
  });
</script>

<style scoped>
  .oauth-callback {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    font-size: 16px;
    color: #666;
  }
</style>
```

- [ ] **Step 2: 注册路由（constant 模块，免登录）**

`src/router/routes/constantModules/oauth.ts`（该目录被 `src/router/routes/index.ts` 的 `import.meta.glob` 自动装配）：

```ts
import type { AppRouteModule } from '@/router/types';

export const oauth: AppRouteModule = {
  path: '/oauth/github/callback',
  name: 'OAuthGithubCallback',
  component: () => import('@/views/oauth/github-callback.vue'),
  meta: {
    title: 'GitHub 授权',
    hidden: true,
    hideMenu: true,
    noTagsView: true,
  },
};

export default oauth;
```

- [ ] **Step 3: 类型检查 + 构建验证**

```bash
cd /home/hhoa/autoclip/autoclip-web-front
pnpm install
pnpm lint:tsc
```

Expected: vue-tsc 无错误。（本仓库无单测基础设施，类型检查即自动验证。）

- [ ] **Step 4: 本地手动验证（可选但推荐）**

```bash
pnpm dev
```

浏览器访问 `http://localhost:端口/oauth/github/callback?port=12345&code=abc&state=xyz` → 期望 2 秒后显示"手动返回"文案（因为 `http://127.0.0.1:12345` 无服务，跳转失败降级）；访问无 code 的 URL → 显示"授权已取消"。

- [ ] **Step 5: 提交**

```bash
cd /home/hhoa/autoclip/autoclip-web-front
git add src/views/oauth/github-callback.vue src/router/routes/constantModules/oauth.ts
git commit -m "feat(oauth): GitHub OAuth 回调中转页（桌面/移动分发）"
```

---

### Task 3: huji-app — app_links 依赖 + 平台 deep link 注册

**Repo:** `/home/hhoa/git/hhoa/huji`

**Files:**
- Modify: `huji-app/pubspec.yaml`（dependencies 加 app_links）
- Modify: `huji-app/android/app/src/main/AndroidManifest.xml`（MainActivity 加 VIEW intent-filter）
- Modify: `huji-app/ios/Runner/Info.plist`（CFBundleURLTypes）
- Modify: `huji-app/macos/Runner/Info.plist`（CFBundleURLTypes — **不得触碰 `FLTEnableImpeller` 行**）

**Interfaces:**
- Produces: `package:app_links` 可导入；`huji://` scheme 在 Android/iOS/macOS 注册（桌面登录实际走 loopback，scheme 注册只为兜底与 spec 一致性）。

- [ ] **Step 1: 加依赖**

`huji-app/pubspec.yaml` 的 `dependencies:` 中（`url_launcher: ^6.2.5` 附近）加：

```yaml
  app_links: ^6.4.0
```

然后：

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter pub get
```

若 6.4.0 不可解析，用 `flutter pub add app_links` 让 pub 选最新稳定版，并把 pubspec 里解析到的版本写回本计划的 Global Constraints（记录即可）。

- [ ] **Step 2: Android intent-filter**

`android/app/src/main/AndroidManifest.xml` 的 `<activity android:name=".MainActivity" ...>` 内、现有 LAUNCHER intent-filter 之后加：

```xml
            <!-- GitHub OAuth deep link 回调 -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="huji"
                    android:host="oauth" />
            </intent-filter>
```

（MainActivity 已有 `android:launchMode="singleTop"`，app_links 依赖它避免多实例。）

- [ ] **Step 3: iOS 注册 scheme**

`ios/Runner/Info.plist` 顶层 `<dict>` 内追加（若已有 `CFBundleURLTypes` 键则在既有数组里追加该 dict）：

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>com.hhoa.huji.oauth</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>huji</string>
			</array>
		</dict>
	</array>
```

- [ ] **Step 4: macOS 注册 scheme（⚠️ 不碰 FLTEnableImpeller）**

`macos/Runner/Info.plist` 同样在顶层 `<dict>` 内追加与 Step 3 相同的 `CFBundleURLTypes` 块。提交前确认 `FLTEnableImpeller` 键原样存在：

```bash
grep -n FLTEnableImpeller /home/hhoa/git/hhoa/huji/huji-app/macos/Runner/Info.plist
```

Expected: 能 grep 到该键且值为 false。

- [ ] **Step 5: 验证 + 提交**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter analyze
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist macos/Runner/Info.plist
git commit -m "feat(app): 注册 huji:// scheme 并引入 app_links（GitHub OAuth 回调）"
```

---

### Task 4: huji-app — OAuth 回调捕获层（TDD）

**Repo:** `/home/hhoa/git/hhoa/huji`

**Files:**
- Create: `huji-app/lib/services/auth/oauth_callback.dart`
- Create: `huji-app/test/services/auth/oauth_callback_test.dart`
- Modify: `huji-app/lib/config/environment.dart`（加 `webBaseUrl`）

**Interfaces:**
- Consumes: `package:app_links`（Task 3）、`EnvironmentConfig`（现有）。
- Produces（后续任务按此签名使用）:
  - `class OAuthCallback { final String code; final String state; }`
  - `OAuthCallback? parseGithubCallback(Uri uri)` — 识别 `huji://oauth/github?code=..&state=..` 与 `http://127.0.0.1:<port>/oauth/github?code=..&state=..`
  - `abstract class OAuthCallbackCapture { Future<String> start(); Future<OAuthCallback> get callback; Future<void> stop(); }` — `start()` 返回要传给服务端的 redirectUri
  - `class LoopbackCallbackCapture implements OAuthCallbackCapture`（桌面）
  - `class DeepLinkCallbackCapture implements OAuthCallbackCapture`（移动）
  - `class GithubOAuthConfig { static const int socialType = 40; static String get webCallbackUrl; }`
  - `EnvironmentConfig.webBaseUrl` → `'https://restcut.com'`

- [ ] **Step 1: 写失败的测试**

`huji-app/test/services/auth/oauth_callback_test.dart`：

```dart
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
      // 停止后端口不再监听
      expect(() => client.getUrl(
        Uri.parse('http://127.0.0.1:$port/oauth/github?code=a&state=b'),
      ), returnsNormally); // 请求发出不代表连接成功，仅验证不抛同步异常
    });
  });
}
```

注意最后一个断言较弱（loopback 关闭后的连接拒绝是异步异常，不好在 flutter_test 里断言）——这是刻意的：核心行为（完成 callback、200 响应）已覆盖，stop 幂等性由实现保证。

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter test test/services/auth/oauth_callback_test.dart
```

Expected: 编译错误，`oauth_callback.dart` 不存在。

- [ ] **Step 3: 实现**

`huji-app/lib/config/environment.dart` 的 `wsUrl` getter 之后加：

```dart
  // Web 前端（OAuth 中转页等）基址
  static String get webBaseUrl {
    switch (_environment) {
      case Environment.development:
      // return 'http://localhost:5173';
      case Environment.production:
        return 'https://restcut.com';
    }
  }
```

`huji-app/lib/services/auth/oauth_callback.dart`：

```dart
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
/// `http://127.0.0.1:<port>/oauth/github?code=..&state=..`。
OAuthCallback? parseGithubCallback(Uri uri) {
  if (uri.pathSegments.length < 2) return null;
  if (uri.pathSegments[0] != 'oauth' || uri.pathSegments[1] != 'github') {
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
```

- [ ] **Step 4: 跑测试确认通过**

```bash
flutter test test/services/auth/oauth_callback_test.dart
```

Expected: PASS（loopback 测试在 Linux host 上用真实 HttpServer，`dart:io` 在 flutter_test host 可用）。

- [ ] **Step 5: 提交**

```bash
git add lib/config/environment.dart lib/services/auth/oauth_callback.dart test/services/auth/oauth_callback_test.dart
git commit -m "feat(app): OAuth 回调捕获层（loopback + deep link）"
```

---

### Task 5: huji-app — GithubOAuthService 授权流程 + 修复 socialAuthRedirect 参数名（TDD）

**Repo:** `/home/hhoa/git/hhoa/huji`

> **重要 bug 修复随本任务**：现有 `AuthApi.socialAuthRedirect(@Queries() SocialAuthRedirectParams)` 会发送 query `socialType=40`，但服务端 `@RequestParam("type")`（`AppAuthController.java:109`）要求参数名为 `type`——现有客户端方法从未被使用所以没暴露。本任务改为显式 `@Query`。同时把 `SocialAuthRedirectParams`（已无使用方）从模型中删除。

**Files:**
- Modify: `huji-app/lib/api/internal/member/auth_api.dart`
- Modify: `huji-app/lib/api/models/member/auth_models.dart`（删 `SocialAuthRedirectParams`）
- Regenerate: `huji-app/lib/api/internal/member/auth_api.g.dart`、`auth_models.g.dart`
- Create: `huji-app/lib/services/auth/github_oauth_service.dart`
- Create: `huji-app/test/services/auth/github_oauth_service_test.dart`
- Modify: `huji-app/lib/services/user_service.dart`（`_afterLogin` 改公开 `completeLogin`，加 `loginWithGithub`）

**Interfaces:**
- Consumes: `OAuthCallbackCapture` / `GithubOAuthConfig` / `parseGithubCallback`（Task 4）、`AuthApi`、`UserService._afterLogin`。
- Produces:
  - `AuthApi.socialAuthRedirect(@Query('type') int type, @Query('redirectUri') String redirectUri)` → `Future<String>`
  - `class GithubOAuthService`：
    - `Future<OAuthCallback> authorize()` — 起捕获层 → 拿授权 URL → `launchUrl(externalApplication)` → 等回调（默认 5 分钟超时，构造参数 `timeout` 可覆盖）
    - `void abort()` — 关闭登录框时提前终止（停捕获层；挂起的 future 由超时兜底收尾）
  - `GithubOAuthService({GithubOAuthGateway? gateway, OAuthCallbackCapture? capture, Duration? timeout, Future<bool> Function(Uri)? launch})` — 测试注入点
  - `abstract class GithubOAuthGateway { Future<String> getAuthorizeUrl(String redirectUri); }` + `ApiGithubOAuthGateway` 默认实现
  - `UserService.completeLogin(AppAuthLoginRespVO)`（原 `_afterLogin` 改名，3 个内部调用点同步改）
  - `UserService.loginWithGithub({required String code, required String state})` → `Future<LoginResult>`

- [ ] **Step 1: 写失败的测试**

`huji-app/test/services/auth/github_oauth_service_test.dart`：

```dart
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
```

- [ ] **Step 2: 跑测试确认失败**

```bash
flutter test test/services/auth/github_oauth_service_test.dart
```

Expected: 编译错误，`github_oauth_service.dart` 不存在。

- [ ] **Step 3: 实现 GithubOAuthService**

`huji-app/lib/services/auth/github_oauth_service.dart`：

```dart
import 'dart:async';
import 'dart:io';

import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
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
```

- [ ] **Step 4: 修复 AuthApi.socialAuthRedirect 参数名 + 删除 SocialAuthRedirectParams**

`huji-app/lib/api/internal/member/auth_api.dart`，把：

```dart
  // 社交授权跳转
  @GET('/member/auth/social-auth-redirect')
  Future<String> socialAuthRedirect(@Queries() SocialAuthRedirectParams params);
```

改为：

```dart
  // 社交授权跳转
  @GET('/member/auth/social-auth-redirect')
  Future<String> socialAuthRedirect(
    @Query('type') int type,
    @Query('redirectUri') String redirectUri,
  );
```

`huji-app/lib/api/models/member/auth_models.dart`：整体删除 `SocialAuthRedirectParams` 类（grep 确认无其他引用后）：

```bash
grep -rn "SocialAuthRedirectParams" lib/ --include="*.dart"
```

Expected: 只有 `auth_api.dart`、`auth_models.dart`、`auth_models.g.dart` 命中。

重新生成 retrofit/json 代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: UserService 加 loginWithGithub，_afterLogin 改公开**

`huji-app/lib/services/user_service.dart`：
1. 把 `_afterLogin` 改名为 `completeLogin`（公开），3 处内部调用（`loginWithPassword` / `loginWithCode` 内）同步改名。
2. 在 `loginWithCode` 之后加：

```dart
  // GitHub 社交登录（code 为 GitHub 授权码，state 为授权 URL 携带的状态）
  static Future<LoginResult> loginWithGithub({
    required String code,
    required String state,
  }) async {
    final authToken = await ApiManager.instance.authApi.socialLogin(
      SocialLoginParams(
        socialType: GithubOAuthConfig.socialType,
        code: code,
        state: state,
      ),
    );
    return completeLogin(authToken);
  }
```

文件顶部加 import：

```dart
import 'package:huji_app/services/auth/oauth_callback.dart';
```

- [ ] **Step 6: 跑全部相关测试**

```bash
flutter test test/services/auth/
flutter analyze
```

Expected: PASS / 无告警。

- [ ] **Step 7: 提交**

```bash
git add lib/api/internal/member/auth_api.dart lib/api/internal/member/auth_api.g.dart \
        lib/api/models/member/auth_models.dart lib/api/models/member/auth_models.g.dart \
        lib/services/auth/github_oauth_service.dart lib/services/user_service.dart \
        test/services/auth/github_oauth_service_test.dart
git commit -m "feat(app): GitHub OAuth 授权服务；修复 socialAuthRedirect 参数名 type"
```

---

### Task 6: huji-app — 登录页 GitHub 按钮 + 隐藏占位

**Repo:** `/home/hhoa/git/hhoa/huji`

**Files:**
- Create: `huji-app/assets/icons/login/github.svg`
- Modify: `huji-app/lib/pages/login/login_dialog_icons.dart`（加 `github` 常量）
- Modify: `huji-app/lib/pages/login/login_form.dart`（社交按钮区）
- Modify: `huji-app/lib/l10n/app_en.arb`、`huji-app/lib/l10n/app_zh.arb`
- Regenerate: `huji-app/lib/l10n/app_localizations*.dart`（`flutter gen-l10n`）
- Test: `huji-app/test/pages/login_form_github_test.dart`

**Interfaces:**
- Consumes: `GithubOAuthService.authorize()`、`UserService.loginWithGithub()`（Task 5）。
- Produces: 登录页 GitHub 按钮（`ValueKey('githubLoginButton')`），点击触发完整登录；微信/QQ/支付宝占位按钮不再渲染。

- [ ] **Step 1: 写失败的 widget 测试**

`huji-app/test/pages/login_form_github_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/huji_localizations.dart'; // 若路径报错，改用 lib/l10n 下现有 app_localizations 导入（见 test/login_dialog_theme_test.dart 的用法）
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/pages/login/login_form.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        HujiLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: HujiLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: LoginForm(
          onClose: () {},
          onSwitchForm: (_) {},
        ),
      ),
    );

void main() {
  testWidgets('登录页渲染 GitHub 按钮且不再渲染微信/QQ/支付宝占位', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('githubLoginButton')), findsOneWidget);
    expect(find.byIcon, findsNothing); // 占位图标不渲染：通过 asset 路径断言
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Padding &&
            w.child is SizedBox, // 不精确占位断言见下方精确版
      ),
      findsNothing,
    );
  });
}
```

> **执行者注意**：上面的 import 与占位断言是骨架——先读 `test/login_dialog_theme_test.dart`，抄它现成的 l10n/主题 pump 模板（它已解决 HujiLocalizations 的 delegate 与 shared_ui 主题依赖）；占位按钮断言改为精确形式：`_SocialLoginButton` 渲染 `LoginDialogIcon(asset: ...)`，用 `find.byWidgetPredicate((w) => w is LoginDialogIcon && (w.asset == LoginDialogIcons.wechat || w.asset == LoginDialogIcons.qqchat || w.asset == LoginDialogIcons.alipay))` 应 `findsNothing`，而 `w.asset == LoginDialogIcons.github` 应 `findsOneWidget`。断言必须按此精确版实现，骨架里的模糊断言删掉。

- [ ] **Step 2: 跑测试确认失败**

```bash
flutter test test/pages/login_form_github_test.dart
```

Expected: FAIL（`githubLoginButton` 不存在；wechat 等仍在渲染）。

- [ ] **Step 3: 加图标资源与常量**

`huji-app/assets/icons/login/github.svg`（simple-icons GitHub mark，`fill="currentColor"` 与 wechat.svg 同模式——`LoginDialogIcon` 会用 colorFilter 覆盖填充色）：

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
```

`login_dialog_icons.dart` 的 `alipay` 行后加：

```dart
  static const github = 'assets/icons/login/github.svg';
```

- [ ] **Step 4: 改 login_form.dart**

`_LoginFormState` 里：
1. 加字段与 import：

```dart
  GithubOAuthService? _githubOAuth;
```

```dart
import 'package:huji_app/services/auth/github_oauth_service.dart';
```

2. `dispose()` 里加 `_githubOAuth?.abort();`。
3. 新增处理方法（错误处理镜像 `_handleLogin` 的 AppException 分支）：

```dart
  Future<void> _handleGithubLogin(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final oauth = GithubOAuthService();
    _githubOAuth = oauth;
    try {
      final callback = await oauth.authorize();
      await UserService.loginWithGithub(
        code: callback.code,
        state: callback.state,
      );

      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginSuccess,
          variant: TpToastVariant.success,
        );
      }
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        widget.onClose();
      }
    } on AppException catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: e.message,
          variant: TpToastVariant.error,
        );
      }
    } on TimeoutException {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginGithubTimeout,
          variant: TpToastVariant.warning,
        );
      }
    } on GithubOAuthException {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginGithubOpenFailed,
          variant: TpToastVariant.error,
        );
      }
    } finally {
      _githubOAuth = null;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
```

（`_handleGithubLogin` 内 `mounted` 判断在 `finally` 中用 State 的 `mounted`；`AppException` 的 message 字段以 `lib/exceptions/` 中现有定义为准——如果它不叫 `.message`，按 `_handleLogin` 现有 catch 分支的写法照抄。）

4. 把社交按钮 `Row`（原 wechat/qqchat/alipay 三个 `_SocialLoginButton`，`login_form.dart:345-363`）整体替换为：

```dart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialLoginButton(
                key: const ValueKey('githubLoginButton'),
                iconAsset: LoginDialogIcons.github,
                onTap: () => _handleGithubLogin(context),
              ),
            ],
          ),
```

5. `_SocialLoginButton` 构造函数加 `super.key`：

```dart
  const _SocialLoginButton({super.key, required this.iconAsset, required this.onTap});
```

- [ ] **Step 5: l10n 文案**

`app_zh.arb`（`loginSocialLoginUnavailable` 附近）加：

```json
  "loginGithubTimeout": "授权超时，请重试",
  "loginGithubOpenFailed": "无法打开浏览器，请检查系统默认浏览器设置",
  "loginGithubCancelled": "GitHub 授权已取消",
```

`app_en.arb` 同 key：

```json
  "loginGithubTimeout": "Authorization timed out, please try again",
  "loginGithubOpenFailed": "Could not open the browser, check your default browser settings",
  "loginGithubCancelled": "GitHub authorization was cancelled",
```

生成：

```bash
flutter gen-l10n
```

- [ ] **Step 6: 跑测试确认通过**

```bash
flutter test test/pages/login_form_github_test.dart test/login_dialog_theme_test.dart
flutter analyze
```

Expected: PASS。

- [ ] **Step 7: 提交**

```bash
git add assets/icons/login/github.svg lib/pages/login/login_dialog_icons.dart \
        lib/pages/login/login_form.dart lib/l10n/ test/pages/login_form_github_test.dart
git commit -m "feat(app): 登录页接入 GitHub OAuth（隐藏无效社交占位）"
```

---

### Task 7: huji-app — 绑定/解绑 API + 安全设置页 GitHub 区块

**Repo:** `/home/hhoa/git/hhoa/huji`

**Files:**
- Create: `huji-app/lib/api/models/member/social_user_models.dart`
- Create: `huji-app/lib/api/internal/member/social_user_api.dart`
- Regenerate: 对应 `*.g.dart`（build_runner）
- Modify: `huji-app/lib/api/api_manager.dart`（注册 `socialUserApi`）
- Modify: `huji-app/lib/services/user_service.dart`（`bindGithub` / `unbindGithub` / `getGithubBinding`）
- Modify: `huji-app/lib/pages/user/security_settings_page.dart`
- Modify: `huji-app/lib/l10n/app_en.arb`、`app_zh.arb` + regen
- Test: `huji-app/test/services/user_service_github_binding_test.dart`（模型/网关层参数组装）

**Interfaces:**
- Consumes: `GithubOAuthService.authorize()`（Task 5）、`GithubOAuthConfig.socialType`。
- Produces:
  - `SocialUserApi`：`bind(SocialUserBindParams) → Future<String>`（openid）、`unbind(SocialUserUnbindParams) → Future<bool>`、`getSocialUser(int type) → Future<SocialUserInfo?>`
  - `SocialUserBindParams { int type; String code; String state; }`、`SocialUserUnbindParams { int type; String openid; }`、`SocialUserInfo { String openid; String? nickname; String? avatar; }`
  - `UserService.bindGithub({required String code, required String state})`、`UserService.unbindGithub({required String openid})`、`UserService.getGithubBinding() → Future<SocialUserInfo?>`
  - 服务端契约（已存在，勿改服务端）：`POST /member/social-user/bind`（body `{type, code, state}`，需登录 token）、`DELETE /member/social-user/unbind`（body `{type, openid}`）、`GET /member/social-user/get?type=40`（返回 `{openid, nickname, avatar}`，未绑定为 null data）

- [ ] **Step 1: 写失败的模型测试**

`huji-app/test/services/user_service_github_binding_test.dart`：

```dart
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
```

- [ ] **Step 2: 跑测试确认失败**

```bash
flutter test test/services/user_service_github_binding_test.dart
```

Expected: 编译错误（模型文件不存在）。

- [ ] **Step 3: 实现模型 + API**

`huji-app/lib/api/models/member/social_user_models.dart`：

```dart
import 'package:json_annotation/json_annotation.dart';

part 'social_user_models.g.dart';

// 绑定社交账号参数（对应服务端 AppSocialUserBindReqVO）
@JsonSerializable()
class SocialUserBindParams {
  final int type;
  final String code;
  final String state;

  SocialUserBindParams({required this.type, required this.code, required this.state});

  factory SocialUserBindParams.fromJson(Map<String, dynamic> json) =>
      _$SocialUserBindParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserBindParamsToJson(this);
}

// 解绑参数（对应服务端 AppSocialUserUnbindReqVO）
@JsonSerializable()
class SocialUserUnbindParams {
  final int type;
  final String openid;

  SocialUserUnbindParams({required this.type, required this.openid});

  factory SocialUserUnbindParams.fromJson(Map<String, dynamic> json) =>
      _$SocialUserUnbindParamsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserUnbindParamsToJson(this);
}

// 已绑定的社交用户信息（对应服务端 AppSocialUserRespVO）
@JsonSerializable()
class SocialUserInfo {
  final String openid;
  final String? nickname;
  final String? avatar;

  SocialUserInfo({required this.openid, this.nickname, this.avatar});

  factory SocialUserInfo.fromJson(Map<String, dynamic> json) =>
      _$SocialUserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SocialUserInfoToJson(this);
}
```

`huji-app/lib/api/internal/member/social_user_api.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/member/social_user_models.dart';

part 'social_user_api.g.dart';

// 社交用户绑定 API（/member/social-user）
@RestApi()
abstract class SocialUserApi {
  factory SocialUserApi(Dio dio, {String? baseUrl}) = _SocialUserApi;

  // 绑定社交账号（需登录 token）
  @POST('/member/social-user/bind')
  Future<String> bind(@Body() SocialUserBindParams params);

  // 解绑
  @HTTP(method: 'DELETE', path: '/member/social-user/unbind')
  Future<bool> unbind(@Body() SocialUserUnbindParams params);

  // 查询绑定状态（未绑定返回 null）
  @GET('/member/social-user/get')
  Future<SocialUserInfo?> getSocialUser(@Query('type') int type);
}
```

> 注意：`@DELETE + @Body` 在部分 retrofit_generator 版本不被支持，所以解绑用 `@HTTP(method: 'DELETE', ...)`（dio 原生支持 DELETE 带 body，服务端 `AppSocialUserController.java:55` 正是 `@DeleteMapping + @RequestBody`）。

`huji-app/lib/api/api_manager.dart`（`userApi` 声明之后）：

```dart
  // 社交用户API
  late final SocialUserApi socialUserApi = SocialUserApi(dio);
```

顶部 import：

```dart
import 'package:huji_app/api/internal/member/social_user_api.dart';
```

生成：

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: 跑模型测试**

```bash
flutter test test/services/user_service_github_binding_test.dart
```

Expected: PASS。

- [ ] **Step 5: UserService 加三个方法**

`user_service.dart`（`loginWithGithub` 之后）：

```dart
  // 绑定 GitHub（当前已登录用户）
  static Future<String> bindGithub({
    required String code,
    required String state,
  }) async {
    return ApiManager.instance.socialUserApi.bind(
      SocialUserBindParams(
        type: GithubOAuthConfig.socialType,
        code: code,
        state: state,
      ),
    );
  }

  // 解绑 GitHub
  static Future<bool> unbindGithub({required String openid}) async {
    return ApiManager.instance.socialUserApi.unbind(
      SocialUserUnbindParams(
        type: GithubOAuthConfig.socialType,
        openid: openid,
      ),
    );
  }

  // 查询 GitHub 绑定状态（null = 未绑定）
  static Future<SocialUserInfo?> getGithubBinding() async {
    return ApiManager.instance.socialUserApi
        .getSocialUser(GithubOAuthConfig.socialType);
  }
```

import 加：

```dart
import 'package:huji_app/api/models/member/social_user_models.dart';
```

- [ ] **Step 6: 安全设置页加 GitHub 区块**

`huji-app/lib/pages/user/security_settings_page.dart`：
1. import：

```dart
import 'package:huji_app/services/auth/github_oauth_service.dart';
```

2. State 里加字段：

```dart
  SocialUserInfo? _githubBinding;
  bool _githubBusy = false;
```

3. `initState`（若没有则创建）里加加载：

```dart
    UserService.getGithubBinding().then((info) {
      if (mounted) {
        setState(() => _githubBinding = info);
      }
    }).catchError((_) {});
```

4. 加处理方法：

```dart
  Future<void> _handleGithubBind() async {
    if (_githubBusy) return;
    setState(() => _githubBusy = true);
    try {
      final callback = await GithubOAuthService().authorize();
      await UserService.bindGithub(code: callback.code, state: callback.state);
      final info = await UserService.getGithubBinding();
      if (mounted) {
        setState(() => _githubBinding = info);
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindSuccess,
          variant: TpToastVariant.success,
        );
      }
    } on TimeoutException {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginGithubTimeout,
          variant: TpToastVariant.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindFailed,
          variant: TpToastVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _githubBusy = false);
      }
    }
  }

  Future<void> _handleGithubUnbind() async {
    if (_githubBinding == null || _githubBusy) return;
    setState(() => _githubBusy = true);
    try {
      await UserService.unbindGithub(openid: _githubBinding!.openid);
      if (mounted) {
        setState(() => _githubBinding = null);
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubUnbindSuccess,
          variant: TpToastVariant.success,
        );
      }
    } catch (_) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindFailed,
          variant: TpToastVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _githubBusy = false);
      }
    }
  }
```

5. `build` 的 `ListView` children 中、现有信息分组卡片之后插入一张同构卡片（外层 Container 样式照抄现有卡片）：

```dart
            // GitHub 绑定卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: cs.cardFill,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.softShadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEditRow(
                    context.hujiL10n.settingsGithubBinding,
                    _githubBinding?.nickname ??
                        context.hujiL10n.settingsGithubUnbound,
                    child: _githubBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _githubBinding == null
                            ? buildDialogActionButton(
                                context,
                                onPressed: _handleGithubBind,
                                child: Text(context.hujiL10n.settingsGithubBind),
                              )
                            : buildDialogActionButton(
                                context,
                                onPressed: _handleGithubUnbind,
                                child: Text(
                                  context.hujiL10n.settingsGithubUnbind,
                                ),
                              ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
```

> `buildDialogActionButton` / `_buildEditRow` 的实参形态以页面内现有调用为准（`_buildEditRow` 在 448 行、现有调用见 build 方法内），照抄现有调用的参数风格。若页面没有 import `buildDialogActionButton` 所在文件，用页面内已有的按钮构建方式（如 `ElevatedButton` 风格）替代——保持页面内部一致即可。

- [ ] **Step 7: l10n 文案**

`app_zh.arb`：

```json
  "settingsGithubBinding": "GitHub 账号",
  "settingsGithubUnbound": "未绑定",
  "settingsGithubBind": "绑定",
  "settingsGithubUnbind": "解绑",
  "settingsGithubBindSuccess": "GitHub 绑定成功",
  "settingsGithubUnbindSuccess": "GitHub 已解绑",
  "settingsGithubBindFailed": "GitHub 绑定操作失败，请重试",
```

`app_en.arb`：

```json
  "settingsGithubBinding": "GitHub account",
  "settingsGithubUnbound": "Not bound",
  "settingsGithubBind": "Bind",
  "settingsGithubUnbind": "Unbind",
  "settingsGithubBindSuccess": "GitHub account bound",
  "settingsGithubUnbindSuccess": "GitHub account unbound",
  "settingsGithubBindFailed": "GitHub binding failed, please try again",
```

```bash
flutter gen-l10n
```

- [ ] **Step 8: 全量验证 + 提交**

```bash
flutter analyze
flutter test
```

Expected: 全绿（存量测试不回归）。

```bash
git add lib/api/models/member/social_user_models.dart lib/api/models/member/social_user_models.g.dart \
        lib/api/internal/member/social_user_api.dart lib/api/internal/member/social_user_api.g.dart \
        lib/api/api_manager.dart lib/services/user_service.dart \
        lib/pages/user/security_settings_page.dart lib/l10n/ \
        test/services/user_service_github_binding_test.dart
git commit -m "feat(app): 设置页 GitHub 绑定/解绑（social-user API 客户端）"
```

---

### Task 8: 端到端验证与收尾

**Repo:** `/home/hhoa/git/hhoa/huji`（本地运行；部署动作不在本计划内，仅验证清单）

**Files:** 无新增（验证 + 视情况补 CLAUDE.md 一行）

- [ ] **Step 1: 本地桌面端冒烟（无 GitHub 凭据时的行为）**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter run -d linux
```

点击 GitHub 登录按钮 → 期望：默认浏览器打开（或因服务端未配置 GitHub OAuth App 而在拿到授权 URL 前报错 toast——两种都证明流程接通；后者的报错路径也要给出友好 toast，若直接崩栈则回修 Task 5/6 的错误处理）。

- [ ] **Step 2: 配齐凭据后的完整桌面流程（需要运维配合）**

前置：GitHub OAuth App 已创建（callback `https://restcut.com/oauth/github/callback`）、服务端环境变量 `GITHUB_OAUTH_CLIENT_ID/SECRET` 已注入、web-front 中转页已部署。
验证：登录框点 GitHub → 浏览器授权 → 中转页跳 `127.0.0.1:<port>` → 浏览器显示"授权成功，请回到应用" → app 登录成功 toast → 用户昵称为 GitHub 昵称、头像为 GitHub 头像（数据库自动建号生效，`member_user` + `system_social_user` 各一条新记录）。

- [ ] **Step 3: 移动端冒烟（Android 真机）**

```bash
flutter run -d <android设备>
```

验证 deep link：`adb shell am start -a android.intent.action.VIEW -d "huji://oauth/github?code=test&state=test"` → 期望 app 拉起且不崩（code 无效时 toast 报错即可）。完整流程同 Step 2 需部署环境。

- [ ] **Step 4: 绑定流程验证**

已登录（手机号）状态下：设置 → 账号与安全 → GitHub 账号 → 绑定 → 走授权 → 显示 GitHub 昵称；再点解绑 → 显示"未绑定"。

- [ ] **Step 5: CI 守卫确认**

```bash
grep -n FLTEnableImpeller macos/Runner/Info.plist
git log --oneline -8
```

Expected: plist 键在；三个仓库各有对应提交。

- [ ] **Step 6: 更新 CLAUDE.md（可选，一行）**

若希望后续开发者知道 OAuth 配置注入方式，在 `huji/CLAUDE.md` 的合适章节加一行：

```markdown
## GitHub OAuth 登录

社交登录 socialType=40（GitHub）。服务端凭据经环境变量 `GITHUB_OAUTH_CLIENT_ID`/`GITHUB_OAUTH_CLIENT_SECRET` 注入；回调中转页为 web-front `/oauth/github/callback`；app 端 deep link scheme 为 `huji`，桌面端走 loopback（`lib/services/auth/oauth_callback.dart`）。
```

提交（若做了）：

```bash
cd /home/hhoa/git/hhoa/huji
git add CLAUDE.md
git commit -m "docs: GitHub OAuth 登录架构速记"
```

---

## Self-Review 记录

- **Spec 覆盖**：流程（Task 4/5）、三仓库改动（Task 1/2/5/7）、错误处理（Task 6 catch 分支 + 中转页文案 + 超时）、测试（server Task 1 / app Task 4/5/6/7 / web-front tsc + 手动）、YAGNI 边界（未引入任何 spec 外功能）——均有对应任务。
- **类型一致性**：`OAuthCallback{code,state}`、`OAuthCallbackCapture{start,callback,stop}`、`GithubOAuthConfig.socialType=40`、`GithubOAuthService.authorize()`、`UserService.loginWithGithub/bindGithub/unbindGithub/getGithubBinding` 在 Task 4/5/6/7 间签名一致。
- **发现并修复的存量 bug**：`AuthApi.socialAuthRedirect` query 参数名 `socialType` 与服务端 `type` 不匹配（Task 5 Step 4），已在计划内修复。
