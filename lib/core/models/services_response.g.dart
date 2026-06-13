// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServicesResponse _$ServicesResponseFromJson(Map<String, dynamic> json) =>
    _ServicesResponse(
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

Map<String, dynamic> _$ServicesResponseToJson(_ServicesResponse instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
      'errors': ?instance.errors,
    };
