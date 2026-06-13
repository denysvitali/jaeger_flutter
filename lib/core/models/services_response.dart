import 'package:freezed_annotation/freezed_annotation.dart';

part 'services_response.freezed.dart';
part 'services_response.g.dart';

@freezed
abstract class ServicesResponse with _$ServicesResponse {
  const factory ServicesResponse({
    @Default(<String>[]) List<String> data,
    @Default(0) int total,
    @Default(0) int limit,
    @Default(0) int offset,
    List<String>? errors,
  }) = _ServicesResponse;

  factory ServicesResponse.fromJson(Map<String, dynamic> json) =>
      _$ServicesResponseFromJson(json);
}
