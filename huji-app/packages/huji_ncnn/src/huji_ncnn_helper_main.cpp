// Standalone ncnn inference helper for Windows.
//
// Rationale: ncnn's Vulkan device init crashes inside Flutter engine
// processes (NVIDIA nvoglv64 access violation — the engine's GL/D3D
// rendering stack conflicts with the driver's Vulkan path). In a plain
// process the same shim runs flawlessly on GPU. This helper is spawned by
// the app as a child process and speaks a simple binary protocol over
// stdin/stdout:
//
//   load:    u32 cmd=1 | u32 pathLen | path bytes (param|bin separated by '\n',
//            optional third line: gpu index, -1 = CPU)
//            -> u32 status
//   predict: u32 cmd=2 | u32 w | u32 h | (w*h*3 RGB bytes)
//            -> u32 status | u32 count | count * f32
//   gpu:     u32 cmd=3
//            -> u32 status | u32 count | count * (u32 idx, u32 type, u32 score,
//               u32 vendor, u32 nameLen, name bytes)
//   quit:    u32 cmd=0 -> exits
//
// All integers little-endian. Frames are read with full-buffer loops.
#include "huji_ncnn_api.h"

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

static uint32_t get_u32(const uint8_t* b) {
    return (uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) |
           ((uint32_t)b[3] << 24);
}

int main(void) {
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
    // This is a standalone process (NOT the Flutter app) — ncnn's Vulkan
    // stack is safe here. The shim's in-app guard must not apply.
    _putenv_s("HUJI_NCNN_ENABLE_VK", "1");
    // Multi-vendor device enumeration crashes on some driver combos
    // (Intel + NVIDIA dual-GPU laptops, observed 2026-09). If the user
    // hasn't pinned an ICD list, restrict to the NVIDIA ICD only — the
    // app only wants the discrete GPU for inference anyway.
    if (getenv("VK_ICD_FILENAMES") == NULL &&
        getenv("HUJI_NCNN_ALL_ICDS") == NULL) {
        const char* nvCandidates[] = {
            "C:\\Windows\\System32\\DriverStore\\FileRepository\\nvam.inf_amd64_19fcbbfeca9a5b09\\nv-vk64.json",
            NULL,
        };
        // fall back: scan the driver store for the first nv-vk64.json
        WIN32_FIND_DATAA fd;
        HANDLE h = FindFirstFileA(
            "C:\\Windows\\System32\\DriverStore\\FileRepository\\*\\nv-vk64.json", &fd);
        char keep[512] = "";
        if (h != INVALID_HANDLE_VALUE) {
            // FindFirstFile with a path wildcard returns matches relative
            // to the pattern — reconstruct the full path.
            // The pattern itself resolves; use the first match's dir via
            // the returned name only when it contains a path (it doesn't).
            // Simpler: iterate INF dirs ourselves.
            FindClose(h);
        }
        // Robust approach: walk INF directories.
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
        if (keep[0] == '\0') {
            for (int i = 0; nvCandidates[i] != NULL; i++) {
                if (GetFileAttributesA(nvCandidates[i]) != INVALID_FILE_ATTRIBUTES) {
                    snprintf(keep, sizeof(keep), "%s", nvCandidates[i]);
                    break;
                }
            }
        }
        if (keep[0] != '\0') {
            _putenv_s("VK_ICD_FILENAMES", keep);
        }
    }
#endif

    hn_net_t net = NULL;
    uint8_t hdr[4];

    for (;;) {
        if (read_exact(hdr, 4) != 0) break;
        const uint32_t cmd = get_u32(hdr);

        if (cmd == 0) break; // quit

        if (cmd == 1) { // load
            uint8_t lenb[4];
            if (read_exact(lenb, 4) != 0) break;
            const uint32_t pathLen = get_u32(lenb);
            char* payload = (char*)malloc(pathLen + 1);
            if (payload == NULL || read_exact((uint8_t*)payload, pathLen) != 0) {
                put_u32(0xFFFFFFFF);
                break;
            }
            payload[pathLen] = '\0';
            // payload: "<param>\n<bin>[\n<gpu>]" — manual split (no strtok_r on MSVC)
            char* lines[3] = {NULL, NULL, NULL};
            int lineCount = 0;
            char* cur = payload;
            for (char* q = payload; ; q++) {
                if (*q == '\n' || *q == '\0') {
                    const char term = *q;
                    *q = '\0';
                    if (lineCount < 3 && *cur != '\0') lines[lineCount++] = cur;
                    if (term == '\0' || lineCount == 3) break;
                    cur = q + 1;
                }
            }
            const char* param = lines[0];
            const char* bin = lines[1];
            const char* gpuStr = lines[2];
            if (param == NULL || bin == NULL) {
                put_u32(0xFFFFFFFE);
                free(payload);
                fflush(stdout);
                continue;
            }
            int gpu = -1;
            if (gpuStr != NULL) gpu = atoi(gpuStr);

            if (net != NULL) hn_destroy(net);
            net = hn_create(gpu >= 0 ? 1 : 0, gpu);
            if (net == NULL) {
                put_u32(0xFFFFFFFD);
                free(payload);
                fflush(stdout);
                continue;
            }
            const int rc = hn_load(net, param, bin);
            put_u32((uint32_t)rc);
            free(payload);
            fflush(stdout);
            continue;
        }

        if (cmd == 2) { // predict
            uint8_t meta[12];
            if (read_exact(meta, 12) != 0) break;
            const uint32_t w = get_u32(meta);
            const uint32_t h = get_u32(meta + 4);
            const uint32_t frameLen = get_u32(meta + 8);
            uint8_t* frame = (uint8_t*)malloc(frameLen);
            if (frame == NULL || read_exact(frame, frameLen) != 0) {
                put_u32(0xFFFFFFFF);
                break;
            }
            float out[64];
            const int n = hn_predict(net, frame, (int)w, (int)h, out, 64);
            free(frame);
            if (n < 0) {
                put_u32((uint32_t)n);
                fflush(stdout);
                continue;
            }
            put_u32(0);
            put_u32((uint32_t)n);
            write_exact((const uint8_t*)out, (size_t)n * sizeof(float));
            fflush(stdout);
            continue;
        }

        if (cmd == 3) { // gpu enumeration
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
    return 0;
}
