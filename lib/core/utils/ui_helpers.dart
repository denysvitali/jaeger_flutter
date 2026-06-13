import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A curated set of distinct colors used to identify services consistently.
const _serviceColors = <Color>[
  Color(0xFFDC382D), // Jaeger red
  Color(0xFF1F77B4),
  Color(0xFFFF7F0E),
  Color(0xFF2CA02C),
  Color(0xFF9467BD),
  Color(0xFF8C564B),
  Color(0xFFE377C2),
  Color(0xFF7F7F7F),
  Color(0xFFBCBD22),
  Color(0xFF17BECF),
  Color(0xFFAEC7E8),
  Color(0xFFFFBB78),
  Color(0xFF98DF8A),
  Color(0xFFC5B0D5),
  Color(0xFFC49C94),
  Color(0xFFF7B6D2),
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
String formatTimestamp(int microseconds) => _timestampFormat.format(
  DateTime.fromMicrosecondsSinceEpoch(microseconds),
);

final _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

/// Formats a time of day with milliseconds.
String formatTimeOfDay(int microseconds) => _timeFormat.format(
  DateTime.fromMicrosecondsSinceEpoch(microseconds),
);

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
  final step = (residual <= 1
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
