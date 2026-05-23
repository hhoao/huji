// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'large_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClassifierResult {

// ignore: invalid_annotation_target
@JsonKey(fromJson: ImageSize.fromObjectJson) ImageSize get imageSize;// ignore: invalid_annotation_target
@JsonKey(fromJson: Classification._convertClassification) Classification get classification; double get speed; List<Detection> get detections;
/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassifierResultCopyWith<ClassifierResult> get copyWith => _$ClassifierResultCopyWithImpl<ClassifierResult>(this as ClassifierResult, _$identity);

  /// Serializes this ClassifierResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassifierResult&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.speed, speed) || other.speed == speed)&&const DeepCollectionEquality().equals(other.detections, detections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,imageSize,classification,speed,const DeepCollectionEquality().hash(detections));

@override
String toString() {
  return 'ClassifierResult(imageSize: $imageSize, classification: $classification, speed: $speed, detections: $detections)';
}


}

/// @nodoc
abstract mixin class $ClassifierResultCopyWith<$Res>  {
  factory $ClassifierResultCopyWith(ClassifierResult value, $Res Function(ClassifierResult) _then) = _$ClassifierResultCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: ImageSize.fromObjectJson) ImageSize imageSize,@JsonKey(fromJson: Classification._convertClassification) Classification classification, double speed, List<Detection> detections
});


$ImageSizeCopyWith<$Res> get imageSize;$ClassificationCopyWith<$Res> get classification;

}
/// @nodoc
class _$ClassifierResultCopyWithImpl<$Res>
    implements $ClassifierResultCopyWith<$Res> {
  _$ClassifierResultCopyWithImpl(this._self, this._then);

  final ClassifierResult _self;
  final $Res Function(ClassifierResult) _then;

/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? imageSize = null,Object? classification = null,Object? speed = null,Object? detections = null,}) {
  return _then(_self.copyWith(
imageSize: null == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as ImageSize,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as Classification,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,detections: null == detections ? _self.detections : detections // ignore: cast_nullable_to_non_nullable
as List<Detection>,
  ));
}
/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageSizeCopyWith<$Res> get imageSize {
  
  return $ImageSizeCopyWith<$Res>(_self.imageSize, (value) {
    return _then(_self.copyWith(imageSize: value));
  });
}/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassificationCopyWith<$Res> get classification {
  
  return $ClassificationCopyWith<$Res>(_self.classification, (value) {
    return _then(_self.copyWith(classification: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClassifierResult].
extension ClassifierResultPatterns on ClassifierResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassifierResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassifierResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassifierResult value)  $default,){
final _that = this;
switch (_that) {
case _ClassifierResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassifierResult value)?  $default,){
final _that = this;
switch (_that) {
case _ClassifierResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: ImageSize.fromObjectJson)  ImageSize imageSize, @JsonKey(fromJson: Classification._convertClassification)  Classification classification,  double speed,  List<Detection> detections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassifierResult() when $default != null:
return $default(_that.imageSize,_that.classification,_that.speed,_that.detections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: ImageSize.fromObjectJson)  ImageSize imageSize, @JsonKey(fromJson: Classification._convertClassification)  Classification classification,  double speed,  List<Detection> detections)  $default,) {final _that = this;
switch (_that) {
case _ClassifierResult():
return $default(_that.imageSize,_that.classification,_that.speed,_that.detections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: ImageSize.fromObjectJson)  ImageSize imageSize, @JsonKey(fromJson: Classification._convertClassification)  Classification classification,  double speed,  List<Detection> detections)?  $default,) {final _that = this;
switch (_that) {
case _ClassifierResult() when $default != null:
return $default(_that.imageSize,_that.classification,_that.speed,_that.detections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClassifierResult implements ClassifierResult {
  const _ClassifierResult({@JsonKey(fromJson: ImageSize.fromObjectJson) required this.imageSize, @JsonKey(fromJson: Classification._convertClassification) required this.classification, required this.speed, required final  List<Detection> detections}): _detections = detections;
  factory _ClassifierResult.fromJson(Map<String, dynamic> json) => _$ClassifierResultFromJson(json);

// ignore: invalid_annotation_target
@override@JsonKey(fromJson: ImageSize.fromObjectJson) final  ImageSize imageSize;
// ignore: invalid_annotation_target
@override@JsonKey(fromJson: Classification._convertClassification) final  Classification classification;
@override final  double speed;
 final  List<Detection> _detections;
@override List<Detection> get detections {
  if (_detections is EqualUnmodifiableListView) return _detections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detections);
}


/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassifierResultCopyWith<_ClassifierResult> get copyWith => __$ClassifierResultCopyWithImpl<_ClassifierResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassifierResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassifierResult&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.speed, speed) || other.speed == speed)&&const DeepCollectionEquality().equals(other._detections, _detections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,imageSize,classification,speed,const DeepCollectionEquality().hash(_detections));

@override
String toString() {
  return 'ClassifierResult(imageSize: $imageSize, classification: $classification, speed: $speed, detections: $detections)';
}


}

/// @nodoc
abstract mixin class _$ClassifierResultCopyWith<$Res> implements $ClassifierResultCopyWith<$Res> {
  factory _$ClassifierResultCopyWith(_ClassifierResult value, $Res Function(_ClassifierResult) _then) = __$ClassifierResultCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: ImageSize.fromObjectJson) ImageSize imageSize,@JsonKey(fromJson: Classification._convertClassification) Classification classification, double speed, List<Detection> detections
});


@override $ImageSizeCopyWith<$Res> get imageSize;@override $ClassificationCopyWith<$Res> get classification;

}
/// @nodoc
class __$ClassifierResultCopyWithImpl<$Res>
    implements _$ClassifierResultCopyWith<$Res> {
  __$ClassifierResultCopyWithImpl(this._self, this._then);

  final _ClassifierResult _self;
  final $Res Function(_ClassifierResult) _then;

/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? imageSize = null,Object? classification = null,Object? speed = null,Object? detections = null,}) {
  return _then(_ClassifierResult(
imageSize: null == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as ImageSize,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as Classification,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,detections: null == detections ? _self._detections : detections // ignore: cast_nullable_to_non_nullable
as List<Detection>,
  ));
}

/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageSizeCopyWith<$Res> get imageSize {
  
  return $ImageSizeCopyWith<$Res>(_self.imageSize, (value) {
    return _then(_self.copyWith(imageSize: value));
  });
}/// Create a copy of ClassifierResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassificationCopyWith<$Res> get classification {
  
  return $ClassificationCopyWith<$Res>(_self.classification, (value) {
    return _then(_self.copyWith(classification: value));
  });
}
}


/// @nodoc
mixin _$ImageSize {

 int get width; int get height;
/// Create a copy of ImageSize
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageSizeCopyWith<ImageSize> get copyWith => _$ImageSizeCopyWithImpl<ImageSize>(this as ImageSize, _$identity);

  /// Serializes this ImageSize to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageSize&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height);

@override
String toString() {
  return 'ImageSize(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $ImageSizeCopyWith<$Res>  {
  factory $ImageSizeCopyWith(ImageSize value, $Res Function(ImageSize) _then) = _$ImageSizeCopyWithImpl;
@useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class _$ImageSizeCopyWithImpl<$Res>
    implements $ImageSizeCopyWith<$Res> {
  _$ImageSizeCopyWithImpl(this._self, this._then);

  final ImageSize _self;
  final $Res Function(ImageSize) _then;

/// Create a copy of ImageSize
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageSize].
extension ImageSizePatterns on ImageSize {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageSize value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageSize() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageSize value)  $default,){
final _that = this;
switch (_that) {
case _ImageSize():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageSize value)?  $default,){
final _that = this;
switch (_that) {
case _ImageSize() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageSize() when $default != null:
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _ImageSize():
return $default(_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _ImageSize() when $default != null:
return $default(_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageSize implements ImageSize {
  const _ImageSize({required this.width, required this.height});
  factory _ImageSize.fromJson(Map<String, dynamic> json) => _$ImageSizeFromJson(json);

@override final  int width;
@override final  int height;

/// Create a copy of ImageSize
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageSizeCopyWith<_ImageSize> get copyWith => __$ImageSizeCopyWithImpl<_ImageSize>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageSizeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageSize&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,width,height);

@override
String toString() {
  return 'ImageSize(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$ImageSizeCopyWith<$Res> implements $ImageSizeCopyWith<$Res> {
  factory _$ImageSizeCopyWith(_ImageSize value, $Res Function(_ImageSize) _then) = __$ImageSizeCopyWithImpl;
@override @useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class __$ImageSizeCopyWithImpl<$Res>
    implements _$ImageSizeCopyWith<$Res> {
  __$ImageSizeCopyWithImpl(this._self, this._then);

  final _ImageSize _self;
  final $Res Function(_ImageSize) _then;

/// Create a copy of ImageSize
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,}) {
  return _then(_ImageSize(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Classification {

 String get topClass; double get topConfidence; List<String> get top5Classes; List<double> get top5Confidences;
/// Create a copy of Classification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassificationCopyWith<Classification> get copyWith => _$ClassificationCopyWithImpl<Classification>(this as Classification, _$identity);

  /// Serializes this Classification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Classification&&(identical(other.topClass, topClass) || other.topClass == topClass)&&(identical(other.topConfidence, topConfidence) || other.topConfidence == topConfidence)&&const DeepCollectionEquality().equals(other.top5Classes, top5Classes)&&const DeepCollectionEquality().equals(other.top5Confidences, top5Confidences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topClass,topConfidence,const DeepCollectionEquality().hash(top5Classes),const DeepCollectionEquality().hash(top5Confidences));

@override
String toString() {
  return 'Classification(topClass: $topClass, topConfidence: $topConfidence, top5Classes: $top5Classes, top5Confidences: $top5Confidences)';
}


}

/// @nodoc
abstract mixin class $ClassificationCopyWith<$Res>  {
  factory $ClassificationCopyWith(Classification value, $Res Function(Classification) _then) = _$ClassificationCopyWithImpl;
@useResult
$Res call({
 String topClass, double topConfidence, List<String> top5Classes, List<double> top5Confidences
});




}
/// @nodoc
class _$ClassificationCopyWithImpl<$Res>
    implements $ClassificationCopyWith<$Res> {
  _$ClassificationCopyWithImpl(this._self, this._then);

  final Classification _self;
  final $Res Function(Classification) _then;

/// Create a copy of Classification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topClass = null,Object? topConfidence = null,Object? top5Classes = null,Object? top5Confidences = null,}) {
  return _then(_self.copyWith(
topClass: null == topClass ? _self.topClass : topClass // ignore: cast_nullable_to_non_nullable
as String,topConfidence: null == topConfidence ? _self.topConfidence : topConfidence // ignore: cast_nullable_to_non_nullable
as double,top5Classes: null == top5Classes ? _self.top5Classes : top5Classes // ignore: cast_nullable_to_non_nullable
as List<String>,top5Confidences: null == top5Confidences ? _self.top5Confidences : top5Confidences // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [Classification].
extension ClassificationPatterns on Classification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Classification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Classification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Classification value)  $default,){
final _that = this;
switch (_that) {
case _Classification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Classification value)?  $default,){
final _that = this;
switch (_that) {
case _Classification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String topClass,  double topConfidence,  List<String> top5Classes,  List<double> top5Confidences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Classification() when $default != null:
return $default(_that.topClass,_that.topConfidence,_that.top5Classes,_that.top5Confidences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String topClass,  double topConfidence,  List<String> top5Classes,  List<double> top5Confidences)  $default,) {final _that = this;
switch (_that) {
case _Classification():
return $default(_that.topClass,_that.topConfidence,_that.top5Classes,_that.top5Confidences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String topClass,  double topConfidence,  List<String> top5Classes,  List<double> top5Confidences)?  $default,) {final _that = this;
switch (_that) {
case _Classification() when $default != null:
return $default(_that.topClass,_that.topConfidence,_that.top5Classes,_that.top5Confidences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Classification implements Classification {
  const _Classification({required this.topClass, required this.topConfidence, required final  List<String> top5Classes, required final  List<double> top5Confidences}): _top5Classes = top5Classes,_top5Confidences = top5Confidences;
  factory _Classification.fromJson(Map<String, dynamic> json) => _$ClassificationFromJson(json);

@override final  String topClass;
@override final  double topConfidence;
 final  List<String> _top5Classes;
@override List<String> get top5Classes {
  if (_top5Classes is EqualUnmodifiableListView) return _top5Classes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top5Classes);
}

 final  List<double> _top5Confidences;
@override List<double> get top5Confidences {
  if (_top5Confidences is EqualUnmodifiableListView) return _top5Confidences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_top5Confidences);
}


/// Create a copy of Classification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassificationCopyWith<_Classification> get copyWith => __$ClassificationCopyWithImpl<_Classification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClassificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Classification&&(identical(other.topClass, topClass) || other.topClass == topClass)&&(identical(other.topConfidence, topConfidence) || other.topConfidence == topConfidence)&&const DeepCollectionEquality().equals(other._top5Classes, _top5Classes)&&const DeepCollectionEquality().equals(other._top5Confidences, _top5Confidences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topClass,topConfidence,const DeepCollectionEquality().hash(_top5Classes),const DeepCollectionEquality().hash(_top5Confidences));

@override
String toString() {
  return 'Classification(topClass: $topClass, topConfidence: $topConfidence, top5Classes: $top5Classes, top5Confidences: $top5Confidences)';
}


}

/// @nodoc
abstract mixin class _$ClassificationCopyWith<$Res> implements $ClassificationCopyWith<$Res> {
  factory _$ClassificationCopyWith(_Classification value, $Res Function(_Classification) _then) = __$ClassificationCopyWithImpl;
@override @useResult
$Res call({
 String topClass, double topConfidence, List<String> top5Classes, List<double> top5Confidences
});




}
/// @nodoc
class __$ClassificationCopyWithImpl<$Res>
    implements _$ClassificationCopyWith<$Res> {
  __$ClassificationCopyWithImpl(this._self, this._then);

  final _Classification _self;
  final $Res Function(_Classification) _then;

/// Create a copy of Classification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topClass = null,Object? topConfidence = null,Object? top5Classes = null,Object? top5Confidences = null,}) {
  return _then(_Classification(
topClass: null == topClass ? _self.topClass : topClass // ignore: cast_nullable_to_non_nullable
as String,topConfidence: null == topConfidence ? _self.topConfidence : topConfidence // ignore: cast_nullable_to_non_nullable
as double,top5Classes: null == top5Classes ? _self._top5Classes : top5Classes // ignore: cast_nullable_to_non_nullable
as List<String>,top5Confidences: null == top5Confidences ? _self._top5Confidences : top5Confidences // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}


/// @nodoc
mixin _$Detection {

 int get classIndex; String get className; double get confidence; BoundingBox get boundingBox; BoundingBox get normalizedBox;
/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectionCopyWith<Detection> get copyWith => _$DetectionCopyWithImpl<Detection>(this as Detection, _$identity);

  /// Serializes this Detection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Detection&&(identical(other.classIndex, classIndex) || other.classIndex == classIndex)&&(identical(other.className, className) || other.className == className)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.normalizedBox, normalizedBox) || other.normalizedBox == normalizedBox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classIndex,className,confidence,boundingBox,normalizedBox);

@override
String toString() {
  return 'Detection(classIndex: $classIndex, className: $className, confidence: $confidence, boundingBox: $boundingBox, normalizedBox: $normalizedBox)';
}


}

/// @nodoc
abstract mixin class $DetectionCopyWith<$Res>  {
  factory $DetectionCopyWith(Detection value, $Res Function(Detection) _then) = _$DetectionCopyWithImpl;
@useResult
$Res call({
 int classIndex, String className, double confidence, BoundingBox boundingBox, BoundingBox normalizedBox
});


$BoundingBoxCopyWith<$Res> get boundingBox;$BoundingBoxCopyWith<$Res> get normalizedBox;

}
/// @nodoc
class _$DetectionCopyWithImpl<$Res>
    implements $DetectionCopyWith<$Res> {
  _$DetectionCopyWithImpl(this._self, this._then);

  final Detection _self;
  final $Res Function(Detection) _then;

/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? classIndex = null,Object? className = null,Object? confidence = null,Object? boundingBox = null,Object? normalizedBox = null,}) {
  return _then(_self.copyWith(
classIndex: null == classIndex ? _self.classIndex : classIndex // ignore: cast_nullable_to_non_nullable
as int,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,boundingBox: null == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as BoundingBox,normalizedBox: null == normalizedBox ? _self.normalizedBox : normalizedBox // ignore: cast_nullable_to_non_nullable
as BoundingBox,
  ));
}
/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundingBoxCopyWith<$Res> get boundingBox {
  
  return $BoundingBoxCopyWith<$Res>(_self.boundingBox, (value) {
    return _then(_self.copyWith(boundingBox: value));
  });
}/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundingBoxCopyWith<$Res> get normalizedBox {
  
  return $BoundingBoxCopyWith<$Res>(_self.normalizedBox, (value) {
    return _then(_self.copyWith(normalizedBox: value));
  });
}
}


/// Adds pattern-matching-related methods to [Detection].
extension DetectionPatterns on Detection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Detection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Detection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Detection value)  $default,){
final _that = this;
switch (_that) {
case _Detection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Detection value)?  $default,){
final _that = this;
switch (_that) {
case _Detection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int classIndex,  String className,  double confidence,  BoundingBox boundingBox,  BoundingBox normalizedBox)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Detection() when $default != null:
return $default(_that.classIndex,_that.className,_that.confidence,_that.boundingBox,_that.normalizedBox);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int classIndex,  String className,  double confidence,  BoundingBox boundingBox,  BoundingBox normalizedBox)  $default,) {final _that = this;
switch (_that) {
case _Detection():
return $default(_that.classIndex,_that.className,_that.confidence,_that.boundingBox,_that.normalizedBox);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int classIndex,  String className,  double confidence,  BoundingBox boundingBox,  BoundingBox normalizedBox)?  $default,) {final _that = this;
switch (_that) {
case _Detection() when $default != null:
return $default(_that.classIndex,_that.className,_that.confidence,_that.boundingBox,_that.normalizedBox);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Detection implements Detection {
  const _Detection({required this.classIndex, required this.className, required this.confidence, required this.boundingBox, required this.normalizedBox});
  factory _Detection.fromJson(Map<String, dynamic> json) => _$DetectionFromJson(json);

@override final  int classIndex;
@override final  String className;
@override final  double confidence;
@override final  BoundingBox boundingBox;
@override final  BoundingBox normalizedBox;

/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectionCopyWith<_Detection> get copyWith => __$DetectionCopyWithImpl<_Detection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Detection&&(identical(other.classIndex, classIndex) || other.classIndex == classIndex)&&(identical(other.className, className) || other.className == className)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.normalizedBox, normalizedBox) || other.normalizedBox == normalizedBox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,classIndex,className,confidence,boundingBox,normalizedBox);

@override
String toString() {
  return 'Detection(classIndex: $classIndex, className: $className, confidence: $confidence, boundingBox: $boundingBox, normalizedBox: $normalizedBox)';
}


}

/// @nodoc
abstract mixin class _$DetectionCopyWith<$Res> implements $DetectionCopyWith<$Res> {
  factory _$DetectionCopyWith(_Detection value, $Res Function(_Detection) _then) = __$DetectionCopyWithImpl;
@override @useResult
$Res call({
 int classIndex, String className, double confidence, BoundingBox boundingBox, BoundingBox normalizedBox
});


@override $BoundingBoxCopyWith<$Res> get boundingBox;@override $BoundingBoxCopyWith<$Res> get normalizedBox;

}
/// @nodoc
class __$DetectionCopyWithImpl<$Res>
    implements _$DetectionCopyWith<$Res> {
  __$DetectionCopyWithImpl(this._self, this._then);

  final _Detection _self;
  final $Res Function(_Detection) _then;

/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? classIndex = null,Object? className = null,Object? confidence = null,Object? boundingBox = null,Object? normalizedBox = null,}) {
  return _then(_Detection(
classIndex: null == classIndex ? _self.classIndex : classIndex // ignore: cast_nullable_to_non_nullable
as int,className: null == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,boundingBox: null == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as BoundingBox,normalizedBox: null == normalizedBox ? _self.normalizedBox : normalizedBox // ignore: cast_nullable_to_non_nullable
as BoundingBox,
  ));
}

/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundingBoxCopyWith<$Res> get boundingBox {
  
  return $BoundingBoxCopyWith<$Res>(_self.boundingBox, (value) {
    return _then(_self.copyWith(boundingBox: value));
  });
}/// Create a copy of Detection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoundingBoxCopyWith<$Res> get normalizedBox {
  
  return $BoundingBoxCopyWith<$Res>(_self.normalizedBox, (value) {
    return _then(_self.copyWith(normalizedBox: value));
  });
}
}


/// @nodoc
mixin _$BoundingBox {

 double get left; double get top; double get right; double get bottom;
/// Create a copy of BoundingBox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoundingBoxCopyWith<BoundingBox> get copyWith => _$BoundingBoxCopyWithImpl<BoundingBox>(this as BoundingBox, _$identity);

  /// Serializes this BoundingBox to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoundingBox&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,top,right,bottom);

@override
String toString() {
  return 'BoundingBox(left: $left, top: $top, right: $right, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class $BoundingBoxCopyWith<$Res>  {
  factory $BoundingBoxCopyWith(BoundingBox value, $Res Function(BoundingBox) _then) = _$BoundingBoxCopyWithImpl;
@useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class _$BoundingBoxCopyWithImpl<$Res>
    implements $BoundingBoxCopyWith<$Res> {
  _$BoundingBoxCopyWithImpl(this._self, this._then);

  final BoundingBox _self;
  final $Res Function(BoundingBox) _then;

/// Create a copy of BoundingBox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(_self.copyWith(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BoundingBox].
extension BoundingBoxPatterns on BoundingBox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoundingBox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoundingBox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoundingBox value)  $default,){
final _that = this;
switch (_that) {
case _BoundingBox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoundingBox value)?  $default,){
final _that = this;
switch (_that) {
case _BoundingBox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoundingBox() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom)  $default,) {final _that = this;
switch (_that) {
case _BoundingBox():
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double left,  double top,  double right,  double bottom)?  $default,) {final _that = this;
switch (_that) {
case _BoundingBox() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoundingBox implements BoundingBox {
  const _BoundingBox({required this.left, required this.top, required this.right, required this.bottom});
  factory _BoundingBox.fromJson(Map<String, dynamic> json) => _$BoundingBoxFromJson(json);

@override final  double left;
@override final  double top;
@override final  double right;
@override final  double bottom;

/// Create a copy of BoundingBox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoundingBoxCopyWith<_BoundingBox> get copyWith => __$BoundingBoxCopyWithImpl<_BoundingBox>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoundingBoxToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoundingBox&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,top,right,bottom);

@override
String toString() {
  return 'BoundingBox(left: $left, top: $top, right: $right, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class _$BoundingBoxCopyWith<$Res> implements $BoundingBoxCopyWith<$Res> {
  factory _$BoundingBoxCopyWith(_BoundingBox value, $Res Function(_BoundingBox) _then) = __$BoundingBoxCopyWithImpl;
@override @useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class __$BoundingBoxCopyWithImpl<$Res>
    implements _$BoundingBoxCopyWith<$Res> {
  __$BoundingBoxCopyWithImpl(this._self, this._then);

  final _BoundingBox _self;
  final $Res Function(_BoundingBox) _then;

/// Create a copy of BoundingBox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(_BoundingBox(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
