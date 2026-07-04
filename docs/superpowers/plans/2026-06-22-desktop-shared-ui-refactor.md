# 弧迹桌面端 shared_ui 重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 huji 桌面端迁移到 `/home/hhoa/git/hhoa/shared_ui` 共享主题/控件，并用 Teampilot 风格宽侧栏壳层替换现有 `DesktopAppShell`。

**Architecture:** 从 teampilot 复制 theme/widgets 到同级 `shared_ui` package；huji 新建 `HujiDesktopShell`（标题栏 + 280px 侧栏 + `WorkspacePageCardShell`）；`AppearanceCubit` 管理主题与语言；业务 l10n 留在 huji-app。

**Tech Stack:** Flutter 3.11+, flex_color_scheme, google_fonts, flutter_bloc, go_router, window_manager, flutter_gen l10n

**Spec:** `docs/superpowers/specs/2026-06-22-desktop-shared-ui-design.md`

---

## File map

| 路径 | 职责 |
|------|------|
| `/home/hhoa/git/hhoa/shared_ui/` | 新建 package |
| `huji-app/lib/shell/huji_desktop_shell.dart` | 新桌面壳层 |
| `huji-app/lib/shell/huji_desktop_sidebar.dart` | 弧迹侧栏 |
| `huji-app/lib/main_desktop.dart` | AppearanceCubit + AppTheme 接入 |
| `huji-app/lib/router/modules/desktop.dart` | ShellRoute → HujiDesktopShell |
| `huji-app/lib/constants/desktop_theme.dart` | 迁移后删除 |
| `huji-app/lib/widgets/desktop/desktop_page_shell.dart` | 移除 DesktopAppShell，保留 DesktopPageShell |
| `huji-app/l10n/` | 业务 ARB |

---

### Task 1: 脚手架 shared_ui package

**Files:**
- Create: `/home/hhoa/git/hhoa/shared_ui/pubspec.yaml`
- Create: `/home/hhoa/git/hhoa/shared_ui/analysis_options.yaml`
- Create: `/home/hhoa/git/hhoa/shared_ui/lib/shared_ui.dart`
- Create: `/home/hhoa/git/hhoa/shared_ui/l10n.yaml`

- [ ] **Step 1: 创建 pubspec.yaml**

```yaml
name: shared_ui
description: Shared Flutter UI infrastructure for huji and teampilot.
publish_to: "none"
version: 0.1.0

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_bloc: ^9.1.0
  equatable: ^2.0.5
  flex_color_scheme: ^8.4.0
  google_fonts: ^8.1.0
  shared_preferences: ^2.5.3
  window_manager: ^0.5.1
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/google_fonts/
```

- [ ] **Step 2: 创建 l10n.yaml**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: SharedUiLocalizations
nullable-getter: false
```

- [ ] **Step 3: 创建最小 barrel**

```dart
// lib/shared_ui.dart
library shared_ui;

export 'theme/app_theme.dart';
export 'shell/workspace_surface_layers.dart';
export 'preferences/appearance_cubit.dart';
export 'preferences/appearance_preferences.dart';
export 'l10n/l10n_extensions.dart';
export 'widgets/chrome/desktop_window_title_bar.dart';
```

- [ ] **Step 4: 验证 package 可解析**

Run: `cd /home/hhoa/git/hhoa/shared_ui && flutter pub get`  
Expected: `Got dependencies!` 无 error

---

### Task 2: 迁移 theme 目录

**Files:**
- Create: `shared_ui/lib/theme/*`（从 `teampilot/client/lib/theme/` 复制 12 个文件）
- Modify: 所有 `package:teampilot/` → `package:shared_ui/`

- [ ] **Step 1: 复制文件**

```bash
cp -r /home/hhoa/git/hhoa/teampilot/client/lib/theme /home/hhoa/git/hhoa/shared_ui/lib/
find /home/hhoa/git/hhoa/shared_ui/lib/theme -name '*.dart' -exec sed -i 's/package:teampilot\//package:shared_ui\//g' {} +
```

- [ ] **Step 2: 复制 google_fonts 资产**

```bash
mkdir -p /home/hhoa/git/hhoa/shared_ui/assets/google_fonts
cp -r /home/hhoa/git/hhoa/teampilot/client/google_fonts/. /home/hhoa/git/hhoa/shared_ui/assets/google_fonts/
```

- [ ] **Step 3: 分析**

Run: `cd /home/hhoa/git/hhoa/shared_ui && dart analyze lib/theme`  
Expected: 无 error（warning 可后续处理）

---

### Task 3: 迁移 shell + widgets

**Files:**
- Create: `shared_ui/lib/shell/workspace_surface_layers.dart`
- Create: `shared_ui/lib/widgets/chrome/*.dart`
- Create: `shared_ui/lib/widgets/dialog/app_dialog.dart`
- Create: `shared_ui/lib/widgets/controls/*`
- Create: `shared_ui/lib/widgets/layout/ui_zoom.dart`, `app_text_scale_boundary.dart`

- [ ] **Step 1: 复制并改 import**

```bash
cp /home/hhoa/git/hhoa/teampilot/client/lib/theme/workspace_surface_layers.dart \
   /home/hhoa/git/hhoa/shared_ui/lib/shell/
# chrome
mkdir -p shared_ui/lib/widgets/chrome shared_ui/lib/widgets/dialog shared_ui/lib/widgets/controls shared_ui/lib/widgets/layout
cp teampilot/client/lib/widgets/desktop_window_title_bar.dart shared_ui/lib/widgets/chrome/
cp teampilot/client/lib/widgets/window_chrome_controls.dart shared_ui/lib/widgets/chrome/
cp teampilot/client/lib/widgets/window_drag_area.dart shared_ui/lib/widgets/chrome/
cp teampilot/client/lib/widgets/app_dialog.dart shared_ui/lib/widgets/dialog/
cp teampilot/client/lib/widgets/app_icon_button.dart shared_ui/lib/widgets/controls/
cp teampilot/client/lib/widgets/app_toggle_switch.dart shared_ui/lib/widgets/controls/
cp teampilot/client/lib/widgets/hover_widget.dart shared_ui/lib/widgets/controls/
cp teampilot/client/lib/widgets/hover_text_tooltip.dart shared_ui/lib/widgets/controls/
cp teampilot/client/lib/widgets/ui_zoom.dart shared_ui/lib/widgets/layout/
cp teampilot/client/lib/widgets/app_text_scale_boundary.dart shared_ui/lib/widgets/layout/
find shared_ui/lib -name '*.dart' -exec sed -i 's/package:teampilot\//package:shared_ui\//g' {} +
```

- [ ] **Step 2: 抽取 `useCustomDesktopWindowTitleBar`**

在 `shared_ui/lib/widgets/chrome/desktop_window_platform.dart` 新建：

```dart
import 'dart:io' show Platform;

bool get useCustomDesktopWindowTitleBar =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;
```

修改 `desktop_window_title_bar.dart` 引用该文件，去掉对 teampilot `platform_utils.dart` 的依赖。

- [ ] **Step 3: dart analyze widgets**

Run: `cd /home/hhoa/git/hhoa/shared_ui && dart analyze lib/widgets lib/shell`  
Expected: 无 error

---

### Task 4: AppearanceCubit + shared l10n

**Files:**
- Create: `shared_ui/lib/preferences/appearance_preferences.dart`
- Create: `shared_ui/lib/preferences/appearance_preferences_store.dart`
- Create: `shared_ui/lib/preferences/appearance_cubit.dart`
- Create: `shared_ui/lib/l10n/app_en.arb`, `app_zh.arb`
- Create: `shared_ui/lib/l10n/l10n_extensions.dart`

- [ ] **Step 1: appearance_preferences.dart**

```dart
import 'package:equatable/equatable.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography_scale.dart';

class AppearancePreferences extends Equatable {
  const AppearancePreferences({
    this.themeMode = 'dark',
    this.themeColorPreset = kDefaultThemeColorPreset,
    this.typographyScale = kDefaultTypographyScaleId,
    this.typographyScaleCustomMultiplier = kDefaultTypographyCustomMultiplier,
    this.uiZoomScale = kDefaultTypographyScaleId,
    this.uiZoomCustomMultiplier = kDefaultTypographyCustomMultiplier,
    this.locale = 'zh',
  });

  final String themeMode; // light | dark | system
  final String themeColorPreset;
  final String typographyScale;
  final double typographyScaleCustomMultiplier;
  final String uiZoomScale;
  final double uiZoomCustomMultiplier;
  final String locale; // zh | en | empty=system

  AppearancePreferences copyWith({...}) => ...;

  @override
  List<Object?> get props => [themeMode, themeColorPreset, typographyScale,
      typographyScaleCustomMultiplier, uiZoomScale, uiZoomCustomMultiplier, locale];
}
```

- [ ] **Step 2: store + cubit**（SharedPreferences 键前缀 `shared_ui.appearance.`）

- [ ] **Step 3: 最小 ARB（en/zh 各 ~15 条）**

`app_en.arb` / `app_zh.arb` 含：`themeModeLight`, `themeModeDark`, `themeModeSystem`, `themePresetAmber`, `themePresetGraphite`, `settingsAppearance`, `actionOk`, `actionCancel`

- [ ] **Step 4: 生成 l10n**

Run: `cd /home/hhoa/git/hhoa/shared_ui && flutter gen-l10n`  
Expected: 生成 `lib/l10n/app_localizations*.dart`

- [ ] **Step 5: l10n_extensions.dart**

```dart
import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
export 'app_localizations.dart';

extension SharedUiL10n on BuildContext {
  SharedUiLocalizations get sharedL10n => SharedUiLocalizations.of(this)!;
}
```

---

### Task 5: huji-app 接入 shared_ui 依赖

**Files:**
- Modify: `huji-app/pubspec.yaml`

- [ ] **Step 1: 添加依赖**

```yaml
  shared_ui:
    path: ../../shared_ui
  flex_color_scheme: ^8.4.0
  google_fonts: ^8.1.0
  flutter_animate: 4.5.2
```

- [ ] **Step 2: pub get**

Run: `cd /home/hhoa/git/hhoa/huji/huji-app && flutter pub get`  
Expected: 成功解析 shared_ui

---

### Task 6: HujiDesktopShell + Sidebar

**Files:**
- Create: `huji-app/lib/shell/huji_desktop_shell.dart`
- Create: `huji-app/lib/shell/huji_desktop_sidebar.dart`
- Modify: `huji-app/lib/router/modules/desktop.dart`
- Modify: `huji-app/lib/widgets/desktop/desktop_page_shell.dart`（删除 `DesktopAppShell` 类）

- [ ] **Step 1: huji_desktop_shell.dart**

```dart
class HujiDesktopShell extends StatelessWidget {
  const HujiDesktopShell({required this.currentRoute, required this.child, super.key});
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          DesktopWindowTitleBar(title: '弧迹'), // 后续改 l10n
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HujiDesktopSidebar(currentRoute: currentRoute),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: WorkspacePageCardShell(child: child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: huji_desktop_sidebar.dart** — 从 `desktop_sidebar.dart` 迁移账户区 + `DesktopNav` 导航，样式用 `Theme.of(context)` + `AppTextStyles`（shared_ui）

- [ ] **Step 3: desktop.dart ShellRoute**

```dart
ShellRoute(
  builder: (context, state, child) => HujiDesktopShell(
    currentRoute: state.uri.path,
    child: child,
  ),
  routes: [...],
),
```

- [ ] **Step 4: 删除 DesktopAppShell**，确认无引用

Run: `cd huji-app && rg 'DesktopAppShell' lib/`  
Expected: 无匹配

---

### Task 7: main_desktop.dart 主题宿主

**Files:**
- Modify: `huji-app/lib/main_desktop.dart`

- [ ] **Step 1: 初始化 AppearanceCubit + hidden title bar**

在 `_initWindowManager` 增加：

```dart
await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
```

- [ ] **Step 2: MaterialApp.router 外包 BlocProvider + BlocBuilder**

仿 teampilot `TeamPilotApp` 子集：读取 `AppearanceCubit.state` → `buildLightTheme`/`buildDarkTheme` → `themeMode` → `locale` → `builder` 内 `AppTextScaleBoundary` + `UiZoom`

- [ ] **Step 3: localizationsDelegates**

```dart
localizationsDelegates: const [
  ...SharedUiLocalizations.localizationsDelegates,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: SharedUiLocalizations.supportedLocales,
```

- [ ] **Step 4: 移除 DesktopTheme 引用**

Run: `cd huji-app && flutter analyze lib/main_desktop.dart`  
Expected: 无 error

---

### Task 8: 迁移 DesktopHomePage

**Files:**
- Modify: `huji-app/lib/pages/desktop/desktop_home_page.dart`

- [ ] **Step 1:** 将所有 `DesktopTheme.*` 替换为 `Theme.of(context).colorScheme` / `textTheme`
- [ ] **Step 2:** 去掉外层 `DesktopPageShell` 的 `currentRoute` 重复壳层（保留 `_PageHeader` 或内联标题行）
- [ ] **Step 3:** 空状态/网格卡片使用 `cs.workspaceCard`（`WorkspaceSurfaceLayers` extension）

Run: `flutter analyze lib/pages/desktop/desktop_home_page.dart`

---

### Task 9: 迁移 DesktopSettingsPage（主题/语言设置）

**Files:**
- Modify: `huji-app/lib/pages/desktop/desktop_settings_page.dart`

- [ ] **Step 1:** `_setThemeMode` 改为 `context.read<AppearanceCubit>().setThemeMode(...)`
- [ ] **Step 2:** 新增主题色预设 picker（复用 teampilot `theme_color_preset_picker` 逻辑，复制到 huji 或 shared_ui `widgets/settings/`）
- [ ] **Step 3:** 语言切换 → `AppearanceCubit.setLocale`
- [ ] **Step 4:** 删除 `DesktopTheme.loadThemeMode/saveThemeMode` 调用

---

### Task 10: 批量迁移剩余 DesktopTheme 引用

**Files:**
- Modify: 见 `rg DesktopTheme huji-app/lib` 列出的 ~20 个文件

- [ ] **Step 1:** 逐文件替换 `DesktopTheme.primaryColor` → `Theme.of(context).colorScheme.primary`
- [ ] **Step 2:** 替换 `DesktopTheme.textPrimary` → `colorScheme.onSurface` 等映射表（见 spec §3.7）
- [ ] **Step 3:** `desktop_theme.dart` 顶部加 `@Deprecated('Use shared_ui AppTheme')`

Run: `cd huji-app && flutter analyze`  
Expected: 0 errors

---

### Task 11: huji 业务 l10n（首批）

**Files:**
- Create: `huji-app/l10n.yaml`
- Create: `huji-app/lib/l10n/app_zh.arb`, `app_en.arb`

- [ ] **Step 1:** 提取侧栏、首页、设置页硬编码中文（约 40 条）
- [ ] **Step 2:** `flutter gen-l10n`，`MaterialApp` 注册 `HujiLocalizations`
- [ ] **Step 3:** 替换对应 `const Text('...')` 为 `context.l10n.xxx`

---

### Task 12: 清扫与验收

**Files:**
- Delete: `huji-app/lib/constants/desktop_theme.dart`（analyze 无引用后）
- Delete: `huji-app/lib/widgets/desktop/desktop_sidebar.dart`（已由 huji_desktop_sidebar 替代）

- [ ] **Step 1: 全项目 analyze**

Run: `cd /home/hhoa/git/hhoa/huji/huji-app && flutter analyze`  
Expected: No issues found!

- [ ] **Step 2: Linux 桌面冒烟**（spec §3.11 清单）

- [ ] **Step 3: 确认移动端**

Run: `flutter analyze lib/main.dart`（非 desktop 路径无 shared_ui 强依赖断裂）

---

## Plan self-review

| Spec 要求 | 对应 Task |
|-----------|-----------|
| shared_ui 独立 package | Task 1–4 |
| 从 teampilot 复制 theme/widgets | Task 2–3 |
| HujiDesktopShell 壳层 | Task 6 |
| AppearanceCubit | Task 4, 7, 9 |
| l10n 拆分 | Task 4, 11 |
| 页面迁移顺序 | Task 8–10 |
| 不引入 workspace/tabs | Task 6 设计约束 |
| teampilot 本轮不动 | 无 teampilot 修改 task |
| 测试清单 | Task 12 |

无 TBD/占位步骤。
