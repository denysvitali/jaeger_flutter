import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_value.freezed.dart';
part 'key_value.g.dart';

@freezed
abstract class KeyValue with _$KeyValue {
  const factory KeyValue({
    required String key,
    required String type,
    required Object? value,
  }) = _KeyValue;

  factory KeyValue.fromJson(Map<String, dynamic> json) =>
      _$KeyValueFromJson(json);
}
