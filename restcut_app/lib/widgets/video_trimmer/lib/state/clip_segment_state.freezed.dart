// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clip_segment_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClipSegmentState {

 List<VideoClipSegment> get segments; VideoClipSegment? get selectedSegment; int? get totalDuration; bool get isInitialized;
/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipSegmentStateCopyWith<ClipSegmentState> get copyWith => _$ClipSegmentStateCopyWithImpl<ClipSegmentState>(this as ClipSegmentState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipSegmentState&&const DeepCollectionEquality().equals(other.segments, segments)&&(identical(other.selectedSegment, selectedSegment) || other.selectedSegment == selectedSegment)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(segments),selectedSegment,totalDuration,isInitialized);

@override
String toString() {
  return 'ClipSegmentState(segments: $segments, selectedSegment: $selectedSegment, totalDuration: $totalDuration, isInitialized: $isInitialized)';
}


}

/// @nodoc
abstract mixin class $ClipSegmentStateCopyWith<$Res>  {
  factory $ClipSegmentStateCopyWith(ClipSegmentState value, $Res Function(ClipSegmentState) _then) = _$ClipSegmentStateCopyWithImpl;
@useResult
$Res call({
 List<VideoClipSegment> segments, VideoClipSegment? selectedSegment, int? totalDuration, bool isInitialized
});


$VideoClipSegmentCopyWith<$Res>? get selectedSegment;

}
/// @nodoc
class _$ClipSegmentStateCopyWithImpl<$Res>
    implements $ClipSegmentStateCopyWith<$Res> {
  _$ClipSegmentStateCopyWithImpl(this._self, this._then);

  final ClipSegmentState _self;
  final $Res Function(ClipSegmentState) _then;

/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segments = null,Object? selectedSegment = freezed,Object? totalDuration = freezed,Object? isInitialized = null,}) {
  return _then(_self.copyWith(
segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<VideoClipSegment>,selectedSegment: freezed == selectedSegment ? _self.selectedSegment : selectedSegment // ignore: cast_nullable_to_non_nullable
as VideoClipSegment?,totalDuration: freezed == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int?,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoClipSegmentCopyWith<$Res>? get selectedSegment {
    if (_self.selectedSegment == null) {
    return null;
  }

  return $VideoClipSegmentCopyWith<$Res>(_self.selectedSegment!, (value) {
    return _then(_self.copyWith(selectedSegment: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClipSegmentState].
extension ClipSegmentStatePatterns on ClipSegmentState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipSegmentState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipSegmentState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipSegmentState value)  $default,){
final _that = this;
switch (_that) {
case _ClipSegmentState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipSegmentState value)?  $default,){
final _that = this;
switch (_that) {
case _ClipSegmentState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VideoClipSegment> segments,  VideoClipSegment? selectedSegment,  int? totalDuration,  bool isInitialized)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipSegmentState() when $default != null:
return $default(_that.segments,_that.selectedSegment,_that.totalDuration,_that.isInitialized);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VideoClipSegment> segments,  VideoClipSegment? selectedSegment,  int? totalDuration,  bool isInitialized)  $default,) {final _that = this;
switch (_that) {
case _ClipSegmentState():
return $default(_that.segments,_that.selectedSegment,_that.totalDuration,_that.isInitialized);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VideoClipSegment> segments,  VideoClipSegment? selectedSegment,  int? totalDuration,  bool isInitialized)?  $default,) {final _that = this;
switch (_that) {
case _ClipSegmentState() when $default != null:
return $default(_that.segments,_that.selectedSegment,_that.totalDuration,_that.isInitialized);case _:
  return null;

}
}

}

/// @nodoc


class _ClipSegmentState extends ClipSegmentState {
  const _ClipSegmentState({final  List<VideoClipSegment> segments = const [], this.selectedSegment = null, this.totalDuration = null, this.isInitialized = false}): _segments = segments,super._();
  

 final  List<VideoClipSegment> _segments;
@override@JsonKey() List<VideoClipSegment> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

@override@JsonKey() final  VideoClipSegment? selectedSegment;
@override@JsonKey() final  int? totalDuration;
@override@JsonKey() final  bool isInitialized;

/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipSegmentStateCopyWith<_ClipSegmentState> get copyWith => __$ClipSegmentStateCopyWithImpl<_ClipSegmentState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipSegmentState&&const DeepCollectionEquality().equals(other._segments, _segments)&&(identical(other.selectedSegment, selectedSegment) || other.selectedSegment == selectedSegment)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_segments),selectedSegment,totalDuration,isInitialized);

@override
String toString() {
  return 'ClipSegmentState(segments: $segments, selectedSegment: $selectedSegment, totalDuration: $totalDuration, isInitialized: $isInitialized)';
}


}

/// @nodoc
abstract mixin class _$ClipSegmentStateCopyWith<$Res> implements $ClipSegmentStateCopyWith<$Res> {
  factory _$ClipSegmentStateCopyWith(_ClipSegmentState value, $Res Function(_ClipSegmentState) _then) = __$ClipSegmentStateCopyWithImpl;
@override @useResult
$Res call({
 List<VideoClipSegment> segments, VideoClipSegment? selectedSegment, int? totalDuration, bool isInitialized
});


@override $VideoClipSegmentCopyWith<$Res>? get selectedSegment;

}
/// @nodoc
class __$ClipSegmentStateCopyWithImpl<$Res>
    implements _$ClipSegmentStateCopyWith<$Res> {
  __$ClipSegmentStateCopyWithImpl(this._self, this._then);

  final _ClipSegmentState _self;
  final $Res Function(_ClipSegmentState) _then;

/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segments = null,Object? selectedSegment = freezed,Object? totalDuration = freezed,Object? isInitialized = null,}) {
  return _then(_ClipSegmentState(
segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<VideoClipSegment>,selectedSegment: freezed == selectedSegment ? _self.selectedSegment : selectedSegment // ignore: cast_nullable_to_non_nullable
as VideoClipSegment?,totalDuration: freezed == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as int?,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ClipSegmentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoClipSegmentCopyWith<$Res>? get selectedSegment {
    if (_self.selectedSegment == null) {
    return null;
  }

  return $VideoClipSegmentCopyWith<$Res>(_self.selectedSegment!, (value) {
    return _then(_self.copyWith(selectedSegment: value));
  });
}
}

// dart format on
