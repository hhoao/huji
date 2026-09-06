# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Suppress warnings for missing java.beans classes
# These classes are referenced by snakeyaml but are not available on Android
-dontwarn java.beans.BeanInfo
-dontwarn java.beans.FeatureDescriptor
-dontwarn java.beans.IntrospectionException
-dontwarn java.beans.Introspector
-dontwarn java.beans.PropertyDescriptor

# ffmpeg_kit_flutter_new: 避免 release 下 JNI/插件注册被混淆导致 path_provider 等 Pigeon channel 无法建立
# 参考: https://github.com/sk3llo/ffmpeg_kit_flutter/wiki/Common-Bugfixes 与 PR #133 / issue #129
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }

# onnxruntime: native 层通过 JNI 按签名反射调用 OnnxModelMetadata 等构造器,
# R8 看不到 native 引用会将其混淆/移除, 导致 release 下 mid == null 直接 abort
# (debug 不混淆所以不复现)
-keep class ai.onnxruntime.** { *; }

