// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_clip_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoClipSegment {

 String get id; int get startTime; int get endTime; bool get isSelected; bool get isDeleted; bool get isFavorite; int get order;
/// Create a copy of VideoClipSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoClipSegmentCopyWith<VideoClipSegment> get copyWith => _$VideoClipSegmentCopyWithImpl<VideoClipSegment>(this as VideoClipSegment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoClipSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,isSelected,isDeleted,isFavorite,order);

@override
String toString() {
  return 'VideoClipSegment(id: $id, startTime: $startTime, endTime: $endTime, isSelected: $isSelected, isDeleted: $isDeleted, isFavorite: $isFavorite, order: $order)';
}


}

/// @nodoc
abstract mixin class $VideoClipSegmentCopyWith<$Res>  {
  factory $VideoClipSegmentCopyWith(VideoClipSegment value, $Res Function(VideoClipSegment) _then) = _$VideoClipSegmentCopyWithImpl;
@useResult
$Res call({
 String id, int startTime, int endTime, bool isSelected, bool isDeleted, bool isFavorite, int order
});




}
/// @nodoc
class _$VideoClipSegmentCopyWithImpl<$Res>
    implements $VideoClipSegmentCopyWith<$Res> {
  _$VideoClipSegmentCopyWithImpl(this._self, this._then);

  final VideoClipSegment _self;
  final $Res Function(VideoClipSegment) _then;

/// Create a copy of VideoClipSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startTime = null,Object? endTime = null,Object? isSelected = null,Object? isDeleted = null,Object? isFavorite = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoClipSegment].
extension VideoClipSegmentPatterns on VideoClipSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoClipSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoClipSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoClipSegment value)  $default,){
final _that = this;
switch (_that) {
case _VideoClipSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoClipSegment value)?  $default,){
final _that = this;
switch (_that) {
case _VideoClipSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int startTime,  int endTime,  bool isSelected,  bool isDeleted,  bool isFavorite,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoClipSegment() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.isSelected,_that.isDeleted,_that.isFavorite,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int startTime,  int endTime,  bool isSelected,  bool isDeleted,  bool isFavorite,  int order)  $default,) {final _that = this;
switch (_that) {
case _VideoClipSegment():
return $default(_that.id,_that.startTime,_that.endTime,_that.isSelected,_that.isDeleted,_that.isFavorite,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int startTime,  int endTime,  bool isSelected,  bool isDeleted,  bool isFavorite,  int order)?  $default,) {final _that = this;
switch (_that) {
case _VideoClipSegment() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.isSelected,_that.isDeleted,_that.isFavorite,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class _VideoClipSegment extends VideoClipSegment {
  const _VideoClipSegment({required this.id, required this.startTime, required this.endTime, this.isSelected = false, this.isDeleted = false, this.isFavorite = false, this.order = 0}): super._();
  

@override final  String id;
@override final  int startTime;
@override final  int endTime;
@override@JsonKey() final  bool isSelected;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  int order;

/// Create a copy of VideoClipSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoClipSegmentCopyWith<_VideoClipSegment> get copyWith => __$VideoClipSegmentCopyWithImpl<_VideoClipSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoClipSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isSelected, isSelected) || other.isSelected == isSelected)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,isSelected,isDeleted,isFavorite,order);

@override
String toString() {
  return 'VideoClipSegment(id: $id, startTime: $startTime, endTime: $endTime, isSelected: $isSelected, isDeleted: $isDeleted, isFavorite: $isFavorite, order: $order)';
}


}

/// @nodoc
abstract mixin class _$VideoClipSegmentCopyWith<$Res> implements $VideoClipSegmentCopyWith<$Res> {
  factory _$VideoClipSegmentCopyWith(_VideoClipSegment value, $Res Function(_VideoClipSegment) _then) = __$VideoClipSegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, int startTime, int endTime, bool isSelected, bool isDeleted, bool isFavorite, int order
});




}
/// @nodoc
class __$VideoClipSegmentCopyWithImpl<$Res>
    implements _$VideoClipSegmentCopyWith<$Res> {
  __$VideoClipSegmentCopyWithImpl(this._self, this._then);

  final _VideoClipSegment _self;
  final $Res Function(_VideoClipSegment) _then;

/// Create a copy of VideoClipSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startTime = null,Object? endTime = null,Object? isSelected = null,Object? isDeleted = null,Object? isFavorite = null,Object? order = null,}) {
  return _then(_VideoClipSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as int,isSelected: null == isSelected ? _self.isSelected : isSelected // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
