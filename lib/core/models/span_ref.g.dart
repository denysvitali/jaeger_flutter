// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'span_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpanRef _$SpanRefFromJson(Map<String, dynamic> json) => _SpanRef(
  refType: json['refType'] as String,
  traceID: json['traceID'] as String,
  spanID: json['spanID'] as String,
);

Map<String, dynamic> _$SpanRefToJson(_SpanRef instance) => <String, dynamic>{
  'refType': instance.refType,
  'traceID': instance.traceID,
  'spanID': instance.spanID,
};
