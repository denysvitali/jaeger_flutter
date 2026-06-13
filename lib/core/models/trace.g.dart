// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trace _$TraceFromJson(Map<String, dynamic> json) => _Trace(
  traceID: json['traceID'] as String,
  spans:
      (json['spans'] as List<dynamic>?)
          ?.map((e) => Span.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Span>[],
  processes:
      (json['processes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Process.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, Process>{},
  warnings: (json['warnings'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TraceToJson(_Trace instance) => <String, dynamic>{
  'traceID': instance.traceID,
  'spans': instance.spans.map((e) => e.toJson()).toList(),
  'processes': instance.processes.map((k, e) => MapEntry(k, e.toJson())),
  'warnings': ?instance.warnings,
};
