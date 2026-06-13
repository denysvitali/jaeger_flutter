import 'package:freezed_annotation/freezed_annotation.dart';

part 'operations_response.freezed.dart';
part 'operations_response.g.dart';

@freezed
abstract class OperationsResponse with _$OperationsResponse {
  const factory OperationsResponse({
    @Default(<String>[]) List<String> data,
    @Default(0) int total,
    @Default(0) int limit,
    @Default(0) int offset,
    List<String>? errors,
  }) = _OperationsResponse;

  factory OperationsResponse.fromJson(Map<String, dynamic> json) =>
      _$OperationsResponseFromJson(json);
}
