#include <stdint.h>

#if defined(_WIN32)
#define HUJI_NCNN_API __declspec(dllexport)
#else
#define HUJI_NCNN_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Opaque handle to a loaded ncnn network.
typedef void* hn_net_t;

/// Vulkan device info returned by hn_enumerate_gpu.
typedef struct {
    int index;          /// ncnn device index (-1 = no Vulkan)
    int type;           /// 0=discrete, 1=integrated, 2=virtual, 3=cpu
    int score;          /// ncnn rough_score heuristic (higher = faster)
    uint32_t vendor_id; /// PCI vendor id
} hn_gpu_device_t;

#define HN_MAX_GPU 8
#define HN_NAME_MAX 128

/// Create a network object. Returns NULL on OOM.
/// [use_vulkan] selects Vulkan compute; [device_index] picks the Vulkan
/// device (-1 = ncnn default), ignored when use_vulkan is 0.
HUJI_NCNN_API hn_net_t hn_create(int use_vulkan, int device_index);

/// Load a model. Returns 0 on success, non-zero on failure.
/// param_path: model.ncnn.param; bin_path: model.ncnn.bin
HUJI_NCNN_API int hn_load(hn_net_t net, const char* param_path, const char* bin_path);

/// Run inference on an RGB24 (HWC, w*h*3 bytes) input and write class
/// scores into out (at least out_len floats). Returns the number of class
/// scores written, or a negative value on failure.
HUJI_NCNN_API int hn_predict(hn_net_t net, const uint8_t* rgb, int w, int h,
                             float* out, int out_len);

/// Destroy a network object (NULL is a no-op).
HUJI_NCNN_API void hn_destroy(hn_net_t net);

/// Count available Vulkan devices (0 if Vulkan is unavailable/disabled).
HUJI_NCNN_API int hn_gpu_count(void);

/// Fill devices[0..n-1] and names[i][HN_NAME_MAX] for up to n Vulkan
/// devices. Returns the number written.
HUJI_NCNN_API int hn_gpu_devices(hn_gpu_device_t* devices,
                                 char (*names)[HN_NAME_MAX], int n);

#ifdef __cplusplus
}
#endif
