#
# huji_ncnn — iOS: ncnn (Vulkan via MoltenVK discovery) static frameworks
# from the official ncnn ios-vulkan release.
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

  s.prepare_command = <<-CMD
    mkdir -p build
    if [ ! -d "#{ncnn_dir}/ncnn.framework" ]; then
      curl -fL --retry 3 \
        "https://github.com/Tencent/ncnn/releases/download/#{ncnn_version}/ncnn-#{ncnn_version}-ios-vulkan.zip" \
        -o build/ncnn-ios-vulkan.zip
      unzip -qo build/ncnn-ios-vulkan.zip -d #{ncnn_dir}
      rm -f build/ncnn-ios-vulkan.zip
    fi
  CMD

  s.vendored_frameworks = [
    "#{ncnn_dir}/ncnn.framework",
    "#{ncnn_dir}/glslang.framework",
    "#{ncnn_dir}/openmp.framework",
  ]

  s.pod_target_xcconfig = { "DEFINES_MODULE" => "YES" }
  s.compiler_flags = "-std=c++17 -fexceptions -frtti"
  s.source_files = "src/*.{h,cpp}"
  s.public_header_files = "src/huji_ncnn_api.h"
  s.requires_arc = false
end
