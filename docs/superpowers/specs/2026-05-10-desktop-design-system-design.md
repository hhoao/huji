# Desktop Design System & Interaction Layer

## Meta
- **Date**: 2026-05-10
- **Status**: approved
- **Scope**: 完整的桌面端设计系统：Token 层 → 组件层 → 页面替换 + 过渡动画

## 1. Problem Statement

桌面端当前存在三级交互缺陷：

1. **无 hover 反馈** — 大量使用 `GestureDetector`（零视觉反馈），未使用 `MouseRegion`（无指针变化）
2. **下拉菜单不可靠** — `_DropdownSetting` 纯装饰不可点击，`_PresetDropdown` 用 Stack 条件渲染（无 overlay/无 dismiss），`_SportTypeDropdown` 手动 `showMenu` 定位偏移
3. **无动画** — 全项目零 `Animated*` widget，零 `pageTransitionsTheme`，所有切换瞬间完成

根因：没有设计系统组件层，每个页面从零拼 `GestureDetector` + `Container`。

## 2. Architecture

三层结构：

```
Token 层 (DesktopTheme 增强)
   ↓
组件层 (lib/widgets/desktop/app_*.dart)
   ↓
页面层 (lib/pages/desktop/*.dart — 替换旧写法)
```

### 2.1 Token 层 — DesktopTheme 补充

| Token | 值 | 用途 |
|---|---|---|
| `hoverHighlight` | `Colors.white.withAlpha(8)` | hover 背景色变 |
| `overlayColor` | `primaryColor.withAlpha(15)` | MenuAnchor overlay |
| `splashColor` | `primaryColor.withAlpha(30)` | 点击涟漪 |
| `animationFast` | 150ms | 微交互 (hover/press) |
| `animationNormal` | 250ms | 常规过渡 (tab 切换) |
| `animationSlow` | 400ms | 页面过渡 |
| `pageTransitionsTheme` | FadeThrough + slideUp | 页面路由过渡 |

所有组件通过 `DesktopTheme.of(context)` 或硬引用这些 token。

### 2.2 组件层 — `lib/widgets/desktop/`

| 组件 | 文件 | 替代目标 |
|------|------|----------|
| `AppHoverBox` | `app_hover_box.dart` | 通用 wrapper: MouseRegion + AnimatedScale + AnimatedContainer |
| `AppButton` | `app_button.dart` | 各处 GestureDetector+Container 按钮 |
| `AppChip` | `app_chip.dart` | filter chips、status 选择 |
| `AppDropdown<T>` | `app_dropdown.dart` | 所有自建下拉 (sport type, preset, settings dropdowns) |
| `AppTab` | `app_tab.dart` | 状态标签页、筛选标签页、设置导航 |
| `AppIconButton` | `app_icon_button.dart` | 小图标按钮 |
| `AppSwitch` | `app_switch.dart` | _ToggleSwitch |

**交互契约** (由 `AppHoverBox` 统一提供)：

- `MouseRegion` → `SystemMouseCursors.click` on enter
- `AnimatedContainer` → 150ms 背景色变过渡 (hover ↔ idle)
- `AnimatedScale` → 0.97x on tapDown, 1.0x on tapUp/Cancel
- 统一 corner radius (6px), 统一 padding 体系

**`AppDropdown<T>` 实现**：内部使用 `MenuAnchor` + `MenuItemButton` (Flutter 3.19+)，自动处理 overlay 定位、外部点击关闭、键盘导航、150ms 淡入。

### 2.3 页面层 — 替换策略

原则：纯替换交互壳，不改业务逻辑。`onTap`/`onChanged` 原样透传。

| 页面 | GestureDetector 大致数量 | 替换 |
|------|--------------------------|------|
| sidebar | 已用 InkWell ✅ | `showMenu` → `MenuAnchor` (账户菜单) |
| home | tabs 用 GestureDetector | tabs → `AppTab` |
| tasks | ~15 | tabs→`AppTab`, filters→`AppChip`, actions→`AppButton` |
| settings | ~10 | nav→`AppTab`, dropdown→`AppDropdown`, toggle→`AppSwitch`, cards→`AppHoverBox` |
| clip_config | ~8 | preset/sport/detection→`AppDropdown`, checkboxes 保留 Material |
| preview_export | ~5 (待确认) | 同上模式 |
| precision_edit | ~5 (待确认) | 同上模式 |

### 2.4 页面过渡

在 `DesktopTheme` 配置 `pageTransitionsTheme`，使用 Material 3 内置 `FadeThroughPageTransitionsBuilder` + 轻微上滑，300ms easeOut。

GoRouter 的 `CustomTransitionPage` 或全局 `pageTransitionsTheme` 统一生效。

## 3. Non-Goals

- 不重构业务逻辑
- 不改 mobile 端 (`lib/pages/`, `lib/main.dart`)
- 不改视频播放器 (`media_kit` 组件)
- 不改第三方组件 (`desktop_drop_zone`, `multi_split_view`)

## 4. Risks

- `MenuAnchor` 要求 Flutter 3.19+，当前 SDK 3.8.1 ✅ 满足
- 替换过程需保持 `go_router` 导航不中断
- 侧栏 `InkWell` 保持不动（已合格），只修菜单

## 5. File Change Summary

| File | Action |
|------|--------|
| `lib/constants/desktop_theme.dart` | Modify — 添加 token + pageTransitionsTheme |
| `lib/widgets/desktop/app_hover_box.dart` | Create |
| `lib/widgets/desktop/app_button.dart` | Create |
| `lib/widgets/desktop/app_chip.dart` | Create |
| `lib/widgets/desktop/app_dropdown.dart` | Create |
| `lib/widgets/desktop/app_tab.dart` | Create |
| `lib/widgets/desktop/app_icon_button.dart` | Create |
| `lib/widgets/desktop/app_switch.dart` | Create |
| `lib/widgets/desktop/desktop_sidebar.dart` | Modify — account menu MigrationAnchor |
| `lib/pages/desktop/desktop_home_page.dart` | Modify — tabs→AppTab |
| `lib/pages/desktop/desktop_tasks_page.dart` | Modify — tabs/chips/buttons 替换 |
| `lib/pages/desktop/desktop_settings_page.dart` | Modify — nav/dropdown/toggle/cards 替换 |
| `lib/pages/desktop/desktop_clip_config_page.dart` | Modify — preset/sport/detection dropdowns 替换 |
| `lib/pages/desktop/desktop_preview_export_page.dart` | Modify — 替换 GestureDetector (如适用) |
| `lib/pages/desktop/desktop_precision_edit_page.dart` | Modify — 替换 GestureDetector (如适用) |
