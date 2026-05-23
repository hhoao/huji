// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trimmer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrimmerState {

 double get totalDuration; bool get isPlaying; int get currentMilliseconds; double get playbackSpeed; bool get isSlowMotion; bool get playSelectedSegmentOnly; double get volume; bool get isDragging; bool get mute; bool get isLoading; String? get error; VideoPlayerController? get videoPlayerController; ScrollController? get scrollController; String? get coverImage; ThumbnailConfig? get thumbnailConfig; double get timeIntervalSeconds;
/// Create a copy of TrimmerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrimmerStateCopyWith<TrimmerState> get copyWith => _$TrimmerStateCopyWithImpl<TrimmerState>(this as TrimmerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrimmerState&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.currentMilliseconds, currentMilliseconds) || other.currentMilliseconds == currentMilliseconds)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.isSlowMotion, isSlowMotion) || other.isSlowMotion == isSlowMotion)&&(identical(other.playSelectedSegmentOnly, playSelectedSegmentOnly) || other.playSelectedSegmentOnly == playSelectedSegmentOnly)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isDragging, isDragging) || other.isDragging == isDragging)&&(identical(other.mute, mute) || other.mute == mute)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.videoPlayerController, videoPlayerController) || other.videoPlayerController == videoPlayerController)&&(identical(other.scrollController, scrollController) || other.scrollController == scrollController)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.thumbnailConfig, thumbnailConfig) || other.thumbnailConfig == thumbnailConfig)&&(identical(other.timeIntervalSeconds, timeIntervalSeconds) || other.timeIntervalSeconds == timeIntervalSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,totalDuration,isPlaying,currentMilliseconds,playbackSpeed,isSlowMotion,playSelectedSegmentOnly,volume,isDragging,mute,isLoading,error,videoPlayerController,scrollController,coverImage,thumbnailConfig,timeIntervalSeconds);

@override
String toString() {
  return 'TrimmerState(totalDuration: $totalDuration, isPlaying: $isPlaying, currentMilliseconds: $currentMilliseconds, playbackSpeed: $playbackSpeed, isSlowMotion: $isSlowMotion, playSelectedSegmentOnly: $playSelectedSegmentOnly, volume: $volume, isDragging: $isDragging, mute: $mute, isLoading: $isLoading, error: $error, videoPlayerController: $videoPlayerController, scrollController: $scrollController, coverImage: $coverImage, thumbnailConfig: $thumbnailConfig, timeIntervalSeconds: $timeIntervalSeconds)';
}


}

/// @nodoc
abstract mixin class $TrimmerStateCopyWith<$Res>  {
  factory $TrimmerStateCopyWith(TrimmerState value, $Res Function(TrimmerState) _then) = _$TrimmerStateCopyWithImpl;
@useResult
$Res call({
 double totalDuration, bool isPlaying, int currentMilliseconds, double playbackSpeed, bool isSlowMotion, bool playSelectedSegmentOnly, double volume, bool isDragging, bool mute, bool isLoading, String? error, VideoPlayerController? videoPlayerController, ScrollController? scrollController, String? coverImage, ThumbnailConfig? thumbnailConfig, double timeIntervalSeconds
});




}
/// @nodoc
class _$TrimmerStateCopyWithImpl<$Res>
    implements $TrimmerStateCopyWith<$Res> {
  _$TrimmerStateCopyWithImpl(this._self, this._then);

  final TrimmerState _self;
  final $Res Function(TrimmerState) _then;

/// Create a copy of TrimmerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalDuration = null,Object? isPlaying = null,Object? currentMilliseconds = null,Object? playbackSpeed = null,Object? isSlowMotion = null,Object? playSelectedSegmentOnly = null,Object? volume = null,Object? isDragging = null,Object? mute = null,Object? isLoading = null,Object? error = freezed,Object? videoPlayerController = freezed,Object? scrollController = freezed,Object? coverImage = freezed,Object? thumbnailConfig = freezed,Object? timeIntervalSeconds = null,}) {
  return _then(_self.copyWith(
totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as double,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,currentMilliseconds: null == currentMilliseconds ? _self.currentMilliseconds : currentMilliseconds // ignore: cast_nullable_to_non_nullable
as int,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,isSlowMotion: null == isSlowMotion ? _self.isSlowMotion : isSlowMotion // ignore: cast_nullable_to_non_nullable
as bool,playSelectedSegmentOnly: null == playSelectedSegmentOnly ? _self.playSelectedSegmentOnly : playSelectedSegmentOnly // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,isDragging: null == isDragging ? _self.isDragging : isDragging // ignore: cast_nullable_to_non_nullable
as bool,mute: null == mute ? _self.mute : mute // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,videoPlayerController: freezed == videoPlayerController ? _self.videoPlayerController : videoPlayerController // ignore: cast_nullable_to_non_nullable
as VideoPlayerController?,scrollController: freezed == scrollController ? _self.scrollController : scrollController // ignore: cast_nullable_to_non_nullable
as ScrollController?,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,thumbnailConfig: freezed == thumbnailConfig ? _self.thumbnailConfig : thumbnailConfig // ignore: cast_nullable_to_non_nullable
as ThumbnailConfig?,timeIntervalSeconds: null == timeIntervalSeconds ? _self.timeIntervalSeconds : timeIntervalSeconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TrimmerState].
extension TrimmerStatePatterns on TrimmerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrimmerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrimmerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrimmerState value)  $default,){
final _that = this;
switch (_that) {
case _TrimmerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrimmerState value)?  $default,){
final _that = this;
switch (_that) {
case _TrimmerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalDuration,  bool isPlaying,  int currentMilliseconds,  double playbackSpeed,  bool isSlowMotion,  bool playSelectedSegmentOnly,  double volume,  bool isDragging,  bool mute,  bool isLoading,  String? error,  VideoPlayerController? videoPlayerController,  ScrollController? scrollController,  String? coverImage,  ThumbnailConfig? thumbnailConfig,  double timeIntervalSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrimmerState() when $default != null:
return $default(_that.totalDuration,_that.isPlaying,_that.currentMilliseconds,_that.playbackSpeed,_that.isSlowMotion,_that.playSelectedSegmentOnly,_that.volume,_that.isDragging,_that.mute,_that.isLoading,_that.error,_that.videoPlayerController,_that.scrollController,_that.coverImage,_that.thumbnailConfig,_that.timeIntervalSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalDuration,  bool isPlaying,  int currentMilliseconds,  double playbackSpeed,  bool isSlowMotion,  bool playSelectedSegmentOnly,  double volume,  bool isDragging,  bool mute,  bool isLoading,  String? error,  VideoPlayerController? videoPlayerController,  ScrollController? scrollController,  String? coverImage,  ThumbnailConfig? thumbnailConfig,  double timeIntervalSeconds)  $default,) {final _that = this;
switch (_that) {
case _TrimmerState():
return $default(_that.totalDuration,_that.isPlaying,_that.currentMilliseconds,_that.playbackSpeed,_that.isSlowMotion,_that.playSelectedSegmentOnly,_that.volume,_that.isDragging,_that.mute,_that.isLoading,_that.error,_that.videoPlayerController,_that.scrollController,_that.coverImage,_that.thumbnailConfig,_that.timeIntervalSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalDuration,  bool isPlaying,  int currentMilliseconds,  double playbackSpeed,  bool isSlowMotion,  bool playSelectedSegmentOnly,  double volume,  bool isDragging,  bool mute,  bool isLoading,  String? error,  VideoPlayerController? videoPlayerController,  ScrollController? scrollController,  String? coverImage,  ThumbnailConfig? thumbnailConfig,  double timeIntervalSeconds)?  $default,) {final _that = this;
switch (_that) {
case _TrimmerState() when $default != null:
return $default(_that.totalDuration,_that.isPlaying,_that.currentMilliseconds,_that.playbackSpeed,_that.isSlowMotion,_that.playSelectedSegmentOnly,_that.volume,_that.isDragging,_that.mute,_that.isLoading,_that.error,_that.videoPlayerController,_that.scrollController,_that.coverImage,_that.thumbnailConfig,_that.timeIntervalSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _TrimmerState implements TrimmerState {
  const _TrimmerState([this.totalDuration = 0.0, this.isPlaying = false, this.currentMilliseconds = 0, this.playbackSpeed = 1.0, this.isSlowMotion = false, this.playSelectedSegmentOnly = false, this.volume = 1.0, this.isDragging = false, this.mute = false, this.isLoading = true, this.error = null, this.videoPlayerController = null, this.scrollController = null, this.coverImage = null, this.thumbnailConfig = null, this.timeIntervalSeconds = 1]);
  

@override@JsonKey() final  double totalDuration;
@override@JsonKey() final  bool isPlaying;
@override@JsonKey() final  int currentMilliseconds;
@override@JsonKey() final  double playbackSpeed;
@override@JsonKey() final  bool isSlowMotion;
@override@JsonKey() final  bool playSelectedSegmentOnly;
@override@JsonKey() final  double volume;
@override@JsonKey() final  bool isDragging;
@override@JsonKey() final  bool mute;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  String? error;
@override@JsonKey() final  VideoPlayerController? videoPlayerController;
@override@JsonKey() final  ScrollController? scrollController;
@override@JsonKey() final  String? coverImage;
@override@JsonKey() final  ThumbnailConfig? thumbnailConfig;
@override@JsonKey() final  double timeIntervalSeconds;

/// Create a copy of TrimmerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrimmerStateCopyWith<_TrimmerState> get copyWith => __$TrimmerStateCopyWithImpl<_TrimmerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrimmerState&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.currentMilliseconds, currentMilliseconds) || other.currentMilliseconds == currentMilliseconds)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.isSlowMotion, isSlowMotion) || other.isSlowMotion == isSlowMotion)&&(identical(other.playSelectedSegmentOnly, playSelectedSegmentOnly) || other.playSelectedSegmentOnly == playSelectedSegmentOnly)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.isDragging, isDragging) || other.isDragging == isDragging)&&(identical(other.mute, mute) || other.mute == mute)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.videoPlayerController, videoPlayerController) || other.videoPlayerController == videoPlayerController)&&(identical(other.scrollController, scrollController) || other.scrollController == scrollController)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.thumbnailConfig, thumbnailConfig) || other.thumbnailConfig == thumbnailConfig)&&(identical(other.timeIntervalSeconds, timeIntervalSeconds) || other.timeIntervalSeconds == timeIntervalSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,totalDuration,isPlaying,currentMilliseconds,playbackSpeed,isSlowMotion,playSelectedSegmentOnly,volume,isDragging,mute,isLoading,error,videoPlayerController,scrollController,coverImage,thumbnailConfig,timeIntervalSeconds);

@override
String toString() {
  return 'TrimmerState(totalDuration: $totalDuration, isPlaying: $isPlaying, currentMilliseconds: $currentMilliseconds, playbackSpeed: $playbackSpeed, isSlowMotion: $isSlowMotion, playSelectedSegmentOnly: $playSelectedSegmentOnly, volume: $volume, isDragging: $isDragging, mute: $mute, isLoading: $isLoading, error: $error, videoPlayerController: $videoPlayerController, scrollController: $scrollController, coverImage: $coverImage, thumbnailConfig: $thumbnailConfig, timeIntervalSeconds: $timeIntervalSeconds)';
}


}

/// @nodoc
abstract mixin class _$TrimmerStateCopyWith<$Res> implements $TrimmerStateCopyWith<$Res> {
  factory _$TrimmerStateCopyWith(_TrimmerState value, $Res Function(_TrimmerState) _then) = __$TrimmerStateCopyWithImpl;
@override @useResult
$Res call({
 double totalDuration, bool isPlaying, int currentMilliseconds, double playbackSpeed, bool isSlowMotion, bool playSelectedSegmentOnly, double volume, bool isDragging, bool mute, bool isLoading, String? error, VideoPlayerController? videoPlayerController, ScrollController? scrollController, String? coverImage, ThumbnailConfig? thumbnailConfig, double timeIntervalSeconds
});




}
/// @nodoc
class __$TrimmerStateCopyWithImpl<$Res>
    implements _$TrimmerStateCopyWith<$Res> {
  __$TrimmerStateCopyWithImpl(this._self, this._then);

  final _TrimmerState _self;
  final $Res Function(_TrimmerState) _then;

/// Create a copy of TrimmerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalDuration = null,Object? isPlaying = null,Object? currentMilliseconds = null,Object? playbackSpeed = null,Object? isSlowMotion = null,Object? playSelectedSegmentOnly = null,Object? volume = null,Object? isDragging = null,Object? mute = null,Object? isLoading = null,Object? error = freezed,Object? videoPlayerController = freezed,Object? scrollController = freezed,Object? coverImage = freezed,Object? thumbnailConfig = freezed,Object? timeIntervalSeconds = null,}) {
  return _then(_TrimmerState(
null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as double,null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,null == currentMilliseconds ? _self.currentMilliseconds : currentMilliseconds // ignore: cast_nullable_to_non_nullable
as int,null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,null == isSlowMotion ? _self.isSlowMotion : isSlowMotion // ignore: cast_nullable_to_non_nullable
as bool,null == playSelectedSegmentOnly ? _self.playSelectedSegmentOnly : playSelectedSegmentOnly // ignore: cast_nullable_to_non_nullable
as bool,null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,null == isDragging ? _self.isDragging : isDragging // ignore: cast_nullable_to_non_nullable
as bool,null == mute ? _self.mute : mute // ignore: cast_nullable_to_non_nullable
as bool,null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,freezed == videoPlayerController ? _self.videoPlayerController : videoPlayerController // ignore: cast_nullable_to_non_nullable
as VideoPlayerController?,freezed == scrollController ? _self.scrollController : scrollController // ignore: cast_nullable_to_non_nullable
as ScrollController?,freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,freezed == thumbnailConfig ? _self.thumbnailConfig : thumbnailConfig // ignore: cast_nullable_to_non_nullable
as ThumbnailConfig?,null == timeIntervalSeconds ? _self.timeIntervalSeconds : timeIntervalSeconds // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
