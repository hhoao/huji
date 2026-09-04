# Code quality guidelines

For contributors and AI assistants: defines **layering, file size, state management, and testing** norms for `huji-app/` so pages and blocks do not grow without bound and test gaps stay visible.

## Quality gates (required)

Before merge, from `huji-app/` (same as [CI Verify](../.github/workflows/ci-verify.yml)):

```bash
cd huji-app
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --exclude-tags integration
```

Run these commands and confirm success before claiming work is done.

## Layering

| Layer | Path | Responsibility |
|-------|------|----------------|
| Page module | `pages/<domain>/` | Route pages, sections, per-page blocs (`<domain>/bloc/`), route helpers |
| Shared UI | `packages/shared_ui` (`Tp*`) | Cross-route **design-system primitives only** (Button, Input, Select, Dialog, Form, Toast, …). Git submodule; import via `package:shared_ui/shared_ui.dart` |
| Product / domain chrome | `widgets/` | App-specific widgets reused across routes (`multi_video_player/`, `video_trimmer/`, `file_picker/`, export/save progress dialogs, …) — not generic controls |
| Global state | `store/` | App-level Blocs (`user/`, `video`, `message`) and long-running task managers (`store/task/`) |
| Services | `services/` | Detection (local/realtime), inference (ONNX), upload/download, websocket, storage, permissions, app update |
| Core | `core/` | Realtime detection pipeline, cross-cutting primitives |
| Models | `models/` | Immutable data, serialization |
| Routing / shell | `router/`, `shell/`, `desktop/` pages | Navigation and desktop workspace chrome |

**Paths:** use `path_provider`-resolved roots via `services/storage_*` — not `Directory.current` for app data.

**DI:** Services that touch processes, network, or disk should accept injectable clients/runners so tests can fake them.

## Seven design principles

Apply these when adding or refactoring code. They complement the layering table — not a substitute for it.

| Principle | Rule of thumb | In Huji |
|-----------|---------------|---------|
| **Single responsibility** | One class/file has one reason to change. | Task managers live one per concern (`video_upload_task_manager`, `video_compress_task_manager`, …); do not merge unrelated task flows into one manager. |
| **Open/closed** | Open for extension, closed for modification. | Add a new `<sport>/<match_type>` model resolver path under `services/inference/` instead of scattering `if (sport == …)` across pages and blocs. |
| **Liskov substitution** | Subtypes must honor the contract of the base type. | Fakes in tests (uploaders, detection services) must behave like production implementations at the boundary you mock. |
| **Interface segregation** | Prefer small, focused interfaces over fat ones. | Blocs depend on narrow service seams (constructor injection), not whole app singletons. |
| **Dependency inversion** | Depend on abstractions, not concretions. | Video playback goes through `MultiVideoPlayerBloc` + `PlatformCapability.isDesktop` — feature code never branches on `Platform.isLinux` itself. |
| **Law of Demeter** | Talk to immediate collaborators; avoid long chains. | Pages `context.read`/`BlocBuilder` on blocs; blocs call services — avoid reaching through three layers of internal state from UI. |
| **Composition over inheritance** | Favor composing objects/widgets over deep subclass trees. | Compose `pages/<domain>/` sections and `Tp*` primitives; limit deep `Row`/`Column` nesting. |

When a change violates more than one principle, fix structure first (split file, inject dependency) before adding behavior.

### `pages/` vs `widgets/` vs `shared_ui`

| Question | Location | Examples |
|----------|----------|---------|
| Used by a single route / screen? | `pages/<domain>/` | `pages/task/task/task_tab/`, `pages/clip/` |
| New cross-route **design primitive** (button, input, select, dialog, toast, …)? | `packages/shared_ui` as `Tp*` | `TpButton`, `TpInput`, `TpSelect`, `showTpDialog`, `TpToast` |
| Product / domain widget imported from unrelated routes? | `widgets/` | `multi_video_player/`, `video_export_progress_dialog.dart`, `common_app_bar_with_tabs.dart` |

**Do not** add new generic controls under `lib/widgets/` — put them in `packages/shared_ui` as `Tp*` components. Keep `widgets/` for product/domain chrome only (trimmer timeline, player surfaces, progress dialogs).

**Do not** put route-only sections under `widgets/<feature>/` when the folder name mirrors a page. Prefer `pages/<domain>/` with blocs colocated (`pages/clip/bloc/`).

## File size (soft limits)

| Kind | Soft limit |
|------|------------|
| Page shell | ~400 lines |
| Single file under `pages/<domain>/` | ~500 lines (split further or extract **shared** widgets) |
| Bloc / task manager | ~500 lines |
| Services | ~600 lines |

**Do not** add large UI or business blocks to files already **~800+ lines** without splitting and adding tests (e.g. `services/storage_service.dart`, `store/task/task_manager.dart`).

**Generated:** `*.g.dart`, `*.freezed.dart`, and `l10n/app_localizations*.dart` are excluded from these limits; never hand-edit.

## UI and state

- Route-specific UI lives under **`pages/<domain>/`**; cross-route **design primitives** under **`packages/shared_ui`** (`Tp*`); product/domain widgets under **`widgets/`**. Pages connect via `BlocBuilder` / `context.read`.
- **Use `flutter_bloc` (Bloc/Cubit) for app state**; do not introduce `provider` / `ChangeNotifier` as a parallel pattern in feature code.
- Bloc states: `Equatable` or immutable `copyWith`; explicit load/error states; fine-grained busy sets where needed.
- User-facing errors: **l10n (`HujiLocalizations`)**, not raw `e.toString()` as final copy (logging is fine).
- Routing: existing router (`lib/router/`); short-lived UI (dialogs, sheets) may use `Navigator`.
- Desktop/mobile divergence goes through `PlatformCapability` and the dual-backend players — never sprinkle `Platform.isXxx` in widget trees.

### Flutter UI practices (when splitting large pages)

| Practice | Notes |
|----------|--------|
| Dedicated **Widget classes** | Split large `build()` bodies into `class FooSection extends StatelessWidget` under **`pages/<domain>/`**. **Avoid** private methods that only return a `Widget`. |
| Long lists | Use **`ListView.builder` / `SliverList`** (video feeds, task rows); avoid huge `children: [...]`. |
| Keep `build()` light | **No** disk/network/subprocess, heavy JSON parse, or decode inside `build()`; use Bloc/Service + `BlocBuilder`. |
| `const` | Use `const` constructors where subtrees are stable to cut unnecessary rebuilds. |
| Typography | Prefer [`TpTextStyles`](huji-app/packages/shared_ui/lib/src/theme/tp_text_styles.dart) **named scale tokens** from `shared_ui`; do **not** construct `TextStyle(...)` inline or invent combinations outside shipped getters. Exceptions: video/timeline overlays, terminal-like monospace surfaces. |

Shared pieces for multiple sections on the **same** screen stay in the **same** `pages/<domain>/` folder. When a second route needs them: use **`packages/shared_ui`** for design primitives (`Tp*`), or **`widgets/`** for product chrome only.

## Function and logic size

- One responsibility per function; past **~30 lines** with branches and IO, move logic to `services/` or a dedicated widget.
- Bloc event handlers past **~40 lines** should delegate domain steps to services; the bloc orchestrates and emits.

## Errors and logging

- Expected failures (upload failed, detection miss) → result types or bloc error state; **no** silent catches.
- User copy → **l10n + bloc state**; diagnostics → the `logger` package. **No** `print`; do not rely on `debugPrint` as persistent logging.
- Follow [DEBUGGING.md](DEBUGGING.md) for framework/engine errors before changing app logic.

## Models and code generation

- Persistence/API models: **`json_serializable` + `json_annotation`** (and `freezed` / `retrofit_generator` where already used in that domain); after edits run `dart run build_runner build --delete-conflicting-outputs` ([DEVELOPMENT.md](DEVELOPMENT.md)).
- New models should match **existing models in the same domain** for JSON keys and serialization options.
- `///` docs on **`services/` and shared models**; page sections rely on clear names.

## Testing

### Default (CI)

```bash
flutter test --exclude-tags integration
```

New features: unit-test `services/` and blocs first. When editing large pages: at least **bloc** tests; newly extracted **`pages/<domain>/`** sections should get **widget tests** (key interactions, empty/error states). Structure: **Arrange–Act–Assert**; one behavior per `test`.

### Integration tests

- Tag: `@Tags(['integration'])`; live under `test/integration/`.
- Excluded from default CI and `flutter test` runs — select them deliberately (`flutter test --tags integration`), see [DEVELOPMENT.md](DEVELOPMENT.md#tests).

### Fakes and mocks

- **Prefer fakes/stubs** (injected services, fake uploaders with fixed responses).
- Use mocks only at hard boundaries (network, platform channels, file system).
- Do not mock: pure functions, trivial types matching real behavior.
- Local detection / inference: never hit real models or the network in unit tests; use golden fixtures (`test/fixtures/`, `scripts/generate_*_golden.py`).

## Dart conventions

- `async`/`await` + `try/catch` should surface outcomes in blocs/services, not unhandled exceptions in `build`.
- Naming: `PascalCase` types, `camelCase` members, `snake_case` files; avoid opaque abbreviations.
- Every `Isolate.spawn` / `Isolate.run` must pass **`debugName`** (e.g. `'local-detection-isolate'`) so DevTools and stack traces identify the isolate.
- From `pages/<domain>/`: `Tp*` primitives → `import 'package:shared_ui/shared_ui.dart'`; product chrome → `import '../../widgets/...'`; same domain → `import 'foo_section.dart'`.

## Tech debt

- Avoid new `TODO`/`FIXME` without an issue or same-PR follow-up.
- No `// ignore` without reason; fix analyze issues when possible.
- Comments explain **why**, not what the code obviously does; `///` on public service APIs.
- Bugs: [DEBUGGING.md](DEBUGGING.md) — search framework errors before local hacks.

## Manual pre-release checks

- Android: select a video → run a local/cloud detection task → progress → edit rounds → export/save.
- Desktop (Linux): same flow through `media_kit` playback; verify ONNX path with and without CUDA (CPU fallback).
- Background recording (边拍边剪辑): hand-test when detection, workmanager, or camera code changes.

## Related docs

| Doc | Topic |
|-----|--------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | Commands, build, tests, releases |
| [DEBUGGING.md](DEBUGGING.md) | Debugging process |
| [CLAUDE.md](../CLAUDE.md) | Agent entry point |
