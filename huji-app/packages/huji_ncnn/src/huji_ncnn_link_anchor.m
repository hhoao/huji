// Link anchor for Apple platforms (macOS / iOS).
//
// huji_ncnn is a pure-FFI pod: no ObjC/Swift plugin class ever references
// the hn_* entry points from native code, so when linking the app the
// static-archive members that define them are never pulled in (and would be
// dead-code-stripped even if they were). dart:ffi resolves them via
// dlsym(RTLD_DEFAULT, ...) at runtime, which only sees symbols that actually
// made it into the binary.
//
// CocoaPods passes -ObjC when linking the app, which loads every static
// archive member containing ObjC metadata — including this one. +load of a
// registered ObjC class is a dead-strip root, and its body stores the
// addresses of all hn_* entry points into a volatile table, forcing the
// linker to pull in (and keep) huji_ncnn_api.o and, transitively, the ncnn
// static frameworks.
#import <Foundation/Foundation.h>

#include "huji_ncnn_api.h"

static void *volatile huji_ncnn_link_anchors[6];

@interface HujiNcnnLinkAnchor : NSObject
@end

@implementation HujiNcnnLinkAnchor

+ (void)load {
  // Never executed beyond the stores; addresses must simply be resolved.
  huji_ncnn_link_anchors[0] = (void *)&hn_create;
  huji_ncnn_link_anchors[1] = (void *)&hn_load;
  huji_ncnn_link_anchors[2] = (void *)&hn_predict;
  huji_ncnn_link_anchors[3] = (void *)&hn_destroy;
  huji_ncnn_link_anchors[4] = (void *)&hn_gpu_count;
  huji_ncnn_link_anchors[5] = (void *)&hn_gpu_devices;
}

@end
