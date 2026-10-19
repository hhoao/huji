# 本地日志与设置内日志查看器

日期：2026-10-19
状态：已批准（方案 B）

## 背景

Huji 已有文件日志（`应用文档目录/logs/app_YYYY-MM-DD.log`）和一个日志查看页，
但查看页只在「开发者选项」里，且存在以下问题：

- 文件日志使用 `logger` 的 `PrettyPrinter`，多行、带边框与 emoji，级别和
  调用来源无法用简单的行解析准确过滤。
- 查看页一次性 `readAsLines()` 整个文件，大文件会卡 UI。
- `_applyFilters()` 直接改写 `_allLines`，连续调整筛选条件会丢数据。
- 待写入日志用 `getFormattedPendingLogs()[index]` 渲染，把字符串当列表下标。
- 文件列表为空时 `_logFiles.first` 会抛异常。
- 清理逻辑只保留“今天”的日志，与注释中的 7 天保留策略不符。

参考实现：`teampilot/client/lib/utils/logging/logger_utils.dart` 与
`teampilot/client/lib/pages/system/log_viewer_*`、`log_config_workspace.dart`。

## 目标

1. 文件日志改为单行、可解析、可过滤的格式，并在写入后立即 flush。
2. 提供与 teampilot 等价的查看器：文件选择、搜索、级别过滤、紧凑/换行、
   倒序、分页、刷新、复制路径、复制全部、清理旧日志。
3. 桌面端在「设置 → 关于」提供日志入口，以弹窗打开查看器。
4. 移动端保留现有「开发者选项 → 日志」入口，复用同一个查看器实现。
5. 删除旧的 `LogViewerPage` 实现，避免两套逻辑与格式不兼容。

## 非目标

- 不改变控制台彩色日志的行为。
- 不改变检测/剪辑/推理逻辑。
- 不做日志上传、分享或云端同步。

## 日志文件格式

文件日志每条记录一行：

```
2026-10-19 12:00:00.123 |  INFO 12345 | package:huji_app/.../xxx.dart:42:9 | message
```

- 时间：`yyyy-MM-dd HH:mm:ss.SSS`
- 级别：`DEBUG` / ` INFO` / ` WARN` / `ERROR`，左补齐 5 字符
- PID：当前进程号
- 来源：调用栈中第一个非 logger 内部帧，保留 `package:` 形式便于 IDE 跳转
- 消息：单行；`error` 追加在消息后，error 级别的 stack trace 追加为后续行
  （warning 不追加，避免把调用点栈误当成诊断栈）

文件名与轮转保持不变：`app_YYYY-MM-DD.log`，单文件 10MB，最多 5 个文件，
最多保留 7 天。

## 组件

### `lib/utils/logger_utils.dart`

- 新增 `_Log4jStylePrinter`（仅文件日志使用）。
- 新增 `_FlushingFileOutput`：`writeAsStringSync(mode: append, flush: true)`。
- 新增 `ensureFileLogging([String? appDataRoot])`，供测试与查看器调用；
  `initializeFileLogger()` 保持现有启动时行为。
- 新增 `readLogFileLines(path, {timeout, maxBytes = 512KB})`：只读尾部。
- 新增 `currentLogFilePath`、`flushFileLogging()`、`resetForTesting()`。
- `getLogFiles({String? appDataRoot})` 不再要求文件 logger 已初始化。
- `clearOldLogs({int keepDays = 7, String? appDataRoot})` 不再提前 return，
  按修改时间与保留数量清理。
- 文件过滤策略：debug 构建保留 DEBUG+，release 保留 INFO+。

### `lib/widgets/settings/log_viewer_filter.dart`

纯函数：

- `kLogViewerLevels = ['ALL', 'DEBUG', 'INFO', 'WARNING', 'ERROR']`
- `logLineMatchesLevel(line, level)`：优先解析单行格式中的级别段；旧格式回退
  到关键词匹配。
- `filterLogLines({rawLines, compactView, searchText, selectedLevel})`：
  不改写入参，返回新列表。
- `logLineColor(context, line)`、`logMonospaceStyle(context)`。

### `lib/widgets/settings/log_viewer_panel.dart`

`LogViewerPanel`（StatefulWidget）：

- 状态：文件列表、原始行、过滤后行、当前页、加载中、换行、倒序、紧凑、
  搜索、级别。
- 初始化：`ensureFileLogging()` → `getLogFiles()` → 读取第一个文件。
- 分页：每页 500 行，滚动到 85% 加载下一页。
- 工具栏：文件下拉、搜索框、级别下拉、紧凑/换行切换、操作菜单
  （刷新、复制路径、复制全部、清理旧日志、倒序）、行数徽标。
- 内容：`SelectionArea` + 虚拟化 `ListView`，等宽字体，按级别着色。
- 空状态：无文件/未初始化时展示提示与待写入日志。
- 错误通过 `TpToast` 提示。

### `lib/widgets/settings/log_viewer_dialog.dart`

`showLogViewerDialog(context)`：`TpDialog`（约 920×640，按视口收缩），
标题/副标题/关闭按钮 + `LogViewerPanel(useSurfaceCard: false)`。

### `lib/pages/system/log_viewer_page.dart`

重写为移动端/整页壳：`Scaffold` + `LogViewerPanel`，保留
`LogViewerPage` 类名与导入路径，`developer_options_page.dart`、
`error_page.dart`、路由无需改动。

### 设置入口

`lib/widgets/settings/about_section.dart` 在“更新日志”前新增一行：
`应用日志` → `showLogViewerDialog(context)`。

### 本地化

新增中英文 key：

- `settingsViewLogs`
- `logViewerSubtitle`
- `logViewerCopyPath`
- `logViewerCopyAll`
- `logViewerClearOld`
- `logViewerReverseOrder`
- `logViewerCompactView`
- `logViewerWrapLines`
- `logViewerRefresh`
- `logViewerPathCopied`
- `logViewerAllCopied`
- `logViewerClearDone`
- `logViewerClearFailed`
- `logViewerLineCount`
- `logViewerEmpty`
- `logViewerEmptyHint`
- `logViewerPendingTitle`
- `logViewerPendingBody`

其余文案复用现有 `logViewerTitle`、`searchLogsHint`、`noLogFilesFound` 等。

## 测试

- `test/utils/logger_utils_test.dart`
  - 初始化到临时目录后写入，文件包含单行格式与消息。
  - `readLogFileLines` 只读尾部并丢弃不完整首行。
  - `getLogFiles` 按修改时间倒序列出。
  - `clearOldLogs` 删除过期文件、保留近期文件。
- `test/widgets/settings/log_viewer_filter_test.dart`
  - 级别解析不受消息正文影响。
  - 搜索 + 级别 + 紧凑组合过滤。
  - 输入列表不被修改。
- 运行 `flutter analyze` 与相关 `flutter test`。

## 风险

- 日志格式改变后，磁盘上的旧日志仍可查看；级别过滤对旧格式回退为关键词匹配。
- `pid` 在 Flutter web 不可用；本项目日志依赖 `dart:io`，维持现状即可。
- Windows 上同步 flush 会增加少量 I/O，但换取查看器即时可见，符合桌面日志场景。
