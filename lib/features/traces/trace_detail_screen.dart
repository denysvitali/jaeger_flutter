import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ui_helpers.dart';

class TraceDetailScreen extends ConsumerWidget {
  const TraceDetailScreen({required this.traceId, super.key});

  final String traceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traceAsync = ref.watch(traceProvider(traceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(traceProvider(traceId)),
          ),
        ],
      ),
      body: traceAsync.when(
        data: (trace) => _TraceBody(trace: trace),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load trace: $e')),
      ),
    );
  }
}

class _TraceBody extends StatefulWidget {
  const _TraceBody({required this.trace});

  final Trace trace;

  @override
  State<_TraceBody> createState() => _TraceBodyState();
}

class _TraceBodyState extends State<_TraceBody> {
  static const double _minTimelineScale = 1.0;
  static const double _maxTimelineScale = 20.0;
  static const double _scaleStep = 1.25;

  late final int _traceStartUs;
  late final int _traceEndUs;
  late final int _traceDurationUs;
  late final List<Span> _roots;
  late final Map<String, List<Span>> _childrenMap;
  late final Map<String, String> _serviceNames;
  late final int _traceDepth;
  late final int _servicesCount;

  final Set<String> _expandedSpanIds = {};
  final ScrollController _horizontalScrollController = ScrollController();
  double _timelineScale = 1.0;

  @override
  void initState() {
    super.initState();
    _precompute();
    // Expand roots by default so the tree is visible initially.
    for (final root in _roots) {
      _expandedSpanIds.add(root.spanID);
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _precompute() {
    final spans = widget.trace.spans;

    _traceStartUs = spans.isEmpty
        ? 0
        : spans.map((s) => s.startTime).reduce((a, b) => a < b ? a : b);
    _traceEndUs = spans.isEmpty
        ? _traceStartUs
        : spans
              .map((s) => s.startTime + s.duration)
              .reduce((a, b) => a > b ? a : b);
    _traceDurationUs = _traceEndUs - _traceStartUs;

    _childrenMap = {};
    for (final span in spans) {
      for (final ref in span.references) {
        _childrenMap.putIfAbsent(ref.spanID, () => <Span>[]).add(span);
      }
    }
    for (final children in _childrenMap.values) {
      children.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    _roots = spans.where((s) => s.references.isEmpty).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _serviceNames = {
      for (final span in spans)
        span.spanID:
            widget.trace.processes[span.processID]?.serviceName ??
            span.processID,
    };

    _servicesCount = _serviceNames.values.toSet().length;
    _traceDepth = _computeDepth();
  }

  int _computeDepth() {
    if (_roots.isEmpty) return 0;
    var maxDepth = 0;
    final stack = <_SpanFrame>[];
    for (var i = _roots.length - 1; i >= 0; i--) {
      stack.add(_SpanFrame(span: _roots[i], depth: 1));
    }
    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      if (frame.depth > maxDepth) maxDepth = frame.depth;
      final children = _childrenMap[frame.span.spanID] ?? [];
      for (var i = children.length - 1; i >= 0; i--) {
        stack.add(_SpanFrame(span: children[i], depth: frame.depth + 1));
      }
    }
    return maxDepth;
  }

  List<_VisibleSpan> get _visibleSpans {
    final result = <_VisibleSpan>[];
    final stack = <_SpanFrame>[];
    for (var i = _roots.length - 1; i >= 0; i--) {
      stack.add(_SpanFrame(span: _roots[i], depth: 0));
    }
    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final span = frame.span;
      final children = _childrenMap[span.spanID] ?? [];
      final hasChildren = children.isNotEmpty;
      result.add(
        _VisibleSpan(span: span, depth: frame.depth, hasChildren: hasChildren),
      );
      if (_expandedSpanIds.contains(span.spanID) && hasChildren) {
        for (var i = children.length - 1; i >= 0; i--) {
          stack.add(_SpanFrame(span: children[i], depth: frame.depth + 1));
        }
      }
    }
    return result;
  }

  void _toggleSpan(String spanId) {
    setState(() {
      if (_expandedSpanIds.contains(spanId)) {
        _expandedSpanIds.remove(spanId);
      } else {
        _expandedSpanIds.add(spanId);
      }
    });
  }

  void _zoomIn() {
    setState(() {
      _timelineScale = min(_timelineScale * _scaleStep, _maxTimelineScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _timelineScale = max(_timelineScale / _scaleStep, _minTimelineScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _timelineScale = _minTimelineScale;
    });
  }

  Future<void> _copyTraceJson() async {
    final json = jsonEncode(widget.trace.toJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trace JSON copied to clipboard')),
      );
    }
  }

  Future<void> _copyTraceId() async {
    await Clipboard.setData(ClipboardData(text: widget.trace.traceID));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trace ID copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootSpan = _roots.isNotEmpty ? _roots.first : null;
    final title = rootSpan?.operationName ?? widget.trace.traceID;
    final visibleSpans = _visibleSpans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TraceHeader(
          trace: widget.trace,
          title: title,
          startUs: _traceStartUs,
          durationUs: _traceDurationUs,
          servicesCount: _servicesCount,
          depth: _traceDepth,
          scale: _timelineScale,
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onResetZoom: _resetZoom,
          onCopyTraceId: _copyTraceId,
          onCopyTraceJson: _copyTraceJson,
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final timelineWidth =
                  max(
                    (viewportWidth - _labelColumnWidth).clamp(
                      300.0,
                      double.infinity,
                    ),
                    300.0,
                  ) *
                  _timelineScale;
              final contentWidth = _labelColumnWidth + timelineWidth;

              return SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      _TimelineAxisHeader(
                        startUs: _traceStartUs,
                        durationUs: _traceDurationUs,
                        width: timelineWidth,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: visibleSpans.isEmpty
                            ? const Center(child: Text('No spans in trace'))
                            : ListView.builder(
                                itemCount: visibleSpans.length,
                                itemBuilder: (context, index) {
                                  final item = visibleSpans[index];
                                  return RepaintBoundary(
                                    child: _SpanNode(
                                      span: item.span,
                                      depth: item.depth,
                                      hasChildren: item.hasChildren,
                                      isExpanded: _expandedSpanIds.contains(
                                        item.span.spanID,
                                      ),
                                      onToggle: () =>
                                          _toggleSpan(item.span.spanID),
                                      traceStartUs: _traceStartUs,
                                      traceDurationUs: _traceDurationUs,
                                      timelineWidth: timelineWidth,
                                      service: _serviceNames[item.span.spanID]!,
                                      serviceColor: serviceColor(
                                        _serviceNames[item.span.spanID]!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpanFrame {
  const _SpanFrame({required this.span, required this.depth});

  final Span span;
  final int depth;
}

class _VisibleSpan {
  const _VisibleSpan({
    required this.span,
    required this.depth,
    required this.hasChildren,
  });

  final Span span;
  final int depth;
  final bool hasChildren;
}

class _TraceHeader extends StatelessWidget {
  const _TraceHeader({
    required this.trace,
    required this.title,
    required this.startUs,
    required this.durationUs,
    required this.servicesCount,
    required this.depth,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onCopyTraceId,
    required this.onCopyTraceJson,
  });

  final Trace trace;
  final String title;
  final int startUs;
  final int durationUs;
  final int servicesCount;
  final int depth;
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onCopyTraceId;
  final VoidCallback onCopyTraceJson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'Copy trace ID',
                onPressed: onCopyTraceId,
              ),
              IconButton(
                icon: const Icon(Icons.code, size: 18),
                tooltip: 'Copy trace as JSON',
                onPressed: onCopyTraceJson,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            trace.traceID,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.schedule, label: formatTimestamp(startUs)),
              _MetaChip(
                icon: Icons.timer_outlined,
                label: formatDuration(durationUs),
              ),
              _MetaChip(
                icon: Icons.account_tree_outlined,
                label: '${trace.spans.length} spans',
              ),
              _MetaChip(
                icon: Icons.dns_outlined,
                label: '$servicesCount services',
              ),
              _MetaChip(icon: Icons.layers_outlined, label: 'depth $depth'),
            ],
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: _MiniTraceTimeline(
              trace: trace,
              traceStartUs: startUs,
              traceDurationUs: durationUs,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: colorScheme.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom out',
                    onPressed: scale > 1.0 ? onZoomOut : null,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      '${(scale * 100).toStringAsFixed(0)}%',
                      key: ValueKey<double>(scale),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom in',
                    onPressed: scale < 20.0 ? onZoomIn : null,
                  ),
                  TextButton(
                    onPressed: scale > 1.0 ? onResetZoom : null,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(label),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}

class _MiniTraceTimeline extends StatelessWidget {
  const _MiniTraceTimeline({
    required this.trace,
    required this.traceStartUs,
    required this.traceDurationUs,
  });

  final Trace trace;
  final int traceStartUs;
  final int traceDurationUs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: _MiniTimelinePainter(
          trace: trace,
          traceStartUs: traceStartUs,
          traceDurationUs: traceDurationUs,
        ),
      ),
    );
  }
}

class _MiniTimelinePainter extends CustomPainter {
  _MiniTimelinePainter({
    required this.trace,
    required this.traceStartUs,
    required this.traceDurationUs,
  });

  final Trace trace;
  final int traceStartUs;
  final int traceDurationUs;

  @override
  void paint(Canvas canvas, Size size) {
    if (traceDurationUs <= 0 || trace.spans.isEmpty) return;

    final sorted = trace.spans.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final rowHeight = size.height / 6;
    var y = 0.0;

    for (final span in sorted) {
      final left =
          ((span.startTime - traceStartUs) / traceDurationUs) * size.width;
      final width = (span.duration / traceDurationUs) * size.width;
      final service =
          trace.processes[span.processID]?.serviceName ?? span.processID;
      final paint = Paint()
        ..color = serviceColor(service)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, width.clamp(1, double.infinity), rowHeight - 2),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);

      y += rowHeight;
      if (y + rowHeight > size.height) y = 0;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTimelinePainter oldDelegate) {
    return oldDelegate.trace != trace ||
        oldDelegate.traceStartUs != traceStartUs ||
        oldDelegate.traceDurationUs != traceDurationUs;
  }
}

class _TimelineAxisHeader extends StatelessWidget {
  const _TimelineAxisHeader({
    required this.startUs,
    required this.durationUs,
    required this.width,
  });

  final int startUs;
  final int durationUs;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const SizedBox(width: _labelColumnWidth),
          SizedBox(
            width: width,
            child: CustomPaint(
              painter: _AxisPainter(
                durationUs: durationUs,
                textColor: colorScheme.onSurfaceVariant,
                lineColor: colorScheme.outlineVariant,
              ),
              size: Size(width, 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisPainter extends CustomPainter {
  _AxisPainter({
    required this.durationUs,
    required this.textColor,
    required this.lineColor,
  });

  final int durationUs;
  final Color textColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (durationUs <= 0) return;

    final ticks = timelineTicks(durationUs);
    final textStyle = TextStyle(color: textColor, fontSize: 10, height: 1);
    final axisPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      axisPaint,
    );

    for (final tick in ticks) {
      final x = (tick / durationUs) * size.width;
      canvas.drawLine(
        Offset(x, size.height - 6),
        Offset(x, size.height - 1),
        axisPaint,
      );

      final text = formatTimeAxisLabel(tick);
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AxisPainter oldDelegate) {
    return oldDelegate.durationUs != durationUs ||
        oldDelegate.textColor != textColor ||
        oldDelegate.lineColor != lineColor;
  }
}

const double _labelColumnWidth = 260;

class _SpanNode extends StatelessWidget {
  const _SpanNode({
    required this.span,
    required this.depth,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.timelineWidth,
    required this.service,
    required this.serviceColor,
  });

  final Span span;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int traceStartUs;
  final int traceDurationUs;
  final double timelineWidth;
  final String service;
  final Color serviceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationUs = traceDurationUs;
    final left = durationUs <= 0
        ? 0.0
        : ((span.startTime - traceStartUs) / durationUs) * timelineWidth;
    final barWidth = durationUs <= 0
        ? 2.0
        : (span.duration / durationUs * timelineWidth).clamp(
            2.0,
            timelineWidth,
          );

    return InkWell(
      onTap: () => _showSpanDetails(context),
      child: Row(
        children: [
          SizedBox(
            width: _labelColumnWidth,
            child: Padding(
              padding: EdgeInsets.only(
                left: 12 + depth * 16,
                top: 8,
                bottom: 8,
                right: 8,
              ),
              child: Row(
                children: [
                  if (hasChildren)
                    GestureDetector(
                      onTap: onToggle,
                      child: AnimatedRotation(
                        turns: isExpanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          span.operationName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$service · ${formatDuration(span.duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: timelineWidth,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  top: 12,
                  width: barWidth,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: left + barWidth + 4,
                  top: 10,
                  child: Text(
                    formatDuration(span.duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSpanDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _SpanDetailHeader(
              span: span,
              service: service,
              color: serviceColor,
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Details',
              rows: [
                _DetailRow(label: 'Span ID', value: span.spanID),
                _DetailRow(label: 'Trace ID', value: span.traceID),
                _DetailRow(label: 'Service', value: service),
                _DetailRow(
                  label: 'Duration',
                  value: formatDuration(span.duration),
                ),
                _DetailRow(
                  label: 'Start time',
                  value: formatTimeOfDay(span.startTime),
                ),
              ],
            ),
            const Divider(height: 1),
            if (span.tags.isNotEmpty)
              _DetailSection(
                title: 'Tags',
                rows: span.tags
                    .map(
                      (t) => _DetailRow(
                        label: t.key,
                        value: t.value?.toString() ?? '',
                      ),
                    )
                    .toList(),
              ),
            if (span.tags.isNotEmpty && span.logs.isNotEmpty)
              const Divider(height: 1),
            if (span.logs.isNotEmpty)
              _DetailSection(
                title: 'Logs',
                rows: span.logs
                    .map(
                      (log) => _DetailRow(
                        label: formatTimeOfDay(log.timestamp),
                        value: log.fields
                            .map((f) => '${f.key}=${f.value}')
                            .join(', '),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpanDetailHeader extends StatelessWidget {
  const _SpanDetailHeader({
    required this.span,
    required this.service,
    required this.color,
  });

  final Span span;
  final String service;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                service,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 18),
              tooltip: 'Copy span ID',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: span.spanID));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Span ID copied')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          span.operationName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
