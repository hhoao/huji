// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChunkInfo {

 int get partNumber; int get startByte; int get endByte; String? get eTag; bool get isUploaded; int? get uploadedAt;
/// Create a copy of ChunkInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChunkInfoCopyWith<ChunkInfo> get copyWith => _$ChunkInfoCopyWithImpl<ChunkInfo>(this as ChunkInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChunkInfo&&(identical(other.partNumber, partNumber) || other.partNumber == partNumber)&&(identical(other.startByte, startByte) || other.startByte == startByte)&&(identical(other.endByte, endByte) || other.endByte == endByte)&&(identical(other.eTag, eTag) || other.eTag == eTag)&&(identical(other.isUploaded, isUploaded) || other.isUploaded == isUploaded)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,partNumber,startByte,endByte,eTag,isUploaded,uploadedAt);

@override
String toString() {
  return 'ChunkInfo(partNumber: $partNumber, startByte: $startByte, endByte: $endByte, eTag: $eTag, isUploaded: $isUploaded, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $ChunkInfoCopyWith<$Res>  {
  factory $ChunkInfoCopyWith(ChunkInfo value, $Res Function(ChunkInfo) _then) = _$ChunkInfoCopyWithImpl;
@useResult
$Res call({
 int partNumber, int startByte, int endByte, String? eTag, bool isUploaded, int? uploadedAt
});




}
/// @nodoc
class _$ChunkInfoCopyWithImpl<$Res>
    implements $ChunkInfoCopyWith<$Res> {
  _$ChunkInfoCopyWithImpl(this._self, this._then);

  final ChunkInfo _self;
  final $Res Function(ChunkInfo) _then;

/// Create a copy of ChunkInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? partNumber = null,Object? startByte = null,Object? endByte = null,Object? eTag = freezed,Object? isUploaded = null,Object? uploadedAt = freezed,}) {
  return _then(ChunkInfo(
partNumber: null == partNumber ? _self.partNumber : partNumber // ignore: cast_nullable_to_non_nullable
as int,startByte: null == startByte ? _self.startByte : startByte // ignore: cast_nullable_to_non_nullable
as int,endByte: null == endByte ? _self.endByte : endByte // ignore: cast_nullable_to_non_nullable
as int,eTag: freezed == eTag ? _self.eTag : eTag // ignore: cast_nullable_to_non_nullable
as String?,isUploaded: null == isUploaded ? _self.isUploaded : isUploaded // ignore: cast_nullable_to_non_nullable
as bool,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChunkInfo].
extension ChunkInfoPatterns on ChunkInfo {
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
mixin _$UploadTask {

 String get id; String get filePath; String get fileName; String? get directory; String? get contentType; int get fileSize; int get chunkSize; List<ChunkInfo> get chunks; String? get uploadId; set uploadId(String? value); String? get path; set path(String? value); UploadStatus get status; set status(UploadStatus value); double get progress; set progress(double value); String? get error; set error(String? value); int get createdAt; int? get updatedAt; set updatedAt(int? value); int get retryCount; set retryCount(int value); int get maxRetries; bool get multipartUploaded; set multipartUploaded(bool value);// after upload
 int? get configId;// after upload
 set configId(int? value); String? get uploadUrl; set uploadUrl(String? value); String? get remotePath; set remotePath(String? value);
/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadTaskCopyWith<UploadTask> get copyWith => _$UploadTaskCopyWithImpl<UploadTask>(this as UploadTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.directory, directory) || other.directory == directory)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.chunkSize, chunkSize) || other.chunkSize == chunkSize)&&const DeepCollectionEquality().equals(other.chunks, chunks)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.error, error) || other.error == error)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.multipartUploaded, multipartUploaded) || other.multipartUploaded == multipartUploaded)&&(identical(other.configId, configId) || other.configId == configId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.remotePath, remotePath) || other.remotePath == remotePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,filePath,fileName,directory,contentType,fileSize,chunkSize,const DeepCollectionEquality().hash(chunks),uploadId,path,status,progress,error,createdAt,updatedAt,retryCount,maxRetries,multipartUploaded,configId,uploadUrl,remotePath]);

@override
String toString() {
  return 'UploadTask(id: $id, filePath: $filePath, fileName: $fileName, directory: $directory, contentType: $contentType, fileSize: $fileSize, chunkSize: $chunkSize, chunks: $chunks, uploadId: $uploadId, path: $path, status: $status, progress: $progress, error: $error, createdAt: $createdAt, updatedAt: $updatedAt, retryCount: $retryCount, maxRetries: $maxRetries, multipartUploaded: $multipartUploaded, configId: $configId, uploadUrl: $uploadUrl, remotePath: $remotePath)';
}


}

/// @nodoc
abstract mixin class $UploadTaskCopyWith<$Res>  {
  factory $UploadTaskCopyWith(UploadTask value, $Res Function(UploadTask) _then) = _$UploadTaskCopyWithImpl;
@useResult
$Res call({
 String id, String filePath, String fileName, String? directory, String? contentType, int fileSize, int chunkSize, List<ChunkInfo> chunks, String? uploadId, String? path, UploadStatus status, double progress, String? error, int createdAt, int? updatedAt, int retryCount, int maxRetries, int? configId, String? uploadUrl, String? remotePath, bool multipartUploaded
});




}
/// @nodoc
class _$UploadTaskCopyWithImpl<$Res>
    implements $UploadTaskCopyWith<$Res> {
  _$UploadTaskCopyWithImpl(this._self, this._then);

  final UploadTask _self;
  final $Res Function(UploadTask) _then;

/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filePath = null,Object? fileName = null,Object? directory = freezed,Object? contentType = freezed,Object? fileSize = null,Object? chunkSize = null,Object? chunks = null,Object? uploadId = freezed,Object? path = freezed,Object? status = null,Object? progress = null,Object? error = freezed,Object? createdAt = null,Object? updatedAt = freezed,Object? retryCount = null,Object? maxRetries = null,Object? configId = freezed,Object? uploadUrl = freezed,Object? remotePath = freezed,Object? multipartUploaded = null,}) {
  return _then(UploadTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,directory: freezed == directory ? _self.directory : directory // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,chunkSize: null == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int,chunks: null == chunks ? _self.chunks : chunks // ignore: cast_nullable_to_non_nullable
as List<ChunkInfo>,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UploadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,configId: freezed == configId ? _self.configId : configId // ignore: cast_nullable_to_non_nullable
as int?,uploadUrl: freezed == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String?,remotePath: freezed == remotePath ? _self.remotePath : remotePath // ignore: cast_nullable_to_non_nullable
as String?,multipartUploaded: null == multipartUploaded ? _self.multipartUploaded : multipartUploaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadTask].
extension UploadTaskPatterns on UploadTask {
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
