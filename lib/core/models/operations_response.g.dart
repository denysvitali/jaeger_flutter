// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operations_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OperationsResponse _$OperationsResponseFromJson(Map<String, dynamic> json) =>
    _OperationsResponse(
      data:
          (json['data'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$OperationsResponseToJson(_OperationsResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
      'errors': ?instance.errors,
    };
