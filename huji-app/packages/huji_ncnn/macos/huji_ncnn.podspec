#
# huji_ncnn — macOS: ncnn (Vulkan via MoltenVK discovery) static frameworks
# from the official ncnn apple-vulkan release.
#
# The prebuilt archive is fetched by the prepare_command into
# build/ncnn-apple-vulkan/ and vendored via vendored_frameworks.
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
  s.osx.deployment_target  = "10.15"

  ncnn_version = "20260526"
  ncnn_dir = "build/ncnn-apple-vulkan"

  s.prepare_command = <<-CMD
    mkdir -p build
    if [ ! -d "#{ncnn_dir}/ncnn.xcframework" ]; then
      curl -fL --retry 3 \
        "https://github.com/Tencent/ncnn/releases/download/#{ncnn_version}/ncnn-#{ncnn_version}-apple-vulkan.zip" \
        -o build/ncnn-apple-vulkan.zip
      unzip -qo build/ncnn-apple-vulkan.zip -d #{ncnn_dir}
      rm -f build/ncnn-apple-vulkan.zip
    fi
  CMD

  s.vendored_frameworks = [
    "#{ncnn_dir}/ncnn.xcframework",
    "#{ncnn_dir}/glslang.xcframework",
    "#{ncnn_dir}/openmp.xcframework",
  ]

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "",
  }

  s.user_target_xcconfig = { "OTHER_LDFLAGS" => "-force_load $(PODS_ROOT)/huji_ncnn/#{ncnn_dir}/ncnn.xcframework/macos-arm64_x86_64/ncnn.framework/ncnn" }

  s.source_files = "src/*.{h,cpp}"
  s.public_header_files = "src/huji_ncnn_api.h"
  s.compiler_flags = "-std=c++17 -fexceptions -frtti"
  s.requires_arc = false
end
