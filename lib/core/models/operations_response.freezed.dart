// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operations_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OperationsResponse {

 List<String> get data; int get total; int get limit; int get offset; List<String>? get errors;
/// Create a copy of OperationsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationsResponseCopyWith<OperationsResponse> get copyWith => _$OperationsResponseCopyWithImpl<OperationsResponse>(this as OperationsResponse, _$identity);

  /// Serializes this OperationsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationsResponse&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&const DeepCollectionEquality().equals(other.errors, errors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),total,limit,offset,const DeepCollectionEquality().hash(errors));

@override
String toString() {
  return 'OperationsResponse(data: $data, total: $total, limit: $limit, offset: $offset, errors: $errors)';
}


}

/// @nodoc
abstract mixin class $OperationsResponseCopyWith<$Res>  {
  factory $OperationsResponseCopyWith(OperationsResponse value, $Res Function(OperationsResponse) _then) = _$OperationsResponseCopyWithImpl;
@useResult
$Res call({
 List<String> data, int total, int limit, int offset, List<String>? errors
});




}
/// @nodoc
class _$OperationsResponseCopyWithImpl<$Res>
    implements $OperationsResponseCopyWith<$Res> {
  _$OperationsResponseCopyWithImpl(this._self, this._then);

  final OperationsResponse _self;
  final $Res Function(OperationsResponse) _then;

/// Create a copy of OperationsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? total = null,Object? limit = null,Object? offset = null,Object? errors = freezed,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<String>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,errors: freezed == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [OperationsResponse].
extension OperationsResponsePatterns on OperationsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationsResponse value)  $default,){
final _that = this;
switch (_that) {
case _OperationsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OperationsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> data,  int total,  int limit,  int offset,  List<String>? errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationsResponse() when $default != null:
return $default(_that.data,_that.total,_that.limit,_that.offset,_that.errors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> data,  int total,  int limit,  int offset,  List<String>? errors)  $default,) {final _that = this;
switch (_that) {
case _OperationsResponse():
return $default(_that.data,_that.total,_that.limit,_that.offset,_that.errors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> data,  int total,  int limit,  int offset,  List<String>? errors)?  $default,) {final _that = this;
switch (_that) {
case _OperationsResponse() when $default != null:
return $default(_that.data,_that.total,_that.limit,_that.offset,_that.errors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationsResponse implements OperationsResponse {
  const _OperationsResponse({final  List<String> data = const <String>[], this.total = 0, this.limit = 0, this.offset = 0, final  List<String>? errors}): _data = data,_errors = errors;
  factory _OperationsResponse.fromJson(Map<String, dynamic> json) => _$OperationsResponseFromJson(json);

 final  List<String> _data;
@override@JsonKey() List<String> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override@JsonKey() final  int total;
@override@JsonKey() final  int limit;
@override@JsonKey() final  int offset;
 final  List<String>? _errors;
@override List<String>? get errors {
  final value = _errors;
  if (value == null) return null;
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of OperationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationsResponseCopyWith<_OperationsResponse> get copyWith => __$OperationsResponseCopyWithImpl<_OperationsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationsResponse&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&const DeepCollectionEquality().equals(other._errors, _errors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),total,limit,offset,const DeepCollectionEquality().hash(_errors));

@override
String toString() {
  return 'OperationsResponse(data: $data, total: $total, limit: $limit, offset: $offset, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$OperationsResponseCopyWith<$Res> implements $OperationsResponseCopyWith<$Res> {
  factory _$OperationsResponseCopyWith(_OperationsResponse value, $Res Function(_OperationsResponse) _then) = __$OperationsResponseCopyWithImpl;
@override @useResult
$Res call({
 List<String> data, int total, int limit, int offset, List<String>? errors
});




}
/// @nodoc
class __$OperationsResponseCopyWithImpl<$Res>
    implements _$OperationsResponseCopyWith<$Res> {
  __$OperationsResponseCopyWithImpl(this._self, this._then);

  final _OperationsResponse _self;
  final $Res Function(_OperationsResponse) _then;

/// Create a copy of OperationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? total = null,Object? limit = null,Object? offset = null,Object? errors = freezed,}) {
  return _then(_OperationsResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<String>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,errors: freezed == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
