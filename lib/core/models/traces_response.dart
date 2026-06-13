import 'package:freezed_annotation/freezed_annotation.dart';

import 'trace.dart';

part 'traces_response.freezed.dart';
part 'traces_response.g.dart';

@freezed
abstract class TracesResponse with _$TracesResponse {
  const factory TracesResponse({
    @Default(<Trace>[]) List<Trace> data,
    @Default(0) int total,
    @Default(0) int limit,
    @Default(0) int offset,
    List<String>? errors,
  }) = _TracesResponse;

  factory TracesResponse.fromJson(Map<String, dynamic> json) =>
      _$TracesResponseFromJson(json);
}
