// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trace {

 String get traceID; List<Span> get spans; Map<String, Process> get processes; List<String>? get warnings;
/// Create a copy of Trace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TraceCopyWith<Trace> get copyWith => _$TraceCopyWithImpl<Trace>(this as Trace, _$identity);

  /// Serializes this Trace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trace&&(identical(other.traceID, traceID) || other.traceID == traceID)&&const DeepCollectionEquality().equals(other.spans, spans)&&const DeepCollectionEquality().equals(other.processes, processes)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traceID,const DeepCollectionEquality().hash(spans),const DeepCollectionEquality().hash(processes),const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'Trace(traceID: $traceID, spans: $spans, processes: $processes, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $TraceCopyWith<$Res>  {
  factory $TraceCopyWith(Trace value, $Res Function(Trace) _then) = _$TraceCopyWithImpl;
@useResult
$Res call({
 String traceID, List<Span> spans, Map<String, Process> processes, List<String>? warnings
});




}
/// @nodoc
class _$TraceCopyWithImpl<$Res>
    implements $TraceCopyWith<$Res> {
  _$TraceCopyWithImpl(this._self, this._then);

  final Trace _self;
  final $Res Function(Trace) _then;

/// Create a copy of Trace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? traceID = null,Object? spans = null,Object? processes = null,Object? warnings = freezed,}) {
  return _then(_self.copyWith(
traceID: null == traceID ? _self.traceID : traceID // ignore: cast_nullable_to_non_nullable
as String,spans: null == spans ? _self.spans : spans // ignore: cast_nullable_to_non_nullable
as List<Span>,processes: null == processes ? _self.processes : processes // ignore: cast_nullable_to_non_nullable
as Map<String, Process>,warnings: freezed == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Trace].
extension TracePatterns on Trace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trace value)  $default,){
final _that = this;
switch (_that) {
case _Trace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trace value)?  $default,){
final _that = this;
switch (_that) {
case _Trace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String traceID,  List<Span> spans,  Map<String, Process> processes,  List<String>? warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trace() when $default != null:
return $default(_that.traceID,_that.spans,_that.processes,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String traceID,  List<Span> spans,  Map<String, Process> processes,  List<String>? warnings)  $default,) {final _that = this;
switch (_that) {
case _Trace():
return $default(_that.traceID,_that.spans,_that.processes,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String traceID,  List<Span> spans,  Map<String, Process> processes,  List<String>? warnings)?  $default,) {final _that = this;
switch (_that) {
case _Trace() when $default != null:
return $default(_that.traceID,_that.spans,_that.processes,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trace implements Trace {
  const _Trace({required this.traceID, final  List<Span> spans = const <Span>[], final  Map<String, Process> processes = const <String, Process>{}, final  List<String>? warnings}): _spans = spans,_processes = processes,_warnings = warnings;
  factory _Trace.fromJson(Map<String, dynamic> json) => _$TraceFromJson(json);

@override final  String traceID;
 final  List<Span> _spans;
@override@JsonKey() List<Span> get spans {
  if (_spans is EqualUnmodifiableListView) return _spans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spans);
}

 final  Map<String, Process> _processes;
@override@JsonKey() Map<String, Process> get processes {
  if (_processes is EqualUnmodifiableMapView) return _processes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_processes);
}

 final  List<String>? _warnings;
@override List<String>? get warnings {
  final value = _warnings;
  if (value == null) return null;
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Trace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TraceCopyWith<_Trace> get copyWith => __$TraceCopyWithImpl<_Trace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TraceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trace&&(identical(other.traceID, traceID) || other.traceID == traceID)&&const DeepCollectionEquality().equals(other._spans, _spans)&&const DeepCollectionEquality().equals(other._processes, _processes)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traceID,const DeepCollectionEquality().hash(_spans),const DeepCollectionEquality().hash(_processes),const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'Trace(traceID: $traceID, spans: $spans, processes: $processes, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$TraceCopyWith<$Res> implements $TraceCopyWith<$Res> {
  factory _$TraceCopyWith(_Trace value, $Res Function(_Trace) _then) = __$TraceCopyWithImpl;
@override @useResult
$Res call({
 String traceID, List<Span> spans, Map<String, Process> processes, List<String>? warnings
});




}
/// @nodoc
class __$TraceCopyWithImpl<$Res>
    implements _$TraceCopyWith<$Res> {
  __$TraceCopyWithImpl(this._self, this._then);

  final _Trace _self;
  final $Res Function(_Trace) _then;

/// Create a copy of Trace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? traceID = null,Object? spans = null,Object? processes = null,Object? warnings = freezed,}) {
  return _then(_Trace(
traceID: null == traceID ? _self.traceID : traceID // ignore: cast_nullable_to_non_nullable
as String,spans: null == spans ? _self._spans : spans // ignore: cast_nullable_to_non_nullable
as List<Span>,processes: null == processes ? _self._processes : processes // ignore: cast_nullable_to_non_nullable
as Map<String, Process>,warnings: freezed == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
