import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_value.dart';

part 'log_record.freezed.dart';
part 'log_record.g.dart';

@freezed
abstract class LogRecord with _$LogRecord {
  const factory LogRecord({
    required int timestamp,
    @Default(<KeyValue>[]) List<KeyValue> fields,
  }) = _LogRecord;

  factory LogRecord.fromJson(Map<String, dynamic> json) =>
      _$LogRecordFromJson(json);
}
