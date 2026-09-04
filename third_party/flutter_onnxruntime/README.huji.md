# flutter_onnxruntime (huji fork)

Vendored copy of [flutter_onnxruntime](https://github.com/masicai/flutter_onnxruntime) **1.8.4**
(pub.dev tarball), patched for the huji desktop app. Wired in via
`huji-app/pubspec.yaml` → `dependency_overrides`.

Upstream 1.7.0 moved inference off the main thread **only on Android/iOS/macOS**
(Flutter TaskQueue). On Linux the method-channel handler executed
`Ort::Session::Run` synchronously on the platform (GTK main) thread, which
froze input/window event processing and every other plugin channel while local
detection was running (see also masicai/flutter_onnxruntime — no Linux
equivalent shipped as of 1.8.4).

## Patches (all under `linux/src/`)

1. **`flutter_onnxruntime_plugin.cc`** — `runInference` is now asynchronous:
   args are parsed on the platform thread (FlValue/GObject stay there), the
   tensor clone + ORT run execute on a spawned worker thread
   (`TensorManager`/`SessionManager` are mutex-protected), and the reply is
   sent from a `g_idle_add` callback via `fl_method_call_respond`. The plugin
   and the `FlMethodCall` hold strong refs until the response is sent.
2. **`session_manager.{h,cc}`** — sessions are stored as
   `shared_ptr<SessionInfo>` and `runInference()` releases the global mutex
   before `Session::Run` (ORT sessions are thread-safe for concurrent `Run`),
   so concurrent runs are no longer serialized and an in-flight run stays safe
   across `closeSession()`.

Everything else is byte-identical to the 1.8.4 tarball (`example/` removed).

## Upgrading

Re-vendor the new tarball into this directory, then re-apply the two patches
above (search for `huji patch`). Dart API is unchanged.
