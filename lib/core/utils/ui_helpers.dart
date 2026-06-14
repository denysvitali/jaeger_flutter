import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A curated set of distinct colors used to identify services consistently.
const _serviceColors = <Color>[
  Color(0xFF007C89),
  Color(0xFF2563EB),
  Color(0xFF0891B2),
  Color(0xFF16A34A),
  Color(0xFF7C3AED),
  Color(0xFF0F766E),
  Color(0xFF475569),
  Color(0xFF4F46E5),
  Color(0xFF0EA5E9),
  Color(0xFF65A30D),
  Color(0xFF0284C7),
  Color(0xFF059669),
  Color(0xFF6D28D9),
  Color(0xFF155E75),
  Color(0xFF64748B),
  Color(0xFF0369A1),
];

/// Returns a stable color for the given [service] name.
Color serviceColor(String service) {
  if (service.isEmpty) return _serviceColors.last;
  var hash = 0;
  for (var i = 0; i < service.length; i++) {
    hash = ((hash << 5) - hash) + service.codeUnitAt(i);
    hash &= 0xFFFFFFFF;
  }
  return _serviceColors[hash.abs() % _serviceColors.length];
}

/// Formats a microsecond duration like Jaeger does.
String formatDuration(int microseconds) {
  if (microseconds < 1000) return '$microsecondsμs';
  if (microseconds < 1000000) {
    return '${(microseconds / 1000).toStringAsFixed(2)}ms';
  }
  return '${(microseconds / 1000000).toStringAsFixed(2)}s';
}

/// Formats an absolute timestamp with milliseconds.
String formatTimestamp(int microseconds) =>
    _timestampFormat.format(DateTime.fromMicrosecondsSinceEpoch(microseconds));

final _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

/// Formats a time of day with milliseconds.
String formatTimeOfDay(int microseconds) =>
    _timeFormat.format(DateTime.fromMicrosecondsSinceEpoch(microseconds));

final _timeFormat = DateFormat('HH:mm:ss.SSS');

/// Returns a concise label for a time range, e.g. "0ms", "150.5ms".
String formatTimeAxisLabel(int microseconds) {
  if (microseconds < 1000) return '$microsecondsμs';
  if (microseconds < 1000000) {
    return '${(microseconds / 1000).toStringAsFixed(1)}ms';
  }
  return '${(microseconds / 1000000).toStringAsFixed(2)}s';
}

/// Computes nice tick values for a timeline axis of the given [duration].
List<int> timelineTicks(int duration, {int maxTicks = 6}) {
  if (duration <= 0) return const [0];
  final rough = duration / max(1, maxTicks - 1);
  final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
  final residual = rough / magnitude;
  final step =
      (residual <= 1
          ? 1
          : residual <= 2
          ? 2
          : residual <= 5
          ? 5
          : 10) *
      magnitude;

  final ticks = <int>[];
  for (var t = 0.0; t <= duration; t += step) {
    ticks.add(t.toInt());
  }
  if (ticks.last != duration) ticks.add(duration);
  return ticks;
}
