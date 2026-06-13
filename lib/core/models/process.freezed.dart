// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'process.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Process {

 String get serviceName; List<KeyValue> get tags;
/// Create a copy of Process
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessCopyWith<Process> get copyWith => _$ProcessCopyWithImpl<Process>(this as Process, _$identity);

  /// Serializes this Process to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Process&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'Process(serviceName: $serviceName, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ProcessCopyWith<$Res>  {
  factory $ProcessCopyWith(Process value, $Res Function(Process) _then) = _$ProcessCopyWithImpl;
@useResult
$Res call({
 String serviceName, List<KeyValue> tags
});




}
/// @nodoc
class _$ProcessCopyWithImpl<$Res>
    implements $ProcessCopyWith<$Res> {
  _$ProcessCopyWithImpl(this._self, this._then);

  final Process _self;
  final $Res Function(Process) _then;

/// Create a copy of Process
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceName = null,Object? tags = null,}) {
  return _then(_self.copyWith(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [Process].
extension ProcessPatterns on Process {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Process value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Process() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Process value)  $default,){
final _that = this;
switch (_that) {
case _Process():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Process value)?  $default,){
final _that = this;
switch (_that) {
case _Process() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serviceName,  List<KeyValue> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Process() when $default != null:
return $default(_that.serviceName,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serviceName,  List<KeyValue> tags)  $default,) {final _that = this;
switch (_that) {
case _Process():
return $default(_that.serviceName,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serviceName,  List<KeyValue> tags)?  $default,) {final _that = this;
switch (_that) {
case _Process() when $default != null:
return $default(_that.serviceName,_that.tags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Process implements Process {
  const _Process({required this.serviceName, final  List<KeyValue> tags = const <KeyValue>[]}): _tags = tags;
  factory _Process.fromJson(Map<String, dynamic> json) => _$ProcessFromJson(json);

@override final  String serviceName;
 final  List<KeyValue> _tags;
@override@JsonKey() List<KeyValue> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of Process
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessCopyWith<_Process> get copyWith => __$ProcessCopyWithImpl<_Process>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProcessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Process&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'Process(serviceName: $serviceName, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ProcessCopyWith<$Res> implements $ProcessCopyWith<$Res> {
  factory _$ProcessCopyWith(_Process value, $Res Function(_Process) _then) = __$ProcessCopyWithImpl;
@override @useResult
$Res call({
 String serviceName, List<KeyValue> tags
});




}
/// @nodoc
class __$ProcessCopyWithImpl<$Res>
    implements _$ProcessCopyWith<$Res> {
  __$ProcessCopyWithImpl(this._self, this._then);

  final _Process _self;
  final $Res Function(_Process) _then;

/// Create a copy of Process
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceName = null,Object? tags = null,}) {
  return _then(_Process(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,
  ));
}


}

// dart format on
