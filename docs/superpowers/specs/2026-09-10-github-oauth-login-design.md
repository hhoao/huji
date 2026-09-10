# GitHub OAuth 登录设计

日期：2026-09-10
状态：已批准
范围：huji-app（Flutter）+ autoclip-server + autoclip-web-front

## 目标

huji 支持使用 GitHub 账号登录（桌面 + 移动全平台），并支持已有账号在
设置页手动绑定/解绑 GitHub。首次 GitHub 登录自动注册会员账号（昵称、
头像取自 GitHub 资料）。

## 背景

- 服务端（autoclip-server）已具备完整的 JustAuth 社交登录框架：
  `/member/auth/social-auth-redirect`（返回授权 URL）与
  `/member/auth/social-login`（code 换 token）均已存在；
  `AuthRequestFactory` 已内置 GITHUB 分支（JustAuth 原生支持）。
  缺少：`SocialTypeEnum` 无 GITHUB 项、yaml 无 client 配置。
- huji-app 的 API 客户端已有 `socialAuthRedirect` / `socialLogin` 方法与
  `SocialLoginParams` 模型，但登录页社交按钮均为"暂不可用"占位，
  实际 OAuth 流程（打开浏览器 → 捕获回调 code）未实现。
- GitHub OAuth App 回调 URL 要求 HTTPS（localhost 除外），自定义
  scheme 不被官方支持——由此选定方案 A。

## 方案（已批准：方案 A — H5 回调中转 + 平台分发）

```
用户点击"GitHub 登录"
  → App 调 GET /member/auth/social-auth-redirect?type=40&redirectUri=<回调地址>
  → App 用 url_launcher 打开系统默认浏览器
  → 用户在 GitHub 授权
  → GitHub 回调 https://<web域名>/oauth/github/callback?code=xxx&state=xxx&port=...
  → 中转页按平台分发：
     · 移动端：location.href = 'huji://oauth/github?code=...&state=...'
     · 桌面端：location.href = 'http://127.0.0.1:<port>/oauth/github?code=...&state=...'
  → App 捕获 code，调 POST /member/auth/social-login {type:40, code, state}
  → 服务端：已绑定 → 返回 token；未绑定 → 自动注册 + 绑定 + 返回 token
  → App 复用现有 token 持久化 + UserBloc 登录流程
```

### 关键决策

- **回调中转页统一固定 URL**：GitHub OAuth App 注册的 callback URL 是
  固定的中转页地址；桌面端 loopback 端口随机分配，作为授权 URL 的
  额外 query 参数（`?port=<port>`）随跳转传到中转页，中转页读回。
- **`ignore-check-redirect-uri: true`**：服务端 JustAuth 不校验
  redirect_uri 与注册值一致（与现有钉钉/企微配置同模式）。
- **state 校验在服务端**：JustAuth state 缓存于 Redis
  （`social_auth_state:` 前缀），`socialLogin` 校验，App 端只透传。
- **系统浏览器而非 webview**：GitHub 官方禁止嵌入式 webview OAuth。
- **隐藏无效占位按钮**：登录页微信/QQ/支付宝占位按钮隐藏，新增
  GitHub 按钮。

## 各仓库改动

### autoclip-server（最小改动）

1. `SocialTypeEnum.java`：新增 `GITHUB(40, "GITHUB")`。
   （`AuthRequestFactory` 已支持，无需改 Java 逻辑。）
2. `application-dev.yaml` / `application-prod.yaml` 的 `justauth.type`
   增加 `GITHUB` 配置块（client-id / client-secret +
   `ignore-check-redirect-uri: true`）。
3. 运维：在 GitHub 创建 OAuth App，callback URL 填中转页地址。

### autoclip-web-front（新增中转页）

- 新路由 `/oauth/github/callback`（免登录路由），轻量 Vue 页面：
  - 解析 query 中的 `code` / `state` / `port`；
  - UA 检测：移动端跳 `huji://` deep link；桌面端跳
    `http://127.0.0.1:<port>/oauth/github?...`；
  - 跳转失败时显示"请回到应用继续"兜底文案。

### huji-app（主要工作量）

**新服务 `lib/services/auth/github_oauth_service.dart`**

- `startLogin()`：拿授权 URL → 开浏览器 → 等待 code（Completer 由回调
  捕获层完成）→ 调 `socialLogin` → 返回 `LoginResult`。
- `UserService` 新增 `loginWithGithub` 静态方法，复用现有 token 保存 +
  user 加载逻辑。
- 超时控制（5 分钟）与取消（关闭登录框时 abort）。

**回调捕获层 `lib/services/auth/oauth_callback.dart`（按平台抽象）**

- 桌面端：`HttpServer.bind(InternetAddress.loopbackIPv4, 0)` 起临时
  HTTP server；收到带 code 的请求后返回"授权成功，请回到应用"HTML
  并关停。
- 移动端：`app_links` 包捕获 `huji://` deep link。
- 依赖：`app_links`（新依赖；`url_launcher` 已有）。

**平台配置**

- Android `AndroidManifest.xml`：MainActivity 添加 `<intent-filter>`
  （scheme `huji`）。
- iOS `Info.plist`：`CFBundleURLTypes` 注册 `huji`。
- macOS `Info.plist`：同上；不得改动 `FLTEnableImpeller` 行（有 CI
  guard）。

**UI**

- `login_form.dart`：隐藏微信/QQ/支付宝占位按钮；新增 GitHub 按钮
  （`assets/icons/login/github.svg`），点击走真实流程。
- `security_settings_page.dart`：新增"GitHub 绑定"区块，调用服务端已有
  bind/unbind 接口；`auth_api.dart` 补这两个接口的客户端方法。
- l10n：zh/en arb 补文案。

## 错误处理

| 场景 | 处理 |
|---|---|
| 用户在 GitHub 取消授权 | 中转页收到无 code 的回调 → 提示后不再分发；App 端超时后回登录框 |
| 浏览器打开失败 | TpToast 错误提示 |
| code 换 token 失败/过期 | 服务端错误 → App 端现有 `AppException` 提示链 |
| deep link 未被捕获（App 被杀） | 冷启动时路由层将 `huji://oauth/...` 存为 pending 回调，下次打开登录框时询问是否继续 |
| 5 分钟无操作 | 超时取消，loopback server 关停 |

## 测试

- server：参考 `SocialClientServiceImplTest`，补 GITHUB 枚举映射测试。
- web-front：中转页单元测试（UA 分发逻辑、port 透传）。
- huji-app：`github_oauth_service` 单测（mock API：自动建号 / 已绑定
  登录 / 换 code 失败三路径）；deep link 解析单测。
- GitHub 授权端到端手动验证（无法自动化）。

## 明确不做（YAGNI）

- GitHub 资料变更不回写（改名/换头像不同步）。
- 微信/QQ/支付宝真实接入（占位按钮隐藏而非实现）。
- 网页端登录页的 GitHub 按钮（本次只做中转页）。
- 多租户 social client 管理界面（沿用 yaml 配置）。
