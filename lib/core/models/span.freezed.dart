// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'span.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Span {

 String get traceID; String get spanID; String get operationName; List<SpanRef> get references; int get startTime; int get duration; List<KeyValue> get tags; List<LogRecord> get logs; String get processID; List<String>? get warnings;
/// Create a copy of Span
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpanCopyWith<Span> get copyWith => _$SpanCopyWithImpl<Span>(this as Span, _$identity);

  /// Serializes this Span to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Span&&(identical(other.traceID, traceID) || other.traceID == traceID)&&(identical(other.spanID, spanID) || other.spanID == spanID)&&(identical(other.operationName, operationName) || other.operationName == operationName)&&const DeepCollectionEquality().equals(other.references, references)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.logs, logs)&&(identical(other.processID, processID) || other.processID == processID)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traceID,spanID,operationName,const DeepCollectionEquality().hash(references),startTime,duration,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(logs),processID,const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'Span(traceID: $traceID, spanID: $spanID, operationName: $operationName, references: $references, startTime: $startTime, duration: $duration, tags: $tags, logs: $logs, processID: $processID, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $SpanCopyWith<$Res>  {
  factory $SpanCopyWith(Span value, $Res Function(Span) _then) = _$SpanCopyWithImpl;
@useResult
$Res call({
 String traceID, String spanID, String operationName, List<SpanRef> references, int startTime, int duration, List<KeyValue> tags, List<LogRecord> logs, String processID, List<String>? warnings
});




}
/// @nodoc
class _$SpanCopyWithImpl<$Res>
    implements $SpanCopyWith<$Res> {
  _$SpanCopyWithImpl(this._self, this._then);

  final Span _self;
  final $Res Function(Span) _then;

/// Create a copy of Span
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? traceID = null,Object? spanID = null,Object? operationName = null,Object? references = null,Object? startTime = null,Object? duration = null,Object? tags = null,Object? logs = null,Object? processID = null,Object? warnings = freezed,}) {
  return _then(_self.copyWith(
traceID: null == traceID ? _self.traceID : traceID // ignore: cast_nullable_to_non_nullable
as String,spanID: null == spanID ? _self.spanID : spanID // ignore: cast_nullable_to_non_nullable
as String,operationName: null == operationName ? _self.operationName : operationName // ignore: cast_nullable_to_non_nullable
as String,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as List<SpanRef>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as List<LogRecord>,processID: null == processID ? _self.processID : processID // ignore: cast_nullable_to_non_nullable
as String,warnings: freezed == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Span].
extension SpanPatterns on Span {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Span value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Span() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Span value)  $default,){
final _that = this;
switch (_that) {
case _Span():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Span value)?  $default,){
final _that = this;
switch (_that) {
case _Span() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String traceID,  String spanID,  String operationName,  List<SpanRef> references,  int startTime,  int duration,  List<KeyValue> tags,  List<LogRecord> logs,  String processID,  List<String>? warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Span() when $default != null:
return $default(_that.traceID,_that.spanID,_that.operationName,_that.references,_that.startTime,_that.duration,_that.tags,_that.logs,_that.processID,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String traceID,  String spanID,  String operationName,  List<SpanRef> references,  int startTime,  int duration,  List<KeyValue> tags,  List<LogRecord> logs,  String processID,  List<String>? warnings)  $default,) {final _that = this;
switch (_that) {
case _Span():
return $default(_that.traceID,_that.spanID,_that.operationName,_that.references,_that.startTime,_that.duration,_that.tags,_that.logs,_that.processID,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String traceID,  String spanID,  String operationName,  List<SpanRef> references,  int startTime,  int duration,  List<KeyValue> tags,  List<LogRecord> logs,  String processID,  List<String>? warnings)?  $default,) {final _that = this;
switch (_that) {
case _Span() when $default != null:
return $default(_that.traceID,_that.spanID,_that.operationName,_that.references,_that.startTime,_that.duration,_that.tags,_that.logs,_that.processID,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Span implements Span {
  const _Span({required this.traceID, required this.spanID, required this.operationName, final  List<SpanRef> references = const <SpanRef>[], required this.startTime, required this.duration, final  List<KeyValue> tags = const <KeyValue>[], final  List<LogRecord> logs = const <LogRecord>[], required this.processID, final  List<String>? warnings}): _references = references,_tags = tags,_logs = logs,_warnings = warnings;
  factory _Span.fromJson(Map<String, dynamic> json) => _$SpanFromJson(json);

@override final  String traceID;
@override final  String spanID;
@override final  String operationName;
 final  List<SpanRef> _references;
@override@JsonKey() List<SpanRef> get references {
  if (_references is EqualUnmodifiableListView) return _references;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_references);
}

@override final  int startTime;
@override final  int duration;
 final  List<KeyValue> _tags;
@override@JsonKey() List<KeyValue> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<LogRecord> _logs;
@override@JsonKey() List<LogRecord> get logs {
  if (_logs is EqualUnmodifiableListView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_logs);
}

@override final  String processID;
 final  List<String>? _warnings;
@override List<String>? get warnings {
  final value = _warnings;
  if (value == null) return null;
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Span
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpanCopyWith<_Span> get copyWith => __$SpanCopyWithImpl<_Span>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Span&&(identical(other.traceID, traceID) || other.traceID == traceID)&&(identical(other.spanID, spanID) || other.spanID == spanID)&&(identical(other.operationName, operationName) || other.operationName == operationName)&&const DeepCollectionEquality().equals(other._references, _references)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._logs, _logs)&&(identical(other.processID, processID) || other.processID == processID)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traceID,spanID,operationName,const DeepCollectionEquality().hash(_references),startTime,duration,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_logs),processID,const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'Span(traceID: $traceID, spanID: $spanID, operationName: $operationName, references: $references, startTime: $startTime, duration: $duration, tags: $tags, logs: $logs, processID: $processID, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$SpanCopyWith<$Res> implements $SpanCopyWith<$Res> {
  factory _$SpanCopyWith(_Span value, $Res Function(_Span) _then) = __$SpanCopyWithImpl;
@override @useResult
$Res call({
 String traceID, String spanID, String operationName, List<SpanRef> references, int startTime, int duration, List<KeyValue> tags, List<LogRecord> logs, String processID, List<String>? warnings
});




}
/// @nodoc
class __$SpanCopyWithImpl<$Res>
    implements _$SpanCopyWith<$Res> {
  __$SpanCopyWithImpl(this._self, this._then);

  final _Span _self;
  final $Res Function(_Span) _then;

/// Create a copy of Span
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? traceID = null,Object? spanID = null,Object? operationName = null,Object? references = null,Object? startTime = null,Object? duration = null,Object? tags = null,Object? logs = null,Object? processID = null,Object? warnings = freezed,}) {
  return _then(_Span(
traceID: null == traceID ? _self.traceID : traceID // ignore: cast_nullable_to_non_nullable
as String,spanID: null == spanID ? _self.spanID : spanID // ignore: cast_nullable_to_non_nullable
as String,operationName: null == operationName ? _self.operationName : operationName // ignore: cast_nullable_to_non_nullable
as String,references: null == references ? _self._references : references // ignore: cast_nullable_to_non_nullable
as List<SpanRef>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<KeyValue>,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as List<LogRecord>,processID: null == processID ? _self.processID : processID // ignore: cast_nullable_to_non_nullable
as String,warnings: freezed == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
