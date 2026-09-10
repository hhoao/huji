# 新建剪辑页案例缩略图 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将新建剪辑页的乒乓球、羽毛球快速体验案例统一呈现为仅包含可点击缩略图的入口。

**Architecture:** 继续使用 `demoVideos` 作为两个案例的唯一数据源，并复用 `ClipTypeSelectionPage` 现有的 `_DemoThumbnail` 抽帧与缓存组件。仅精简 `_buildDemoCard` 的展示层，保留 `TpHover` 点击反馈、页面级加载锁和 `_startDemoClip` 剪辑跳转流程。

**Tech Stack:** Flutter/Dart、`TpHover`、`flutter_test`、现有 FFmpeg 缩略图生成和本地化配置。

## Global Constraints

- 不改变案例视频资源、案例配置或剪辑流程。
- 不新增静态缩略图资源。
- 不重构通用 `DemoVideoPicker` 文字按钮组件。
- 保留“快速体验”区域标题和说明文字。
- 保留现有缩略图抽帧、缓存和失败占位逻辑。

---

## 文件结构

- Modify: `huji-app/lib/pages/clip/clip_type_selection_page.dart` — 将案例卡片精简为仅展示 16:9 缩略图，并移除标题/时长角标构建代码。
- Create: `huji-app/test/pages/clip/clip_type_selection_page_test.dart` — 验证两个案例均渲染为可点击缩略图，且案例文字不出现在卡片内。

### Task 1: 用回归测试锁定缩略图-only 展示

**Files:**
- Create: `huji-app/test/pages/clip/clip_type_selection_page_test.dart`

**Interfaces:**
- Consumes: `ClipTypeSelectionPage`, `HujiLocalizationsSetup`, `buildDarkTheme`, `TpTheme`。
- Produces: 页面结构回归测试，供 Task 2 验证 UI 精简没有破坏两个案例入口。

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/pages/clip/clip_type_selection_page.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    final theme = buildDarkTheme(
      null,
      AppTypographyScale(multiplier: 1.0),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const ClipTypeSelectionPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('两个快速体验案例只渲染可点击缩略图', (tester) async {
    await pumpPage(tester);

    expect(find.byType(AspectRatio), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TpHover && widget.pressScale == 0.97,
      ),
      findsNWidgets(2),
    );
    expect(find.text('乒乓球演示'), findsNothing);
    expect(find.text('羽毛球演示'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd huji-app && flutter test test/pages/clip/clip_type_selection_page_test.dart`

Expected: FAIL because the current `_buildDemoCard` still renders `乒乓球演示` and `羽毛球演示` as corner badge text.

### Task 2: 移除案例卡片文本并保留点击/缩略图流程

**Files:**
- Modify: `huji-app/lib/pages/clip/clip_type_selection_page.dart:287-350`

**Interfaces:**
- Consumes: `DemoVideo demo`, `_DemoThumbnail`, `_startDemoClip`, `_demoLoading`。
- Produces: `_buildDemoCard(DemoVideo demo)`，返回带 `TpHover` 的 16:9 图片入口；其点击回调仍调用 `_startDemoClip(demo)`。

- [ ] **Step 1: Replace the card body with thumbnail-only content**

保留以下行为不变：

```dart
return TpHover(
  onTap: _demoLoading ? null : () => _startDemoClip(demo),
  borderRadius: BorderRadius.circular(12),
  pressScale: 0.97,
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _DemoThumbnail(demo: demo),
    ),
  ),
);
```

删除 `_demoBadge` 方法及 `_buildDemoCard` 中的标题角标、时长角标和 `styles` 局部变量；不要修改 `_startDemoClip`、`_DemoThumbnail` 或页面级加载状态。

- [ ] **Step 2: Run the focused widget test**

Run: `cd huji-app && flutter test test/pages/clip/clip_type_selection_page_test.dart`

Expected: PASS;页面包含两个 16:9 `AspectRatio` 和两个带 `pressScale: 0.97` 的点击表面，且不包含两个案例标题文本。

- [ ] **Step 3: Format and analyze the changed files**

Run: `cd huji-app && dart format lib/pages/clip/clip_type_selection_page.dart test/pages/clip/clip_type_selection_page_test.dart && flutter analyze lib/pages/clip/clip_type_selection_page.dart test/pages/clip/clip_type_selection_page_test.dart`

Expected: formatter reports no remaining changes and analyzer exits successfully without warnings/errors for the changed files.

- [ ] **Step 4: Run the related demo service regression test**

Run: `cd huji-app && flutter test test/services/demo_video_service_test.dart`

Expected: PASS; both bundled demo materialization/cache behavior remains intact.

- [ ] **Step 5: Commit the implementation**

```bash
git add huji-app/lib/pages/clip/clip_type_selection_page.dart huji-app/test/pages/clip/clip_type_selection_page_test.dart
git commit -m "feat(clip): show demo cases as thumbnails"
```
