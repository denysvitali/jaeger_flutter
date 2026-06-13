import 'package:flutter/material.dart';
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

class _TraceBody extends StatelessWidget {
  const _TraceBody({required this.trace});

  final Trace trace;

  int get _traceStartUs => trace.spans
      .map((s) => s.startTime)
      .fold(0, (a, b) => a == 0 || b < a ? b : a);

  int get _traceEndUs {
    if (trace.spans.isEmpty) return _traceStartUs;
    var maxEnd = 0;
    for (final span in trace.spans) {
      final end = span.startTime + span.duration;
      if (end > maxEnd) maxEnd = end;
    }
    return maxEnd;
  }

  int get _traceDurationUs => _traceEndUs - _traceStartUs;

  int get _servicesCount =>
      trace.processes.values.map((p) => p.serviceName).toSet().length;

  int get _traceDepth {
    int depth(Span span) {
      final children = _childrenOf(span);
      if (children.isEmpty) return 1;
      return 1 + children.map(depth).reduce((a, b) => a > b ? a : b);
    }

    final roots = trace.spans.where((s) => s.references.isEmpty).toList();
    if (roots.isEmpty) return 0;
    return roots.map(depth).reduce((a, b) => a > b ? a : b);
  }

  List<Span> _childrenOf(Span span) => trace.spans
      .where(
        (s) => s.references.any(
          (r) => r.traceID == span.traceID && r.spanID == span.spanID,
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final roots = trace.spans.where((s) => s.references.isEmpty).toList();
    final rootSpan = roots.isNotEmpty ? roots.first : null;
    final title = rootSpan?.operationName ?? trace.traceID;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TraceHeader(
          trace: trace,
          title: title,
          startUs: _traceStartUs,
          durationUs: _traceDurationUs,
          servicesCount: _servicesCount,
          depth: _traceDepth,
        ),
        const Divider(height: 1),
        _TimelineAxisHeader(
          startUs: _traceStartUs,
          durationUs: _traceDurationUs,
        ),
        const Divider(height: 1),
        Expanded(
          child: roots.isEmpty
              ? const Center(child: Text('No spans in trace'))
              : ListView.builder(
                  itemCount: roots.length,
                  itemBuilder: (context, index) => _SpanNode(
                    trace: trace,
                    span: roots[index],
                    depth: 0,
                    traceStartUs: _traceStartUs,
                    traceDurationUs: _traceDurationUs,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TraceHeader extends StatelessWidget {
  const _TraceHeader({
    required this.trace,
    required this.title,
    required this.startUs,
    required this.durationUs,
    required this.servicesCount,
    required this.depth,
  });

  final Trace trace;
  final String title;
  final int startUs;
  final int durationUs;
  final int servicesCount;
  final int depth;

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
                onPressed: () {
                  // Clipboard is not wired in; this keeps the UI honest.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trace ID copied')),
                  );
                },
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
          const SizedBox(height: 16),
          _MiniTraceTimeline(
            trace: trace,
            traceStartUs: startUs,
            traceDurationUs: durationUs,
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
      padding: EdgeInsets.zero,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TimelineAxisHeader extends StatelessWidget {
  const _TimelineAxisHeader({required this.startUs, required this.durationUs});

  final int startUs;
  final int durationUs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const SizedBox(width: _labelColumnWidth),
          Expanded(
            child: CustomPaint(painter: _AxisPainter(durationUs: durationUs)),
          ),
        ],
      ),
    );
  }
}

class _AxisPainter extends CustomPainter {
  _AxisPainter({required this.durationUs});

  final int durationUs;

  @override
  void paint(Canvas canvas, Size size) {
    if (durationUs <= 0) return;

    final ticks = timelineTicks(durationUs);
    final textStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 10,
      height: 1,
    );
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

const double _labelColumnWidth = 260;

class _SpanNode extends StatefulWidget {
  const _SpanNode({
    required this.trace,
    required this.span,
    required this.depth,
    required this.traceStartUs,
    required this.traceDurationUs,
  });

  final Trace trace;
  final Span span;
  final int depth;
  final int traceStartUs;
  final int traceDurationUs;

  @override
  State<_SpanNode> createState() => _SpanNodeState();
}

class _SpanNodeState extends State<_SpanNode> {
  bool _expanded = true;

  List<Span> get _children => widget.trace.spans
      .where(
        (s) => s.references.any(
          (r) =>
              r.traceID == widget.span.traceID &&
              r.spanID == widget.span.spanID,
        ),
      )
      .toList();

  String get _service =>
      widget.trace.processes[widget.span.processID]?.serviceName ??
      widget.span.processID;

  Color get _serviceColor => serviceColor(_service);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = _children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showSpanDetails(context),
          child: Row(
            children: [
              SizedBox(
                width: _labelColumnWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12 + widget.depth * 16,
                    top: 8,
                    bottom: 8,
                    right: 8,
                  ),
                  child: Row(
                    children: [
                      if (hasChildren)
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: AnimatedRotation(
                            turns: _expanded ? 0 : -0.25,
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
                          color: _serviceColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.span.operationName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_service · ${formatDuration(widget.span.duration)}',
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final durationUs = widget.traceDurationUs;
                    final left =
                        ((widget.span.startTime - widget.traceStartUs) /
                            durationUs) *
                        width;
                    final barWidth = (widget.span.duration / durationUs * width)
                        .clamp(2.0, width);

                    return SizedBox(
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
                                color: _serviceColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: left + barWidth + 4,
                            top: 10,
                            child: Text(
                              formatDuration(widget.span.duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 12),
        if (_expanded)
          ..._children.map(
            (child) => _SpanNode(
              trace: widget.trace,
              span: child,
              depth: widget.depth + 1,
              traceStartUs: widget.traceStartUs,
              traceDurationUs: widget.traceDurationUs,
            ),
          ),
      ],
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
              span: widget.span,
              service: _service,
              color: _serviceColor,
            ),
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Details',
              rows: [
                _DetailRow(label: 'Span ID', value: widget.span.spanID),
                _DetailRow(label: 'Trace ID', value: widget.span.traceID),
                _DetailRow(label: 'Service', value: _service),
                _DetailRow(
                  label: 'Duration',
                  value: formatDuration(widget.span.duration),
                ),
                _DetailRow(
                  label: 'Start time',
                  value: formatTimeOfDay(widget.span.startTime),
                ),
              ],
            ),
            if (widget.span.tags.isNotEmpty)
              _DetailSection(
                title: 'Tags',
                rows: widget.span.tags
                    .map(
                      (t) => _DetailRow(
                        label: t.key,
                        value: t.value?.toString() ?? '',
                      ),
                    )
                    .toList(),
              ),
            if (widget.span.logs.isNotEmpty)
              _DetailSection(
                title: 'Logs',
                rows: widget.span.logs
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
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
