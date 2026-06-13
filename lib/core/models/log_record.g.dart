// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogRecord _$LogRecordFromJson(Map<String, dynamic> json) => _LogRecord(
  timestamp: (json['timestamp'] as num).toInt(),
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => KeyValue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValue>[],
);

Map<String, dynamic> _$LogRecordToJson(_LogRecord instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
    };
