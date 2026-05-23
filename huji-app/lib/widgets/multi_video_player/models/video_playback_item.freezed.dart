// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_playback_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoPlaybackItem {

/// 视频文件路径
 String get videoPath;/// 开始播放时间点（毫秒），默认为0
 int get startTimeMs;/// 结束播放时间点（毫秒），如果为null则播放到视频结尾
 int? get endTimeMs;/// 视频总时长（毫秒），用于计算结束时间
 int get totalDurationMs;/// 播放项ID
 String get id;/// 播放项名称
 String get name;/// 是否启用此播放项
 bool get enabled;
/// Create a copy of VideoPlaybackItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoPlaybackItemCopyWith<VideoPlaybackItem> get copyWith => _$VideoPlaybackItemCopyWithImpl<VideoPlaybackItem>(this as VideoPlaybackItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoPlaybackItem&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.startTimeMs, startTimeMs) || other.startTimeMs == startTimeMs)&&(identical(other.endTimeMs, endTimeMs) || other.endTimeMs == endTimeMs)&&(identical(other.totalDurationMs, totalDurationMs) || other.totalDurationMs == totalDurationMs)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,videoPath,startTimeMs,endTimeMs,totalDurationMs,id,name,enabled);

@override
String toString() {
  return 'VideoPlaybackItem(videoPath: $videoPath, startTimeMs: $startTimeMs, endTimeMs: $endTimeMs, totalDurationMs: $totalDurationMs, id: $id, name: $name, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $VideoPlaybackItemCopyWith<$Res>  {
  factory $VideoPlaybackItemCopyWith(VideoPlaybackItem value, $Res Function(VideoPlaybackItem) _then) = _$VideoPlaybackItemCopyWithImpl;
@useResult
$Res call({
 String videoPath, int startTimeMs, int? endTimeMs, int totalDurationMs, String id, String name, bool enabled
});




}
/// @nodoc
class _$VideoPlaybackItemCopyWithImpl<$Res>
    implements $VideoPlaybackItemCopyWith<$Res> {
  _$VideoPlaybackItemCopyWithImpl(this._self, this._then);

  final VideoPlaybackItem _self;
  final $Res Function(VideoPlaybackItem) _then;

/// Create a copy of VideoPlaybackItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoPath = null,Object? startTimeMs = null,Object? endTimeMs = freezed,Object? totalDurationMs = null,Object? id = null,Object? name = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,startTimeMs: null == startTimeMs ? _self.startTimeMs : startTimeMs // ignore: cast_nullable_to_non_nullable
as int,endTimeMs: freezed == endTimeMs ? _self.endTimeMs : endTimeMs // ignore: cast_nullable_to_non_nullable
as int?,totalDurationMs: null == totalDurationMs ? _self.totalDurationMs : totalDurationMs // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoPlaybackItem].
extension VideoPlaybackItemPatterns on VideoPlaybackItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoPlaybackItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoPlaybackItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoPlaybackItem value)  $default,){
final _that = this;
switch (_that) {
case _VideoPlaybackItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoPlaybackItem value)?  $default,){
final _that = this;
switch (_that) {
case _VideoPlaybackItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String videoPath,  int startTimeMs,  int? endTimeMs,  int totalDurationMs,  String id,  String name,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoPlaybackItem() when $default != null:
return $default(_that.videoPath,_that.startTimeMs,_that.endTimeMs,_that.totalDurationMs,_that.id,_that.name,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String videoPath,  int startTimeMs,  int? endTimeMs,  int totalDurationMs,  String id,  String name,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _VideoPlaybackItem():
return $default(_that.videoPath,_that.startTimeMs,_that.endTimeMs,_that.totalDurationMs,_that.id,_that.name,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String videoPath,  int startTimeMs,  int? endTimeMs,  int totalDurationMs,  String id,  String name,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _VideoPlaybackItem() when $default != null:
return $default(_that.videoPath,_that.startTimeMs,_that.endTimeMs,_that.totalDurationMs,_that.id,_that.name,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _VideoPlaybackItem extends VideoPlaybackItem {
  const _VideoPlaybackItem({required this.videoPath, this.startTimeMs = 0, this.endTimeMs, required this.totalDurationMs, required this.id, required this.name, this.enabled = true}): super._();
  

/// 视频文件路径
@override final  String videoPath;
/// 开始播放时间点（毫秒），默认为0
@override@JsonKey() final  int startTimeMs;
/// 结束播放时间点（毫秒），如果为null则播放到视频结尾
@override final  int? endTimeMs;
/// 视频总时长（毫秒），用于计算结束时间
@override final  int totalDurationMs;
/// 播放项ID
@override final  String id;
/// 播放项名称
@override final  String name;
/// 是否启用此播放项
@override@JsonKey() final  bool enabled;

/// Create a copy of VideoPlaybackItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoPlaybackItemCopyWith<_VideoPlaybackItem> get copyWith => __$VideoPlaybackItemCopyWithImpl<_VideoPlaybackItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoPlaybackItem&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.startTimeMs, startTimeMs) || other.startTimeMs == startTimeMs)&&(identical(other.endTimeMs, endTimeMs) || other.endTimeMs == endTimeMs)&&(identical(other.totalDurationMs, totalDurationMs) || other.totalDurationMs == totalDurationMs)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,videoPath,startTimeMs,endTimeMs,totalDurationMs,id,name,enabled);

@override
String toString() {
  return 'VideoPlaybackItem(videoPath: $videoPath, startTimeMs: $startTimeMs, endTimeMs: $endTimeMs, totalDurationMs: $totalDurationMs, id: $id, name: $name, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$VideoPlaybackItemCopyWith<$Res> implements $VideoPlaybackItemCopyWith<$Res> {
  factory _$VideoPlaybackItemCopyWith(_VideoPlaybackItem value, $Res Function(_VideoPlaybackItem) _then) = __$VideoPlaybackItemCopyWithImpl;
@override @useResult
$Res call({
 String videoPath, int startTimeMs, int? endTimeMs, int totalDurationMs, String id, String name, bool enabled
});




}
/// @nodoc
class __$VideoPlaybackItemCopyWithImpl<$Res>
    implements _$VideoPlaybackItemCopyWith<$Res> {
  __$VideoPlaybackItemCopyWithImpl(this._self, this._then);

  final _VideoPlaybackItem _self;
  final $Res Function(_VideoPlaybackItem) _then;

/// Create a copy of VideoPlaybackItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoPath = null,Object? startTimeMs = null,Object? endTimeMs = freezed,Object? totalDurationMs = null,Object? id = null,Object? name = null,Object? enabled = null,}) {
  return _then(_VideoPlaybackItem(
videoPath: null == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String,startTimeMs: null == startTimeMs ? _self.startTimeMs : startTimeMs // ignore: cast_nullable_to_non_nullable
as int,endTimeMs: freezed == endTimeMs ? _self.endTimeMs : endTimeMs // ignore: cast_nullable_to_non_nullable
as int?,totalDurationMs: null == totalDurationMs ? _self.totalDurationMs : totalDurationMs // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
