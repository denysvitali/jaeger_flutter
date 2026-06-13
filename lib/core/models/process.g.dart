// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Process _$ProcessFromJson(Map<String, dynamic> json) => _Process(
  serviceName: json['serviceName'] as String,
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => KeyValue.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValue>[],
);

Map<String, dynamic> _$ProcessToJson(_Process instance) => <String, dynamic>{
  'serviceName': instance.serviceName,
  'tags': instance.tags.map((e) => e.toJson()).toList(),
};
