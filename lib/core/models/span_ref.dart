import 'package:freezed_annotation/freezed_annotation.dart';

part 'span_ref.freezed.dart';
part 'span_ref.g.dart';

@freezed
abstract class SpanRef with _$SpanRef {
  const factory SpanRef({
    required String refType,
    required String traceID,
    required String spanID,
  }) = _SpanRef;

  factory SpanRef.fromJson(Map<String, dynamic> json) =>
      _$SpanRefFromJson(json);
}
