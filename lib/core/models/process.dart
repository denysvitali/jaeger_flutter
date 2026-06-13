import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_value.dart';

part 'process.freezed.dart';
part 'process.g.dart';

@freezed
abstract class Process with _$Process {
  const factory Process({
    required String serviceName,
    @Default(<KeyValue>[]) List<KeyValue> tags,
  }) = _Process;

  factory Process.fromJson(Map<String, dynamic> json) =>
      _$ProcessFromJson(json);
}
