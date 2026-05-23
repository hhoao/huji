// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ffmpeg.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoCompressConfig {

 VideoCompressQuality get quality; VideoCompressPreset get preset; int? get customBitrate;// 自定义比特率 (kbps)
 int? get customWidth;// 自定义宽度
 int? get customHeight;// 自定义高度
 bool get includeAudio;// 是否包含音频
 String? get outputPath;// 输出路径
 String? get outputFileName;// 输出文件名
 bool get keepAspectRatio;// 保持宽高比
 bool get optimizeForWeb;// 优化网络播放
 int? get maxFileSize;
/// Create a copy of VideoCompressConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCompressConfigCopyWith<VideoCompressConfig> get copyWith => _$VideoCompressConfigCopyWithImpl<VideoCompressConfig>(this as VideoCompressConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoCompressConfig&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.customBitrate, customBitrate) || other.customBitrate == customBitrate)&&(identical(other.customWidth, customWidth) || other.customWidth == customWidth)&&(identical(other.customHeight, customHeight) || other.customHeight == customHeight)&&(identical(other.includeAudio, includeAudio) || other.includeAudio == includeAudio)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.outputFileName, outputFileName) || other.outputFileName == outputFileName)&&(identical(other.keepAspectRatio, keepAspectRatio) || other.keepAspectRatio == keepAspectRatio)&&(identical(other.optimizeForWeb, optimizeForWeb) || other.optimizeForWeb == optimizeForWeb)&&(identical(other.maxFileSize, maxFileSize) || other.maxFileSize == maxFileSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quality,preset,customBitrate,customWidth,customHeight,includeAudio,outputPath,outputFileName,keepAspectRatio,optimizeForWeb,maxFileSize);

@override
String toString() {
  return 'VideoCompressConfig(quality: $quality, preset: $preset, customBitrate: $customBitrate, customWidth: $customWidth, customHeight: $customHeight, includeAudio: $includeAudio, outputPath: $outputPath, outputFileName: $outputFileName, keepAspectRatio: $keepAspectRatio, optimizeForWeb: $optimizeForWeb, maxFileSize: $maxFileSize)';
}


}

/// @nodoc
abstract mixin class $VideoCompressConfigCopyWith<$Res>  {
  factory $VideoCompressConfigCopyWith(VideoCompressConfig value, $Res Function(VideoCompressConfig) _then) = _$VideoCompressConfigCopyWithImpl;
@useResult
$Res call({
 VideoCompressQuality quality, VideoCompressPreset preset, int? customBitrate, int? customWidth, int? customHeight, bool includeAudio, String? outputPath, String? outputFileName, bool keepAspectRatio, bool optimizeForWeb, int? maxFileSize
});




}
/// @nodoc
class _$VideoCompressConfigCopyWithImpl<$Res>
    implements $VideoCompressConfigCopyWith<$Res> {
  _$VideoCompressConfigCopyWithImpl(this._self, this._then);

  final VideoCompressConfig _self;
  final $Res Function(VideoCompressConfig) _then;

/// Create a copy of VideoCompressConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quality = null,Object? preset = null,Object? customBitrate = freezed,Object? customWidth = freezed,Object? customHeight = freezed,Object? includeAudio = null,Object? outputPath = freezed,Object? outputFileName = freezed,Object? keepAspectRatio = null,Object? optimizeForWeb = null,Object? maxFileSize = freezed,}) {
  return _then(VideoCompressConfig(
quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as VideoCompressQuality,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as VideoCompressPreset,customBitrate: freezed == customBitrate ? _self.customBitrate : customBitrate // ignore: cast_nullable_to_non_nullable
as int?,customWidth: freezed == customWidth ? _self.customWidth : customWidth // ignore: cast_nullable_to_non_nullable
as int?,customHeight: freezed == customHeight ? _self.customHeight : customHeight // ignore: cast_nullable_to_non_nullable
as int?,includeAudio: null == includeAudio ? _self.includeAudio : includeAudio // ignore: cast_nullable_to_non_nullable
as bool,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,outputFileName: freezed == outputFileName ? _self.outputFileName : outputFileName // ignore: cast_nullable_to_non_nullable
as String?,keepAspectRatio: null == keepAspectRatio ? _self.keepAspectRatio : keepAspectRatio // ignore: cast_nullable_to_non_nullable
as bool,optimizeForWeb: null == optimizeForWeb ? _self.optimizeForWeb : optimizeForWeb // ignore: cast_nullable_to_non_nullable
as bool,maxFileSize: freezed == maxFileSize ? _self.maxFileSize : maxFileSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoCompressConfig].
extension VideoCompressConfigPatterns on VideoCompressConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$VideoCompressResult {

 bool get success; String? get outputPath; String? get errorMessage; int? get originalSize; int? get compressedSize; double? get compressionRatio; double? get originalDuration; double? get compressedDuration; Map<String, dynamic>? get originalInfo; Map<String, dynamic>? get compressedInfo; double? get processingTime;
/// Create a copy of VideoCompressResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCompressResultCopyWith<VideoCompressResult> get copyWith => _$VideoCompressResultCopyWithImpl<VideoCompressResult>(this as VideoCompressResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoCompressResult&&(identical(other.success, success) || other.success == success)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.originalSize, originalSize) || other.originalSize == originalSize)&&(identical(other.compressedSize, compressedSize) || other.compressedSize == compressedSize)&&(identical(other.compressionRatio, compressionRatio) || other.compressionRatio == compressionRatio)&&(identical(other.originalDuration, originalDuration) || other.originalDuration == originalDuration)&&(identical(other.compressedDuration, compressedDuration) || other.compressedDuration == compressedDuration)&&const DeepCollectionEquality().equals(other.originalInfo, originalInfo)&&const DeepCollectionEquality().equals(other.compressedInfo, compressedInfo)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,outputPath,errorMessage,originalSize,compressedSize,compressionRatio,originalDuration,compressedDuration,const DeepCollectionEquality().hash(originalInfo),const DeepCollectionEquality().hash(compressedInfo),processingTime);

@override
String toString() {
  return 'VideoCompressResult(success: $success, outputPath: $outputPath, errorMessage: $errorMessage, originalSize: $originalSize, compressedSize: $compressedSize, compressionRatio: $compressionRatio, originalDuration: $originalDuration, compressedDuration: $compressedDuration, originalInfo: $originalInfo, compressedInfo: $compressedInfo, processingTime: $processingTime)';
}


}

/// @nodoc
abstract mixin class $VideoCompressResultCopyWith<$Res>  {
  factory $VideoCompressResultCopyWith(VideoCompressResult value, $Res Function(VideoCompressResult) _then) = _$VideoCompressResultCopyWithImpl;
@useResult
$Res call({
 bool success, String? outputPath, String? errorMessage, int? originalSize, int? compressedSize, double? compressionRatio, double? originalDuration, double? compressedDuration, Map<String, dynamic>? originalInfo, Map<String, dynamic>? compressedInfo, double? processingTime
});




}
/// @nodoc
class _$VideoCompressResultCopyWithImpl<$Res>
    implements $VideoCompressResultCopyWith<$Res> {
  _$VideoCompressResultCopyWithImpl(this._self, this._then);

  final VideoCompressResult _self;
  final $Res Function(VideoCompressResult) _then;

/// Create a copy of VideoCompressResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? outputPath = freezed,Object? errorMessage = freezed,Object? originalSize = freezed,Object? compressedSize = freezed,Object? compressionRatio = freezed,Object? originalDuration = freezed,Object? compressedDuration = freezed,Object? originalInfo = freezed,Object? compressedInfo = freezed,Object? processingTime = freezed,}) {
  return _then(VideoCompressResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,originalSize: freezed == originalSize ? _self.originalSize : originalSize // ignore: cast_nullable_to_non_nullable
as int?,compressedSize: freezed == compressedSize ? _self.compressedSize : compressedSize // ignore: cast_nullable_to_non_nullable
as int?,compressionRatio: freezed == compressionRatio ? _self.compressionRatio : compressionRatio // ignore: cast_nullable_to_non_nullable
as double?,originalDuration: freezed == originalDuration ? _self.originalDuration : originalDuration // ignore: cast_nullable_to_non_nullable
as double?,compressedDuration: freezed == compressedDuration ? _self.compressedDuration : compressedDuration // ignore: cast_nullable_to_non_nullable
as double?,originalInfo: freezed == originalInfo ? _self.originalInfo : originalInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,compressedInfo: freezed == compressedInfo ? _self.compressedInfo : compressedInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,processingTime: freezed == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoCompressResult].
extension VideoCompressResultPatterns on VideoCompressResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$VideoInfo {

// seconds
 double get duration; int get width; int get height; String get videoCodec; String? get audioCodec; int get bitrate; double get fps; int get fileSize; String get format;
/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoInfoCopyWith<VideoInfo> get copyWith => _$VideoInfoCopyWithImpl<VideoInfo>(this as VideoInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoInfo&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.videoCodec, videoCodec) || other.videoCodec == videoCodec)&&(identical(other.audioCodec, audioCodec) || other.audioCodec == audioCodec)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.format, format) || other.format == format));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,duration,width,height,videoCodec,audioCodec,bitrate,fps,fileSize,format);

@override
String toString() {
  return 'VideoInfo(duration: $duration, width: $width, height: $height, videoCodec: $videoCodec, audioCodec: $audioCodec, bitrate: $bitrate, fps: $fps, fileSize: $fileSize, format: $format)';
}


}

/// @nodoc
abstract mixin class $VideoInfoCopyWith<$Res>  {
  factory $VideoInfoCopyWith(VideoInfo value, $Res Function(VideoInfo) _then) = _$VideoInfoCopyWithImpl;
@useResult
$Res call({
 double duration, int width, int height, String videoCodec, String? audioCodec, int bitrate, double fps, int fileSize, String format
});




}
/// @nodoc
class _$VideoInfoCopyWithImpl<$Res>
    implements $VideoInfoCopyWith<$Res> {
  _$VideoInfoCopyWithImpl(this._self, this._then);

  final VideoInfo _self;
  final $Res Function(VideoInfo) _then;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? width = null,Object? height = null,Object? videoCodec = null,Object? audioCodec = freezed,Object? bitrate = null,Object? fps = null,Object? fileSize = null,Object? format = null,}) {
  return _then(VideoInfo(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,videoCodec: null == videoCodec ? _self.videoCodec : videoCodec // ignore: cast_nullable_to_non_nullable
as String,audioCodec: freezed == audioCodec ? _self.audioCodec : audioCodec // ignore: cast_nullable_to_non_nullable
as String?,bitrate: null == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int,fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoInfo].
extension VideoInfoPatterns on VideoInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
