# ncnn 包拆仓发布实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `huji-app/packages/huji_ncnn` 拆出为独立仓库 `github.com/hhoao/ncnn`（pub 包名 `ncnn`），泛化为通用图像推理绑定，发 0.1.0，huji-app 经 git submodule 无损接入。

**Architecture:** 瘦 C shim（`hn_*` extern "C"，版本化选项结构体）→ 手维护 FFI 绑定 → Dart 分层（runtime/net → yolo 工具 → helper 进程 → 高层 engine）。构建期下载 ncnn 官方预编译库（Vulkan），五平台 ffiPlugin。Windows 经 `ncnn_helper` 子进程绕过 Flutter engine 内 Vulkan 崩溃。

**Tech Stack:** C++17（shim + helper）、Dart/Flutter FFI、CMake（Linux/Windows/Android）、CocoaPods（iOS/macOS）、GitHub Actions。

**设计文档:** `docs/superpowers/specs/2026-09-10-ncnn-package-extraction-design.md`（已修订：绑定手维护 + 符号覆盖测试替代 ffigen）

## Global Constraints

- 新仓本地路径 `/home/hhoa/git/hhoa/ncnn`，远端 `https://github.com/hhoao/ncnn.git`（已存在，空仓，默认分支 main）
- pub 包名 `ncnn`，版本 `0.1.0`，`environment: sdk ^3.4.0, flutter >=3.22.0`
- C 符号保持 `hn_*` 前缀；错误码 `-1..-8`（见 `enum hn_error`）
- 命名映射：`huji_ncnn`→`ncnn`、`HujiNcnn`→`Ncnn`、`huji_ncnn_plugin`→`ncnn_plugin`、`huji_ncnn_helper`→`ncnn_helper`、`HUJI_NCNN_LIB_DIR`→`NCNN_DART_LIB_DIR`、`HUJI_NCNN_ENABLE_VK`→`NCNN_DART_ENABLE_VK`、`HUJI_NCNN_VK_ICD`→`NCNN_DART_VK_ICD`、`HUJI_NCNN_ALLOW_INTEL_VK`→`NCNN_DART_ALLOW_INTEL_VK`、`HUJI_NCNN_ALL_ICDS`→`NCNN_DART_ALL_ICDS`、marker 文件 `huji_ncnn_lib_dir.txt`→`ncnn_dart_lib_dir.txt`、Android namespace `com.hhuoao.huji_ncnn`→`dev.hhoao.ncnn`
- huji 仓库（`/home/hhoa/git/hhoa/huji`）的改动全部在分支 `feat/ncnn-package-extraction` 上
- 验收硬标准：`huji-algorithm/scripts/verify_ncnn_parity.py` 4 模型 bit-exact；huji-app 测试全绿
- 所有 commit message 用 conventional commits，结尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`
- 真正的 `dart pub publish`（Task 13）前必须获得用户确认

## File Structure

**新仓 `/home/hhoa/git/hhoa/ncnn`（包在仓库根）：**

```
├── lib/
│   ├── ncnn.dart                  # 公开导出
│   └── src/
│       ├── bindings.g.dart        # 手维护 FFI 绑定（Task 3）
│       ├── options.dart           # NcnnOptions / NcnnPixelFormat（Task 3）
│       ├── runtime.dart           # NcnnRuntime / NcnnGpuDevice（Task 4）
│       ├── net.dart               # NcnnNet / NcnnOutput（Task 4）
│       ├── metadata.dart          # NcnnMetadata（Task 5）
│       ├── helper_process.dart    # NcnnHelperProcess + 协议帧（Task 7）
│       ├── inference_engine.dart  # NcnnInferenceEngine（Task 8）
│       └── yolo/
│           ├── classify.dart      # argmax / topK / softmax（Task 6）
│           └── detect.dart        # decodeYoloDetect + NMS（Task 6）
├── src/
│   ├── ncnn_api.h                 # C API（Task 2）
│   ├── ncnn_api.cpp               # C 实现（Task 2）
│   ├── ncnn_helper_main.cpp       # Windows helper（Task 7）
│   └── ncnn_link_anchor.m         # ObjC +load 锚（Task 1 随迁改名）
├── android/ ios/ linux/ macos/ windows/   # 平台构建（Task 1 机械改名）
├── example/                       # pub 平台验证 demo（Task 9）
├── test/                          # 单测 + 集成测试（各任务随写）
├── tool/sync_apple_sources.sh     # symlink 备选方案（Task 9 按需）
├── .github/workflows/ci.yml       # Task 10
├── .github/workflows/publish.yml  # Task 10
├── LICENSE / THIRD_PARTY_NOTICES.md / CHANGELOG.md / README.md  # Task 9
└── pubspec.yaml                   # Task 1
```

**huji 仓库改动（Task 11，分支 `feat/ncnn-package-extraction`）：**

```
├── .gitmodules                              # + packages/ncnn submodule
├── huji-app/pubspec.yaml                    # ncnn: path: packages/ncnn
├── huji-app/packages/ncnn                   # submodule（旧 huji_ncnn 删除）
├── huji-app/lib/services/inference/
│   ├── ncnn_inference_engine.dart           # 删除（迁入包）
│   ├── ncnn_helper_process.dart             # 删除（迁入包）
│   ├── ncnn_model_predictor.dart            # import 改 package:ncnn
│   ├── gpu_device_selector.dart             # import 改 package:ncnn
│   └── (其余 inference/*.dart 不动)
├── huji-app/lib/services/platform_capability.dart   # 引用改名
├── huji-app/scripts/build_appimage.sh               # 引用改名
├── .github/workflows/release.yml                    # 引用改名 + submodule checkout
└── huji-app/test/
    ├── helpers/ncnn_test_bootstrap.dart             # 删除（已入包）
    ├── ncnn_stale_marker_test.dart                  # 删除（已入包）
    ├── integration/ncnn_plugin_test.dart            # 删除（已入包）
    ├── integration/ncnn_real_frame_test.dart        # 删除（已入包）
    └── integration/{clip_flow,local_detection_golden}_test.dart  # import 改名保留
```

---

### Task 1: 新仓初始化与机械改名

**Files:**
- Create: `/home/hhoa/git/hhoa/ncnn/`（整包复制自 `huji-app/packages/huji_ncnn/`，排除 `pubspec.lock`、`android/.cxx/`、`.dart_tool/`）

**Interfaces:**
- Consumes: 现有包的全部文件
- Produces: 一个能 `flutter analyze` 通过、API 语义与旧包完全相同的 `ncnn` 包（后续任务的基线）

- [ ] **Step 1: 复制包并初始化 git**

```bash
SRC=/home/hhoa/git/hhoa/huji/huji-app/packages/huji_ncnn
DST=/home/hhoa/git/hhoa/ncnn
mkdir -p "$DST"
cd "$SRC"
# 复制除构建产物/lockfile 外的一切（含隐藏文件）
tar cf - --exclude=pubspec.lock --exclude=.dart_tool --exclude='android/.cxx' \
  --exclude=build . | (cd "$DST" && tar xf -)
cd "$DST"
git init -b main
git remote add origin https://github.com/hhoao/ncnn.git
```

- [ ] **Step 2: 全局机械改名**

```bash
cd /home/hhoa/git/hhoa/ncnn
# 环境变量先改（带 _ 后缀更长的先于通用替换）
grep -rl 'HUJI_NCNN_LIB_DIR'     . | xargs sed -i 's/HUJI_NCNN_LIB_DIR/NCNN_DART_LIB_DIR/g'
grep -rl 'HUJI_NCNN_ENABLE_VK'   . | xargs sed -i 's/HUJI_NCNN_ENABLE_VK/NCNN_DART_ENABLE_VK/g'
grep -rl 'HUJI_NCNN_VK_ICD'      . | xargs sed -i 's/HUJI_NCNN_VK_ICD/NCNN_DART_VK_ICD/g'
grep -rl 'HUJI_NCNN_ALLOW_INTEL_VK' . | xargs sed -i 's/HUJI_NCNN_ALLOW_INTEL_VK/NCNN_DART_ALLOW_INTEL_VK/g'
grep -rl 'HUJI_NCNN_ALL_ICDS'    . | xargs sed -i 's/HUJI_NCNN_ALL_ICDS/NCNN_DART_ALL_ICDS/g'
# Android namespace（含拼写错误修正）
sed -i 's/com\.hhuoao\.huji_ncnn/dev.hhoao.ncnn/g' android/build.gradle
# 通用标识（文件名与内容）
grep -rl 'huji_ncnn' . | xargs sed -i 's/huji_ncnn/ncnn/g'
grep -rl 'HujiNcnn'  . | xargs sed -i 's/HujiNcnn/Ncnn/g'
# 文件重命名
git mv lib/huji_ncnn.dart lib/ncnn.dart        # （git mv 前先 git add -A）
mv src/huji_ncnn_api.h src/ncnn_api.h
mv src/huji_ncnn_api.cpp src/ncnn_api.cpp
mv src/huji_ncnn_helper_main.cpp src/ncnn_helper_main.cpp
mv src/huji_ncnn_link_anchor.m src/ncnn_link_anchor.m
# ios/macos 的 symlink 指向源文件名，重建
for d in ios/src macos/src; do
  rm -f $d/ncnn_api.cpp $d/ncnn_api.h $d/ncnn_link_anchor.m
  ln -s ../../src/ncnn_api.cpp $d/ncnn_api.cpp
  ln -s ../../src/ncnn_api.h   $d/ncnn_api.h
  ln -s ../../src/ncnn_link_anchor.m $d/ncnn_link_anchor.m
done
# podspec 与 podspec 内引用改名
mv ios/huji_ncnn.podspec ios/ncnn.podspec
mv macos/huji_ncnn.podspec macos/ncnn.podspec
```

注意：`ios/src`、`macos/src` 旧 symlink 文件名此时仍是 `huji_ncnn_*`（sed 不跟随 symlink 改目标名），上面显式重建。

- [ ] **Step 3: pubspec 重写**

`pubspec.yaml` 全文替换为：

```yaml
name: ncnn
description: >
  ncnn (Vulkan) inference bindings for Dart/Flutter — a thin C shim over
  ncnn::Net exposed via dart:ffi. Runs image inference on CPU or any
  Vulkan-capable GPU (NVIDIA / AMD / Intel / Apple via MoltenVK / Android),
  with automatic CPU fallback. Ships ultralytics YOLO export conventions
  as defaults.
version: 0.1.0

environment:
  sdk: ^3.4.0
  flutter: '>=3.22.0'

dependencies:
  ffi: ^2.1.0
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^4.0.0
  flutter_test:
    sdk: flutter

flutter:
  # FFI-only plugin: no method channel class, native lib resolved by name.
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true
      linux:
        ffiPlugin: true
      macos:
        ffiPlugin: true
      windows:
        ffiPlugin: true
```

同时删除 `ffigen.yaml`（设计修订：绑定手维护）。

- [ ] **Step 4: .gitignore 重写**

`.gitignore` 全文替换为：

```
# Downloaded prebuilt ncnn / MoltenVK frameworks (podspec prepare_command).
macos/build/
ios/build/
# Build artifacts — CRITICAL for publish: pub reads only the package's own
# .gitignore, and android/.cxx is ~1 GB of NDK build output.
.cxx/
build/
.dart_tool/
*.iml
.idea/
# Library packages must not ship a lockfile.
pubspec.lock
```

- [ ] **Step 5: 验证编译**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter pub get
flutter analyze
```
Expected: `No issues found!`（此时 Dart 代码语义与旧包相同，仅改名）

- [ ] **Step 6: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "chore: extract from huji-app as package ncnn (mechanical rename)"
```

---

### Task 2: C API 泛化重写（ncnn_api.h + ncnn_api.cpp）

**Files:**
- Rewrite: `src/ncnn_api.h`（全文替换）
- Rewrite: `src/ncnn_api.cpp`（全文替换）

**Interfaces:**
- Consumes: 无（C 边界）
- Produces: 后续所有任务依赖的 C 面——`hn_options_t`（struct_size 版本化）、`hn_create(const hn_options_t*)`、`hn_load`、`hn_output_count`、`hn_output_shape(net, i, int32_t shape[4])` 返回 dims（0=无 hint）、`hn_extract(net, pixels, w, h, out, out_cap, shapes, shape_cap, required_out)`、`hn_extract_f32(net, data, shape, dims, out, out_cap, shapes, shape_cap, required_out)`、`hn_destroy`、`hn_gpu_count`、`hn_gpu_devices`。错误码：-1 参数/状态、-2 param、-3 bin、-4 输入 blob、-5 提取、-6 shape、-7 容量（`*required_out` 写入所需 float 数）、-8 C++ 异常屏障。

注意：本任务后 `src/ncnn_helper_main.cpp` 暂时编译不过（仍调旧签名），Task 7 重写。期间不做 Windows 构建。

- [ ] **Step 1: 重写 `src/ncnn_api.h`（全文）**

```c
// Public C surface of the ncnn Dart/Flutter plugin.
//
// Thin extern "C" shim over ncnn::Net. The surface is small and versioned:
// hn_options_t carries struct_size so fields can be appended without
// breaking binary compatibility. Symbols keep the hn_ prefix so they
// cannot collide with ncnn's own C++ symbols.
#ifndef NCNN_DART_API_H
#define NCNN_DART_API_H

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define HN_API __declspec(dllexport)
#else
#define HN_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque handle to a loaded ncnn network.
typedef void* hn_net_t;

/// Vulkan device info returned by hn_gpu_devices.
typedef struct {
    int index;          /// ncnn device index
    int type;           /// 0=discrete, 1=integrated, 2=virtual, 3=cpu
    int score;          /// ncnn rough_score heuristic (higher = faster)
    uint32_t vendor_id; /// PCI vendor id
} hn_gpu_device_t;

#define HN_MAX_GPU 8
#define HN_NAME_MAX 128

/// Input pixel layout (source buffer layout; from_pixels produces a
/// 3-channel Mat, or 1-channel for GRAY).
enum hn_pixel_format {
    HN_PIX_RGB = 0,
    HN_PIX_BGR = 1,
    HN_PIX_RGBA = 2,
    HN_PIX_BGRA = 3,
    HN_PIX_GRAY = 4,
};

/// Error codes (returned as negative ints).
enum hn_error {
    HN_OK = 0,
    HN_ERR_INVALID = -1,       /// null args / bad state / bad options
    HN_ERR_PARAM = -2,         /// load_param failed (or no output blobs)
    HN_ERR_BIN = -3,           /// load_model failed
    HN_ERR_NO_INPUT_BLOB = -4, /// configured input blob not in the graph
    HN_ERR_EXTRACT = -5,       /// extractor input/extract failed
    HN_ERR_SHAPE = -6,         /// output blob has no usable elements
    HN_ERR_CAPACITY = -7,      /// out too small (*required_out set)
    HN_ERR_EXCEPTION = -8,     /// C++ exception caught at the boundary
};

/// Network options. struct_size MUST be sizeof(hn_options_t) as compiled
/// by the caller; fields are only ever APPENDED, and hn_create accepts
/// any struct_size in [HN_OPTIONS_V1_SIZE, sizeof(hn_options_t)].
/// mean/norm are per-channel; the first N entries are used for the actual
/// channel count (GRAY=1, others=3).
typedef struct {
    uint32_t struct_size;
    int use_vulkan;
    int device_index;       /// -1 = ncnn default device
    float mean[3];
    float norm[3];          /// all-1 = no scaling; YOLO convention = 1/255
    int pixel_format;       /// enum hn_pixel_format
    const char* input_blob; /// NULL = "in0" (ultralytics convention)
} hn_options_t;

#define HN_OPTIONS_V1_SIZE \
    ((uint32_t)(offsetof(hn_options_t, input_blob) + sizeof(const char*)))

/// Create a network. opts may be NULL for all defaults. Returns NULL on
/// OOM or a struct_size outside the accepted range.
HN_API hn_net_t hn_create(const hn_options_t* opts);

/// Load param+bin. Discovers graph output blobs by parsing the param
/// file (blobs produced but never consumed) and runs a warm-up (64x64
/// zeros) to record output shapes as hints for hn_output_shape.
HN_API int hn_load(hn_net_t net, const char* param_path, const char* bin_path);

/// Number of graph output blobs (0 before a successful hn_load).
HN_API int hn_output_count(hn_net_t net);

/// Fill shape[0..3] = (w, h, d|1, c) for output `out_index` — 4 entries
/// are always written, padded with 1s. Returns the blob's ncnn dims, or
/// 0 when the warm-up hint is unavailable (size via hn_extract retry).
HN_API int hn_output_shape(hn_net_t net, int out_index, int32_t shape[4]);

/// Run inference on a pixel buffer (layout per options.pixel_format,
/// w*h*channels bytes) and write ALL output blobs, concatenated, into
/// `out`. shapes (may be NULL) gets 4 entries per output, same
/// convention as hn_output_shape but for THIS run. On HN_ERR_CAPACITY,
/// *required_out (if non-NULL) receives the needed float count.
/// Returns total floats written, or a negative enum hn_error.
HN_API int hn_extract(hn_net_t net, const uint8_t* pixels, int w, int h,
                      float* out, int out_cap, int32_t* shapes,
                      int shape_cap, int32_t* required_out);

/// Same, with a raw float input tensor (no pixel decode, no mean/norm —
/// the caller preprocesses). shape holds `dims` entries (1..4, ncnn
/// order w/h/d/c), data is contiguous in that order.
HN_API int hn_extract_f32(hn_net_t net, const float* data,
                          const int32_t* shape, int dims, float* out,
                          int out_cap, int32_t* shapes, int shape_cap,
                          int32_t* required_out);

/// Destroy a network (NULL is a no-op).
HN_API void hn_destroy(hn_net_t net);

/// Count available Vulkan devices (0 if Vulkan is unavailable/disabled).
HN_API int hn_gpu_count(void);

/// Fill devices[0..n-1] and names[i][HN_NAME_MAX] for up to n Vulkan
/// devices. Returns the number written.
HN_API int hn_gpu_devices(hn_gpu_device_t* devices,
                          char (*names)[HN_NAME_MAX], int n);

#ifdef __cplusplus
}
#endif

#endif // NCNN_DART_API_H
```

- [ ] **Step 2: 重写 `src/ncnn_api.cpp`（全文）**

```cpp
// Thin C shim over ncnn::Net for dart:ffi — generalized inference API.
//
// - Every extern "C" entry is wrapped in try/catch: ncnn throws C++
//   exceptions (corrupted param/bin files), and an exception crossing
//   the C boundary into Dart FFI is UB — surface as HN_ERR_EXCEPTION.
// - Output blobs are discovered by parsing the param file (blobs
//   produced but never consumed; Noop-consumed as the onnx2ncnn
//   fallback), so callers never hardcode blob names.
// - A 64x64 warm-up records output shapes as hints; shapes may vary
//   with input size, so hn_extract reports the CURRENT run's shapes and
//   supports a capacity-retry via *required_out.
#include "ncnn_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <string>
#include <unordered_set>
#include <vector>

#include "ncnn/net.h"
#if NCNN_VULKAN
#include "ncnn/gpu.h"
#include <mutex>
#if defined(_WIN32)
#include <cstdlib>
#endif
#endif

namespace {

constexpr int kWarmupSize = 64;

struct hn_net {
    ncnn::Net net;
    bool loaded = false;
    int pixel_format = HN_PIX_RGB;
    float mean[3] = {0.f, 0.f, 0.f};
    float norm[3] = {1.f, 1.f, 1.f};
    std::string input_blob = "in0"; // strdup'd copy — owns the lifetime
    std::vector<int> output_blobs;
    // 5 ints per output: [dims, w, h, d, c]; dims == 0 = no hint.
    std::vector<int> output_shape_hints;
};

hn_net* as_net(hn_net_t net) {
    return static_cast<hn_net*>(net);
}

#if NCNN_VULKAN && defined(_WIN32)

// EVIDENCE (2026-09, RTX 4060 + Intel Arc laptop, ncnn 20260526):
//   hardware Vulkan + Flutter engine process  -> crash AFTER full device
//     enumeration (all device dumps print, incl. NVIDIA), inside the tail
//     of create_gpu_instance / early device use
//   hardware Vulkan + plain native / python   -> works
//   SwiftShader ICD + Flutter engine process  -> works
//   CPU                                        -> always works
// Policy: in-process on Windows the default is ZERO Vulkan devices (CPU
// inference) so apps never touch the crashing path. GPU inference goes
// through the standalone ncnn_helper child process instead. Opt back in
// with NCNN_DART_ENABLE_VK=1 (or pin VK_ICD_FILENAMES yourself).
int windows_vulkan_allowed() {
    if (getenv("NCNN_DART_ENABLE_VK") != nullptr) return 1;
    if (getenv("VK_ICD_FILENAMES") != nullptr) return 1;
    return 0;
}

std::once_flag gpu_init_once;

void warm_up_gpu_instance() {
    std::call_once(gpu_init_once, []() {
        if (!windows_vulkan_allowed()) return;
        // Synchronous init: a detached thread races with the caller's
        // get_gpu_count and can tear down mid-read (observed crash).
        ncnn::create_gpu_instance();
    });
}

// NOTE: non-Windows platforms previously had a detached-thread + 200ms
// sleep warm-up here. Removed: ncnn creates the gpu instance lazily,
// idempotently and under its own lock (get_gpu_count), so the sleep was
// both unnecessary and racy.
#endif

int pixel_type(int fmt) {
    switch (fmt) {
        case HN_PIX_BGR: return ncnn::Mat::PIXEL_BGR;
        case HN_PIX_RGBA: return ncnn::Mat::PIXEL_RGBA;
        case HN_PIX_BGRA: return ncnn::Mat::PIXEL_BGRA;
        case HN_PIX_GRAY: return ncnn::Mat::PIXEL_GRAY;
        case HN_PIX_RGB:
        default: return ncnn::Mat::PIXEL_RGB;
    }
}

int channel_count(int fmt) {
    return fmt == HN_PIX_GRAY ? 1 : 3;
}

void set_options(ncnn::Net& net, int use_vulkan, int device_index) {
    net.opt.num_threads = 4;
#if NCNN_VULKAN
#if defined(_WIN32)
    if (use_vulkan && !windows_vulkan_allowed()) use_vulkan = 0;
#endif
    if (use_vulkan) warm_up_gpu_instance();
    net.opt.use_vulkan_compute = use_vulkan != 0;
    if (use_vulkan && device_index >= 0) net.set_vulkan_device(device_index);
#else
    (void)use_vulkan;
    (void)device_index;
#endif
}

// Parse a param file for graph output blobs: ids produced but never
// consumed by any layer. Empty result falls back to blobs consumed by
// Noop layers (onnx2ncnn marks outputs that way). Ascending blob-id
// order for deterministic output indexing.
bool parse_output_blobs(const char* path, std::vector<int>* out) {
    FILE* f = fopen(path, "rb");
    if (f == nullptr) return false;
    char line[1024];
    if (fgets(line, sizeof(line), f) == nullptr) { fclose(f); return false; }
    int layer_count = 0, blob_count = 0;
    if (fscanf(f, "%d %d", &layer_count, &blob_count) != 2) {
        fclose(f);
        return false;
    }
    fgets(line, sizeof(line), f); // consume EOL after the counts
    std::unordered_set<int> produced, consumed, noop_consumed;
    bool ok = true;
    for (int i = 0; i < layer_count && ok; i++) {
        char type[256], name[256];
        int in_n = 0, out_n = 0;
        if (fscanf(f, "%255s %255s %d %d", type, name, &in_n, &out_n) != 4) {
            ok = false;
            break;
        }
        const bool is_noop = strcmp(type, "Noop") == 0;
        for (int k = 0; k < in_n; k++) {
            int b;
            if (fscanf(f, "%d", &b) != 1) { ok = false; break; }
            consumed.insert(b);
            if (is_noop) noop_consumed.insert(b);
        }
        for (int k = 0; ok && k < out_n; k++) {
            int b;
            if (fscanf(f, "%d", &b) != 1) { ok = false; break; }
            produced.insert(b);
        }
    }
    fclose(f);
    if (!ok) return false;
    for (int b : produced) {
        if (consumed.find(b) == consumed.end()) out->push_back(b);
    }
    if (out->empty()) {
        for (int b : noop_consumed) out->push_back(b);
    }
    std::sort(out->begin(), out->end());
    return !out->empty();
}

// Total element count of an ncnn Mat (logical elements, channels included).
size_t mat_elems(const ncnn::Mat& m) {
    if (m.dims == 1) return (size_t)m.w;
    if (m.dims == 2) return (size_t)m.w * m.h;
    return (size_t)m.c * m.w * m.h * (m.dims == 4 ? m.d : 1);
}

// Fill shape[0..3] = (w, h, d|1, c), padded with 1s. Returns dims.
int fill_shape(const ncnn::Mat& m, int32_t* shape) {
    shape[0] = m.dims >= 1 ? m.w : 1;
    shape[1] = m.dims >= 2 ? m.h : 1;
    shape[2] = m.dims == 4 ? m.d : 1;
    shape[3] = m.dims >= 3 ? m.c : 1;
    return m.dims;
}

// Copy one output Mat into dst. Multi-channel Mats are cstep-strided
// per channel (NOT contiguous) — a flat memcpy across channels
// corrupts data.
void copy_mat(const ncnn::Mat& m, float* dst) {
    if (m.dims <= 2) {
        memcpy(dst, m.data, mat_elems(m) * sizeof(float));
        return;
    }
    const size_t plane = mat_elems(m) / (size_t)(m.c > 0 ? m.c : 1);
    for (int c = 0; c < m.c; c++) {
        memcpy(dst + (size_t)c * plane, m.channel(c).data,
               plane * sizeof(float));
    }
}

// Shared extract path over all discovered outputs.
int extract_all(hn_net* n, const ncnn::Mat& in, float* out, int out_cap,
                int32_t* shapes, int shape_cap, int32_t* required_out) {
    ncnn::Extractor ex = n->net.create_extractor();
    if (ex.input(n->input_blob.c_str(), in) != 0) return HN_ERR_NO_INPUT_BLOB;
    std::vector<ncnn::Mat> outs(n->output_blobs.size());
    size_t total = 0;
    for (size_t i = 0; i < n->output_blobs.size(); i++) {
        if (ex.extract(n->output_blobs[i], outs[i]) != 0) return HN_ERR_EXTRACT;
        const size_t elems = mat_elems(outs[i]);
        if (elems == 0) return HN_ERR_SHAPE;
        total += elems;
        if (shapes != nullptr && (int)(i + 1) * 4 <= shape_cap) {
            fill_shape(outs[i], shapes + i * 4);
        }
    }
    if ((size_t)out_cap < total) {
        if (required_out != nullptr) *required_out = (int32_t)total;
        return HN_ERR_CAPACITY;
    }
    size_t off = 0;
    for (const auto& m : outs) {
        copy_mat(m, out + off);
        off += mat_elems(m);
    }
    return (int)total;
}

} // namespace

hn_net_t hn_create(const hn_options_t* opts) {
    if (opts != nullptr &&
        (opts->struct_size < HN_OPTIONS_V1_SIZE ||
         opts->struct_size > (uint32_t)sizeof(hn_options_t))) {
        return nullptr;
    }
    auto* n = new (std::nothrow) hn_net();
    if (n == nullptr) return nullptr;
    try {
        if (opts != nullptr) {
            n->pixel_format = opts->pixel_format;
            for (int i = 0; i < 3; i++) {
                n->mean[i] = opts->mean[i];
                n->norm[i] = opts->norm[i];
            }
            if (opts->input_blob != nullptr) n->input_blob = opts->input_blob;
        }
        set_options(n->net, opts ? opts->use_vulkan : 0,
                    opts ? opts->device_index : -1);
    } catch (...) {
        delete n;
        return nullptr;
    }
    return n;
}

int hn_load(hn_net_t net, const char* param_path, const char* bin_path) {
    if (net == nullptr || param_path == nullptr || bin_path == nullptr) {
        return HN_ERR_INVALID;
    }
    auto* n = as_net(net);
    try {
        if (!parse_output_blobs(param_path, &n->output_blobs)) {
            return HN_ERR_PARAM;
        }
        if (n->net.load_param(param_path) != 0) return HN_ERR_PARAM;
        if (n->net.load_model(bin_path) != 0) return HN_ERR_BIN;
        n->loaded = true;
        // Warm-up for shape hints: 64x64 zeros through the real input
        // path. Failure is non-fatal — hints stay zero and callers fall
        // back to the capacity-retry on the first real extract.
        const int ch = channel_count(n->pixel_format);
        std::vector<uint8_t> zeros(
            (size_t)kWarmupSize * kWarmupSize * ch, 0);
        ncnn::Mat in = ncnn::Mat::from_pixels(
            zeros.data(), pixel_type(n->pixel_format),
            kWarmupSize, kWarmupSize);
        // substract_mean_normalize reads norm[channels] entries — one per
        // channel, NOT a single shared scalar (a 1-element array reads OOB
        // and corrupts G/B planes).
        in.substract_mean_normalize(n->mean, n->norm);
        n->output_shape_hints.assign(n->output_blobs.size() * 5, 0);
        ncnn::Extractor ex = n->net.create_extractor();
        if (ex.input(n->input_blob.c_str(), in) == 0) {
            for (size_t i = 0; i < n->output_blobs.size(); i++) {
                ncnn::Mat om;
                if (ex.extract(n->output_blobs[i], om) == 0 &&
                    mat_elems(om) > 0) {
                    n->output_shape_hints[i * 5] = om.dims;
                    fill_shape(om, &n->output_shape_hints[i * 5 + 1]);
                }
            }
        }
        return HN_OK;
    } catch (...) {
        n->loaded = false;
        return HN_ERR_EXCEPTION;
    }
}

int hn_output_count(hn_net_t net) {
    if (net == nullptr) return 0;
    return (int)as_net(net)->output_blobs.size();
}

int hn_output_shape(hn_net_t net, int out_index, int32_t shape[4]) {
    if (net == nullptr || shape == nullptr) return 0;
    auto* n = as_net(net);
    if (out_index < 0 || (size_t)out_index >= n->output_blobs.size()) {
        return 0;
    }
    const int32_t* hint = &n->output_shape_hints[out_index * 5];
    if (hint[0] == 0) return 0; // no warm-up hint
    memcpy(shape, hint + 1, 4 * sizeof(int32_t));
    return hint[0];
}

int hn_extract(hn_net_t net, const uint8_t* pixels, int w, int h,
               float* out, int out_cap, int32_t* shapes, int shape_cap,
               int32_t* required_out) {
    if (net == nullptr || pixels == nullptr || w <= 0 || h <= 0) {
        return HN_ERR_INVALID;
    }
    auto* n = as_net(net);
    if (!n->loaded) return HN_ERR_INVALID;
    try {
        ncnn::Mat in = ncnn::Mat::from_pixels(
            pixels, pixel_type(n->pixel_format), w, h);
        in.substract_mean_normalize(n->mean, n->norm);
        return extract_all(n, in, out, out_cap, shapes, shape_cap,
                           required_out);
    } catch (...) {
        return HN_ERR_EXCEPTION;
    }
}

int hn_extract_f32(hn_net_t net, const float* data, const int32_t* shape,
                   int dims, float* out, int out_cap, int32_t* shapes,
                   int shape_cap, int32_t* required_out) {
    if (net == nullptr || data == nullptr || shape == nullptr ||
        dims < 1 || dims > 4) {
        return HN_ERR_INVALID;
    }
    auto* n = as_net(net);
    if (!n->loaded) return HN_ERR_INVALID;
    try {
        // Wraps the caller's buffer (no copy); safe because `data`
        // outlives this call.
        ncnn::Mat in(dims, shape, (void*)data, (size_t)4);
        return extract_all(n, in, out, out_cap, shapes, shape_cap,
                           required_out);
    } catch (...) {
        return HN_ERR_EXCEPTION;
    }
}

void hn_destroy(hn_net_t net) {
    delete static_cast<hn_net*>(net);
}

int hn_gpu_count(void) {
#if NCNN_VULKAN
#if defined(_WIN32)
    if (!windows_vulkan_allowed()) return 0;
#endif
    try {
        return ncnn::get_gpu_count();
    } catch (...) {
        return 0;
    }
#else
    return 0;
#endif
}

int hn_gpu_devices(hn_gpu_device_t* devices, char (*names)[HN_NAME_MAX],
                   int n) {
#if NCNN_VULKAN
#if defined(_WIN32)
    if (!windows_vulkan_allowed()) return 0;
#endif
    try {
        const int count = ncnn::get_gpu_count();
        if (count <= 0 || devices == nullptr || names == nullptr || n <= 0) {
            return 0;
        }
        int written = 0;
        for (int i = 0; i < count && written < n; i++) {
            const ncnn::GpuInfo& info = ncnn::get_gpu_info(i);
            devices[written].index = i;
            devices[written].type = info.type();
            devices[written].score = (int)info.rough_score();
            devices[written].vendor_id = info.vendor_id();
            const char* name = info.device_name();
            if (name != nullptr) {
                strncpy(names[written], name, HN_NAME_MAX - 1);
                names[written][HN_NAME_MAX - 1] = '\0';
            } else {
                names[written][0] = '\0';
            }
            written++;
        }
        return written;
    } catch (...) {
        return 0;
    }
#else
    (void)devices;
    (void)names;
    (void)n;
    return 0;
#endif
}
```

注意：`hn_gpu_count` 旧实现里的 `warm_up_gpu_instance()` 调用已去掉（见 cpp 顶部 NOTE）；`gpu_count`/`gpu_devices` 在非 Windows 无预热直接调用（ncnn 内部幂等加锁）。

- [ ] **Step 3: 语法冒烟（best-effort，无需 Flutter 构建）**

```bash
cd /home/hhoa/git/hhoa/ncnn
curl -fL -o /tmp/ncnn.zip \
  https://github.com/Tencent/ncnn/releases/download/20260526/ncnn-20260526-ubuntu-2204-shared.zip
unzip -qo /tmp/ncnn.zip -d /tmp/ncnn-extract
g++ -fsyntax-only -std=c++17 -Isrc -I/tmp/ncnn-extract/ncnn-*/include \
  -DNCNN_VULKAN=1 src/ncnn_api.cpp && echo SYNTAX-OK
```
Expected: `SYNTAX-OK`（helper_main 此时不检查——Task 7 才重写）

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(api)!: generalize C surface — versioned options, output discovery, extract/extract_f32, exception barriers"
```

---

### Task 3: Dart 绑定与 NcnnOptions

**Files:**
- Rewrite: `lib/src/bindings.g.dart`（全文替换）
- Create: `lib/src/options.dart`
- Test: `test/options_test.dart`

**Interfaces:**
- Consumes: Task 2 的 C 面（函数名/签名/常量值）
- Produces: `NcnnNative.fromLibrary(DynamicLibrary)`（`hnCreate/hnLoad/hnOutputCount/hnOutputShape/hnExtract/hnExtractF32/hnDestroy/hnGpuCount/hnGpuDevices`）、`HnOptions` struct、`HnGpuDevice`、常量 `hnPixRgb..hnPixGray`、`hnOk..hnErrException`、`hnMaxGpu/hnNameMax`；`NcnnOptions`（`{useVulkan, deviceIndex, mean, norm, pixelFormat, inputBlob}` + 命名构造 `NcnnOptions.yolo()`）、`NcnnPixelFormat` enum、`NcnnOptions.toNative()` → `Pointer<HnOptions>`（调用方负责 free，inputBlob 子分配也由 `freeNative` 释放）

- [ ] **Step 1: 写失败测试**

`test/options_test.dart`：

```dart
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/bindings.g.dart' as native;
import 'package:ncnn/src/options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HnOptions struct size is accepted by C (>= V1 size)', () {
    // The C side rejects struct_size outside
    // [HN_OPTIONS_V1_SIZE, sizeof(hn_options_t)] — compiled-together
    // means equality here.
    expect(sizeOf<native.HnOptions>(), greaterThanOrEqualTo(4 + 4 + 4 + 12 + 12 + 4));
  });

  test('NcnnOptions defaults match ultralytics convention', () {
    const o = NcnnOptions();
    expect(o.useVulkan, isFalse);
    expect(o.deviceIndex, -1);
    expect(o.mean, const [0, 0, 0]);
    expect(o.norm, const [1, 1, 1]);
    expect(o.pixelFormat, NcnnPixelFormat.rgb);
    expect(o.inputBlob, isNull);
  });

  test('NcnnOptions.yolo uses x/255 normalization', () {
    const o = NcnnOptions.yolo();
    expect(o.norm, everyElement(closeTo(1 / 255, 1e-9)));
    expect(o.mean, const [0, 0, 0]);
  });

  test('toNative roundtrips fields and frees cleanly', () {
    const o = NcnnOptions.yolo(useVulkan: true, deviceIndex: 2);
    final ptr = o.toNative();
    try {
      final s = ptr.ref;
      expect(s.structSize, sizeOf<native.HnOptions>());
      expect(s.useVulkan, 1);
      expect(s.deviceIndex, 2);
      expect(s.norm[0], closeTo(1 / 255, 1e-9));
      expect(s.inputBlob.cast<Utf8>().toDartString(), 'in0');
    } finally {
      NcnnOptions.freeNative(ptr);
    }
  });
}
```

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/options_test.dart
```
Expected: FAIL（`options.dart` 不存在 / `toNative` 未定义）

- [ ] **Step 3: 写 `lib/src/bindings.g.dart`（全文）**

```dart
// Hand-maintained bindings for src/ncnn_api.h.
//
// ffigen's generated shape cannot plug into NcnnRuntime's custom
// DynamicLibrary resolution chain (test-VM marker machinery), so the
// bindings are hand-written against the header. Symbol coverage is
// guaranteed by test/symbol_coverage_test.dart, which opens the library
// and looks up every function below.
// ignore_for_file: always_specify_types, constant_identifier_names

library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Opaque handle to a loaded ncnn network.
typedef HnNet = Pointer<Void>;

/// enum hn_pixel_format values.
const int hnPixRgb = 0;
const int hnPixBgr = 1;
const int hnPixRgba = 2;
const int hnPixBgra = 3;
const int hnPixGray = 4;

/// enum hn_error values.
const int hnOk = 0;
const int hnErrInvalid = -1;
const int hnErrParam = -2;
const int hnErrBin = -3;
const int hnErrNoInputBlob = -4;
const int hnErrExtract = -5;
const int hnErrShape = -6;
const int hnErrCapacity = -7;
const int hnErrException = -8;

const int hnMaxGpu = 8;
const int hnNameMax = 128;

/// int32 fields — C struct is 4*int + uint32 = 20 bytes, aligned.
final class HnGpuDevice extends Struct {
  @Int32()
  external int index;
  @Int32()
  external int type;
  @Int32()
  external int score;
  @Uint32()
  external int vendorId;
}

/// C mirror of hn_options_t — field order and types must match exactly
/// (struct_size is validated by hn_create).
final class HnOptions extends Struct {
  @Uint32()
  external int structSize;
  @Int32()
  external int useVulkan;
  @Int32()
  external int deviceIndex;
  @Array.multi([3])
  external Array<Float> mean;
  @Array.multi([3])
  external Array<Float> norm;
  @Int32()
  external int pixelFormat;
  external Pointer<Char> inputBlob;
}

typedef HnCreateNative = Pointer<Void> Function(Pointer<HnOptions>);
typedef HnCreateDart = Pointer<Void> Function(Pointer<HnOptions>);
typedef HnLoadNative = Int32 Function(
    Pointer<Void>, Pointer<Char>, Pointer<Char>);
typedef HnLoadDart = int Function(
    Pointer<Void>, Pointer<Char>, Pointer<Char>);
typedef HnOutputCountNative = Int32 Function(Pointer<Void>);
typedef HnOutputCountDart = int Function(Pointer<Void>);
typedef HnOutputShapeNative = Int32 Function(
    Pointer<Void>, Int32, Pointer<Int32>);
typedef HnOutputShapeDart = int Function(Pointer<Void>, int, Pointer<Int32>);
typedef HnExtractNative = Int32 Function(
    Pointer<Void>,
    Pointer<Uint8>,
    Int32,
    Int32,
    Pointer<Float>,
    Int32,
    Pointer<Int32>,
    Int32,
    Pointer<Int32>);
typedef HnExtractDart = int Function(
    Pointer<Void>,
    Pointer<Uint8>,
    int,
    int,
    Pointer<Float>,
    int,
    Pointer<Int32>,
    int,
    Pointer<Int32>);
typedef HnExtractF32Native = Int32 Function(
    Pointer<Void>,
    Pointer<Float>,
    Pointer<Int32>,
    Int32,
    Pointer<Float>,
    Int32,
    Pointer<Int32>,
    Int32,
    Pointer<Int32>);
typedef HnExtractF32Dart = int Function(
    Pointer<Void>,
    Pointer<Float>,
    Pointer<Int32>,
    int,
    Pointer<Float>,
    int,
    Pointer<Int32>,
    int,
    Pointer<Int32>);
typedef HnDestroyNative = Void Function(Pointer<Void>);
typedef HnDestroyDart = void Function(Pointer<Void>);
typedef HnGpuCountNative = Int32 Function();
typedef HnGpuCountDart = int Function();
// names is char (*)[hnNameMax] — inline fixed-size rows, not pointers.
typedef HnGpuDevicesNative = Int32 Function(
    Pointer<HnGpuDevice>, Pointer<Uint8>, Int32);
typedef HnGpuDevicesDart = int Function(
    Pointer<HnGpuDevice>, Pointer<Uint8>, int);

/// Looked-up C entry points of the ncnn shim.
class NcnnNative {
  NcnnNative._();

  late final HnCreateDart hnCreate;
  late final HnLoadDart hnLoad;
  late final HnOutputCountDart hnOutputCount;
  late final HnOutputShapeDart hnOutputShape;
  late final HnExtractDart hnExtract;
  late final HnExtractF32Dart hnExtractF32;
  late final HnDestroyDart hnDestroy;
  late final HnGpuCountDart hnGpuCount;
  late final HnGpuDevicesDart hnGpuDevices;

  /// Resolves all shim symbols from [lib].
  factory NcnnNative.fromLibrary(DynamicLibrary lib) {
    final n = NcnnNative._();
    n.hnCreate =
        lib.lookupFunction<HnCreateNative, HnCreateDart>('hn_create');
    n.hnLoad = lib.lookupFunction<HnLoadNative, HnLoadDart>('hn_load');
    n.hnOutputCount = lib.lookupFunction<HnOutputCountNative,
        HnOutputCountDart>('hn_output_count');
    n.hnOutputShape = lib.lookupFunction<HnOutputShapeNative,
        HnOutputShapeDart>('hn_output_shape');
    n.hnExtract =
        lib.lookupFunction<HnExtractNative, HnExtractDart>('hn_extract');
    n.hnExtractF32 = lib.lookupFunction<HnExtractF32Native, HnExtractF32Dart>(
        'hn_extract_f32');
    n.hnDestroy =
        lib.lookupFunction<HnDestroyNative, HnDestroyDart>('hn_destroy');
    n.hnGpuCount =
        lib.lookupFunction<HnGpuCountNative, HnGpuCountDart>('hn_gpu_count');
    n.hnGpuDevices = lib.lookupFunction<HnGpuDevicesNative, HnGpuDevicesDart>(
        'hn_gpu_devices');
    return n;
  }
}
```

- [ ] **Step 4: 写 `lib/src/options.dart`（全文）**

```dart
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart' as native;

/// Input pixel layout (source buffer layout; the shim produces a
/// 3-channel tensor, or 1-channel for gray).
enum NcnnPixelFormat {
  rgb(native.hnPixRgb),
  bgr(native.hnPixBgr),
  rgba(native.hnPixRgba),
  bgra(native.hnPixBgra),
  gray(native.hnPixGray);

  const NcnnPixelFormat(this.value);

  final int value;
}

/// Preprocessing / backend options for [NcnnNet.load].
///
/// Defaults follow the ultralytics ncnn export convention so YOLO models
/// work with `const NcnnOptions()`; everything is overridable for other
/// models.
class NcnnOptions {
  const NcnnOptions({
    this.useVulkan = false,
    this.deviceIndex = -1,
    this.mean = const [0, 0, 0],
    this.norm = const [1, 1, 1],
    this.pixelFormat = NcnnPixelFormat.rgb,
    this.inputBlob,
  })  : assert(mean.length == 3),
        assert(norm.length == 3);

  /// ultralytics YOLO convention: RGB, x/255, no mean subtraction,
  /// input blob "in0".
  const NcnnOptions.yolo({this.useVulkan = false, this.deviceIndex = -1})
      : mean = const [0, 0, 0],
        norm = const [_oneOver255, _oneOver255, _oneOver255],
        pixelFormat = NcnnPixelFormat.rgb,
        inputBlob = null;

  static const double _oneOver255 = 1.0 / 255.0;

  /// Enable Vulkan compute. CPU fallback happens at a higher level
  /// ([NcnnInferenceEngine]); a failed Vulkan load throws here.
  final bool useVulkan;

  /// Vulkan device index (-1 = ncnn default). Ignored unless
  /// [useVulkan].
  final int deviceIndex;

  /// Per-channel mean subtraction (RGB order).
  final List<double> mean;

  /// Per-channel norm division (all-1 = no scaling).
  final List<double> norm;

  final NcnnPixelFormat pixelFormat;

  /// Input blob name; null = "in0" (ultralytics convention).
  final String? inputBlob;

  /// Allocates the native mirror (caller must [freeNative]).
  Pointer<native.HnOptions> toNative() {
    final p = calloc<native.HnOptions>();
    final s = p.ref;
    s.structSize = sizeOf<native.HnOptions>();
    s.useVulkan = useVulkan ? 1 : 0;
    s.deviceIndex = deviceIndex;
    for (var i = 0; i < 3; i++) {
      s.mean[i] = mean[i];
      s.norm[i] = norm[i];
    }
    s.pixelFormat = pixelFormat.value;
    s.inputBlob = (inputBlob ?? 'in0').toNativeUtf8();
    return p;
  }

  /// Frees a pointer returned by [toNative] (including the blob string).
  static void freeNative(Pointer<native.HnOptions> p) {
    calloc.free(p.ref.inputBlob);
    calloc.free(p);
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/options_test.dart
```
Expected: PASS（4 个测试全绿；此时 lib/ncnn.dart 仍引用旧 API，analyze 会红——Step 6 临时清掉）

- [ ] **Step 6: 清理旧 API 引用（过渡 stub）**

`lib/ncnn.dart` 临时全文替换为（Task 4 会重写）：

```dart
/// ncnn (Vulkan) inference bindings for Dart/Flutter.
library;

export 'src/bindings.g.dart' show HnGpuDevice, hnMaxGpu, hnNameMax;
export 'src/options.dart';
```

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter analyze && flutter test
```
Expected: `No issues found!` + 测试全绿

- [ ] **Step 7: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(bindings): hand-maintained FFI bindings + NcnnOptions for the generalized C surface"
```

---

### Task 4: NcnnRuntime 迁移 + NcnnNet 重写

**Files:**
- Create: `lib/src/runtime.dart`（自旧 `lib/ncnn.dart` 的 `NcnnRuntime`/`NcnnGpuDevice` 平移 + 改名 + 删死代码）
- Create: `lib/src/net.dart`
- Rewrite: `lib/ncnn.dart`
- Test: `test/net_split_test.dart`

**Interfaces:**
- Consumes: Task 3 的 `NcnnNative`/`HnOptions`/`NcnnOptions`
- Produces: `NcnnRuntime.instance`（`lib: NcnnNative`、`gpuDevices: List<NcnnGpuDevice>`）、`NcnnGpuDevice{index,type,score,vendorId,name,isDiscrete}`、`NcnnNet.load({paramPath, binPath, options}) → Future<NcnnNet>`、`NcnnNet.outputCount: int`、`NcnnNet.outputShape(int) → List<int>?`（4 元素，无 hint 为 null）、`NcnnNet.extract(Uint8List, w, h) → List<NcnnOutput>`、`NcnnNet.extractF32(Float32List, List<int> shape) → List<NcnnOutput>`、`NcnnNet.extractInIsolate(Uint8List, w, h) → Future<List<NcnnOutput>>`、`NcnnNet.predict(rgb, w, h) → Float32List`（= 第一个输出，兼容 huji 调用习惯）、`NcnnNet.dispose()`、`NcnnOutput{shape: List<int>, data: Float32List}`、静态纯函数 `NcnnNet.splitOutputs(Float32List flat, List<List<int>> shapes) → List<Float32List>`

- [ ] **Step 1: 写失败测试（纯 Dart 部分先 TDD）**

`test/net_split_test.dart`：

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/net.dart';

void main() {
  test('splitOutputs slices the flat buffer by shape products', () {
    final flat = Float32List.fromList(
      List<double>.generate(10, (i) => i.toDouble()),
    );
    final parts = NcnnNet.splitOutputs(flat, const [
      [3, 1, 1, 1], // 3 elems
      [2, 3, 1, 1], // 6 elems
    ]);
    expect(parts.length, 2);
    expect(parts[0], Float32List.fromList([0, 1, 2]));
    expect(parts[1],
        Float32List.fromList([3, 4, 5, 6, 7, 8]));
  });

  test('splitOutputs with single output returns one view', () {
    final flat = Float32List.fromList([1.5, -2.5]);
    final parts = NcnnNet.splitOutputs(flat, const [
      [2, 1, 1, 1],
    ]);
    expect(parts.length, 1);
    expect(parts[0].length, 2);
    expect(parts[0][1], -2.5);
  });

  test('splitOutputs throws when shapes exceed the buffer', () {
    final flat = Float32List(2);
    expect(
      () => NcnnNet.splitOutputs(flat, const [
        [4, 1, 1, 1],
      ]),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/net_split_test.dart
```
Expected: FAIL（`net.dart` 不存在）

- [ ] **Step 3: 写 `lib/src/runtime.dart`**

从旧包 `lib/ncnn.dart`（git 历史 `huji-app/packages/huji_ncnn/lib/huji_ncnn.dart`，Task 1 后为 `lib/ncnn.dart` 被 Task 3 Step 6 覆盖——从 git 历史取：`git show <task3-commit>^:lib/ncnn.dart` 或 huji 仓库原文件）复制 `NcnnGpuDevice` 与 `NcnnRuntime` 两个类到 `lib/src/runtime.dart`，应用以下**精确修改**（其余逐行保留，包括全部证据注释）：

1. 文件头：
```dart
/// ncnn runtime — resolves the native library once per process and
/// enumerates Vulkan devices.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart' as native;
import 'net.dart' show NcnnNet; // re-exported below (unused-import guard)
export 'net.dart' show NcnnNet, NcnnOutput;
```
（如上 import 造成循环依赖则去掉 `import 'net.dart'` 行，仅保留 export。）
2. `lib` 字段类型 `native.HujiNcnnNative` → `native.NcnnNative`，构造 `native.NcnnNative.fromLibrary(...)`。
3. `_pluginLibraryName`：`'huji_ncnn_plugin.dll'` → `'ncnn_plugin.dll'`（Task 1 的 sed 应已改，验证即可）；`'libhuji_ncnn_plugin.so'` → `'libncnn_plugin.so'`（同上）。
4. `_openLibrary` Windows 分支：`'$dir\\ncnn.dll'` 不变；整个 `_applyIntelIcdWorkaround` 方法和 `_applyIntelIcdWorkaroundGuard` 字段**删除**，两处调用点替换为注释：
```dart
// Intel ICD filtering is native-side and authoritative (see the shim's
// windows_vulkan_allowed / the helper's ICD scan); Dart cannot setenv.
```
5. marker 文件名 `'huji_ncnn_lib_dir.txt'` → `'ncnn_dart_lib_dir.txt'`（sed 应已改，验证）。
6. `gpuDevices` 中 `native.hnMaxGpu`/`hnNameMax` 引用不变（bindings 保留同名常量）。

- [ ] **Step 4: 写 `lib/src/net.dart`（全文）**

```dart
import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart' as native;
import 'options.dart';
import 'runtime.dart';

/// One output blob of an inference run.
class NcnnOutput {
  const NcnnOutput({required this.shape, required this.data});

  /// 4 entries: (w, h, d|1, c) — padded with 1s, ncnn convention.
  final List<int> shape;

  /// Flattened values in ncnn order.
  final Float32List data;
}

/// A loaded ncnn network.
///
/// NOT thread-safe: one extract at a time per instance (ncnn::Net is
/// not reentrant across concurrent extractors on the same net). Use
/// [extractInIsolate] to keep the UI isolate responsive — but never two
/// isolates on the same instance concurrently.
class NcnnNet {
  NcnnNet._(this._handle, this._outputCount, this._shapeHints);

  Pointer<Void>? _handle;
  final int _outputCount;
  final List<List<int>?> _shapeHints;
  int _capHint;

  /// Loads a model. [options] selects Vulkan/device and preprocessing.
  /// Throws [StateError] on any failure — caller decides whether to
  /// retry on CPU (see NcnnInferenceEngine).
  static Future<NcnnNet> load({
    required String paramPath,
    required String binPath,
    NcnnOptions options = const NcnnOptions(),
  }) async {
    final rt = NcnnRuntime.instance;
    final optsPtr = options.toNative();
    final handle = rt.lib.hnCreate(optsPtr);
    NcnnOptions.freeNative(optsPtr);
    if (handle == nullptr) {
      throw StateError('hn_create failed (OOM or bad options struct)');
    }
    final paramPtr = paramPath.toNativeUtf8();
    final binPtr = binPath.toNativeUtf8();
    try {
      final status =
          rt.lib.hnLoad(handle, paramPtr.cast(), binPtr.cast());
      if (status != native.hnOk) {
        rt.lib.hnDestroy(handle);
        throw StateError('hn_load failed with status $status '
            '(-2 param, -3 bin, -8 exception)');
      }
    } finally {
      calloc.free(paramPtr);
      calloc.free(binPtr);
    }

    final count = rt.lib.hnOutputCount(handle);
    if (count <= 0) {
      rt.lib.hnDestroy(handle);
      throw StateError('model has no discoverable output blobs');
    }
    final hints = <List<int>?>[];
    var cap = 0;
    final shapeBuf = calloc<Int32>(4);
    try {
      for (var i = 0; i < count; i++) {
        final dims = rt.lib.hnOutputShape(handle, i, shapeBuf);
        if (dims == 0) {
          hints.add(null);
          continue;
        }
        final shape = List<int>.generate(4, (k) => shapeBuf[k]);
        hints.add(shape);
        cap += shape.fold(1, (a, b) => a * b);
      }
    } finally {
      calloc.free(shapeBuf);
    }
    return NcnnNet._(handle, count, hints..length = count) // ignore: noop
        ._withCap(cap > 0 ? cap : 256);
  }

  NcnnNet _withCap(int cap) {
    _capHint = cap;
    return this;
  }

  int get outputCount => _outputCount;

  /// Warm-up shape hint for output [i] — 4 entries (w, h, d|1, c), or
  /// null when unavailable (shapes may vary with input size).
  List<int>? outputShape(int i) =>
      (i >= 0 && i < _outputCount) ? _shapeHints[i] : null;

  /// Runs inference on a pixel buffer (w*h*channels bytes, layout per
  /// options.pixelFormat). Returns all output blobs in param order.
  List<NcnnOutput> extract(Uint8List pixels, int width, int height) {
    final rt = NcnnRuntime.instance;
    final handle = _handle;
    if (handle == null) {
      throw StateError('NcnnNet disposed or not loaded');
    }
    final pixPtr = calloc<Uint8>(pixels.length);
    pixPtr.asTypedList(pixels.length).setAll(0, pixels);
    try {
      return _run((out, shapes, required) => rt.lib.hnExtract(
            handle,
            pixPtr,
            width,
            height,
            out,
            _capHint,
            shapes,
            _outputCount * 4,
            required,
          ));
    } finally {
      calloc.free(pixPtr);
    }
  }

  /// Same, with a raw float input tensor (caller-preprocessed).
  /// [shape] has 1..4 entries in ncnn order (w, h, d, c).
  List<NcnnOutput> extractF32(Float32List data, List<int> shape) {
    final rt = NcnnRuntime.instance;
    final handle = _handle;
    if (handle == null) {
      throw StateError('NcnnNet disposed or not loaded');
    }
    if (shape.isEmpty || shape.length > 4) {
      throw ArgumentError.value(shape, 'shape', 'must have 1..4 entries');
    }
    final dataPtr = calloc<Float>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final shapePtr = calloc<Int32>(shape.length);
    for (var i = 0; i < shape.length; i++) {
      shapePtr[i] = shape[i];
    }
    try {
      return _run((out, shapes, required) => rt.lib.hnExtractF32(
            handle,
            dataPtr,
            shapePtr,
            shape.length,
            out,
            _capHint,
            shapes,
            _outputCount * 4,
            required,
          ));
    } finally {
      calloc.free(dataPtr);
      calloc.free(shapePtr);
    }
  }

  /// [extract] on a background isolate — keeps the UI isolate free of
  /// the (tens of ms on CPU) synchronous FFI call. Still serialized per
  /// instance: never call concurrently from two isolates.
  Future<List<NcnnOutput>> extractInIsolate(
      Uint8List pixels, int width, int height) {
    return Isolate.run(() => extract(pixels, width, height));
  }

  /// Convenience: first output blob's flat data (classify models).
  Float32List predict(Uint8List pixels, int width, int height) {
    final outputs = extract(pixels, width, height);
    if (outputs.isEmpty) {
      throw StateError('no outputs produced');
    }
    return outputs.first.data;
  }

  /// Shared capacity-retry loop: calls [fn] with an out buffer; on
  /// HN_ERR_CAPACITY retries once with the required size.
  List<NcnnOutput> _run(
      int Function(Pointer<Float>, Pointer<Int32>, Pointer<Int32>) fn) {
    var cap = _capHint;
    while (true) {
      final out = calloc<Float>(cap);
      final shapes = calloc<Int32>(_outputCount * 4);
      final required = calloc<Int32>();
      try {
        final n = fn(out, shapes, required);
        if (n == native.hnErrCapacity) {
          cap = required.value;
          if (cap <= 0) {
            throw StateError('hn_extract reported capacity 0 required');
          }
          continue; // finally frees; retry with the right size
        }
        if (n <= 0) {
          throw StateError('hn_extract failed with status $n');
        }
        _capHint = cap;
        final shapeList = <List<int>>[];
        for (var i = 0; i < _outputCount; i++) {
          shapeList.add(List<int>.generate(
              4, (k) => shapes[i * 4 + k]));
        }
        final flat = Float32List.fromList(out.asTypedList(n));
        final parts = splitOutputs(flat, shapeList);
        return List.generate(_outputCount,
            (i) => NcnnOutput(shape: shapeList[i], data: parts[i]));
      } finally {
        calloc.free(out);
        calloc.free(shapes);
        calloc.free(required);
      }
    }
  }

  /// Slices a flat multi-output buffer by per-output shapes.
  /// Pure function (unit-tested directly).
  static List<Float32List> splitOutputs(
      Float32List flat, List<List<int>> shapes) {
    final parts = <Float32List>[];
    var offset = 0;
    for (final shape in shapes) {
      var elems = 1;
      for (final d in shape) {
        elems *= d;
      }
      if (offset + elems > flat.length) {
        throw ArgumentError(
            'shapes ($shapes) exceed buffer length ${flat.length}');
      }
      parts.add(Float32List.sublistView(flat, offset, offset + elems));
      offset += elems;
    }
    return parts;
  }

  void dispose() {
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      NcnnRuntime.instance.lib.hnDestroy(handle);
    }
  }
}
```

注意：`load()` 里 `hints..length = count` 写法如触发 lint 报警，改为直接 `NcnnNet._(handle, count, hints)` 并在构造函数体内 `_capHint = cap > 0 ? cap : 256;`（删除 `_withCap`）。两处保持一处即可——以 lint 干净为准。

- [ ] **Step 5: 重写 `lib/ncnn.dart`（全文）**

```dart
/// ncnn (Vulkan) inference bindings for Dart/Flutter.
///
/// Loads ncnn models (.param/.bin) and runs image inference on CPU or
/// any Vulkan-capable GPU. See README for the ultralytics YOLO
/// conventions and platform notes.
library;

export 'src/bindings.g.dart'
    show HnGpuDevice, hnMaxGpu, hnNameMax, hnOk, hnErrCapacity;
export 'src/options.dart';
export 'src/runtime.dart';
export 'src/net.dart';
```

- [ ] **Step 6: 运行全部测试 + analyze**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter analyze
flutter test
```
Expected: `No issues found!`，全部 PASS

- [ ] **Step 7: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(net): shape-driven NcnnNet with capacity retry, multi-output split, isolate helper; migrate NcnnRuntime"
```

---

### Task 5: NcnnMetadata 迁移与解析增强

**Files:**
- Create: `lib/src/metadata.dart`（自旧 `lib/ncnn.dart` 的 `NcnnMetadata` 类迁出）
- Test: `test/metadata_test.dart`

**Interfaces:**
- Consumes: 无
- Produces: `NcnnMetadata.tryParseClassNames(String yaml) → List<String>?`（支持引号与含空格类名）

- [ ] **Step 1: 写失败测试**

`test/metadata_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/metadata.dart';

void main() {
  test('parses plain ultralytics metadata.yaml names', () {
    const yaml = 'task: classify\nnames:\n  0: fireball\n  1: pickball\n';
    expect(NcnnMetadata.tryParseClassNames(yaml), ['fireball', 'pickball']);
  });

  test('parses quoted names and names with spaces', () {
    const yaml = 'names:\n  0: "fire ball"\n  1: \'pick ball\'\n  2: plain\n';
    expect(NcnnMetadata.tryParseClassNames(yaml),
        ['fire ball', 'pick ball', 'plain']);
  });

  test('stops at the end of the names block', () {
    const yaml = 'names:\n  0: a\n  1: b\nother_key: 1\n';
    expect(NcnnMetadata.tryParseClassNames(yaml), ['a', 'b']);
  });

  test('returns null when there is no names block', () {
    expect(NcnnMetadata.tryParseClassNames('task: classify\n'), isNull);
  });

  test('returns null for empty names block', () {
    expect(NcnnMetadata.tryParseClassNames('names:\n'), isNull);
  });
}
```

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/metadata_test.dart
```
Expected: FAIL（`metadata.dart` 不存在）

- [ ] **Step 3: 写 `lib/src/metadata.dart`（全文）**

```dart
import 'dart:convert';

/// Parses YOLO class names out of ultralytics ncnn `metadata.yaml`.
///
/// Layout:
/// ```yaml
/// names:
///   0: fireball
///   1: "fire ball"
/// ```
class NcnnMetadata {
  NcnnMetadata._();

  static List<String>? tryParseClassNames(String yaml) {
    final lines = const LineSplitter().convert(yaml);
    var inNames = false;
    final entries = <int, String>{};
    for (final line in lines) {
      if (!inNames) {
        if (line.trim() == 'names:') inNames = true;
        continue;
      }
      final match = RegExp(r'^\s+(\d+):\s*(.*?)\s*$').firstMatch(line);
      if (match == null) break; // names block ended
      var name = match.group(2)!;
      if (name.length >= 2 &&
          ((name.startsWith('"') && name.endsWith('"')) ||
              (name.startsWith("'") && name.endsWith("'")))) {
        name = name.substring(1, name.length - 1);
      }
      if (name.isEmpty) return null;
      entries[int.parse(match.group(1)!)] = name;
    }
    if (entries.isEmpty) return null;
    final indices = entries.keys.toList()..sort();
    return indices.map((i) => entries[i]!).toList();
  }
}
```

- [ ] **Step 4: 运行测试确认通过 + analyze**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/metadata_test.dart && flutter analyze
```
Expected: PASS + `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(metadata): NcnnMetadata with quoted/space class name support"
```

---

### Task 6: YOLO classify / detect 工具

**Files:**
- Create: `lib/src/yolo/classify.dart`
- Create: `lib/src/yolo/detect.dart`
- Test: `test/yolo_classify_test.dart`
- Test: `test/yolo_detect_test.dart`

**Interfaces:**
- Consumes: 无（纯 Dart，吃 `NcnnOutput.data/shape`）
- Produces: `int argmax(Float32List)`、`List<(int, double)> topK(Float32List, int k, {int? limit})`、`Float32List softmax(Float32List, {int? limit})`；`NcnnDetection{x, y, w, h, classIndex, score}`（中心点 + 宽高，输入像素单位）、`List<NcnnDetection> decodeYoloDetect(Float32List out, List<int> shape, {required int numClasses, double confThreshold = 0.25, double iouThreshold = 0.45})`

- [ ] **Step 1: 写 classify 失败测试**

`test/yolo_classify_test.dart`：

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/yolo/classify.dart';

void main() {
  test('argmax finds the highest score', () {
    expect(argmax(Float32List.fromList([0.1, 0.9, 0.3])), 1);
    expect(argmax(Float32List.fromList([0.5])), 0);
  });

  test('topK returns descending pairs', () {
    final top = topK(Float32List.fromList([0.1, 0.9, 0.3, 0.7]), 2);
    expect(top.length, 2);
    expect(top[0], (1, 0.9));
    expect(top[1], (3, 0.7));
  });

  test('topK respects limit (metadata class count vs logits)', () {
    final top = topK(Float32List.fromList([0.1, 0.9, 0.3]), 5, limit: 2);
    expect(top.length, 2);
    expect(top[0].$1, 1);
  });

  test('softmax sums to 1 and is stable for large logits', () {
    final p = softmax(Float32List.fromList([1000.0, 1000.0, 0.0]));
    expect(p.length, 3);
    expect(p[0], closeTo(0.5, 1e-6));
    expect(p.reduce((a, b) => a + b), closeTo(1.0, 1e-6));
  });
}
```

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/yolo_classify_test.dart
```
Expected: FAIL

- [ ] **Step 3: 写 `lib/src/yolo/classify.dart`（全文）**

```dart
import 'dart:typed_data';

/// Pure-Dart post-processing for classify outputs.

/// Index of the highest-scoring element.
int argmax(Float32List scores) {
  var best = 0;
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[best]) best = i;
  }
  return best;
}

/// Top-k (index, value) pairs, descending by value.
List<(int, double)> topK(Float32List scores, int k, {int? limit}) {
  final n = (limit ?? scores.length).clamp(0, scores.length);
  final indexed = List.generate(n, (i) => (i, scores[i].toDouble()));
  indexed.sort((a, b) => b.$2.compareTo(a.$2));
  return indexed.take(k.clamp(0, n)).toList();
}

/// Softmax over the first `limit` entries (max-subtracted for
/// numerical stability).
Float32List softmax(Float32List logits, {int? limit}) {
  final n = (limit ?? logits.length).clamp(0, logits.length);
  if (n == 0) return Float32List(0);
  var maxVal = logits[0];
  for (var i = 1; i < n; i++) {
    if (logits[i] > maxVal) maxVal = logits[i];
  }
  final out = Float32List(n);
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    final e = _exp(logits[i] - maxVal);
    out[i] = e;
    sum += e;
  }
  for (var i = 0; i < n; i++) {
    out[i] /= sum;
  }
  return out;
}

double _exp(double x) {
  // dart:math exp — kept behind a private alias for test mocking clarity.
  // ignore: avoid_redundant_argument_values
  return _mathExp(x);
}

double _mathExp(double x) => x.isNaN ? double.nan : MathShim.exp(x);
```

注意：上面 `_exp` 的间接层是过度设计——直接 `import 'dart:math' as math;` 然后单行 `final e = math.exp(logits[i] - maxVal);`，删掉 `_exp`/`_mathExp`/`MathShim`。以 dart:math 直用为准（lint 干净）。

- [ ] **Step 4: 运行 classify 测试确认通过**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/yolo_classify_test.dart
```
Expected: PASS

- [ ] **Step 5: 写 detect 失败测试**

`test/yolo_detect_test.dart`（合成 2 类、4 锚框，含 NMS 抑制与低置信过滤用例）：

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/yolo/detect.dart';

void main() {
  // 2 类 → 行宽 4+2 = 6。布局 [6, 4]（列主序：out[c*4 + i]）。
  // anchor0: box(50,50,20,20) cls0=0.9   — 保留
  // anchor1: box(52,52,20,20) cls0=0.8   — 与 anchor0 IoU≈0.64，被 NMS
  // anchor2: box(200,200,30,30) cls1=0.7 — 保留（另一类）
  // anchor3: box(300,300,10,10) cls1=0.1 — 低于 0.25，过滤
  final Float32List out = _colMajor([
    50, 52, 200, 300,   // cx
    50, 52, 200, 300,   // cy
    20, 20, 30, 10,     // w
    20, 20, 30, 10,     // h
    0.9, 0.8, 0.05, 0.05, // cls0
    0.05, 0.05, 0.7, 0.1, // cls1
  ], 4);
  const shape = [6, 4, 1, 1];

  test('decodes boxes, filters low conf, NMS per class', () {
    final dets = decodeYoloDetect(out, shape, numClasses: 2);
    expect(dets.length, 2);
    expect(dets[0].classIndex, 0);
    expect(dets[0].score, closeTo(0.9, 1e-6));
    expect(dets[0].x, 50);
    expect(dets[0].w, 20);
    expect(dets[1].classIndex, 1);
    expect(dets[1].x, 200);
  });

  test('row-major [n, 6] layout is auto-detected', () {
    final rowMajor = Float32List.fromList([
      50, 50, 20, 20, 0.9, 0.05, //
      200, 200, 30, 30, 0.05, 0.7,
    ]);
    final dets = decodeYoloDetect(rowMajor, const [2, 6, 1, 1], numClasses: 2);
    expect(dets.length, 2);
    expect(dets[1].classIndex, 1);
  });

  test('iou threshold 0 keeps overlapping same-class boxes', () {
    final dets =
        decodeYoloDetect(out, shape, numClasses: 2, iouThreshold: 1.0);
    expect(dets.length, 3); // anchor0 + anchor1 + anchor2
  });

  test('throws on shape that matches neither layout', () {
    expect(
      () => decodeYoloDetect(Float32List(6), const [3, 2, 1, 1], numClasses: 2),
      throwsArgumentError,
    );
  });
}

Float32List _colMajor(List<double> rows, int n) {
  final out = Float32List(rows.length);
  final ch = rows.length ~/ n;
  for (var c = 0; c < ch; c++) {
    for (var i = 0; i < n; i++) {
      out[c * n + i] = rows[c * n + i];
    }
  }
  return out;
}
```

- [ ] **Step 6: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/yolo_detect_test.dart
```
Expected: FAIL

- [ ] **Step 7: 写 `lib/src/yolo/detect.dart`（全文）**

```dart
import 'dart:math' as math;
import 'dart:typed_data';

/// One decoded detection. (x, y) is the box CENTER in input-pixel
/// units; (w, h) the box size.
class NcnnDetection {
  const NcnnDetection({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.classIndex,
    required this.score,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final int classIndex;
  final double score;
}

/// Decodes an ultralytics ncnn detect output and applies per-class NMS.
///
/// The exported graph already contains DFL + box decode — the output is
/// per-anchor [cx, cy, w, h, cls0..clsN] with cls probs in [0, 1].
/// Layouts: [4+numClasses, n] (column-major, common) or
/// [n, 4+numClasses] (row-major) — auto-detected from [shape]
/// (ncnn convention (w, h, d, c): shape[0]==4+numClasses means
/// column-major).
///
/// Coordinates are in the model INPUT resolution; scale by
/// (imageWidth / inputWidth) for original-image boxes.
List<NcnnDetection> decodeYoloDetect(
  Float32List out,
  List<int> shape, {
  required int numClasses,
  double confThreshold = 0.25,
  double iouThreshold = 0.45,
}) {
  final stride = 4 + numClasses;
  var n = 0;
  var colMajor = false;
  if (shape[0] == stride && shape.length >= 2) {
    n = shape[1];
    colMajor = true;
  } else if (shape.length >= 2 && shape[1] == stride) {
    n = shape[0];
    colMajor = false;
  } else {
    throw ArgumentError(
        'shape $shape matches neither [$stride, n] nor [n, $stride] '
        'for numClasses=$numClasses');
  }
  if (out.length < n * stride) {
    throw ArgumentError('buffer ${out.length} < $n*$stride');
  }

  final candidates = <NcnnDetection>[];
  for (var i = 0; i < n; i++) {
    var bestCls = 0;
    var bestScore = -1.0;
    for (var c = 0; c < numClasses; c++) {
      final s = _at(out, i, 4 + c, colMajor, stride, n);
      if (s > bestScore) {
        bestScore = s;
        bestCls = c;
      }
    }
    if (bestScore < confThreshold) continue;
    candidates.add(NcnnDetection(
      x: _at(out, i, 0, colMajor, stride, n),
      y: _at(out, i, 1, colMajor, stride, n),
      w: _at(out, i, 2, colMajor, stride, n),
      h: _at(out, i, 3, colMajor, stride, n),
      classIndex: bestCls,
      score: bestScore,
    ));
  }
  return _nmsPerClass(candidates, iouThreshold);
}

double _at(Float32List out, int i, int ch, bool colMajor, int stride, int n) {
  return colMajor ? out[ch * n + i] : out[i * stride + ch];
}

List<NcnnDetection> _nmsPerClass(
    List<NcnnDetection> dets, double iouThreshold) {
  final byClass = <int, List<NcnnDetection>>{};
  for (final d in dets) {
    byClass.putIfAbsent(d.classIndex, () => []).add(d);
  }
  final kept = <NcnnDetection>[];
  for (final list in byClass.values) {
    list.sort((a, b) => b.score.compareTo(a.score));
    final suppressed = List<bool>.filled(list.length, false);
    for (var i = 0; i < list.length; i++) {
      if (suppressed[i]) continue;
      kept.add(list[i]);
      for (var j = i + 1; j < list.length; j++) {
        if (!suppressed[j] &&
            _iou(list[i], list[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
  }
  kept.sort((a, b) => b.score.compareTo(a.score));
  return kept;
}

double _iou(NcnnDetection a, NcnnDetection b) {
  final x1 = math.max(a.x - a.w / 2, b.x - b.w / 2);
  final y1 = math.max(a.y - a.h / 2, b.y - b.h / 2);
  final x2 = math.min(a.x + a.w / 2, b.x + b.w / 2);
  final y2 = math.min(a.y + a.h / 2, b.y + b.h / 2);
  final inter = math.max(0.0, x2 - x1) * math.max(0.0, y2 - y1);
  if (inter == 0) return 0;
  final union_ = a.w * a.h + b.w * b.h - inter;
  return union_ <= 0 ? 0 : inter / union_;
}
```

- [ ] **Step 8: 运行全部测试确认通过**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/yolo_detect_test.dart test/yolo_classify_test.dart
```
Expected: PASS

- [ ] **Step 9: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(yolo): classify (argmax/topK/softmax) and detect (grid decode + per-class NMS) utilities"
```

---

### Task 7: helper 协议 v2（C++ + Dart）

**Files:**
- Rewrite: `src/ncnn_helper_main.cpp`（全文）
- Create: `lib/src/helper_process.dart`
- Test: `test/helper_frames_test.dart`

**Interfaces:**
- Consumes: Task 2 C API、Task 3 `NcnnOptions`
- Produces: `NcnnHelperFrames`（纯函数帧编解码，见测试）、`NcnnHelperProcess.start() → Future<NcnnHelperProcess>`、`NcnnHelperProcess.gpuDevices() → Future<List<NcnnGpuDevice>>`、`NcnnHelperProcess.load({paramPath, binPath, options}) → Future<List<List<int>>>`（返回各输出 shape hint）、`NcnnHelperProcess.predict(rgb, w, h) → Future<Float32List>`（拼接的全部输出）、`NcnnHelperProcess.extractF32(data, shape) → Future<Float32List>`、`NcnnHelperProcess.dispose()`

helper 协议 v2（全部小端）：

```
load:    u32 cmd=1 | u32 paramLen | param | u32 binLen | bin | u32 optsLen | opts
         opts: i32 useVulkan, i32 deviceIndex, i32 pixelFormat,
               u32 blobLen | blob, f32 mean[3], f32 norm[3]
         -> i32 status | u32 outCount | outCount × (u32 dims, u32 s0..s3)
predict: u32 cmd=2 | u32 w | u32 h | u32 frameLen | RGB bytes
         -> i32 status | u32 total | total × f32
extractF32: u32 cmd=4 | u32 dims | dims × u32 shape | u32 dataLen | f32 data
         -> i32 status | u32 total | total × f32
gpu:     u32 cmd=3 （不变）
         -> u32 status | u32 count | count × (u32 idx, u32 type, u32 score,
            u32 vendor, u32 nameLen, name bytes)
quit:    u32 cmd=0 （不变）
```

- [ ] **Step 1: 写帧编解码失败测试**

`test/helper_frames_test.dart`：

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/helper_process.dart';
import 'package:ncnn/src/options.dart';

void main() {
  test('loadRequest encodes paths + options frame', () {
    final bytes = NcnnHelperFrames.loadRequest(
      paramPath: '/a.param',
      binPath: '/b.bin',
      options: const NcnnOptions.yolo(useVulkan: true, deviceIndex: 1),
    );
    final d = ByteData.sublistView(bytes);
    var off = 0;
    expect(d.getUint32(off, Endian.little), 1); off += 4; // cmd
    final paramLen = d.getUint32(off, Endian.little); off += 4;
    expect(bytes.sublist(off, off + paramLen), utf8('/a.param'));
    off += paramLen;
    final binLen = d.getUint32(off, Endian.little); off += 4;
    expect(bytes.sublist(off, off + binLen), utf8('/b.bin'));
    off += binLen;
    expect(d.getUint32(off, Endian.little), 32); // optsLen = 4+4+4+4+3+12+12
    off += 4;
    expect(d.getInt32(off, Endian.little), 1); // useVulkan
    expect(d.getUint32(off + 20, Endian.little), 3); // 'in0' length
    expect(bytes.sublist(off + 24, off + 27), utf8('in0'));
  });

  test('parseLoadResponse reads status + shape rows', () {
    final b = BytesBuilder();
    void u32(int v) => b.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
    u32(0); // status
    u32(2); // outCount
    for (final s in [
      [2, 84, 8400, 1, 1],
      [1, 4, 1, 1, 1],
    ]) {
      u32(s[0]); u32(s[1]); u32(s[2]); u32(s[3]); u32(s[4]);
    }
    final (status, shapes) = NcnnHelperFrames.parseLoadResponse(b.takeBytes());
    expect(status, 0);
    expect(shapes, [
      [84, 8400, 1, 1],
      [4, 1, 1, 1],
    ]);
  });

  test('parseDataResponse reads status + floats', () {
    final b = BytesBuilder();
    b.add(Uint8List(4)..buffer.asByteData().setUint32(0, 0, Endian.little));
    b.add(Uint8List(4)..buffer.asByteData().setUint32(0, 2, Endian.little));
    final f = ByteData(8)
      ..setFloat32(0, 1.5, Endian.little)
      ..setFloat32(4, -2.5, Endian.little);
    b.add(f.buffer.asUint8List());
    final (status, data) = NcnnHelperFrames.parseDataResponse(b.takeBytes());
    expect(status, 0);
    expect(data, Float32List.fromList([1.5, -2.5]));
  });
}
```

（测试里 `utf8(...)` 辅助与 `u32` 闭包如 lint 报警，按 flutter_lints 微调；语义不变。）

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/helper_frames_test.dart
```
Expected: FAIL

- [ ] **Step 3: 写 `lib/src/helper_process.dart`（全文）**

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'options.dart';
import 'runtime.dart' show NcnnGpuDevice;

/// Pure protocol helpers — unit-testable without a process.
class NcnnHelperFrames {
  NcnnHelperFrames._();

  static void _u32(BytesBuilder b, int v) {
    b.add(Uint8List(4)
      ..buffer.asByteData().setUint32(0, v, Endian.little));
  }

  static void _i32(BytesBuilder b, int v) {
    b.add(Uint8List(4)
      ..buffer.asByteData().setInt32(0, v, Endian.little));
  }

  static void _f32(BytesBuilder b, double v) {
    b.add(Uint8List(4)
      ..buffer.asByteData().setFloat32(0, v, Endian.little));
  }

  static void _bytes(BytesBuilder b, List<int> v) => b.add(v);

  static void _str(BytesBuilder b, String s) =>
      _bytes(b, s.codeUnits); // paths are ASCII-safe on all supported OSes

  /// cmd=1: load with full options.
  static Uint8List loadRequest({
    required String paramPath,
    required String binPath,
    required NcnnOptions options,
  }) {
    final b = BytesBuilder();
    _u32(b, 1);
    final param = paramPath.codeUnits;
    final bin = binPath.codeUnits;
    _u32(b, param.length);
    _bytes(b, param);
    _u32(b, bin.length);
    _bytes(b, bin);
    final blob = (options.inputBlob ?? 'in0').codeUnits;
    const optsLen = 4 + 4 + 4 + 4 + 3 + 12 + 12; // 47
    _u32(b, optsLen);
    _i32(b, options.useVulkan ? 1 : 0);
    _i32(b, options.deviceIndex);
    _i32(b, options.pixelFormat.value);
    _u32(b, blob.length);
    _bytes(b, blob);
    for (var i = 0; i < 3; i++) {
      _f32(b, options.mean[i]);
    }
    for (var i = 0; i < 3; i++) {
      _f32(b, options.norm[i]);
    }
    return b.takeBytes();
  }

  /// cmd=1 response → (status, per-output shape hints).
  static (int, List<List<int>>) parseLoadResponse(Uint8List bytes) {
    final d = ByteData.sublistView(bytes);
    var off = 0;
    final status = d.getInt32(off, Endian.little);
    off += 4;
    final count = d.getUint32(off, Endian.little);
    off += 4;
    final shapes = <List<int>>[];
    for (var i = 0; i < count; i++) {
      off += 4; // dims (redundant with shape entries)
      shapes.add([
        d.getUint32(off, Endian.little),
        d.getUint32(off + 4, Endian.little),
        d.getUint32(off + 8, Endian.little),
        d.getUint32(off + 12, Endian.little),
      ]);
      off += 16;
    }
    return (status, shapes);
  }

  /// cmd=2 / cmd=4 request bodies.
  static Uint8List predictRequest(Uint8List rgb, int w, int h) {
    final b = BytesBuilder();
    _u32(b, 2);
    _u32(b, w);
    _u32(b, h);
    _u32(b, rgb.length);
    _bytes(b, rgb);
    return b.takeBytes();
  }

  static Uint8List extractF32Request(Float32List data, List<int> shape) {
    final b = BytesBuilder();
    _u32(b, 4);
    _u32(b, shape.length);
    for (final d in shape) {
      _u32(b, d);
    }
    _u32(b, data.length);
    final raw = data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes);
    _bytes(b, raw);
    return b.takeBytes();
  }

  /// cmd=2/cmd=4 response → (status, concatenated outputs).
  static (int, Float32List) parseDataResponse(Uint8List bytes) {
    final d = ByteData.sublistView(bytes);
    final status = d.getInt32(0, Endian.little);
    final total = d.getUint32(4, Endian.little);
    return (
      status,
      Float32List.view(bytes.buffer, bytes.offsetInBytes + 8, total),
    );
  }
}

/// Runs ncnn inference in the standalone `ncnn_helper` child process.
///
/// Windows: ncnn's Vulkan device init crashes inside Flutter engine
/// processes (NVIDIA nvoglv64 access violation caused by the engine's
/// GL/D3D rendering stack — reproduced and dump-verified 2026-09). The
/// same shim runs flawlessly in a plain process, so on Windows GPU
/// inference goes through this helper; requests are framed
/// little-endian over stdin/stdout (see ncnn_helper_main.cpp).
class NcnnHelperProcess {
  NcnnHelperProcess._(this._process);

  final Process _process;
  final List<Uint8List> _chunks = <Uint8List>[];
  int _chunkOffset = 0;
  Completer<void>? _drained;
  bool _disposed = false;

  /// Shapes of the loaded model's outputs (filled by [load]).
  List<List<int>> outputShapes = const [];

  /// Spawn the helper exe. Lookup order: the directory of the running
  /// executable (bundled apps), then the pinned lib dir (test VM /
  /// NCNN_DART_LIB_DIR — the plugin dll and helper sit together).
  static Future<NcnnHelperProcess> start() async {
    if (!Platform.isWindows) {
      throw StateError('ncnn_helper is Windows-only');
    }
    final candidates = <String>[
      File(Platform.resolvedExecutable).parent.path,
      Platform.environment['NCNN_DART_LIB_DIR'] ?? '',
    ];
    for (final dir in candidates) {
      if (dir.isEmpty) continue;
      final p = '$dir${Platform.pathSeparator}ncnn_helper.exe';
      if (File(p).existsSync()) return _spawn(p);
    }
    throw StateError('ncnn_helper.exe not found (looked in '
        '${candidates.where((d) => d.isNotEmpty).join(', ')})');
  }

  static Future<NcnnHelperProcess> _spawn(String path) async {
    final process = await Process.start(path, const [],
        environment: Platform.environment);
    final helper = NcnnHelperProcess._(process);
    // Single long-lived subscription (a stream allows one listener).
    process.stdout.listen(
      (chunk) {
        helper._chunks.add(chunk as Uint8List);
        helper._drained?.complete();
      },
      onDone: () => helper._drained
          ?.completeError(StateError('helper closed the pipe')),
      onError: (Object e) => helper._drained?.completeError(e),
    );
    return helper;
  }

  Future<Uint8List> _readExact(int len) async {
    final result = Uint8List(len);
    var copied = 0;
    while (copied < len) {
      while (_chunks.isEmpty) {
        final done = Completer<void>();
        _drained = done;
        await done.future;
        _drained = null;
      }
      final chunk = _chunks.first;
      final take = (chunk.length - _chunkOffset).clamp(0, len - copied);
      result.setRange(copied, copied + take, chunk, _chunkOffset);
      copied += take;
      _chunkOffset += take;
      if (_chunkOffset >= chunk.length) {
        _chunks.removeAt(0);
        _chunkOffset = 0;
      }
    }
    return result;
  }

  /// Enumerate Vulkan devices (safe in the child process).
  Future<List<NcnnGpuDevice>> gpuDevices() async {
    final b = BytesBuilder();
    NcnnHelperFrames._u32(b, 3);
    _process.stdin.add(b.takeBytes());
    final head = await _readExact(8);
    final d = ByteData.sublistView(head);
    final status = d.getUint32(0, Endian.little);
    final count = d.getUint32(4, Endian.little);
    if (status != 0 || count == 0) return const [];
    final result = <NcnnGpuDevice>[];
    for (var i = 0; i < count; i++) {
      final meta = await _readExact(20);
      final md = ByteData.sublistView(meta);
      final nameLen = md.getUint32(16, Endian.little);
      final nameBytes = await _readExact(nameLen);
      result.add(NcnnGpuDevice(
        index: md.getUint32(0, Endian.little),
        type: md.getUint32(4, Endian.little),
        score: md.getUint32(8, Endian.little),
        vendorId: md.getUint32(12, Endian.little),
        name: String.fromCharCodes(nameBytes),
      ));
    }
    return result;
  }

  /// Loads a model; returns per-output shape hints.
  Future<List<List<int>>> load({
    required String paramPath,
    required String binPath,
    NcnnOptions options = const NcnnOptions(),
  }) async {
    _process.stdin.add(NcnnHelperFrames.loadRequest(
      paramPath: paramPath,
      binPath: binPath,
      options: options,
    ));
    final (status, shapes) =
        NcnnHelperFrames.parseLoadResponse(await _readExact(8 + shapesLength(_peekCount)));
```

（此处省略——完整实现见下）注意：上面 `load` 的响应长度依赖 outCount，需要先读 8 字节头再按 count 读 `count × 20` 字节。完整 `load`/`predict`/`extractF32`/`dispose` 实现如下，直接使用：

```dart
  Future<List<List<int>>> load({
    required String paramPath,
    required String binPath,
    NcnnOptions options = const NcnnOptions(),
  }) async {
    _process.stdin.add(NcnnHelperFrames.loadRequest(
      paramPath: paramPath,
      binPath: binPath,
      options: options,
    ));
    final head = await _readExact(8);
    final hd = ByteData.sublistView(head);
    final status = hd.getInt32(0, Endian.little);
    final count = hd.getUint32(4, Endian.little);
    final body = count > 0 ? await _readExact(count * 20) : Uint8List(0);
    if (status != 0) {
      throw StateError('helper load failed with status $status');
    }
    final (s2, shapes) = NcnnHelperFrames.parseLoadResponse(
        Uint8List.fromList(head + body));
    outputShapes = shapes;
    return s2 == 0 ? shapes : const [];
  }

  /// Runs one prediction on a pixel buffer; returns ALL outputs
  /// concatenated (split via [outputShapes] / NcnnNet.splitOutputs).
  Future<Float32List> predict(Uint8List rgb, int width, int height) async {
    _process.stdin
        .add(NcnnHelperFrames.predictRequest(rgb, width, height));
    final head = await _readExact(8);
    final hd = ByteData.sublistView(head);
    final status = hd.getInt32(0, Endian.little);
    final total = hd.getUint32(4, Endian.little);
    if (status != 0) {
      throw StateError('helper predict failed with status $status');
    }
    final body = await _readExact(total * 4);
    final (s2, data) = NcnnHelperFrames.parseDataResponse(
        Uint8List.fromList(head + body));
    return data;
  }

  /// Raw float tensor input (caller-preprocessed).
  Future<Float32List> extractF32(
      Float32List data, List<int> shape) async {
    _process.stdin.add(NcnnHelperFrames.extractF32Request(data, shape));
    final head = await _readExact(8);
    final hd = ByteData.sublistView(head);
    final status = hd.getInt32(0, Endian.little);
    final total = hd.getUint32(4, Endian.little);
    if (status != 0) {
      throw StateError('helper extractF32 failed with status $status');
    }
    final body = await _readExact(total * 4);
    final (s2, out) = NcnnHelperFrames.parseDataResponse(
        Uint8List.fromList(head + body));
    return out;
  }

  /// Kill the helper. The helper's ncnn atexit cleanup crashes on exit
  /// (known NVIDIA driver issue), so terminate hard — the OS reclaims
  /// everything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _process.stdin.close();
    _process.kill();
  }
}
```

（文件中上面第一段 `load` 草稿删除，只保留第二段完整实现；`NcnnHelperFrames._u32` 的私有下划线在跨类调用处改为 `static void u32(...)` 公开或把 gpu 命令构造也放进 `NcnnHelperFrames.gpuRequest()`——以 lint `library_private_types_in_public_api`/unused 干净为准，推荐后者。）

- [ ] **Step 4: 重写 `src/ncnn_helper_main.cpp`（全文）**

```cpp
// Standalone ncnn inference helper for Windows.
//
// Rationale: ncnn's Vulkan device init crashes inside Flutter engine
// processes (NVIDIA nvoglv64 access violation — the engine's GL/D3D
// rendering stack conflicts with the driver's Vulkan path). In a plain
// process the same shim runs flawlessly on GPU. This helper is spawned
// by the app as a child process and speaks a binary protocol over
// stdin/stdout (all integers little-endian, full-buffer reads):
//
//   load:  u32 cmd=1 | u32 paramLen | param | u32 binLen | bin |
//          u32 optsLen(=47) | opts
//          opts: i32 useVulkan, i32 deviceIndex, i32 pixelFormat,
//                u32 blobLen | blob, f32 mean[3], f32 norm[3]
//          -> i32 status | u32 outCount | outCount × (u32 dims, u32 s0..s3)
//   predict: u32 cmd=2 | u32 w | u32 h | u32 frameLen | pixels
//          -> i32 status | u32 total | total × f32 (all outputs concat)
//   extractF32: u32 cmd=4 | u32 dims | dims × u32 shape |
//          u32 dataLen | f32 data
//          -> i32 status | u32 total | total × f32
//   gpu:   u32 cmd=3
//          -> u32 status | u32 count | count × (u32 idx, u32 type,
//             u32 score, u32 vendor, u32 nameLen, name bytes)
//   quit:  u32 cmd=0 -> exits
#include "ncnn_api.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <fcntl.h>
#include <windows.h>
#endif

static int read_exact(uint8_t* buf, size_t len) {
    size_t got = 0;
    while (got < len) {
        size_t n = fread(buf + got, 1, len - got, stdin);
        if (n == 0) return -1;
        got += n;
    }
    return 0;
}

static int write_exact(const uint8_t* buf, size_t len) {
    size_t put = 0;
    while (put < len) {
        size_t n = fwrite(buf + put, 1, len - put, stdout);
        if (n == 0) return -1;
        put += n;
    }
    return 0;
}

static void put_u32(uint32_t v) {
    uint8_t b[4] = {(uint8_t)(v & 0xFF), (uint8_t)((v >> 8) & 0xFF),
                    (uint8_t)((v >> 16) & 0xFF), (uint8_t)((v >> 24) & 0xFF)};
    write_exact(b, 4);
}

static void put_i32(int32_t v) { put_u32((uint32_t)v); }

static void put_f32(float v) {
    uint32_t bits;
    memcpy(&bits, &v, 4);
    put_u32(bits);
}

static uint32_t get_u32(const uint8_t* b) {
    return (uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) |
           ((uint32_t)b[3] << 24);
}

static int read_str(char** out) {
    uint8_t lenb[4];
    if (read_exact(lenb, 4) != 0) return -1;
    const uint32_t len = get_u32(lenb);
    char* s = (char*)malloc(len + 1);
    if (s == NULL) return -1;
    if (read_exact((uint8_t*)s, len) != 0) { free(s); return -1; }
    s[len] = '\0';
    *out = s;
    return 0;
}

int main(void) {
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
    // This is a standalone process (NOT the Flutter app) — ncnn's
    // Vulkan stack is safe here. The shim's in-app guard must not apply.
    _putenv_s("NCNN_DART_ENABLE_VK", "1");
    // Multi-vendor device enumeration crashes on some driver combos
    // (Intel + NVIDIA dual-GPU laptops, observed 2026-09). If the user
    // hasn't pinned an ICD list, restrict to the NVIDIA ICD only —
    // inference wants the discrete GPU anyway.
    if (getenv("VK_ICD_FILENAMES") == NULL &&
        getenv("NCNN_DART_ALL_ICDS") == NULL) {
        char keep[512] = "";
        WIN32_FIND_DATAA fdInf;
        HANDLE hInf = FindFirstFileA(
            "C:\\Windows\\System32\\DriverStore\\FileRepository\\*", &fdInf);
        if (hInf != INVALID_HANDLE_VALUE) {
            do {
                if (!(fdInf.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) continue;
                char path[512];
                snprintf(path, sizeof(path),
                         "C:\\Windows\\System32\\DriverStore\\FileRepository\\%s\\nv-vk64.json",
                         fdInf.cFileName);
                if (GetFileAttributesA(path) != INVALID_FILE_ATTRIBUTES) {
                    snprintf(keep, sizeof(keep), "%s", path);
                    break;
                }
            } while (FindNextFileA(hInf, &fdInf));
            FindClose(hInf);
        }
        if (keep[0] != '\0') _putenv_s("VK_ICD_FILENAMES", keep);
    }
#endif

    hn_net_t net = NULL;
    float* out_buf = NULL;
    size_t out_cap = 0;
    int32_t* shapes = NULL;      // 4 per output
    int out_count = 0;
    uint8_t hdr[4];

    for (;;) {
        if (read_exact(hdr, 4) != 0) break;
        const uint32_t cmd = get_u32(hdr);

        if (cmd == 0) break; // quit

        if (cmd == 1) { // load
            char *param = NULL, *bin = NULL, *blob = NULL;
            int32_t use_vulkan = 0, device_index = -1, pixel_format = 0;
            float mean[3] = {0, 0, 0}, norm[3] = {1, 1, 1};
            int bad = 0;
            bad |= read_str(&param);
            bad |= read_str(&bin);
            uint8_t optsLenb[4];
            if (read_exact(optsLenb, 4) != 0) bad = -1;
            if (bad == 0 && get_u32(optsLenb) != 47) bad = -1;
            if (bad == 0) {
                uint8_t o[39];
                if (read_exact(o, 39) != 0) bad = -1;
                else {
                    use_vulkan = (int32_t)get_u32(o);
                    device_index = (int32_t)get_u32(o + 4);
                    pixel_format = (int32_t)get_u32(o + 8);
                }
            }
            if (bad == 0) bad = read_str(&blob);
            if (bad == 0) {
                uint8_t f[24];
                if (read_exact(f, 24) != 0) bad = -1;
                else {
                    for (int i = 0; i < 3; i++) {
                        memcpy(&mean[i], f + i * 4, 4);
                        memcpy(&norm[i], f + 12 + i * 4, 4);
                    }
                }
            }
            if (bad != 0) {
                put_i32(HN_ERR_INVALID);
                fflush(stdout);
                free(param); free(bin); free(blob);
                continue;
            }

            hn_options_t opts;
            memset(&opts, 0, sizeof(opts));
            opts.struct_size = (uint32_t)sizeof(hn_options_t);
            opts.use_vulkan = use_vulkan;
            opts.device_index = device_index;
            opts.pixel_format = pixel_format;
            memcpy(opts.mean, mean, sizeof(mean));
            memcpy(opts.norm, norm, sizeof(norm));
            opts.input_blob = blob;

            if (net != NULL) hn_destroy(net);
            net = hn_create(&opts);
            free(blob); // hn_create strdups
            const int rc = net != NULL ? hn_load(net, param, bin) : HN_ERR_INVALID;
            free(param);
            free(bin);

            out_count = net != NULL ? hn_output_count(net) : 0;
            put_i32(rc);
            put_u32((uint32_t)out_count);
            if (rc == HN_OK && out_count > 0) {
                if (shapes == NULL) shapes = (int32_t*)malloc(out_count * 4 * sizeof(int32_t));
                size_t need = 0;
                for (int i = 0; i < out_count; i++) {
                    int32_t s[4];
                    hn_output_shape(net, i, s); // 0s when no hint
                    if (shapes != NULL) memcpy(shapes + i * 4, s, sizeof(s));
                    size_t elems = 1;
                    for (int k = 0; k < 4; k++) elems *= s[k] > 0 ? (size_t)s[k] : 1;
                    need += elems;
                    put_u32(4); put_u32((uint32_t)s[0]); put_u32((uint32_t)s[1]);
                    put_u32((uint32_t)s[2]); put_u32((uint32_t)s[3]);
                }
                if (need > out_cap) {
                    free(out_buf);
                    out_buf = (float*)malloc(need * sizeof(float));
                    out_cap = out_buf != NULL ? need : 0;
                }
            }
            fflush(stdout);
            continue;
        }

        if (cmd == 2) { // predict (pixels)
            uint8_t meta[12];
            if (read_exact(meta, 12) != 0) break;
            const uint32_t w = get_u32(meta);
            const uint32_t h = get_u32(meta + 4);
            const uint32_t frameLen = get_u32(meta + 8);
            uint8_t* frame = (uint8_t*)malloc(frameLen);
            if (frame == NULL || read_exact(frame, frameLen) != 0) {
                put_i32(HN_ERR_INVALID);
                break;
            }
            int32_t required = 0;
            int n = HN_ERR_INVALID;
            if (net != NULL) {
                for (int attempt = 0; attempt < 2; attempt++) {
                    n = hn_extract(net, frame, (int)w, (int)h, out_buf,
                                   (int)out_cap, shapes, out_count * 4, &required);
                    if (n != HN_ERR_CAPACITY) break;
                    free(out_buf);
                    out_cap = (size_t)required;
                    out_buf = (float*)malloc(out_cap * sizeof(float));
                    if (out_buf == NULL) { out_cap = 0; break; }
                }
            }
            free(frame);
            if (n < 0) {
                put_i32(n);
            } else {
                put_i32(0);
                put_u32((uint32_t)n);
                write_exact((const uint8_t*)out_buf, (size_t)n * sizeof(float));
            }
            fflush(stdout);
            continue;
        }

        if (cmd == 4) { // extractF32
            uint8_t dimsb[4];
            if (read_exact(dimsb, 4) != 0) break;
            const uint32_t dims = get_u32(dimsb);
            if (dims < 1 || dims > 4) { put_i32(HN_ERR_INVALID); fflush(stdout); continue; }
            int32_t shape[4] = {1, 1, 1, 1};
            uint8_t sb[16];
            if (read_exact(sb, dims * 4) != 0) break;
            for (uint32_t i = 0; i < dims; i++) shape[i] = (int32_t)get_u32(sb + i * 4);
            uint8_t lenb[4];
            if (read_exact(lenb, 4) != 0) break;
            const uint32_t dataLen = get_u32(lenb);
            float* data = (float*)malloc(dataLen * sizeof(float));
            if (data == NULL || read_exact((uint8_t*)data, dataLen * 4) != 0) {
                put_i32(HN_ERR_INVALID);
                break;
            }
            int32_t required = 0;
            int n = HN_ERR_INVALID;
            if (net != NULL) {
                for (int attempt = 0; attempt < 2; attempt++) {
                    n = hn_extract_f32(net, data, shape, (int)dims, out_buf,
                                       (int)out_cap, shapes, out_count * 4, &required);
                    if (n != HN_ERR_CAPACITY) break;
                    free(out_buf);
                    out_cap = (size_t)required;
                    out_buf = (float*)malloc(out_cap * sizeof(float));
                    if (out_buf == NULL) { out_cap = 0; break; }
                }
            }
            free(data);
            if (n < 0) {
                put_i32(n);
            } else {
                put_i32(0);
                put_u32((uint32_t)n);
                write_exact((const uint8_t*)out_buf, (size_t)n * sizeof(float));
            }
            fflush(stdout);
            continue;
        }

        if (cmd == 3) { // gpu enumeration (unchanged from v1)
            hn_gpu_device_t devices[HN_MAX_GPU];
            char names[HN_MAX_GPU][HN_NAME_MAX];
            const int count = hn_gpu_devices(devices, names, HN_MAX_GPU);
            put_u32(0);
            put_u32((uint32_t)count);
            for (int i = 0; i < count; i++) {
                put_u32((uint32_t)devices[i].index);
                put_u32((uint32_t)devices[i].type);
                put_u32((uint32_t)devices[i].score);
                put_u32(devices[i].vendor_id);
                const uint32_t nameLen = (uint32_t)strnlen(names[i], HN_NAME_MAX);
                put_u32(nameLen);
                write_exact((const uint8_t*)names[i], nameLen);
            }
            fflush(stdout);
            continue;
        }
    }

    if (net != NULL) hn_destroy(net);
    free(out_buf);
    free(shapes);
    return 0;
}
```

注意 load 分支里 opts 帧的 39 字节 = 12（三个 i32）+ 4（blobLen）+ 12（mean）+ 12（norm）+ 3（blob 内容）——不，blob 内容长度可变由 blobLen 决定，39 = 12 + 24（mean+norm）+ 3（最小 blob "in0"）不对。**修正**：固定部分是 12（i32×3）+ 4（blobLen）+ 12（mean）+ 12（norm）= 40 字节，blob 内容跟在后面。`optsLen = 40 + blobLen`。执行时按此实现：先读 optsLen（≥40），读 40 字节固定部分，再读 `optsLen - 40` 字节 blob（等价于 read_str）。Dart 侧 `loadRequest` 的 optsLen 同步改为 `40 + blob.length`，对应测试的 `expect(optsLen, 43)`（blob "in0" = 3）。**测试 Step 1 中 `expect(d.getUint32(off, Endian.little), 32)` 改为 `43`，blob 偏移相应后移。**以 40+blobLen 为准。

- [ ] **Step 5: 运行帧测试确认通过 + 语法冒烟**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/helper_frames_test.dart
g++ -fsyntax-only -std=c++17 -Isrc -I/tmp/ncnn-extract/ncnn-*/include \
  -DNCNN_VULKAN=1 src/ncnn_api.cpp src/ncnn_helper_main.cpp && echo SYNTAX-OK
```
Expected: PASS + `SYNTAX-OK`

- [ ] **Step 6: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(helper)!: protocol v2 — options + output shapes over the wire, dynamic buffers"
```

---

### Task 8: NcnnInferenceEngine 迁入（后端选择 + CPU 回退）

**Files:**
- Create: `lib/src/inference_engine.dart`
- Modify: `lib/ncnn.dart`（追加 export）
- Test: `test/inference_engine_test.dart`

**Interfaces:**
- Consumes: `NcnnNet`（Task 4）、`NcnnHelperProcess`（Task 7）、`NcnnGpuDevice`（Task 4）
- Produces: `typedef NcnnNetLoader = Future<NcnnNet> Function({required String paramPath, required String binPath, required NcnnOptions options})`、`typedef NcnnHelperStarter = Future<NcnnHelperProcess> Function()`、`NcnnInferenceEngine({NcnnNetLoader netLoader, NcnnHelperStarter helperStarter, bool forceInProcess, void Function(String)? onLog})`、`loadModel({paramPath, binPath, options, fallbackClassNames})`、`classNames: List<String>`、`usingGpu: bool`、`extract(rgb, w, h) → Future<List<NcnnOutput>>`、`predict(rgb, w, h) → Future<Float32List>`、`static NcnnGpuDevice? bestDevice(List<NcnnGpuDevice>)`、`dispose()`

- [ ] **Step 1: 写失败测试（fake 后端注入）**

`test/inference_engine_test.dart`：

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/ncnn.dart';
import 'package:ncnn/src/inference_engine.dart';

class _FakeNet implements NcnnNet {
  _FakeNet(this.options);
  final NcnnOptions options;
  bool disposed = false;

  @override
  List<NcnnOutput> extract(Uint8List pixels, int width, int height) =>
      [NcnnOutput(shape: const [2, 1, 1, 1], data: Float32List.fromList([1, 2]))];

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #dispose) {
      disposed = true;
      return null;
    }
    throw UnimplementedError('${invocation.memberName}');
  }
}

void main() {
  test('bestDevice prefers discrete, then score', () {
    NcnnGpuDevice dev(int type, int score, int index) => NcnnGpuDevice(
        index: index, type: type, score: score, vendorId: 0, name: 'd$index');
    final best = NcnnInferenceEngine.bestDevice([
      dev(1, 90, 0), // integrated, high score
      dev(0, 50, 1), // discrete, lower score
      dev(0, 80, 2), // discrete, higher score
    ]);
    expect(best!.index, 2);
  });

  test('non-Windows: GPU load failure falls back to CPU', () async {
    final calls = <NcnnOptions>[];
    final engine = NcnnInferenceEngine(
      netLoader: ({required paramPath, required binPath, required options}) async {
        calls.add(options);
        if (options.useVulkan) {
          throw StateError('vulkan boom');
        }
        return _FakeNet(options);
      },
    );
    await engine.loadModel(
      paramPath: '/a.param',
      binPath: '/b.bin',
      fallbackClassNames: const ['x', 'y'],
    );
    expect(calls.length, 2);
    expect(calls[0].useVulkan, isTrue);
    expect(calls[1].useVulkan, isFalse);
    expect(calls[1].deviceIndex, -1);
    expect(engine.usingGpu, isFalse);
    expect(engine.classNames, ['x', 'y']);
    final logits = await engine.predict(Uint8List(12), 2, 2);
    expect(logits, [1, 2]);
  });

  test('non-Windows: no GPU device → direct CPU load', () async {
    final calls = <NcnnOptions>[];
    final engine = NcnnInferenceEngine(
      netLoader: ({required paramPath, required binPath, required options}) async {
        calls.add(options);
        return _FakeNet(options);
      },
    );
    await engine.loadModel(paramPath: '/a.param', binPath: '/b.bin');
    expect(calls.length, 1);
    expect(calls[0].useVulkan, isFalse);
  });
}
```

（`gpuDevices` 注入：`NcnnInferenceEngine` 增加可选 `Future<List<NcnnGpuDevice>> Function()? gpuDeviceProbe`，默认走 `NcnnRuntime.instance.gpuDevices`；上面第二个测试传 `gpuDeviceProbe: () async => [dev(...)]` 使 GPU 路径被选中。执行时按此在测试里补上。）

- [ ] **Step 2: 运行确认失败**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter test test/inference_engine_test.dart
```
Expected: FAIL

- [ ] **Step 3: 写 `lib/src/inference_engine.dart`（全文）**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'helper_process.dart';
import 'net.dart';
import 'options.dart';
import 'runtime.dart';

typedef NcnnNetLoader = Future<NcnnNet> Function({
  required String paramPath,
  required String binPath,
  required NcnnOptions options,
});

typedef NcnnHelperStarter = Future<NcnnHelperProcess> Function();

/// High-level inference engine: picks the backend (Windows: ncnn_helper
/// child process for GPU; other platforms: in-process FFI), selects the
/// best Vulkan device and falls back to CPU on any failure.
///
/// [NcnnNet.extract] is a synchronous FFI call (tens of ms on CPU) — do
/// not call it on the UI isolate; use [NcnnNet.extractInIsolate] or run
/// the engine inside a worker isolate.
class NcnnInferenceEngine {
  NcnnInferenceEngine({
    NcnnNetLoader? netLoader,
    NcnnHelperStarter? helperStarter,
    Future<List<NcnnGpuDevice>> Function()? gpuDeviceProbe,
    bool forceInProcess = false,
    void Function(String message)? onLog,
  })  : _netLoader = netLoader ?? _defaultNetLoader,
        _helperStarter = helperStarter ?? NcnnHelperProcess.start,
        _gpuDeviceProbe = gpuDeviceProbe ??
            () async => NcnnRuntime.instance.gpuDevices,
        _forceInProcess = forceInProcess,
        _log = onLog ?? ((_) {});

  final NcnnNetLoader _netLoader;
  final NcnnHelperStarter _helperStarter;
  final Future<List<NcnnGpuDevice>> Function() _gpuDeviceProbe;
  final bool _forceInProcess;
  final void Function(String) _log;

  NcnnNet? _net;
  NcnnHelperProcess? _helper;
  bool _loaded = false;
  List<String>? _classNames;
  bool _usingGpu = false;

  static Future<NcnnNet> _defaultNetLoader({
    required String paramPath,
    required String binPath,
    required NcnnOptions options,
  }) {
    return NcnnNet.load(
        paramPath: paramPath, binPath: binPath, options: options);
  }

  /// Class names (caller-provided; the engine itself never parses
  /// model metadata).
  List<String> get classNames {
    final names = _classNames;
    if (names == null || names.isEmpty) {
      throw StateError('Class names not set. Call loadModel() first.');
    }
    return names;
  }

  bool get isLoaded => _loaded;
  bool get usingGpu => _usingGpu;

  /// Discrete first, then ncnn rough_score (higher = faster).
  static NcnnGpuDevice? bestDevice(List<NcnnGpuDevice> devices) {
    if (devices.isEmpty) return null;
    final sorted = [...devices]..sort((a, b) {
        final aDiscrete = a.type == 0 ? 1 : 0;
        final bDiscrete = b.type == 0 ? 1 : 0;
        final cmp = bDiscrete.compareTo(aDiscrete);
        if (cmp != 0) return cmp;
        return b.score.compareTo(a.score);
      });
    return sorted.first;
  }

  Future<void> loadModel({
    required String paramPath,
    required String binPath,
    NcnnOptions options = const NcnnOptions.yolo(),
    List<String>? fallbackClassNames,
  }) async {
    if (Platform.isWindows && !_forceInProcess) {
      await _loadViaHelper(
          paramPath: paramPath, binPath: binPath, options: options);
    } else {
      await _loadInProcess(
          paramPath: paramPath, binPath: binPath, options: options);
    }
    _loaded = true;
    _classNames = fallbackClassNames;
    _log('ncnn session ready '
        '(${_classNames?.length ?? 0} classes, gpu=$_usingGpu)');
  }

  Future<void> _loadInProcess({
    required String paramPath,
    required String binPath,
    required NcnnOptions options,
  }) async {
    var device = await _bestProbeDevice();
    _usingGpu = device != null;
    if (device != null) {
      _log('ncnn using Vulkan device ${device.index}: ${device.name} '
          '(type=${device.type}, score=${device.score})');
    } else {
      _log('ncnn using CPU (no Vulkan device)');
    }
    try {
      _net = await _netLoader(
        paramPath: paramPath,
        binPath: binPath,
        options: _withDevice(options, device?.index ?? -1),
      );
    } catch (e) {
      if (device == null) rethrow;
      _log('ncnn Vulkan load failed, falling back to CPU: $e');
      _usingGpu = false;
      _net = await _netLoader(
        paramPath: paramPath,
        binPath: binPath,
        options: _withDevice(options, -1),
      );
    }
  }

  Future<void> _loadViaHelper({
    required String paramPath,
    required String binPath,
    required NcnnOptions options,
  }) async {
    try {
      final helper = await _helperStarter();
      _helper = helper;
      var gpuIndex = -1;
      final devices = await helper.gpuDevices();
      final best = bestDevice(devices);
      if (best != null) {
        gpuIndex = best.index;
        _usingGpu = true;
        _log('ncnn (helper) using Vulkan device ${best.index}: '
            '${best.name} (score=${best.score})');
      } else {
        _log('ncnn (helper) using CPU (no Vulkan device)');
      }
      await helper.load(
          paramPath: paramPath,
          binPath: binPath,
          options: _withDevice(options, gpuIndex));
    } catch (e) {
      _log('ncnn helper path failed, falling back to in-process CPU: $e');
      _helper?.dispose();
      _helper = null;
      _usingGpu = false;
      _net = await _netLoader(
        paramPath: paramPath,
        binPath: binPath,
        options: _withDevice(options, -1),
      );
    }
  }

  NcnnOptions _withDevice(NcnnOptions o, int deviceIndex) => NcnnOptions(
        useVulkan: deviceIndex >= 0,
        deviceIndex: deviceIndex,
        mean: o.mean,
        norm: o.norm,
        pixelFormat: o.pixelFormat,
        inputBlob: o.inputBlob,
      );

  Future<NcnnGpuDevice?> _bestProbeDevice() async {
    try {
      return bestDevice(await _gpuDeviceProbe());
    } catch (e) {
      _log('gpu probe failed, using CPU: $e');
      return null;
    }
  }

  /// All output blobs of one run (pixel input).
  Future<List<NcnnOutput>> extract(
      Uint8List pixels, int width, int height) async {
    final helper = _helper;
    if (helper != null) {
      final flat = await helper.predict(pixels, width, height);
      return NcnnNet.splitOutputs(flat, helper.outputShapes)
          .asMap()
          .entries
          .map((e) => NcnnOutput(
              shape: helper.outputShapes[e.key], data: e.value))
          .toList();
    }
    final net = _net;
    if (net == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
    return net.extract(pixels, width, height);
  }

  /// Convenience: first output (classify models).
  Future<Float32List> predict(
      Uint8List pixels, int width, int height) async {
    final outputs = await extract(pixels, width, height);
    if (outputs.isEmpty) throw StateError('no outputs produced');
    return outputs.first.data;
  }

  Future<void> dispose() async {
    _helper?.dispose();
    _helper = null;
    _net?.dispose();
    _net = null;
    _loaded = false;
    _classNames = null;
    _usingGpu = false;
  }
}
```

- [ ] **Step 4: `lib/ncnn.dart` 追加导出并更新测试**

`lib/ncnn.dart` 的 export 列表追加：

```dart
export 'src/inference_engine.dart';
export 'src/metadata.dart';
export 'src/helper_process.dart' show NcnnHelperProcess;
export 'src/yolo/classify.dart';
export 'src/yolo/detect.dart';
```

- [ ] **Step 5: 运行全部测试 + analyze**

```bash
cd /home/hhoa/git/hhoa/ncnn
flutter analyze && flutter test
```
Expected: `No issues found!`，全部 PASS

- [ ] **Step 6: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "feat(engine): NcnnInferenceEngine with injectable backends, GPU->CPU fallback, helper integration"
```

---

### Task 9: 发布卫生（LICENSE / NOTICES / CHANGELOG / README / example / dry-run）

**Files:**
- Create: `LICENSE`、`THIRD_PARTY_NOTICES.md`、`CHANGELOG.md`、`README.md`（重写）、`example/`（pubspec.yaml + lib/main.dart + 分析选项）、`test/symbol_coverage_test.dart`
- Create: `tool/sync_apple_sources.sh`（仅当 dry-run 发现 symlink 不保真时启用）

**Interfaces:**
- Consumes: 全部前置任务
- Produces: 可 `flutter build linux` 的 example、通过 `dart pub publish --dry-run` 的包

- [ ] **Step 1: LICENSE（全文）**

```
BSD 3-Clause License

Copyright (c) 2026, hhoao
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

- [ ] **Step 2: THIRD_PARTY_NOTICES.md（全文）**

```markdown
# Third-party notices

This package builds against and redistributes (at build time) the
following third-party software:

## ncnn — BSD 3-Clause
- Source: https://github.com/Tencent/ncnn
- Release: 20260526 (official prebuilt archives, downloaded at build
  time by the platform build scripts; not committed to this repository)
- License: https://github.com/Tencent/ncnn/blob/master/LICENSE.txt

## MoltenVK — Apache License 2.0
- Source: https://github.com/KhronosGroup/MoltenVK
- Release: 1.4.2 (official tarball, downloaded by the Apple podspec
  prepare_command and vendored into the app bundle at build time)
- License: https://github.com/KhronosGroup/MoltenVK/blob/main/LICENSE

The prebuilt ncnn archives used per platform:
- Linux x86_64: ncnn-20260526-ubuntu-2204-shared.zip
- Windows x64: ncnn-20260526-windows-vs2022-shared.zip
- Android: ncnn-20260526-android-vulkan.zip (static, per-ABI)
- iOS: ncnn-20260526-ios-vulkan.zip (static frameworks)
- macOS: ncnn-20260526-apple-vulkan.zip (static frameworks)
```

- [ ] **Step 3: CHANGELOG.md（全文）**

```markdown
## 0.1.0

Initial release.

- ncnn (Vulkan) inference bindings for Dart/Flutter via a thin C shim
  and dart:ffi — CPU + any Vulkan GPU (NVIDIA / AMD / Intel / Apple via
  MoltenVK / Android), automatic CPU fallback.
- Five-platform FFI plugin (Android / iOS / Linux / macOS / Windows);
  official ncnn prebuilts downloaded at build time.
- `NcnnNet`: shape-driven multi-output inference with capacity retry,
  configurable preprocessing (mean/norm), pixel format and input blob
  (ultralytics YOLO conventions as defaults).
- `hn_extract_f32`: raw float tensor input for non-image models.
- `NcnnInferenceEngine`: backend selection, best-device heuristic,
  GPU→CPU fallback, injectable backends for testing.
- Windows `ncnn_helper` child process: full GPU acceleration outside
  the Flutter engine process (ncnn's Vulkan init crashes inside it —
  dump-verified; see README).
- YOLO post-processing utilities: classify (argmax/topK/softmax),
  detect (grid decode + per-class NMS).
```

- [ ] **Step 4: README.md 重写（全文）**

```markdown
# ncnn

[ncnn](https://github.com/Tencent/ncnn) inference bindings for Dart and
Flutter — a thin C shim over `ncnn::Net` exposed via `dart:ffi`.

Runs image inference on CPU or **any Vulkan-capable GPU** (NVIDIA /
AMD / Intel / Apple via MoltenVK / Android), with automatic CPU
fallback. Five platforms: Android, iOS, Linux, macOS, Windows.

## Quick start

```dart
import 'package:ncnn/ncnn.dart';

final engine = NcnnInferenceEngine();
await engine.loadModel(
  paramPath: 'model.ncnn.param',
  binPath: 'model.ncnn.bin',
  fallbackClassNames: ['fireball', 'pickball'], // or parse metadata.yaml
);

// RGB24 bytes (w*h*3), e.g. from your own decode/letterbox step.
final logits = await engine.predict(rgb, width, height);
final top = topK(logits, 5);
```

Defaults follow the **ultralytics ncnn export** convention
(`YOLO('best.pt').export(format='ncnn')`): input blob `in0`,
preprocessing `x/255` (no mean), RGB input. Override anything:

```dart
final net = await NcnnNet.load(
  paramPath: '...param', binPath: '...bin',
  options: NcnnOptions(
    useVulkan: true, deviceIndex: 0,
    mean: [0.485, 0.456, 0.406], norm: [0.229, 0.224, 0.225],
    inputBlob: 'data',
  ),
);
final outputs = net.extract(rgb, w, h); // all output blobs + shapes
```

Non-image models: `net.extractF32(Float32List data, [w, h, d, c])`.

## YOLO utilities

```dart
final outputs = await engine.extract(rgb, w, h);
final dets = decodeYoloDetect(
  outputs.first.data, outputs.first.shape, numClasses: 80);
```

Detect outputs of ultralytics exports are already decoded
(DFL/box decode live in the graph); this performs per-class NMS.
Classify: `argmax` / `topK` / `softmax`.

## Platform notes

| Platform | GPU | Notes |
|---|---|---|
| Linux | Vulkan | needs host Vulkan loader (`libvulkan`) — every distro ships it |
| Windows | Vulkan via `ncnn_helper` | see below |
| macOS | Vulkan via MoltenVK | MoltenVK vendored automatically by the podspec |
| iOS | Vulkan via MoltenVK | same |
| Android | Vulkan | falls back to CPU on non-Vulkan devices |

### Windows: inference in a helper process

ncnn's Vulkan device init crashes inside Flutter engine processes
(NVIDIA `nvoglv64` access violation, reproduced and dump-verified; the
engine's GL/D3D stack conflicts with the driver's Vulkan path). This
package runs GPU inference in a tiny `ncnn_helper.exe` child process
over stdin/stdout — full GPU acceleration, transparent to your code.
In-process Vulkan can be re-enabled with `NCNN_DART_ENABLE_VK=1`.

### Thread/isolate safety

`NcnnNet.extract` is a synchronous FFI call (tens of ms on CPU). Never
call it on the UI isolate — use `NcnnNet.extractInIsolate`, or run the
engine in a worker isolate. One extract at a time per `NcnnNet`.

## API stability

C surface versioning: `hn_options_t` carries `struct_size`; fields are
only ever appended, so bindings compiled against older structs keep
working. Dart API follows semantic versioning.

## License

BSD 3-Clause. ncnn (BSD 3) and MoltenVK (Apache 2.0) are downloaded at
build time — see THIRD_PARTY_NOTICES.md.
```

- [ ] **Step 5: example app**

`example/pubspec.yaml`：

```yaml
name: ncnn_example
description: Demonstrates the ncnn Flutter plugin.
publish_to: none
version: 1.0.0

environment:
  sdk: ^3.4.0

dependencies:
  flutter:
    sdk: flutter
  ncnn:
    path: ../

flutter:
  uses-material-design: true
```

`example/lib/main.dart`（无第三方依赖：路径输入框 + 加载 + 单帧 classify）：

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ncnn/ncnn.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ncnn example',
        theme: ThemeData(useMaterial3: true),
        home: const _Home(),
      );
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _param = TextEditingController();
  final _bin = TextEditingController();
  String _status = 'Enter model paths, then Load.';
  List<String> _top = const [];
  NcnnInferenceEngine? _engine;

  @override
  void dispose() {
    _engine?.dispose();
    _param.dispose();
    _bin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = 'Loading…');
    final engine = NcnnInferenceEngine(
        onLog: (m) => setState(() => _status = m));
    try {
      final names = await _classNames();
      await engine.loadModel(
        paramPath: _param.text,
        binPath: _bin.text,
        fallbackClassNames: names,
      );
      setState(() => _status = 'Ready (gpu=${engine.usingGpu})');
      _engine = engine;
    } catch (e) {
      engine.dispose();
      setState(() => _status = 'Load failed: $e');
    }
  }

  Future<List<String>> _classNames() async {
    final meta = File('${File(_param.text).parent.path}/metadata.yaml');
    if (meta.existsSync()) {
      return NcnnMetadata.tryParseClassNames(meta.readAsStringSync()) ??
          const ['class0'];
    }
    return const ['class0'];
  }

  Future<void> _run() async {
    final engine = _engine;
    if (engine == null) return;
    // 64x64 gray frame — a real app feeds decoded/letterboxed frames.
    const size = 64;
    final rgb = Uint8List(size * size * 3);
    setState(() => _status = 'Running…');
    try {
      final logits = await engine.predict(rgb, size, size);
      final top = topK(logits, 5, limit: engine.classNames.length);
      setState(() {
        _top = top
            .map((t) => '${engine.classNames[t.$1]}: '
                '${t.$2.toStringAsFixed(3)}')
            .toList();
      });
    } catch (e) {
      setState(() => _status = 'Run failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ncnn example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                  controller: _param,
                  decoration: const InputDecoration(labelText: 'model.ncnn.param path')),
              TextField(
                  controller: _bin,
                  decoration: const InputDecoration(labelText: 'model.ncnn.bin path')),
              const SizedBox(height: 8),
              FilledButton(onPressed: _load, child: const Text('Load')),
              FilledButton(
                  onPressed: _engine != null ? _run : null,
                  child: const Text('Run (64x64 zeros)')),
              const SizedBox(height: 16),
              Text(_status),
              ..._top.map((t) => Text(t)),
              const Spacer(),
              FutureBuilder<List<NcnnGpuDevice>>(
                future: NcnnRuntime.instance.gpuDevices.isEmpty
                    ? Future.value(const <NcnnGpuDevice>[])
                    : Future.value(NcnnRuntime.instance.gpuDevices),
                builder: (context, snap) => Text(
                    'Vulkan devices: '
                    '${snap.data?.map((d) => d.name).join(', ') ?? '…'}'),
              ),
            ],
          ),
        ),
      );
}
```

（`FutureBuilder` 的写法执行时可简化为 `ListenableBuilder` + 直接读 getter——以 lint 干净、无未用警告为准。）

- [ ] **Step 6: 符号覆盖集成测试**

`test/symbol_coverage_test.dart`：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ncnn/src/bindings.g.dart' as native;

void main() {
  // Guards against header/bindings drift: every hn_* entry the Dart
  // side looks up must exist in the built plugin library. Skipped when
  // no plugin library can be resolved (pure-Dart CI jobs).
  test('all hn_* symbols resolve in the native library', () {
    final libDir = Platform.environment['NCNN_DART_LIB_DIR'];
    final names = <String, String>{
      'linux': 'libncnn_plugin.so',
      'windows': 'ncnn_plugin.dll',
    };
    final libName = names[Platform.operatingSystem];
    if (libDir == null || libName == null) {
      // Marked skip via success — CI runs the real check after a build.
      return;
    }
    final path = '$libDir${Platform.pathSeparator}$libName';
    if (!File(path).existsSync()) {
      fail('NCNN_DART_LIB_DIR set but $path missing — run a build first');
    }
    final lib = native.DynamicLibrary.open(path);
    for (final symbol in [
      'hn_create',
      'hn_load',
      'hn_output_count',
      'hn_output_shape',
      'hn_extract',
      'hn_extract_f32',
      'hn_destroy',
      'hn_gpu_count',
      'hn_gpu_devices',
    ]) {
      expect(() => lib.lookup(symbol), returnsNormally,
          reason: 'missing symbol $symbol');
    }
  });
}
```

（`native.DynamicLibrary` 不可直接访问——`import 'dart:ffi'` 引入 `DynamicLibrary`；执行时修正 import。）

- [ ] **Step 7: Linux 构建验证（真正的 C 编译检查）**

```bash
cd /home/hhoa/git/hhoa/ncnn/example
flutter pub get
flutter build linux --debug
ls build/linux/*/debug/bundle/lib/ | grep -E 'ncnn'
```
Expected: 构建成功，bundle/lib 里有 `libncnn_plugin.so` 和 `libncnn.so.1`。首次构建会下载 ncnn ubuntu 预编译包（~30 MB）。

- [ ] **Step 8: dry-run 验证（重点：symlink 与体积）**

```bash
cd /home/hhoa/git/hhoa/ncnn
dart pub publish --dry-run 2>&1 | tail -30
```
检查三点：
1. 总大小 < 1 MB（不含 example/build——确认被忽略）
2. `ios/src/*` 和 `macos/src/*` 以 symlink 形式进入 tarball（GNU tar `ls -l` 验证解包；pub 打包用 tar 格式保留 symlink）
3. 无 `pubspec.lock`、无 `.cxx`

若 symlink 不保真：执行备选方案——删除 symlink，`ios/src`、`macos/src` 放真实文件副本，创建 `tool/sync_apple_sources.sh`：

```bash
#!/usr/bin/env bash
# Syncs the shared shim sources into ios/src and macos/src (real files —
# CocoaPods globs cannot escape the podspec dir; symlinks are not
# preserved by pub tarballs). CI asserts copies match src/.
set -euo pipefail
cd "$(dirname "$0")/.."
for d in ios/src macos/src; do
  mkdir -p "$d"
  cp src/ncnn_api.h src/ncnn_api.cpp src/ncnn_link_anchor.m "$d/"
done
diff -r <(cat src/ncnn_api.h) <(cat ios/src/ncnn_api.h)
```

并把 `ncnn_api.{h,cpp}` 从 podspec `source_files` 引用改为副本路径（即现状引用不变，只是真文件）。CI 加 `tool/sync_apple_sources.sh && git diff --exit-code ios/src macos/src`。

- [ ] **Step 9: Commit**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "docs(publish): LICENSE, third-party notices, changelog, README, example app, symbol coverage test"
```

---

### Task 10: CI workflow + 推送 GitHub

**Files:**
- Create: `.github/workflows/ci.yml`、`.github/workflows/publish.yml`

**Interfaces:**
- Consumes: Task 9 的全部
- Produces: 远端 `main` 分支 + CI 绿

- [ ] **Step 1: `.github/workflows/ci.yml`（全文）**

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  analyze-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed --output=none .
      - run: flutter analyze
      - run: flutter test

  build-example-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - name: Install Linux build deps
        run: sudo apt-get update && sudo apt-get install -y ninja-build libgtk-3-dev libvulkan-dev
      - run: flutter pub get
        working-directory: example
      - name: Build example (downloads ncnn, compiles shim)
        run: flutter build linux --debug
        working-directory: example
      - name: Symbol coverage against the built plugin
        run: |
          flutter test test/symbol_coverage_test.dart
        env:
          NCNN_DART_LIB_DIR: ${{ github.workspace }}/example/build/linux/x64/debug/bundle/lib
```

（`NCNN_DART_LIB_DIR` 的实际 bundle 路径以构建输出为准——执行时核对 `find example/build -name 'libncnn_plugin.so'` 的目录。）

- [ ] **Step 2: `.github/workflows/publish.yml`（全文）**

```yaml
name: publish
on:
  push:
    tags: ['v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - name: Publish
        run: dart pub publish --force
        env:
          # Publishing token created on pub.dev (Manage publishing tokens).
          # See https://dart.dev/tools/pub/automated-publishing — if the
          # env var name differs at execution time, follow those docs.
          PUB_TOKEN: ${{ secrets.PUB_TOKEN }}
```

- [ ] **Step 3: 推送**

```bash
cd /home/hhoa/git/hhoa/ncnn
git add -A
git commit -m "ci: analyze/test + linux example build + tag-driven publish"
git push -u origin main
```
Expected: push 成功；GitHub Actions 两个 job 排队。等待 CI 绿（若 CI 红按日志修复后追加 commit 再推）。

---

### Task 11: huji-app 迁移（huji 仓库）

**Files:**
- Delete: `huji-app/packages/huji_ncnn/`（整目录）
- Create: `huji-app/packages/ncnn/`（submodule）
- Modify: `huji-app/pubspec.yaml`、`huji-app/lib/services/inference/{ncnn_model_predictor,gpu_device_selector}.dart`、`huji-app/lib/services/platform_capability.dart`、`huji-app/scripts/build_appimage.sh`、`.github/workflows/release.yml`、`huji-app/test/integration/{clip_flow_integration,local_detection_golden}_test.dart`
- Delete: `huji-app/test/helpers/ncnn_test_bootstrap.dart`、`huji-app/test/ncnn_stale_marker_test.dart`、`huji-app/test/integration/{ncnn_plugin_test,ncnn_real_frame_test}.dart`
- Modify: `huji-app/test/services/inference/ncnn_predictor_pool_test.dart`（import 改名）

**Interfaces:**
- Consumes: 远端 `hhoao/ncnn` main（Task 10 已推送）、包的公开 API（Task 4/8）
- Produces: huji-app 通过 `package:ncnn` 工作，旧包目录消失

执行前先建分支：

```bash
cd /home/hhoa/git/hhoa/huji
git switch -c feat/ncnn-package-extraction
```

- [ ] **Step 1: 替换包为 submodule**

```bash
cd /home/hhoa/git/hhoa/huji
git rm -r huji-app/packages/huji_ncnn
git submodule add https://github.com/hhoao/ncnn.git huji-app/packages/ncnn
```

- [ ] **Step 2: pubspec 与全局引用改名**

`huji-app/pubspec.yaml` 中的依赖（约 96-97 行）：

```yaml
  ncnn:
    path: packages/ncnn
```
（删除原 `huji_ncnn: path: packages/huji_ncnn` 条目）

```bash
cd /home/hhoa/git/hhoa/huji
grep -rl 'package:huji_ncnn' huji-app/lib huji-app/test | \
  xargs sed -i 's|package:huji_ncnn|package:ncnn|g'
grep -rl 'HUJI_NCN_LIB_DIR\|HUJI_NCNN_LIB_DIR' huji-app .github | \
  xargs sed -i 's/HUJI_NCN_LIB_DIR/NCNN_DART_LIB_DIR/g; s/HUJI_NCNN_LIB_DIR/NCNN_DART_LIB_DIR/g'
grep -rl 'huji_ncnn_helper' huji-app .github | \
  xargs sed -i 's/huji_ncnn_helper/ncnn_helper/g'
grep -rl 'huji_ncnn' huji-app/lib huji-app/test huji-app/scripts .github | \
  xargs sed -i 's/huji_ncnn/ncnn/g'
```

- [ ] **Step 3: 删除已迁入包的 app 层文件与测试**

```bash
cd /home/hhoa/git/hhoa/huji
# 引擎与 helper 已入包（NcnnInferenceEngine 现在从 package:ncnn 导入）
git rm huji-app/lib/services/inference/ncnn_inference_engine.dart \
       huji-app/lib/services/inference/ncnn_helper_process.dart
# 包级测试已随包迁移（新仓 test/）
git rm huji-app/test/helpers/ncnn_test_bootstrap.dart \
       huji-app/test/ncnn_stale_marker_test.dart \
       huji-app/test/integration/ncnn_plugin_test.dart \
       huji-app/test/integration/ncnn_real_frame_test.dart
```

- [ ] **Step 4: 接线修正（手工）**

逐个检查并修正（sed 改不了语义）：

1. `huji-app/lib/services/inference/ncnn_model_predictor.dart`——原 `import '.../ncnn_inference_engine.dart'` 删除，引擎类型来自 `package:ncnn/ncnn.dart`（类名不变 `NcnnInferenceEngine`）。原 app 引擎构造 `NcnnInferenceEngine()` 无参照旧；若 app 需要 AppLogger，改为：
```dart
final engine = NcnnInferenceEngine(
  onLog: (m) => AppLogger().i(m),
);
```
2. `huji-app/lib/services/inference/gpu_device_selector.dart`——`NcnnGpuDevice` 从 `package:ncnn/ncnn.dart` 导入（名字不变）。
3. `huji-app/lib/services/platform_capability.dart`、`huji-app/lib/services/inference/ncnn_model_asset_resolver.dart`——按 grep 结果改引用。
4. `huji-app/scripts/build_appimage.sh`——grep 残留的 `huji_ncnn`/`ncnn_plugin` 路径（插件产物名已变，脚本若按文件名拷贝需同步）。
5. `.github/workflows/release.yml`——`huji_ncnn` 引用改名 + `actions/checkout` 需要 `submodules: recursive`（ncnn submodule 必须检出才能构建）。
6. 留守测试里 bootstrap 引用：`local_detection_golden_test.dart` / `clip_flow_integration_test.dart` 若 import 了已删除的 `helpers/ncnn_test_bootstrap.dart`，把 bootstrap 逻辑（设置 `NCNN_DART_LIB_DIR` 指向 build 产物）内联或删除该依赖——这些测试本就走 app 的 predictor/pool 路径，原生库经 path 依赖的插件构建解析。

- [ ] **Step 5: 验证**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter pub get
flutter analyze
flutter test
```
Expected: `No issues found!`，全部测试通过（原生库依赖的集成测试需要先 `flutter build linux --debug`，未构建时它们应跳过或由纯 Dart 测试覆盖）

- [ ] **Step 6: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add -A
git commit -m "refactor(app)!: consume ncnn as package via submodule (was in-repo huji_ncnn)"
```

---

### Task 12: 全量回归验收

**Files:**
- 无新增文件（验证任务）

**Interfaces:**
- Consumes: Task 11 的迁移结果
- Produces: 验收结论（parity bit-exact + 测试全绿 + 真实推理冒烟）

- [ ] **Step 1: Linux 构建与原生库集成测试**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter build linux --debug
```
Expected: 构建成功，bundle 中出现 `libncnn_plugin.so` + `libncnn.so.1`（`ls build/linux/*/debug/bundle/lib/`）。

- [ ] **Step 2: app 全量测试**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter test
```
Expected: 全绿。重点关注 `test/services/inference/`（pool 测试）、`test/integration/local_detection_golden_test.dart`（端到端真实推理——golden 数值必须不变，这是泛化后数值行为不变的直接证据）。

- [ ] **Step 3: parity bit-exact（硬验收）**

```bash
cd /home/hhoa/git/hhoa/huji/huji-algorithm
# Linux venv（CLAUDE.md 记录的是 Windows .venv/Scripts 路径，按实际环境取）
if [ -x .venv/bin/python ]; then PY=.venv/bin/python; else PY=python3; fi
$PY scripts/verify_ncnn_parity.py --help
```
按脚本实际参数运行全部 4 个模型（badminton singles/doubles + 现有另外两组合）。
Expected: 4/4 bit-exact。
（若本机无 python 环境/依赖，记录 blocked 并向用户说明——此项是发布前必须补的验收，不可跳过。）

- [ ] **Step 4: 真机冒烟（Vulkan + CPU 两路）**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter run -d linux
```
在 app 里跑一次真实视频检测流程，日志应出现 `ncnn using Vulkan device …`；再以 CPU 强制路径验证（临时设 `NCNN_DART_LIB_DIR` 不可用时观察回退，或拔掉 Vulkan 环境变量模拟）。
Expected: GPU 路径正常推理；无 Vulkan 时回退 CPU 正常。

- [ ] **Step 5: huji 仓库推送**

```bash
cd /home/hhoa/git/hhoa/huji
git push -u origin feat/ncnn-package-extraction
```

---

### Task 13: 发布 0.1.0（需用户确认）

**Files:**
- 无代码改动

**Interfaces:**
- Consumes: Task 12 全绿结论、Task 10 的远端 main
- Produces: pub.dev 上的 `ncnn` 0.1.0 + `v0.1.0` tag

- [ ] **Step 1: 终验 dry-run**

```bash
cd /home/hhoa/git/hhoa/ncnn
dart pub publish --dry-run
```
Expected: 无 error；file list 与 Task 9 Step 8 一致（symlink/体积/lockfile 三点复查）。

- [ ] **Step 2: 向用户确认**

**此步骤必须停下向用户报告并征得同意**（发布不可撤销，pub.dev 上线即公开）：
- 包名 `ncnn`、版本 0.1.0、file list、大小
- CI 状态（hhoao/ncnn main 绿）
- parity 验收结果

- [ ] **Step 3: 发布（用户同意后）**

```bash
cd /home/hhoa/git/hhoa/ncnn
dart pub publish
git tag v0.1.0
git push origin v0.1.0
```
Expected: `Successfully published ncnn 0.1.0`；publish workflow 在 tag 推送时不会重复发布（`--force` 失败即忽略，或 workflow 保留作未来版本的发布通道）。

- [ ] **Step 4: 收尾**

- huji 仓库分支开 PR（`feat/ncnn-package-extraction` → `main`），PR 描述引用本计划与 spec
- 新仓 README 如需徽章（pub version / CI）在发布后追加一个小 commit

---

## Self-Review 记录（计划完成后执行的自查）

1. **Spec coverage**：
   - §1 命名 → Task 1（机械改名）+ Global Constraints 映射表 ✓
   - §2 C API → Task 2（含异常屏障、删 sleep）✓
   - §3 Dart 分层 → Task 3/4/5/6/7/8 ✓
   - §4 helper 迁入 → Task 7 + Task 1（CMake 目标已在 windows/ 内，sed 改名覆盖）✓
   - §5 huji-app 迁移 → Task 11/12 ✓
   - §6 发布卫生 → Task 9（LICENSE/NOTICES/CHANGELOG/README/example/symlink 风险与备选）✓
   - §7 CI/发布流 → Task 10/13 ✓
   - 风险表对策：symlink（Task 9 Step 8 双方案）、抢注（Task 13 尽快发布）、改名残留（Task 11 Step 2 全局 grep + Step 4 手工清单）、数值漂移（Task 12 parity + golden）、helper 定位失败（回退逻辑 Task 8 测试覆盖）✓
2. **Placeholder scan**：Task 7 Step 3 含一段带删除标记的草稿（保留完整实现为准的说明明确）；Task 7 协议帧长 40+blobLen 的修正已内联写明；其余无 TBD/TODO ✓
3. **Type consistency**：`NcnnOptions`/`NcnnNet.load`/`extract`/`splitOutputs`/`NcnnOutput{shape,data}`/`NcnnInferenceEngine{loadModel,predict,extract}`/`bestDevice`/`NcnnHelperProcess.{load,predict,extractF32,dispose}` 在 Task 4/7/8/11 间签名一致 ✓

## 执行注意事项

- 任务 1-10 在新仓 `/home/hhoa/git/hhoa/ncnn`；任务 11-12 在 huji 仓分支；任务 13 回新仓。顺序不可调换（Task 11 的 submodule 需要 Task 10 的远端存在）。
- Task 2 后到 Task 7 前，`ncnn_helper_main.cpp` 编译不过——期间只跑 Linux 侧验证（Task 2 Step 3 的语法检查不含 helper）。
- Flutter 命令假定本机 flutter 在 PATH；如无，按 huji-app 现有开发环境（VSCode launch 配置）的环境变量/路径取。
- 每个任务完成即 commit（计划内已含 commit 步骤），不要攒批。
