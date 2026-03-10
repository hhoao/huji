// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'autoclip_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoInfo {

 double get fps; double get duration; int get totalFrames; bool get isVfr; String get rFrameRateStr; String get avgFrameRateStr; double get rFrameRateVal; double get avgFrameRateVal; String get videoPath; String get videoFile; String get codecName; String get bitRate;
/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoInfoCopyWith<VideoInfo> get copyWith => _$VideoInfoCopyWithImpl<VideoInfo>(this as VideoInfo, _$identity);

  /// Serializes this VideoInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoInfo&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.totalFrames, totalFrames) || other.totalFrames == totalFrames)&&(identical(other.isVfr, isVfr) || other.isVfr == isVfr)&&(identical(other.rFrameRateStr, rFrameRateStr) || other.rFrameRateStr == rFrameRateStr)&&(identical(other.avgFrameRateStr, avgFrameRateStr) || other.avgFrameRateStr == avgFrameRateStr)&&(identical(other.rFrameRateVal, rFrameRateVal) || other.rFrameRateVal == rFrameRateVal)&&(identical(other.avgFrameRateVal, avgFrameRateVal) || other.avgFrameRateVal == avgFrameRateVal)&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.codecName, codecName) || other.codecName == codecName)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fps,duration,totalFrames,isVfr,rFrameRateStr,avgFrameRateStr,rFrameRateVal,avgFrameRateVal,videoPath,videoFile,codecName,bitRate);

@override
String toString() {
  return 'VideoInfo(fps: $fps, duration: $duration, totalFrames: $totalFrames, isVfr: $isVfr, rFrameRateStr: $rFrameRateStr, avgFrameRateStr: $avgFrameRateStr, rFrameRateVal: $rFrameRateVal, avgFrameRateVal: $avgFrameRateVal, videoPath: $videoPath, videoFile: $videoFile, codecName: $codecName, bitRate: $bitRate)';
}


}

/// @nodoc
abstract mixin class $VideoInfoCopyWith<$Res>  {
  factory $VideoInfoCopyWith(VideoInfo value, $Res Function(VideoInfo) _then) = _$VideoInfoCopyWithImpl;
@useResult
$Res call({
 double fps, double duration, int totalFrames, bool isVfr, String rFrameRateStr, String avgFrameRateStr, double rFrameRateVal, double avgFrameRateVal, String videoPath, String videoFile, String codecName, String bitRate
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
@pragma('vm:prefer-inline') @override $Res call({Object? fps = null,Object? duration = null,Object? totalFrames = null,Object? isVfr = null,Object? rFrameRateStr = null,Object? avgFrameRateStr = null,Object? rFrameRateVal = null,Object? avgFrameRateVal = null,Object? videoPath = null,Object? videoFile = null,Object? codecName = null,Object? bitRate = null,}) {
  return _then(_self.copyWith(
fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,totalFrames: null == totalFrames ? _self.totalFrames : totalFrames // ignore: cast_nullable_to_non_nullable
as int,isVfr: null == isVfr ? _self.isVfr : isVfr // ignore: cast_nullable_to_non_nullable
as bool,rFrameRateStr: null == rFrameRateStr ? _self.rFrameRateStr : rFrameRateStr // ignore: cast_nullable_to_non_nullable
as String,avgFrameRateStr: null == avgFrameRateStr ? _self.avgFrameRateStr : avgFrameRateStr // ignore: cast_nullable_to_non_nullable
as String,rFrameRateVal: null == rFrameRateVal ? _self.rFrameRateVal : rFrameRateVal // ignore: cast_nullable_to_non_nullable
as double,avgFrameRateVal: null == avgFrameRateVal ? _self.avgFrameRateVal : avgFrameRateVal // ignore: cast_nullable_to_non_nullable
as double,videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,videoFile: null == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as String,codecName: null == codecName ? _self.codecName : codecName // ignore: cast_nullable_to_non_nullable
as String,bitRate: null == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoInfo value)  $default,){
final _that = this;
switch (_that) {
case _VideoInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoInfo value)?  $default,){
final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double fps,  double duration,  int totalFrames,  bool isVfr,  String rFrameRateStr,  String avgFrameRateStr,  double rFrameRateVal,  double avgFrameRateVal,  String videoPath,  String videoFile,  String codecName,  String bitRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that.fps,_that.duration,_that.totalFrames,_that.isVfr,_that.rFrameRateStr,_that.avgFrameRateStr,_that.rFrameRateVal,_that.avgFrameRateVal,_that.videoPath,_that.videoFile,_that.codecName,_that.bitRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double fps,  double duration,  int totalFrames,  bool isVfr,  String rFrameRateStr,  String avgFrameRateStr,  double rFrameRateVal,  double avgFrameRateVal,  String videoPath,  String videoFile,  String codecName,  String bitRate)  $default,) {final _that = this;
switch (_that) {
case _VideoInfo():
return $default(_that.fps,_that.duration,_that.totalFrames,_that.isVfr,_that.rFrameRateStr,_that.avgFrameRateStr,_that.rFrameRateVal,_that.avgFrameRateVal,_that.videoPath,_that.videoFile,_that.codecName,_that.bitRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double fps,  double duration,  int totalFrames,  bool isVfr,  String rFrameRateStr,  String avgFrameRateStr,  double rFrameRateVal,  double avgFrameRateVal,  String videoPath,  String videoFile,  String codecName,  String bitRate)?  $default,) {final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that.fps,_that.duration,_that.totalFrames,_that.isVfr,_that.rFrameRateStr,_that.avgFrameRateStr,_that.rFrameRateVal,_that.avgFrameRateVal,_that.videoPath,_that.videoFile,_that.codecName,_that.bitRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoInfo implements VideoInfo {
  const _VideoInfo({required this.fps, required this.duration, required this.totalFrames, required this.isVfr, required this.rFrameRateStr, required this.avgFrameRateStr, required this.rFrameRateVal, required this.avgFrameRateVal, required this.videoPath, required this.videoFile, required this.codecName, required this.bitRate});
  factory _VideoInfo.fromJson(Map<String, dynamic> json) => _$VideoInfoFromJson(json);

@override final  double fps;
@override final  double duration;
@override final  int totalFrames;
@override final  bool isVfr;
@override final  String rFrameRateStr;
@override final  String avgFrameRateStr;
@override final  double rFrameRateVal;
@override final  double avgFrameRateVal;
@override final  String videoPath;
@override final  String videoFile;
@override final  String codecName;
@override final  String bitRate;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoInfoCopyWith<_VideoInfo> get copyWith => __$VideoInfoCopyWithImpl<_VideoInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoInfo&&(identical(other.fps, fps) || other.fps == fps)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.totalFrames, totalFrames) || other.totalFrames == totalFrames)&&(identical(other.isVfr, isVfr) || other.isVfr == isVfr)&&(identical(other.rFrameRateStr, rFrameRateStr) || other.rFrameRateStr == rFrameRateStr)&&(identical(other.avgFrameRateStr, avgFrameRateStr) || other.avgFrameRateStr == avgFrameRateStr)&&(identical(other.rFrameRateVal, rFrameRateVal) || other.rFrameRateVal == rFrameRateVal)&&(identical(other.avgFrameRateVal, avgFrameRateVal) || other.avgFrameRateVal == avgFrameRateVal)&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.codecName, codecName) || other.codecName == codecName)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fps,duration,totalFrames,isVfr,rFrameRateStr,avgFrameRateStr,rFrameRateVal,avgFrameRateVal,videoPath,videoFile,codecName,bitRate);

@override
String toString() {
  return 'VideoInfo(fps: $fps, duration: $duration, totalFrames: $totalFrames, isVfr: $isVfr, rFrameRateStr: $rFrameRateStr, avgFrameRateStr: $avgFrameRateStr, rFrameRateVal: $rFrameRateVal, avgFrameRateVal: $avgFrameRateVal, videoPath: $videoPath, videoFile: $videoFile, codecName: $codecName, bitRate: $bitRate)';
}


}

/// @nodoc
abstract mixin class _$VideoInfoCopyWith<$Res> implements $VideoInfoCopyWith<$Res> {
  factory _$VideoInfoCopyWith(_VideoInfo value, $Res Function(_VideoInfo) _then) = __$VideoInfoCopyWithImpl;
@override @useResult
$Res call({
 double fps, double duration, int totalFrames, bool isVfr, String rFrameRateStr, String avgFrameRateStr, double rFrameRateVal, double avgFrameRateVal, String videoPath, String videoFile, String codecName, String bitRate
});




}
/// @nodoc
class __$VideoInfoCopyWithImpl<$Res>
    implements _$VideoInfoCopyWith<$Res> {
  __$VideoInfoCopyWithImpl(this._self, this._then);

  final _VideoInfo _self;
  final $Res Function(_VideoInfo) _then;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fps = null,Object? duration = null,Object? totalFrames = null,Object? isVfr = null,Object? rFrameRateStr = null,Object? avgFrameRateStr = null,Object? rFrameRateVal = null,Object? avgFrameRateVal = null,Object? videoPath = null,Object? videoFile = null,Object? codecName = null,Object? bitRate = null,}) {
  return _then(_VideoInfo(
fps: null == fps ? _self.fps : fps // ignore: cast_nullable_to_non_nullable
as double,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,totalFrames: null == totalFrames ? _self.totalFrames : totalFrames // ignore: cast_nullable_to_non_nullable
as int,isVfr: null == isVfr ? _self.isVfr : isVfr // ignore: cast_nullable_to_non_nullable
as bool,rFrameRateStr: null == rFrameRateStr ? _self.rFrameRateStr : rFrameRateStr // ignore: cast_nullable_to_non_nullable
as String,avgFrameRateStr: null == avgFrameRateStr ? _self.avgFrameRateStr : avgFrameRateStr // ignore: cast_nullable_to_non_nullable
as String,rFrameRateVal: null == rFrameRateVal ? _self.rFrameRateVal : rFrameRateVal // ignore: cast_nullable_to_non_nullable
as double,avgFrameRateVal: null == avgFrameRateVal ? _self.avgFrameRateVal : avgFrameRateVal // ignore: cast_nullable_to_non_nullable
as double,videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,videoFile: null == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as String,codecName: null == codecName ? _self.codecName : codecName // ignore: cast_nullable_to_non_nullable
as String,bitRate: null == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SegmentInfo {

 ActionType get actionType; double get startSeconds; double get endSeconds;
/// Create a copy of SegmentInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentInfoCopyWith<SegmentInfo> get copyWith => _$SegmentInfoCopyWithImpl<SegmentInfo>(this as SegmentInfo, _$identity);

  /// Serializes this SegmentInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SegmentInfo&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.startSeconds, startSeconds) || other.startSeconds == startSeconds)&&(identical(other.endSeconds, endSeconds) || other.endSeconds == endSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionType,startSeconds,endSeconds);

@override
String toString() {
  return 'SegmentInfo(actionType: $actionType, startSeconds: $startSeconds, endSeconds: $endSeconds)';
}


}

/// @nodoc
abstract mixin class $SegmentInfoCopyWith<$Res>  {
  factory $SegmentInfoCopyWith(SegmentInfo value, $Res Function(SegmentInfo) _then) = _$SegmentInfoCopyWithImpl;
@useResult
$Res call({
 ActionType actionType, double startSeconds, double endSeconds
});




}
/// @nodoc
class _$SegmentInfoCopyWithImpl<$Res>
    implements $SegmentInfoCopyWith<$Res> {
  _$SegmentInfoCopyWithImpl(this._self, this._then);

  final SegmentInfo _self;
  final $Res Function(SegmentInfo) _then;

/// Create a copy of SegmentInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionType = null,Object? startSeconds = null,Object? endSeconds = null,}) {
  return _then(_self.copyWith(
actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType,startSeconds: null == startSeconds ? _self.startSeconds : startSeconds // ignore: cast_nullable_to_non_nullable
as double,endSeconds: null == endSeconds ? _self.endSeconds : endSeconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SegmentInfo].
extension SegmentInfoPatterns on SegmentInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SegmentInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SegmentInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SegmentInfo value)  $default,){
final _that = this;
switch (_that) {
case _SegmentInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SegmentInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SegmentInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ActionType actionType,  double startSeconds,  double endSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SegmentInfo() when $default != null:
return $default(_that.actionType,_that.startSeconds,_that.endSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ActionType actionType,  double startSeconds,  double endSeconds)  $default,) {final _that = this;
switch (_that) {
case _SegmentInfo():
return $default(_that.actionType,_that.startSeconds,_that.endSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ActionType actionType,  double startSeconds,  double endSeconds)?  $default,) {final _that = this;
switch (_that) {
case _SegmentInfo() when $default != null:
return $default(_that.actionType,_that.startSeconds,_that.endSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SegmentInfo implements SegmentInfo {
  const _SegmentInfo({required this.actionType, required this.startSeconds, required this.endSeconds});
  factory _SegmentInfo.fromJson(Map<String, dynamic> json) => _$SegmentInfoFromJson(json);

@override final  ActionType actionType;
@override final  double startSeconds;
@override final  double endSeconds;

/// Create a copy of SegmentInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SegmentInfoCopyWith<_SegmentInfo> get copyWith => __$SegmentInfoCopyWithImpl<_SegmentInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SegmentInfo&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.startSeconds, startSeconds) || other.startSeconds == startSeconds)&&(identical(other.endSeconds, endSeconds) || other.endSeconds == endSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionType,startSeconds,endSeconds);

@override
String toString() {
  return 'SegmentInfo(actionType: $actionType, startSeconds: $startSeconds, endSeconds: $endSeconds)';
}


}

/// @nodoc
abstract mixin class _$SegmentInfoCopyWith<$Res> implements $SegmentInfoCopyWith<$Res> {
  factory _$SegmentInfoCopyWith(_SegmentInfo value, $Res Function(_SegmentInfo) _then) = __$SegmentInfoCopyWithImpl;
@override @useResult
$Res call({
 ActionType actionType, double startSeconds, double endSeconds
});




}
/// @nodoc
class __$SegmentInfoCopyWithImpl<$Res>
    implements _$SegmentInfoCopyWith<$Res> {
  __$SegmentInfoCopyWithImpl(this._self, this._then);

  final _SegmentInfo _self;
  final $Res Function(_SegmentInfo) _then;

/// Create a copy of SegmentInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionType = null,Object? startSeconds = null,Object? endSeconds = null,}) {
  return _then(_SegmentInfo(
actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType,startSeconds: null == startSeconds ? _self.startSeconds : startSeconds // ignore: cast_nullable_to_non_nullable
as double,endSeconds: null == endSeconds ? _self.endSeconds : endSeconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PredictedFrameInfo {

 ActionType get actionType; double get seconds;
/// Create a copy of PredictedFrameInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredictedFrameInfoCopyWith<PredictedFrameInfo> get copyWith => _$PredictedFrameInfoCopyWithImpl<PredictedFrameInfo>(this as PredictedFrameInfo, _$identity);

  /// Serializes this PredictedFrameInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredictedFrameInfo&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.seconds, seconds) || other.seconds == seconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionType,seconds);

@override
String toString() {
  return 'PredictedFrameInfo(actionType: $actionType, seconds: $seconds)';
}


}

/// @nodoc
abstract mixin class $PredictedFrameInfoCopyWith<$Res>  {
  factory $PredictedFrameInfoCopyWith(PredictedFrameInfo value, $Res Function(PredictedFrameInfo) _then) = _$PredictedFrameInfoCopyWithImpl;
@useResult
$Res call({
 ActionType actionType, double seconds
});




}
/// @nodoc
class _$PredictedFrameInfoCopyWithImpl<$Res>
    implements $PredictedFrameInfoCopyWith<$Res> {
  _$PredictedFrameInfoCopyWithImpl(this._self, this._then);

  final PredictedFrameInfo _self;
  final $Res Function(PredictedFrameInfo) _then;

/// Create a copy of PredictedFrameInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actionType = null,Object? seconds = null,}) {
  return _then(_self.copyWith(
actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PredictedFrameInfo].
extension PredictedFrameInfoPatterns on PredictedFrameInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredictedFrameInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredictedFrameInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredictedFrameInfo value)  $default,){
final _that = this;
switch (_that) {
case _PredictedFrameInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredictedFrameInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PredictedFrameInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ActionType actionType,  double seconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredictedFrameInfo() when $default != null:
return $default(_that.actionType,_that.seconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ActionType actionType,  double seconds)  $default,) {final _that = this;
switch (_that) {
case _PredictedFrameInfo():
return $default(_that.actionType,_that.seconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ActionType actionType,  double seconds)?  $default,) {final _that = this;
switch (_that) {
case _PredictedFrameInfo() when $default != null:
return $default(_that.actionType,_that.seconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredictedFrameInfo implements PredictedFrameInfo {
  const _PredictedFrameInfo({required this.actionType, required this.seconds});
  factory _PredictedFrameInfo.fromJson(Map<String, dynamic> json) => _$PredictedFrameInfoFromJson(json);

@override final  ActionType actionType;
@override final  double seconds;

/// Create a copy of PredictedFrameInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredictedFrameInfoCopyWith<_PredictedFrameInfo> get copyWith => __$PredictedFrameInfoCopyWithImpl<_PredictedFrameInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredictedFrameInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredictedFrameInfo&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.seconds, seconds) || other.seconds == seconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,actionType,seconds);

@override
String toString() {
  return 'PredictedFrameInfo(actionType: $actionType, seconds: $seconds)';
}


}

/// @nodoc
abstract mixin class _$PredictedFrameInfoCopyWith<$Res> implements $PredictedFrameInfoCopyWith<$Res> {
  factory _$PredictedFrameInfoCopyWith(_PredictedFrameInfo value, $Res Function(_PredictedFrameInfo) _then) = __$PredictedFrameInfoCopyWithImpl;
@override @useResult
$Res call({
 ActionType actionType, double seconds
});




}
/// @nodoc
class __$PredictedFrameInfoCopyWithImpl<$Res>
    implements _$PredictedFrameInfoCopyWith<$Res> {
  __$PredictedFrameInfoCopyWithImpl(this._self, this._then);

  final _PredictedFrameInfo _self;
  final $Res Function(_PredictedFrameInfo) _then;

/// Create a copy of PredictedFrameInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actionType = null,Object? seconds = null,}) {
  return _then(_PredictedFrameInfo(
actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as ActionType,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$VideoBaseInfo {

 double get duration; int get size;
/// Create a copy of VideoBaseInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoBaseInfoCopyWith<VideoBaseInfo> get copyWith => _$VideoBaseInfoCopyWithImpl<VideoBaseInfo>(this as VideoBaseInfo, _$identity);

  /// Serializes this VideoBaseInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoBaseInfo&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,duration,size);

@override
String toString() {
  return 'VideoBaseInfo(duration: $duration, size: $size)';
}


}

/// @nodoc
abstract mixin class $VideoBaseInfoCopyWith<$Res>  {
  factory $VideoBaseInfoCopyWith(VideoBaseInfo value, $Res Function(VideoBaseInfo) _then) = _$VideoBaseInfoCopyWithImpl;
@useResult
$Res call({
 double duration, int size
});




}
/// @nodoc
class _$VideoBaseInfoCopyWithImpl<$Res>
    implements $VideoBaseInfoCopyWith<$Res> {
  _$VideoBaseInfoCopyWithImpl(this._self, this._then);

  final VideoBaseInfo _self;
  final $Res Function(VideoBaseInfo) _then;

/// Create a copy of VideoBaseInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? size = null,}) {
  return _then(_self.copyWith(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoBaseInfo].
extension VideoBaseInfoPatterns on VideoBaseInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoBaseInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoBaseInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoBaseInfo value)  $default,){
final _that = this;
switch (_that) {
case _VideoBaseInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoBaseInfo value)?  $default,){
final _that = this;
switch (_that) {
case _VideoBaseInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double duration,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoBaseInfo() when $default != null:
return $default(_that.duration,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double duration,  int size)  $default,) {final _that = this;
switch (_that) {
case _VideoBaseInfo():
return $default(_that.duration,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double duration,  int size)?  $default,) {final _that = this;
switch (_that) {
case _VideoBaseInfo() when $default != null:
return $default(_that.duration,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoBaseInfo implements VideoBaseInfo {
  const _VideoBaseInfo({required this.duration, required this.size});
  factory _VideoBaseInfo.fromJson(Map<String, dynamic> json) => _$VideoBaseInfoFromJson(json);

@override final  double duration;
@override final  int size;

/// Create a copy of VideoBaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoBaseInfoCopyWith<_VideoBaseInfo> get copyWith => __$VideoBaseInfoCopyWithImpl<_VideoBaseInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoBaseInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoBaseInfo&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,duration,size);

@override
String toString() {
  return 'VideoBaseInfo(duration: $duration, size: $size)';
}


}

/// @nodoc
abstract mixin class _$VideoBaseInfoCopyWith<$Res> implements $VideoBaseInfoCopyWith<$Res> {
  factory _$VideoBaseInfoCopyWith(_VideoBaseInfo value, $Res Function(_VideoBaseInfo) _then) = __$VideoBaseInfoCopyWithImpl;
@override @useResult
$Res call({
 double duration, int size
});




}
/// @nodoc
class __$VideoBaseInfoCopyWithImpl<$Res>
    implements _$VideoBaseInfoCopyWith<$Res> {
  __$VideoBaseInfoCopyWithImpl(this._self, this._then);

  final _VideoBaseInfo _self;
  final $Res Function(_VideoBaseInfo) _then;

/// Create a copy of VideoBaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? size = null,}) {
  return _then(_VideoBaseInfo(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VideoClipOutputInfo {

 List<Map<ActionType, SegmentInfo>> get allMatchSegments; List<Map<ActionType, SegmentInfo>> get greatMatchSegments; VideoInfo get inputVideoInfo;
/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoClipOutputInfoCopyWith<VideoClipOutputInfo> get copyWith => _$VideoClipOutputInfoCopyWithImpl<VideoClipOutputInfo>(this as VideoClipOutputInfo, _$identity);

  /// Serializes this VideoClipOutputInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoClipOutputInfo&&const DeepCollectionEquality().equals(other.allMatchSegments, allMatchSegments)&&const DeepCollectionEquality().equals(other.greatMatchSegments, greatMatchSegments)&&(identical(other.inputVideoInfo, inputVideoInfo) || other.inputVideoInfo == inputVideoInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allMatchSegments),const DeepCollectionEquality().hash(greatMatchSegments),inputVideoInfo);

@override
String toString() {
  return 'VideoClipOutputInfo(allMatchSegments: $allMatchSegments, greatMatchSegments: $greatMatchSegments, inputVideoInfo: $inputVideoInfo)';
}


}

/// @nodoc
abstract mixin class $VideoClipOutputInfoCopyWith<$Res>  {
  factory $VideoClipOutputInfoCopyWith(VideoClipOutputInfo value, $Res Function(VideoClipOutputInfo) _then) = _$VideoClipOutputInfoCopyWithImpl;
@useResult
$Res call({
 List<Map<ActionType, SegmentInfo>> allMatchSegments, List<Map<ActionType, SegmentInfo>> greatMatchSegments, VideoInfo inputVideoInfo
});


$VideoInfoCopyWith<$Res> get inputVideoInfo;

}
/// @nodoc
class _$VideoClipOutputInfoCopyWithImpl<$Res>
    implements $VideoClipOutputInfoCopyWith<$Res> {
  _$VideoClipOutputInfoCopyWithImpl(this._self, this._then);

  final VideoClipOutputInfo _self;
  final $Res Function(VideoClipOutputInfo) _then;

/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allMatchSegments = null,Object? greatMatchSegments = null,Object? inputVideoInfo = null,}) {
  return _then(_self.copyWith(
allMatchSegments: null == allMatchSegments ? _self.allMatchSegments : allMatchSegments // ignore: cast_nullable_to_non_nullable
as List<Map<ActionType, SegmentInfo>>,greatMatchSegments: null == greatMatchSegments ? _self.greatMatchSegments : greatMatchSegments // ignore: cast_nullable_to_non_nullable
as List<Map<ActionType, SegmentInfo>>,inputVideoInfo: null == inputVideoInfo ? _self.inputVideoInfo : inputVideoInfo // ignore: cast_nullable_to_non_nullable
as VideoInfo,
  ));
}
/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoInfoCopyWith<$Res> get inputVideoInfo {
  
  return $VideoInfoCopyWith<$Res>(_self.inputVideoInfo, (value) {
    return _then(_self.copyWith(inputVideoInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoClipOutputInfo].
extension VideoClipOutputInfoPatterns on VideoClipOutputInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoClipOutputInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoClipOutputInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoClipOutputInfo value)  $default,){
final _that = this;
switch (_that) {
case _VideoClipOutputInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoClipOutputInfo value)?  $default,){
final _that = this;
switch (_that) {
case _VideoClipOutputInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Map<ActionType, SegmentInfo>> allMatchSegments,  List<Map<ActionType, SegmentInfo>> greatMatchSegments,  VideoInfo inputVideoInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoClipOutputInfo() when $default != null:
return $default(_that.allMatchSegments,_that.greatMatchSegments,_that.inputVideoInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Map<ActionType, SegmentInfo>> allMatchSegments,  List<Map<ActionType, SegmentInfo>> greatMatchSegments,  VideoInfo inputVideoInfo)  $default,) {final _that = this;
switch (_that) {
case _VideoClipOutputInfo():
return $default(_that.allMatchSegments,_that.greatMatchSegments,_that.inputVideoInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Map<ActionType, SegmentInfo>> allMatchSegments,  List<Map<ActionType, SegmentInfo>> greatMatchSegments,  VideoInfo inputVideoInfo)?  $default,) {final _that = this;
switch (_that) {
case _VideoClipOutputInfo() when $default != null:
return $default(_that.allMatchSegments,_that.greatMatchSegments,_that.inputVideoInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoClipOutputInfo implements VideoClipOutputInfo {
  const _VideoClipOutputInfo({required final  List<Map<ActionType, SegmentInfo>> allMatchSegments, required final  List<Map<ActionType, SegmentInfo>> greatMatchSegments, required this.inputVideoInfo}): _allMatchSegments = allMatchSegments,_greatMatchSegments = greatMatchSegments;
  factory _VideoClipOutputInfo.fromJson(Map<String, dynamic> json) => _$VideoClipOutputInfoFromJson(json);

 final  List<Map<ActionType, SegmentInfo>> _allMatchSegments;
@override List<Map<ActionType, SegmentInfo>> get allMatchSegments {
  if (_allMatchSegments is EqualUnmodifiableListView) return _allMatchSegments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMatchSegments);
}

 final  List<Map<ActionType, SegmentInfo>> _greatMatchSegments;
@override List<Map<ActionType, SegmentInfo>> get greatMatchSegments {
  if (_greatMatchSegments is EqualUnmodifiableListView) return _greatMatchSegments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_greatMatchSegments);
}

@override final  VideoInfo inputVideoInfo;

/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoClipOutputInfoCopyWith<_VideoClipOutputInfo> get copyWith => __$VideoClipOutputInfoCopyWithImpl<_VideoClipOutputInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoClipOutputInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoClipOutputInfo&&const DeepCollectionEquality().equals(other._allMatchSegments, _allMatchSegments)&&const DeepCollectionEquality().equals(other._greatMatchSegments, _greatMatchSegments)&&(identical(other.inputVideoInfo, inputVideoInfo) || other.inputVideoInfo == inputVideoInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allMatchSegments),const DeepCollectionEquality().hash(_greatMatchSegments),inputVideoInfo);

@override
String toString() {
  return 'VideoClipOutputInfo(allMatchSegments: $allMatchSegments, greatMatchSegments: $greatMatchSegments, inputVideoInfo: $inputVideoInfo)';
}


}

/// @nodoc
abstract mixin class _$VideoClipOutputInfoCopyWith<$Res> implements $VideoClipOutputInfoCopyWith<$Res> {
  factory _$VideoClipOutputInfoCopyWith(_VideoClipOutputInfo value, $Res Function(_VideoClipOutputInfo) _then) = __$VideoClipOutputInfoCopyWithImpl;
@override @useResult
$Res call({
 List<Map<ActionType, SegmentInfo>> allMatchSegments, List<Map<ActionType, SegmentInfo>> greatMatchSegments, VideoInfo inputVideoInfo
});


@override $VideoInfoCopyWith<$Res> get inputVideoInfo;

}
/// @nodoc
class __$VideoClipOutputInfoCopyWithImpl<$Res>
    implements _$VideoClipOutputInfoCopyWith<$Res> {
  __$VideoClipOutputInfoCopyWithImpl(this._self, this._then);

  final _VideoClipOutputInfo _self;
  final $Res Function(_VideoClipOutputInfo) _then;

/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allMatchSegments = null,Object? greatMatchSegments = null,Object? inputVideoInfo = null,}) {
  return _then(_VideoClipOutputInfo(
allMatchSegments: null == allMatchSegments ? _self._allMatchSegments : allMatchSegments // ignore: cast_nullable_to_non_nullable
as List<Map<ActionType, SegmentInfo>>,greatMatchSegments: null == greatMatchSegments ? _self._greatMatchSegments : greatMatchSegments // ignore: cast_nullable_to_non_nullable
as List<Map<ActionType, SegmentInfo>>,inputVideoInfo: null == inputVideoInfo ? _self.inputVideoInfo : inputVideoInfo // ignore: cast_nullable_to_non_nullable
as VideoInfo,
  ));
}

/// Create a copy of VideoClipOutputInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoInfoCopyWith<$Res> get inputVideoInfo {
  
  return $VideoInfoCopyWith<$Res>(_self.inputVideoInfo, (value) {
    return _then(_self.copyWith(inputVideoInfo: value));
  });
}
}


/// @nodoc
mixin _$SegmentDetectorConfig {

 double get intervalSeconds; int get windowCount;
/// Create a copy of SegmentDetectorConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentDetectorConfigCopyWith<SegmentDetectorConfig> get copyWith => _$SegmentDetectorConfigCopyWithImpl<SegmentDetectorConfig>(this as SegmentDetectorConfig, _$identity);

  /// Serializes this SegmentDetectorConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SegmentDetectorConfig&&(identical(other.intervalSeconds, intervalSeconds) || other.intervalSeconds == intervalSeconds)&&(identical(other.windowCount, windowCount) || other.windowCount == windowCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalSeconds,windowCount);

@override
String toString() {
  return 'SegmentDetectorConfig(intervalSeconds: $intervalSeconds, windowCount: $windowCount)';
}


}

/// @nodoc
abstract mixin class $SegmentDetectorConfigCopyWith<$Res>  {
  factory $SegmentDetectorConfigCopyWith(SegmentDetectorConfig value, $Res Function(SegmentDetectorConfig) _then) = _$SegmentDetectorConfigCopyWithImpl;
@useResult
$Res call({
 double intervalSeconds, int windowCount
});




}
/// @nodoc
class _$SegmentDetectorConfigCopyWithImpl<$Res>
    implements $SegmentDetectorConfigCopyWith<$Res> {
  _$SegmentDetectorConfigCopyWithImpl(this._self, this._then);

  final SegmentDetectorConfig _self;
  final $Res Function(SegmentDetectorConfig) _then;

/// Create a copy of SegmentDetectorConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intervalSeconds = null,Object? windowCount = null,}) {
  return _then(_self.copyWith(
intervalSeconds: null == intervalSeconds ? _self.intervalSeconds : intervalSeconds // ignore: cast_nullable_to_non_nullable
as double,windowCount: null == windowCount ? _self.windowCount : windowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SegmentDetectorConfig].
extension SegmentDetectorConfigPatterns on SegmentDetectorConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SegmentDetectorConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SegmentDetectorConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SegmentDetectorConfig value)  $default,){
final _that = this;
switch (_that) {
case _SegmentDetectorConfig():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SegmentDetectorConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SegmentDetectorConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double intervalSeconds,  int windowCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SegmentDetectorConfig() when $default != null:
return $default(_that.intervalSeconds,_that.windowCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double intervalSeconds,  int windowCount)  $default,) {final _that = this;
switch (_that) {
case _SegmentDetectorConfig():
return $default(_that.intervalSeconds,_that.windowCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double intervalSeconds,  int windowCount)?  $default,) {final _that = this;
switch (_that) {
case _SegmentDetectorConfig() when $default != null:
return $default(_that.intervalSeconds,_that.windowCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SegmentDetectorConfig implements SegmentDetectorConfig {
  const _SegmentDetectorConfig({required this.intervalSeconds, required this.windowCount});
  factory _SegmentDetectorConfig.fromJson(Map<String, dynamic> json) => _$SegmentDetectorConfigFromJson(json);

@override final  double intervalSeconds;
@override final  int windowCount;

/// Create a copy of SegmentDetectorConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SegmentDetectorConfigCopyWith<_SegmentDetectorConfig> get copyWith => __$SegmentDetectorConfigCopyWithImpl<_SegmentDetectorConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentDetectorConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SegmentDetectorConfig&&(identical(other.intervalSeconds, intervalSeconds) || other.intervalSeconds == intervalSeconds)&&(identical(other.windowCount, windowCount) || other.windowCount == windowCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalSeconds,windowCount);

@override
String toString() {
  return 'SegmentDetectorConfig(intervalSeconds: $intervalSeconds, windowCount: $windowCount)';
}


}

/// @nodoc
abstract mixin class _$SegmentDetectorConfigCopyWith<$Res> implements $SegmentDetectorConfigCopyWith<$Res> {
  factory _$SegmentDetectorConfigCopyWith(_SegmentDetectorConfig value, $Res Function(_SegmentDetectorConfig) _then) = __$SegmentDetectorConfigCopyWithImpl;
@override @useResult
$Res call({
 double intervalSeconds, int windowCount
});




}
/// @nodoc
class __$SegmentDetectorConfigCopyWithImpl<$Res>
    implements _$SegmentDetectorConfigCopyWith<$Res> {
  __$SegmentDetectorConfigCopyWithImpl(this._self, this._then);

  final _SegmentDetectorConfig _self;
  final $Res Function(_SegmentDetectorConfig) _then;

/// Create a copy of SegmentDetectorConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intervalSeconds = null,Object? windowCount = null,}) {
  return _then(_SegmentDetectorConfig(
intervalSeconds: null == intervalSeconds ? _self.intervalSeconds : intervalSeconds // ignore: cast_nullable_to_non_nullable
as double,windowCount: null == windowCount ? _self.windowCount : windowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
