// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'span.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Span _$SpanFromJson(Map<String, dynamic> json) => _Span(
  traceID: json['traceID'] as String,
  spanID: json['spanID'] as String,
  operationName: json['operationName'] as String,
  references:
      (json['references'] as List<dynamic>?)
          ?.map((e) => SpanRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SpanRef>[],
  startTime: (json['startTime'] as num).toInt(),
  duration: (json['duration'] as num).toInt(),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => KeyValue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValue>[],
  logs:
      (json['logs'] as List<dynamic>?)
          ?.map((e) => LogRecord.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LogRecord>[],
  processID: json['processID'] as String,
  warnings: (json['warnings'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SpanToJson(_Span instance) => <String, dynamic>{
  'traceID': instance.traceID,
  'spanID': instance.spanID,
  'operationName': instance.operationName,
  'references': instance.references.map((e) => e.toJson()).toList(),
  'startTime': instance.startTime,
  'duration': instance.duration,
  'tags': instance.tags.map((e) => e.toJson()).toList(),
  'logs': instance.logs.map((e) => e.toJson()).toList(),
  'processID': instance.processID,
  'warnings': ?instance.warnings,
};
