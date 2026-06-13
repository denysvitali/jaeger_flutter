// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KeyValue _$KeyValueFromJson(Map<String, dynamic> json) => _KeyValue(
  key: json['key'] as String,
  type: json['type'] as String,
  value: json['value'],
);

Map<String, dynamic> _$KeyValueToJson(_KeyValue instance) => <String, dynamic>{
  'key': instance.key,
  'type': instance.type,
  'value': ?instance.value,
};
