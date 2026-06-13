import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_value.dart';
import 'log_record.dart';
import 'span_ref.dart';

part 'span.freezed.dart';
part 'span.g.dart';

@freezed
abstract class Span with _$Span {
  const factory Span({
    required String traceID,
    required String spanID,
    required String operationName,
    @Default(<SpanRef>[]) List<SpanRef> references,
    required int startTime,
    required int duration,
    @Default(<KeyValue>[]) List<KeyValue> tags,
    @Default(<LogRecord>[]) List<LogRecord> logs,
    required String processID,
    List<String>? warnings,
  }) = _Span;

  factory Span.fromJson(Map<String, dynamic> json) => _$SpanFromJson(json);
}
