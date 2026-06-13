// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traces_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TracesResponse _$TracesResponseFromJson(Map<String, dynamic> json) =>
    _TracesResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => Trace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Trace>[],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TracesResponseToJson(_TracesResponse instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'limit': instance.limit,
      'offset': instance.offset,
      'errors': ?instance.errors,
    };
