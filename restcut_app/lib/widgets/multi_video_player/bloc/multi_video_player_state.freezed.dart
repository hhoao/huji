// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'multi_video_player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MultiVideoPlayerState {

 int get currentTimeMs; VideoPlaybackItem? get currentItem; List<VideoPlaybackItem> get items; VideoPlayerController? get currentVideoController; double get volume; double get playbackSpeed; bool get isLooping;// 播放状态字段
 bool get isLoading; bool get isPlaying;// 全屏状态
 bool get isFullscreen;// 连续播放状态
 bool get isContinuousPlayback;
/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MultiVideoPlayerStateCopyWith<MultiVideoPlayerState> get copyWith => _$MultiVideoPlayerStateCopyWithImpl<MultiVideoPlayerState>(this as MultiVideoPlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MultiVideoPlayerState&&(identical(other.currentTimeMs, currentTimeMs) || other.currentTimeMs == currentTimeMs)&&(identical(other.currentItem, currentItem) || other.currentItem == currentItem)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.currentVideoController, currentVideoController) || other.currentVideoController == currentVideoController)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.isLooping, isLooping) || other.isLooping == isLooping)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isFullscreen, isFullscreen) || other.isFullscreen == isFullscreen)&&(identical(other.isContinuousPlayback, isContinuousPlayback) || other.isContinuousPlayback == isContinuousPlayback));
}


@override
int get hashCode => Object.hash(runtimeType,currentTimeMs,currentItem,const DeepCollectionEquality().hash(items),currentVideoController,volume,playbackSpeed,isLooping,isLoading,isPlaying,isFullscreen,isContinuousPlayback);

@override
String toString() {
  return 'MultiVideoPlayerState(currentTimeMs: $currentTimeMs, currentItem: $currentItem, items: $items, currentVideoController: $currentVideoController, volume: $volume, playbackSpeed: $playbackSpeed, isLooping: $isLooping, isLoading: $isLoading, isPlaying: $isPlaying, isFullscreen: $isFullscreen, isContinuousPlayback: $isContinuousPlayback)';
}


}

/// @nodoc
abstract mixin class $MultiVideoPlayerStateCopyWith<$Res>  {
  factory $MultiVideoPlayerStateCopyWith(MultiVideoPlayerState value, $Res Function(MultiVideoPlayerState) _then) = _$MultiVideoPlayerStateCopyWithImpl;
@useResult
$Res call({
 int currentTimeMs, VideoPlaybackItem? currentItem, List<VideoPlaybackItem> items, VideoPlayerController? currentVideoController, double volume, double playbackSpeed, bool isLooping, bool isLoading, bool isPlaying, bool isFullscreen, bool isContinuousPlayback
});


$VideoPlaybackItemCopyWith<$Res>? get currentItem;

}
/// @nodoc
class _$MultiVideoPlayerStateCopyWithImpl<$Res>
    implements $MultiVideoPlayerStateCopyWith<$Res> {
  _$MultiVideoPlayerStateCopyWithImpl(this._self, this._then);

  final MultiVideoPlayerState _self;
  final $Res Function(MultiVideoPlayerState) _then;

/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTimeMs = null,Object? currentItem = freezed,Object? items = null,Object? currentVideoController = freezed,Object? volume = null,Object? playbackSpeed = null,Object? isLooping = null,Object? isLoading = null,Object? isPlaying = null,Object? isFullscreen = null,Object? isContinuousPlayback = null,}) {
  return _then(_self.copyWith(
currentTimeMs: null == currentTimeMs ? _self.currentTimeMs : currentTimeMs // ignore: cast_nullable_to_non_nullable
as int,currentItem: freezed == currentItem ? _self.currentItem : currentItem // ignore: cast_nullable_to_non_nullable
as VideoPlaybackItem?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<VideoPlaybackItem>,currentVideoController: freezed == currentVideoController ? _self.currentVideoController : currentVideoController // ignore: cast_nullable_to_non_nullable
as VideoPlayerController?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,isLooping: null == isLooping ? _self.isLooping : isLooping // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isFullscreen: null == isFullscreen ? _self.isFullscreen : isFullscreen // ignore: cast_nullable_to_non_nullable
as bool,isContinuousPlayback: null == isContinuousPlayback ? _self.isContinuousPlayback : isContinuousPlayback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoPlaybackItemCopyWith<$Res>? get currentItem {
    if (_self.currentItem == null) {
    return null;
  }

  return $VideoPlaybackItemCopyWith<$Res>(_self.currentItem!, (value) {
    return _then(_self.copyWith(currentItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [MultiVideoPlayerState].
extension MultiVideoPlayerStatePatterns on MultiVideoPlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MultiVideoPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MultiVideoPlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MultiVideoPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _MultiVideoPlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MultiVideoPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _MultiVideoPlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentTimeMs,  VideoPlaybackItem? currentItem,  List<VideoPlaybackItem> items,  VideoPlayerController? currentVideoController,  double volume,  double playbackSpeed,  bool isLooping,  bool isLoading,  bool isPlaying,  bool isFullscreen,  bool isContinuousPlayback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MultiVideoPlayerState() when $default != null:
return $default(_that.currentTimeMs,_that.currentItem,_that.items,_that.currentVideoController,_that.volume,_that.playbackSpeed,_that.isLooping,_that.isLoading,_that.isPlaying,_that.isFullscreen,_that.isContinuousPlayback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentTimeMs,  VideoPlaybackItem? currentItem,  List<VideoPlaybackItem> items,  VideoPlayerController? currentVideoController,  double volume,  double playbackSpeed,  bool isLooping,  bool isLoading,  bool isPlaying,  bool isFullscreen,  bool isContinuousPlayback)  $default,) {final _that = this;
switch (_that) {
case _MultiVideoPlayerState():
return $default(_that.currentTimeMs,_that.currentItem,_that.items,_that.currentVideoController,_that.volume,_that.playbackSpeed,_that.isLooping,_that.isLoading,_that.isPlaying,_that.isFullscreen,_that.isContinuousPlayback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentTimeMs,  VideoPlaybackItem? currentItem,  List<VideoPlaybackItem> items,  VideoPlayerController? currentVideoController,  double volume,  double playbackSpeed,  bool isLooping,  bool isLoading,  bool isPlaying,  bool isFullscreen,  bool isContinuousPlayback)?  $default,) {final _that = this;
switch (_that) {
case _MultiVideoPlayerState() when $default != null:
return $default(_that.currentTimeMs,_that.currentItem,_that.items,_that.currentVideoController,_that.volume,_that.playbackSpeed,_that.isLooping,_that.isLoading,_that.isPlaying,_that.isFullscreen,_that.isContinuousPlayback);case _:
  return null;

}
}

}

/// @nodoc


class _MultiVideoPlayerState extends MultiVideoPlayerState {
  const _MultiVideoPlayerState({this.currentTimeMs = 0, this.currentItem, final  List<VideoPlaybackItem> items = const [], this.currentVideoController, this.volume = 1.0, this.playbackSpeed = 1.0, this.isLooping = false, this.isLoading = true, this.isPlaying = false, this.isFullscreen = false, this.isContinuousPlayback = true}): _items = items,super._();
  

@override@JsonKey() final  int currentTimeMs;
@override final  VideoPlaybackItem? currentItem;
 final  List<VideoPlaybackItem> _items;
@override@JsonKey() List<VideoPlaybackItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  VideoPlayerController? currentVideoController;
@override@JsonKey() final  double volume;
@override@JsonKey() final  double playbackSpeed;
@override@JsonKey() final  bool isLooping;
// 播放状态字段
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isPlaying;
// 全屏状态
@override@JsonKey() final  bool isFullscreen;
// 连续播放状态
@override@JsonKey() final  bool isContinuousPlayback;

/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MultiVideoPlayerStateCopyWith<_MultiVideoPlayerState> get copyWith => __$MultiVideoPlayerStateCopyWithImpl<_MultiVideoPlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MultiVideoPlayerState&&(identical(other.currentTimeMs, currentTimeMs) || other.currentTimeMs == currentTimeMs)&&(identical(other.currentItem, currentItem) || other.currentItem == currentItem)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.currentVideoController, currentVideoController) || other.currentVideoController == currentVideoController)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.isLooping, isLooping) || other.isLooping == isLooping)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isFullscreen, isFullscreen) || other.isFullscreen == isFullscreen)&&(identical(other.isContinuousPlayback, isContinuousPlayback) || other.isContinuousPlayback == isContinuousPlayback));
}


@override
int get hashCode => Object.hash(runtimeType,currentTimeMs,currentItem,const DeepCollectionEquality().hash(_items),currentVideoController,volume,playbackSpeed,isLooping,isLoading,isPlaying,isFullscreen,isContinuousPlayback);

@override
String toString() {
  return 'MultiVideoPlayerState(currentTimeMs: $currentTimeMs, currentItem: $currentItem, items: $items, currentVideoController: $currentVideoController, volume: $volume, playbackSpeed: $playbackSpeed, isLooping: $isLooping, isLoading: $isLoading, isPlaying: $isPlaying, isFullscreen: $isFullscreen, isContinuousPlayback: $isContinuousPlayback)';
}


}

/// @nodoc
abstract mixin class _$MultiVideoPlayerStateCopyWith<$Res> implements $MultiVideoPlayerStateCopyWith<$Res> {
  factory _$MultiVideoPlayerStateCopyWith(_MultiVideoPlayerState value, $Res Function(_MultiVideoPlayerState) _then) = __$MultiVideoPlayerStateCopyWithImpl;
@override @useResult
$Res call({
 int currentTimeMs, VideoPlaybackItem? currentItem, List<VideoPlaybackItem> items, VideoPlayerController? currentVideoController, double volume, double playbackSpeed, bool isLooping, bool isLoading, bool isPlaying, bool isFullscreen, bool isContinuousPlayback
});


@override $VideoPlaybackItemCopyWith<$Res>? get currentItem;

}
/// @nodoc
class __$MultiVideoPlayerStateCopyWithImpl<$Res>
    implements _$MultiVideoPlayerStateCopyWith<$Res> {
  __$MultiVideoPlayerStateCopyWithImpl(this._self, this._then);

  final _MultiVideoPlayerState _self;
  final $Res Function(_MultiVideoPlayerState) _then;

/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentTimeMs = null,Object? currentItem = freezed,Object? items = null,Object? currentVideoController = freezed,Object? volume = null,Object? playbackSpeed = null,Object? isLooping = null,Object? isLoading = null,Object? isPlaying = null,Object? isFullscreen = null,Object? isContinuousPlayback = null,}) {
  return _then(_MultiVideoPlayerState(
currentTimeMs: null == currentTimeMs ? _self.currentTimeMs : currentTimeMs // ignore: cast_nullable_to_non_nullable
as int,currentItem: freezed == currentItem ? _self.currentItem : currentItem // ignore: cast_nullable_to_non_nullable
as VideoPlaybackItem?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VideoPlaybackItem>,currentVideoController: freezed == currentVideoController ? _self.currentVideoController : currentVideoController // ignore: cast_nullable_to_non_nullable
as VideoPlayerController?,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,isLooping: null == isLooping ? _self.isLooping : isLooping // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isFullscreen: null == isFullscreen ? _self.isFullscreen : isFullscreen // ignore: cast_nullable_to_non_nullable
as bool,isContinuousPlayback: null == isContinuousPlayback ? _self.isContinuousPlayback : isContinuousPlayback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of MultiVideoPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoPlaybackItemCopyWith<$Res>? get currentItem {
    if (_self.currentItem == null) {
    return null;
  }

  return $VideoPlaybackItemCopyWith<$Res>(_self.currentItem!, (value) {
    return _then(_self.copyWith(currentItem: value));
  });
}
}

// dart format on
