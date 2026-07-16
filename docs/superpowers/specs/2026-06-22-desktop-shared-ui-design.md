# 弧迹桌面端 UI 重构设计（shared_ui + Teampilot 壳层）

**日期:** 2026-06-22  
**状态:** 已批准（用户授权全权决策，不再逐项确认）  
**范围:** 仅 `huji-app` 桌面端；`teampilot` 本轮不迁移

---

## 1. 目标

将弧迹桌面端从自研 `DesktopTheme` + 窄侧栏壳层，迁移到与 Teampilot 一致的视觉与基础设施：

- 独立 Flutter package：`/home/hhoa/git/hhoa/shared_ui`
- 主界面布局对齐 `home_workspace_page.dart` 的**壳层**（宽侧栏 + 卡片内容区 + 自定义标题栏）
- **不引入**工作区、团队、顶栏多标签等业务概念
- 共享 package API 预留移动端后续接入

## 2. 已锁定决策

| 维度 | 决策 |
|------|------|
| 适配深度 | 壳层对齐（A） |
| 代码复用 | 独立 `shared_ui` package（B） |
| 影响范围 | 桌面优先，API 预留移动端（B） |
| Package 位置 | `/home/hhoa/git/hhoa/shared_ui`（与 huji、teampilot 同级） |
| Teampilot | 本轮仅从 teampilot **复制**源码到 shared_ui；teampilot 不改 import |

## 3. 架构

### 3.1 包职责

```
shared_ui/          # 纯 UI 基础设施，零业务依赖
huji-app/           # 弧迹业务、路由、桌面壳层适配
teampilot/client/   # 本轮不动
```

### 3.2 `shared_ui` 目录结构

```
shared_ui/
├── pubspec.yaml
├── l10n.yaml
├── lib/
│   ├── shared_ui.dart                 # barrel export
│   ├── theme/                         # 自 teampilot/client/lib/theme/ 复制
│   ├── shell/
│   │   └── workspace_surface_layers.dart
│   ├── preferences/
│   │   ├── appearance_preferences.dart    # themeMode, colorPreset, typography, uiZoom, locale
│   │   ├── appearance_preferences_store.dart
│   │   └── appearance_cubit.dart
│   ├── l10n/                          # 仅通用 UI 文案（ARB + 生成物）
│   └── widgets/
│       ├── chrome/                    # desktop_window_title_bar, window_chrome_controls, window_drag_area
│       ├── dialog/                    # app_dialog
│       ├── controls/                  # app_icon_button, app_toggle_switch, hover_*, dropdown/*
│       └── layout/                    # ui_zoom, app_text_scale_boundary
└── assets/
    └── google_fonts/                  # 从 teampilot 复制所需字体子集
```

### 3.3 迁入 shared_ui 的文件清单（自 teampilot 复制后改 package 名）

**主题（完整目录）**

- `app_theme.dart`, `app_fonts.dart`, `app_spacing.dart`, `app_icon_sizes.dart`
- `app_text_styles.dart`, `app_typography_scale.dart`
- `app_dialog_theme.dart`, `app_list_tile_theme.dart`, `app_outline_input_theme.dart`
- `app_tooltip_theme.dart`, `app_toast_theme.dart`

**壳层**

- `workspace_surface_layers.dart` → `lib/shell/`

**偏好（新建，从 LayoutPreferences 抽取子集）**

- 字段：`themeMode`, `themeColorPreset`, `typographyScale`, `typographyScaleCustomMultiplier`, `uiZoomScale`, `uiZoomCustomMultiplier`, `locale`
- 存储键前缀：`shared_ui.appearance.`（避免与 huji 旧 `DesktopTheme` 键冲突）

**通用控件**

- `widgets/app_dialog.dart`
- `widgets/app_icon_button.dart`
- `widgets/app_toggle_switch.dart`
- `widgets/hover_widget.dart`, `widgets/hover_text_tooltip.dart`
- `widgets/dropdown/app_dropdown_field.dart`, `app_dropdown_decoration.dart`, `popover/*`
- `widgets/desktop_window_title_bar.dart`, `window_chrome_controls.dart`, `window_drag_area.dart`
- `widgets/ui_zoom.dart`, `widgets/app_text_scale_boundary.dart`

**不迁入（留在各 app 或 teampilot 专有）**

- `LaunchProfileCubit`, workspace stores, terminal, git, chat 相关
- `HomeShell` 顶栏标签、`home_workspace_*` 业务页面
- teampilot 完整 `l10n/app_*.arb`（体量过大且含大量 Agent 文案）

### 3.4 huji 桌面新壳层

替换 `DesktopAppShell`（`widgets/desktop/desktop_page_shell.dart` 中的 `DesktopAppShell`）为：

```
HujiDesktopShell (huji-app/lib/shell/huji_desktop_shell.dart)
├── DesktopWindowTitleBar(title: l10n.appTitle)     # shared_ui
└── Row
    ├── HujiDesktopSidebar (width: 280)             # 仿 HomeSidebar 视觉，非 420（弧迹导航项少）
    └── Expanded
        └── WorkspacePageCardShell                  # shared_ui
            └── child (GoRouter 子路由页面)
```

**侧栏导航项（映射现有 `DesktopNav`）**

| 项 | 路由 | 说明 |
|----|------|------|
| 视频库 | `/` | 原 DesktopHomePage |
| 任务 | `/tasks` | 带 processing 角标 |
| — | spacer | |
| 设置 | `/settings` | |
| 帮助 | `/help` | 暂保留占位 |
| 关于 | `/about` | 暂保留占位 |

账户区保留现有登录/头像逻辑（自 `desktop_sidebar.dart` 迁移）。

**侧栏宽度决策：** 280px（非 teampilot 420px）。弧迹仅 4–6 个导航项，420px 过宽；保留 teampilot 的排版、hover、分组样式。

**不引入：** `HomeShell`、workspace tabs、`LaunchProfileCubit`。

### 3.5 `main_desktop.dart` 改造

`MaterialApp.router` 外包：

1. `BlocProvider<AppearanceCubit>`（shared_ui）
2. `BlocBuilder` 读取偏好 → `buildLightTheme` / `buildDarkTheme`（shared_ui `AppTheme`）
3. `ToastificationWrapper`（可选：若 huji 暂无 toast 依赖则 Phase 2 再加；首轮用 `SnackBar` 兼容）
4. `builder` 链：`AppTextScaleBoundary` → `UiZoom` → `DragToResizeArea`（Linux 边框缩放，与 teampilot 一致）
5. `localizationsDelegates`：`AppLocalizations`（shared_ui 通用）+ `HujiLocalizations`（huji 业务）+ Flutter 全局 delegates
6. 默认 `themeColorPreset`: `amber`（与 teampilot 默认一致）
7. 默认 `locale`: 沿用 huji 当前 `zh_CN`；持久化后用户可在设置页切换

删除对 `DesktopTheme.lightTheme/darkTheme` 的引用；`constants/desktop_theme.dart` 标记 `@Deprecated` 并在迁移完成后删除。

### 3.6 l10n 拆分

| 包 | 内容 | ARB 示例 |
|----|------|----------|
| `shared_ui` | 主题色名、明暗模式、字号、窗口按钮、通用 OK/Cancel | `themePresetAmber`, `actionCancel` |
| `huji-app` | 视频库、剪辑、任务、运动类型、错误文案 | `desktopNavLibrary`, `clipNew` |

配置：

- `shared_ui`: `flutter: generate: true` + `l10n.yaml`
- `huji-app`: 新增 `l10n.yaml` + `lib/l10n/app_zh.arb`, `app_en.arb`

迁移策略：**按页面批次替换硬编码字符串**，首轮至少覆盖：侧栏、设置页、DesktopHomePage 空状态。

### 3.7 页面迁移顺序

1. **基础设施** — 创建 `shared_ui`，huji 能编译通过
2. **壳层** — `HujiDesktopShell` + 路由 `ShellRoute` 接入
3. **首页** — `DesktopHomePage` 改用 `Theme.of(context)` / `ColorScheme`，去掉 `DesktopTheme.*`
4. **设置页** — 接入 `AppearanceCubit`（主题/语言/字号），替换 `DesktopTheme.loadThemeMode`
5. **剪辑流** — `desktop_clip_config_page`, `desktop_preview_export_page`, `desktop_precision_edit_page`
6. **任务页** — `desktop_tasks_page` + `task_row_desktop` 等
7. **控件清扫** — `widgets/desktop/*` 逐步改为 `shared_ui` 或删除；`DesktopPageShell` 的 `_PageHeader` 保留但改用 theme tokens

`DesktopPageShell`：**保留**页内 breadcrumb + actions 模式（弧迹剪辑页需要），仅更新样式 token，不再包一层旧 `DesktopAppShell`。

### 3.8 依赖变更（huji-app `pubspec.yaml`）

```yaml
dependencies:
  shared_ui:
    path: ../../shared_ui
  flex_color_scheme: ^8.4.0
  google_fonts: ^8.1.0
  flutter_animate: 4.5.2
```

`shared_ui/pubspec.yaml` 直接声明上述依赖；huji 通过 shared_ui 传递使用主题 API。

### 3.9 窗口管理

- 启动时 `TitleBarStyle.hidden` + 自定义 `DesktopWindowTitleBar`（与 teampilot 一致）
- 保留 huji 现有窗口位置/尺寸持久化（`SharedPreferences` 键 `window_x/y/w/h` 不变）
- `window_manager` 监听逻辑留在 `main_desktop.dart`

### 3.10 错误处理

- `DesktopErrorPage` 保留，样式改为 `Theme.of(context).colorScheme`
- 路由 `errorBuilder` 不变
- `AppearanceCubit` 加载失败 → 回退默认偏好（amber / dark / zh_CN），不阻断启动

### 3.11 测试与验收

**手动冒烟清单（Linux 桌面）：**

- [ ] 启动后显示新壳层（标题栏 + 宽侧栏 + 卡片内容区）
- [ ] 侧栏导航切换：视频库 / 任务 / 设置
- [ ] 设置页切换明/暗色、主题色预设立即生效
- [ ] 设置页切换中/英文，侧栏与首页文案更新
- [ ] 新建剪辑 → 配置 → 预览 → 精编 全流程可走通
- [ ] 窗口拖拽、缩放、位置记忆正常
- [ ] 移动端 `MyApp` 编译不受影响（`flutter build apk --debug` 或 `flutter analyze` 全项目）

**静态分析：** `flutter analyze` 在 `shared_ui` 与 `huji-app` 均无 error。

### 3.12 非目标（YAGNI）

- teampilot 改 import / 删重复代码
- 顶栏多标签（HomeShell tabs）
- 工作区 / 团队 / LaunchProfile 模型
- 移动端本轮切换主题
- `toastification` 包（除非剪辑页已有强需求；默认 SnackBar）

### 3.13 风险与缓解

| 风险 | 缓解 |
|------|------|
| teampilot 与 shared_ui 双份 theme 漂移 | 文档注明 teampilot 迁移时需 diff；shared_ui 以 teampilot 当前 commit 为基线 |
| `DesktopTheme` 引用面广（~20 文件） | 按页面批次迁移；过渡期 `desktop_theme.dart` 保留但 deprecated |
| google_fonts 离线资源 | 复制 teampilot `google_fonts/` 资产到 shared_ui |
| SDK 版本差（huji ^3.11.5 vs teampilot ^3.8.1） | shared_ui 用 huji SDK 约束；复制代码时修 analyzer 警告 |

---

## 4. 方案选择记录

采用 **方案 1：基础设施包 + huji 自写壳层**（见 brainstorming 记录）。未采用可配置 `DesktopHomeScaffold`（方案 2）与分阶段仅换皮（方案 3），以降低首轮抽象成本。

---

## Amendment (2026-07-16)

Package surface superseded by the Tp\* design-system line. See [2026-07-16-huji-tp-shared-ui-adapt-design.md](./2026-07-16-huji-tp-shared-ui-adapt-design.md): bump to Tp\* `shared_ui` `main`, vend appearance/chrome into huji, wire `TpTheme` / `TpToast`.
