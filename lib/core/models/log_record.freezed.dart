// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LogRecord {

 int get timestamp; List<KeyValue> get fields;
/// Create a copy of LogRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogRecordCopyWith<LogRecord> get copyWith => _$LogRecordCopyWithImpl<LogRecord>(this as LogRecord, _$identity);

  /// Serializes this LogRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogRecord&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.fields, fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,const DeepCollectionEquality().hash(fields));

@override
String toString() {
  return 'LogRecord(timestamp: $timestamp, fields: $fields)';
}


}

/// @nodoc
abstract mixin class $LogRecordCopyWith<$Res>  {
  factory $LogRecordCopyWith(LogRecord value, $Res Function(LogRecord) _then) = _$LogRecordCopyWithImpl;
@useResult
$Res call({
 int timestamp, List<KeyValue> fields
});




}
/// @nodoc
class _$LogRecordCopyWithImpl<$Res>
    implements $LogRecordCopyWith<$Res> {
  _$LogRecordCopyWithImpl(this._self, this._then);

  final LogRecord _self;
  final $Res Function(LogRecord) _then;

/// Create a copy of LogRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? fields = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [LogRecord].
extension LogRecordPatterns on LogRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogRecord value)  $default,){
final _that = this;
switch (_that) {
case _LogRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogRecord value)?  $default,){
final _that = this;
switch (_that) {
case _LogRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int timestamp,  List<KeyValue> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogRecord() when $default != null:
return $default(_that.timestamp,_that.fields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int timestamp,  List<KeyValue> fields)  $default,) {final _that = this;
switch (_that) {
case _LogRecord():
return $default(_that.timestamp,_that.fields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int timestamp,  List<KeyValue> fields)?  $default,) {final _that = this;
switch (_that) {
case _LogRecord() when $default != null:
return $default(_that.timestamp,_that.fields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogRecord implements LogRecord {
  const _LogRecord({required this.timestamp, final  List<KeyValue> fields = const <KeyValue>[]}): _fields = fields;
  factory _LogRecord.fromJson(Map<String, dynamic> json) => _$LogRecordFromJson(json);

@override final  int timestamp;
 final  List<KeyValue> _fields;
@override@JsonKey() List<KeyValue> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of LogRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogRecordCopyWith<_LogRecord> get copyWith => __$LogRecordCopyWithImpl<_LogRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogRecord&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._fields, _fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'LogRecord(timestamp: $timestamp, fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$LogRecordCopyWith<$Res> implements $LogRecordCopyWith<$Res> {
  factory _$LogRecordCopyWith(_LogRecord value, $Res Function(_LogRecord) _then) = __$LogRecordCopyWithImpl;
@override @useResult
$Res call({
 int timestamp, List<KeyValue> fields
});




}
/// @nodoc
class __$LogRecordCopyWithImpl<$Res>
    implements _$LogRecordCopyWith<$Res> {
  __$LogRecordCopyWithImpl(this._self, this._then);

  final _LogRecord _self;
  final $Res Function(_LogRecord) _then;

/// Create a copy of LogRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? fields = null,}) {
  return _then(_LogRecord(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,
  ));
}


}

// dart format on
