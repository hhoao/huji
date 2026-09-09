#
# huji_ncnn — iOS: ncnn (Vulkan via MoltenVK discovery) static frameworks
# from the official ncnn ios-vulkan release.
#
# The prebuilt archive is fetched by the prepare_command into
# build/ncnn-ios-vulkan/ and vendored via vendored_frameworks.
#
Pod::Spec.new do |s|
  s.name             = "huji_ncnn"
  s.version          = "1.0.0"
  s.summary          = "ncnn (Vulkan) inference shim for huji"
  s.description      = "Thin C shim over ncnn::Net, exposed via dart:ffi."
  s.homepage         = "https://github.com/hhoao/huji"
  s.license          = "BSD-3-Clause"
  s.author           = { "hhoao" => "hhoao@users.noreply.github.com" }
  s.source           = { :path => "." }
  s.ios.deployment_target  = "12.0"

  ncnn_version = "20260526"
  ncnn_dir = "build/ncnn-ios-vulkan"
  mvk_version = "1.4.2"
  mvk_dir = "build/moltenvk"

  s.prepare_command = <<-CMD
    mkdir -p build
    if [ ! -d "#{ncnn_dir}/ncnn.framework" ]; then
      curl -fL --retry 3 \
        "https://github.com/Tencent/ncnn/releases/download/#{ncnn_version}/ncnn-#{ncnn_version}-ios-vulkan.zip" \
        -o build/ncnn-ios-vulkan.zip
      unzip -qo build/ncnn-ios-vulkan.zip -d #{ncnn_dir}
      rm -f build/ncnn-ios-vulkan.zip
    fi
    # ncnn's ios-vulkan build links against the Vulkan loader; on iOS the
    # loader is MoltenVK. Stream-extract just the dynamic xcframework.
    mkdir -p #{mvk_dir}
    if [ ! -d "#{mvk_dir}/MoltenVK.xcframework" ]; then
      curl -fL --retry 3 \
        "https://github.com/KhronosGroup/MoltenVK/releases/download/v#{mvk_version}/MoltenVK-ios.tar" \
        | tar -x -C #{mvk_dir} --strip-components=3 MoltenVK/MoltenVK/dynamic/MoltenVK.xcframework
    fi
  CMD

  s.vendored_frameworks = [
    "#{ncnn_dir}/ncnn.framework",
    "#{ncnn_dir}/glslang.framework",
    "#{ncnn_dir}/openmp.framework",
    "#{mvk_dir}/MoltenVK.xcframework",
  ]

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
    # The shim includes "ncnn/net.h". Vendored framework headers are not on
    # the include path by default; point at the staged (platform-selected)
    # Headers dir. "Prepare xcframeworks" phases populate it before compile.
    "HEADER_SEARCH_PATHS" => "$(PODS_CONFIGURATION_BUILD_DIR)/XCFrameworkIntermediates/huji_ncnn/ncnn.framework/Headers",
  }

  # NOTE: `src` is a real directory containing symlinks to the shared shim
  # sources at the package root — CocoaPods file patterns cannot reference
  # files outside the podspec directory (ios/), and its `**` glob does not
  # descend into symlinked *directories*, so we link individual files.
  #
  # huji_ncnn_link_anchor.m keeps the FFI entry points alive at app link
  # time (pure-FFI pod, nothing references hn_* natively; see the file).
  s.source_files = "src/huji_ncnn_api.{h,cpp}", "src/huji_ncnn_link_anchor.m"
  s.public_header_files = "src/huji_ncnn_api.h"
  s.requires_arc = false
end
