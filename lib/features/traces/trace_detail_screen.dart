import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

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

  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  int get _traceStartUs =>
      trace.spans.map((s) => s.startTime).fold(0, (a, b) => a == 0 || b < a ? b : a);

  @override
  Widget build(BuildContext context) {
    final rootSpans = trace.spans.where((s) => s.references.isEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                trace.traceID,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${trace.spans.length} spans · ${_timeFormat.format(DateTime.fromMicrosecondsSinceEpoch(_traceStartUs))}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: rootSpans.length,
            itemBuilder: (context, index) => _SpanTile(
              trace: trace,
              span: rootSpans[index],
              depth: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpanTile extends StatelessWidget {
  const _SpanTile({
    required this.trace,
    required this.span,
    required this.depth,
  });

  final Trace trace;
  final Span span;
  final int depth;

  static final _timeFormat = DateFormat('HH:mm:ss.SSS');

  List<Span> get _children => trace.spans
      .where(
        (s) =>
            s.references.any((r) => r.traceID == span.traceID && r.spanID == span.spanID),
      )
      .toList();

  String _formatDuration(int microseconds) {
    if (microseconds < 1000) return '$microsecondsμs';
    if (microseconds < 1000000) {
      return '${(microseconds / 1000).toStringAsFixed(2)}ms';
    }
    return '${(microseconds / 1000000).toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context) {
    final service = trace.processes[span.processID]?.serviceName ?? span.processID;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showSpanDetails(context, span, service),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16 + depth * 24,
              top: 8,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        span.operationName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$service · ${_formatDuration(span.duration)} · '
                        '${_timeFormat.format(DateTime.fromMicrosecondsSinceEpoch(span.startTime))}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_children.isNotEmpty) const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 16),
        ..._children.map(
          (child) => _SpanTile(trace: trace, span: child, depth: depth + 1),
        ),
      ],
    );
  }

  void _showSpanDetails(BuildContext context, Span span, String service) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                span.operationName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _DetailRow(label: 'Span ID', value: span.spanID),
              _DetailRow(label: 'Service', value: service),
              _DetailRow(label: 'Duration', value: _formatDuration(span.duration)),
              _DetailRow(
                label: 'Start time',
                value: _timeFormat.format(
                  DateTime.fromMicrosecondsSinceEpoch(span.startTime),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tags', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...span.tags.map(
                (t) => _DetailRow(label: t.key, value: t.value?.toString() ?? ''),
              ),
              if (span.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Logs', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...span.logs.map(
                  (log) => _DetailRow(
                    label: log.timestamp.toString(),
                    value: log.fields
                        .map((f) => '${f.key}=${f.value}')
                        .join(', '),
                  ),
                ),
              ],
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
