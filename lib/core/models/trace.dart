import 'package:freezed_annotation/freezed_annotation.dart';

import 'process.dart';
import 'span.dart';

part 'trace.freezed.dart';
part 'trace.g.dart';

@freezed
abstract class Trace with _$Trace {
  const factory Trace({
    required String traceID,
    @Default(<Span>[]) List<Span> spans,
    @Default(<String, Process>{}) Map<String, Process> processes,
    List<String>? warnings,
  }) = _Trace;

  factory Trace.fromJson(Map<String, dynamic> json) => _$TraceFromJson(json);
}
