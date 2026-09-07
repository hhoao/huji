// Thin C shim over ncnn::Net for dart:ffi.
//
// Only what the huji app needs: load a YOLO classify model, run one frame,
// enumerate Vulkan devices. Keep the C surface minimal and stable so the
// ffigen bindings never need regeneration for behavior changes.
#include "huji_ncnn_api.h"

#include <string.h>

#include "ncnn/net.h"
#if NCNN_VULKAN
#include "ncnn/gpu.h"
#include <mutex>
#include <thread>
#endif

namespace {
struct hn_net {
    ncnn::Net net;
    bool loaded;
};

hn_net* as_net(hn_net_t net) {
    return static_cast<hn_net*>(net);
}

#if NCNN_VULKAN
// create_gpu_instance() crashes when run on a Dart VM isolate thread
// (observed: access violation during driver enumeration; same call works
// from plain native binaries and Python). Run it once on a vanilla std
// thread instead — after this warm-up, get_gpu_count() is safe anywhere.
std::once_flag gpu_init_once;

void warm_up_gpu_instance() {
    std::call_once(gpu_init_once, []() {
        std::thread t([]() { ncnn::create_gpu_instance(); });
        t.join();
    });
}
#endif

void set_options(ncnn::Net& net, int use_vulkan, int device_index) {
    net.opt.num_threads = 4;
#if NCNN_VULKAN
    if (use_vulkan) {
        warm_up_gpu_instance();
    }
    net.opt.use_vulkan_compute = use_vulkan != 0;
    if (use_vulkan && device_index >= 0) {
        net.set_vulkan_device(device_index);
    }
#else
    (void)use_vulkan;
    (void)device_index;
#endif
}
} // namespace

hn_net_t hn_create(int use_vulkan, int device_index) {
    auto* n = new (std::nothrow) hn_net();
    if (n == nullptr) return nullptr;
    set_options(n->net, use_vulkan, device_index);
    return n;
}

int hn_load(hn_net_t net, const char* param_path, const char* bin_path) {
    if (net == nullptr || param_path == nullptr || bin_path == nullptr) {
        return -1;
    }
    auto* n = as_net(net);
    if (n->net.load_param(param_path) != 0) return -2;
    if (n->net.load_model(bin_path) != 0) return -3;
    n->loaded = true;
    return 0;
}

int hn_predict(hn_net_t net, const uint8_t* rgb, int w, int h,
               float* out, int out_len) {
    if (net == nullptr || rgb == nullptr || out == nullptr) {
        return -1;
    }
    auto* n = as_net(net);
    if (!n->loaded) return -1;
    if (w <= 0 || h <= 0 || out_len <= 0) return -2;

    ncnn::Mat in = ncnn::Mat::from_pixels(rgb, ncnn::Mat::PIXEL_RGB, w, h);
    // YOLO preprocess: x/255, no mean subtraction. substract_mean_normalize
    // reads norm[channels] entries — one per channel, NOT a single shared
    // scalar (a 1-element array reads OOB and corrupts G/B planes).
    const float norm[3] = {
        1.0f / 255.0f, 1.0f / 255.0f, 1.0f / 255.0f,
    };
    in.substract_mean_normalize(nullptr, norm);

    ncnn::Mat out_mat;
    ncnn::Extractor ex = n->net.create_extractor();
    if (ex.input("in0", in) != 0) return -4;
    if (ex.extract("out0", out_mat) != 0) return -5;

    // Classify head emits [num_classes] (dims=1) or [1, num_classes] (dims=2).
    int classes = out_mat.dims == 1 ? out_mat.w : (out_mat.dims == 2 ? out_mat.w * out_mat.h : 0);
    if (classes <= 0) return -6;
    if (classes > out_len) return -7;

    memcpy(out, out_mat.data, (size_t)classes * sizeof(float));
    return classes;
}

void hn_destroy(hn_net_t net) {
    delete static_cast<hn_net*>(net);
}

int hn_gpu_count(void) {
#if NCNN_VULKAN
    warm_up_gpu_instance();
    return ncnn::get_gpu_count();
#else
    return 0;
#endif
}

int hn_gpu_devices(hn_gpu_device_t* devices, char (*names)[HN_NAME_MAX], int n) {
#if NCNN_VULKAN
    warm_up_gpu_instance();
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
#else
    (void)devices;
    (void)names;
    (void)n;
    return 0;
#endif
}
