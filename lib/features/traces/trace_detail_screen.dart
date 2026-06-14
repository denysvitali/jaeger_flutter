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
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _spanQueryController = TextEditingController();
  double _timelineScale = 1.0;
  double _gestureStartTimelineScale = 1.0;
  double _timelineScrollOffset = 0.0;
  double _timelineScrollFraction = 0.0;
  double _lastTimelineWidth = 0.0;
  double _lastLabelColumnWidth = _desktopLabelColumnWidth;
  bool _lastCompactLayout = false;
  String _spanQuery = '';
  bool _criticalPathOnly = false;
  bool _mobileToolsExpanded = false;
  String? _lastOpenedSpanId;

  @override
  void initState() {
    super.initState();
    _precompute();
    _horizontalScrollController.addListener(_syncTimelineScrollFraction);
    // Expand roots by default so the tree is visible initially.
    for (final root in _roots) {
      _expandedSpanIds.add(root.spanID);
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_syncTimelineScrollFraction);
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _spanQueryController.dispose();
    super.dispose();
  }

  void _syncTimelineScrollFraction() {
    final position = _horizontalScrollController.position;
    final maxExtent = position.maxScrollExtent;
    final nextOffset = position.pixels;
    final nextFraction = maxExtent <= 0
        ? 0.0
        : (position.pixels / maxExtent).clamp(0.0, 1.0).toDouble();
    if ((nextFraction - _timelineScrollFraction).abs() < 0.01 &&
        (nextOffset - _timelineScrollOffset).abs() < 1) {
      return;
    }
    setState(() {
      _timelineScrollOffset = nextOffset;
      _timelineScrollFraction = nextFraction;
    });
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

  Set<String> get _criticalPathSpanIds {
    final ids = <String>{};
    Span? current = _roots.isEmpty ? null : _roots.first;
    while (current != null) {
      ids.add(current.spanID);
      final children = _childrenMap[current.spanID] ?? const <Span>[];
      if (children.isEmpty) break;
      current = children.reduce((a, b) {
        final aEnd = a.startTime + a.duration;
        final bEnd = b.startTime + b.duration;
        return aEnd >= bEnd ? a : b;
      });
    }
    return ids;
  }

  List<Span> get _signalSpans {
    if (widget.trace.spans.isEmpty) return const [];
    final sortedDurations = widget.trace.spans.map((s) => s.duration).toList()
      ..sort();
    final p90Index = (sortedDurations.length * 0.9)
        .floor()
        .clamp(0, sortedDurations.length - 1)
        .toInt();
    final p90 = sortedDurations[p90Index];
    final signals = widget.trace.spans.where((span) {
      return _spanHasError(span) ||
          (span.warnings?.isNotEmpty ?? false) ||
          span.duration >= p90;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    return signals;
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

    Iterable<_VisibleSpan> filtered = result;
    if (_criticalPathOnly) {
      final criticalPath = _criticalPathSpanIds;
      filtered = filtered.where(
        (item) => criticalPath.contains(item.span.spanID),
      );
    }
    final query = _spanQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where(
        (item) =>
            item.span.operationName.toLowerCase().contains(query) ||
            (_serviceNames[item.span.spanID]?.toLowerCase().contains(query) ??
                false) ||
            item.span.tags.any(
              (tag) =>
                  tag.key.toLowerCase().contains(query) ||
                  (tag.value?.toString().toLowerCase().contains(query) ??
                      false),
            ),
      );
    }
    return filtered.toList(growable: false);
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
    _seekTimelineFraction(0);
  }

  void _setCriticalPathOnly(bool value) {
    setState(() {
      _criticalPathOnly = value;
      if (value) {
        _expandedSpanIds.addAll(_criticalPathSpanIds);
      }
    });
  }

  void _toggleMobileToolsExpanded() {
    setState(() => _mobileToolsExpanded = !_mobileToolsExpanded);
  }

  void _applyScaleGesture(double scale) {
    if (scale == 1.0) return;
    setState(() {
      _timelineScale = (_gestureStartTimelineScale * scale)
          .clamp(_minTimelineScale, _maxTimelineScale)
          .toDouble();
    });
  }

  void _panTimeline(int direction) {
    if (!_horizontalScrollController.hasClients) return;
    final position = _horizontalScrollController.position;
    final target = (position.pixels + (position.viewportDimension * direction))
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _horizontalScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _seekTimelineFraction(double fraction) {
    if (!_horizontalScrollController.hasClients) return;
    final position = _horizontalScrollController.position;
    final target = (position.maxScrollExtent * fraction)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _horizontalScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _revealSpan(Span span) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScrollController.hasClients &&
          _lastTimelineWidth > 0 &&
          _traceDurationUs > 0) {
        final position = _horizontalScrollController.position;
        final left =
            ((span.startTime - _traceStartUs) / _traceDurationUs) *
            _lastTimelineWidth;
        final target =
            (_lastLabelColumnWidth + left - (position.viewportDimension * 0.4))
                .clamp(0.0, position.maxScrollExtent)
                .toDouble();
        position.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }

      if (_verticalScrollController.hasClients) {
        final visibleIndex = _visibleSpans.indexWhere(
          (item) => item.span.spanID == span.spanID,
        );
        if (visibleIndex == -1) return;
        final rowHeight = _lastCompactLayout ? 46.0 : 48.0;
        final position = _verticalScrollController.position;
        final target = ((visibleIndex * rowHeight) -
                (position.viewportDimension * 0.25))
            .clamp(0.0, position.maxScrollExtent)
            .toDouble();
        position.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _openSignalSpan(int direction) {
    final signals = _signalSpans;
    if (signals.isEmpty) return;
    final currentIndex = signals.indexWhere(
      (span) => span.spanID == _lastOpenedSpanId,
    );
    final nextIndex =
        (currentIndex == -1
                ? (direction > 0 ? 0 : signals.length - 1)
                : (currentIndex + direction).clamp(0, signals.length - 1))
            .toInt();
    _openSpanDetails(signals[nextIndex]);
  }

  void _openSpanDetails(Span span) {
    setState(() => _lastOpenedSpanId = span.spanID);
    _revealSpan(span);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SpanDetailsSheet(
        span: span,
        service: _serviceNames[span.spanID] ?? span.processID,
        color: serviceColor(_serviceNames[span.spanID] ?? span.processID),
        signalSpans: _signalSpans,
        traceStartUs: _traceStartUs,
        traceDurationUs: _traceDurationUs,
        onOpenSpan: _openSpanDetails,
      ),
    );
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
    final signalSpanIds = _signalSpans.map((span) => span.spanID).toSet();

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
          scrollFraction: _timelineScrollFraction,
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onResetZoom: _resetZoom,
          onPanLeft: () => _panTimeline(-1),
          onPanRight: () => _panTimeline(1),
          onSeekTimeline: _seekTimelineFraction,
          onCopyTraceId: _copyTraceId,
          onCopyTraceJson: _copyTraceJson,
          spanQueryController: _spanQueryController,
          spanQuery: _spanQuery,
          onSpanQueryChanged: (value) => setState(() => _spanQuery = value),
          criticalPathOnly: _criticalPathOnly,
          mobileToolsExpanded: _mobileToolsExpanded,
          onToggleMobileToolsExpanded: _toggleMobileToolsExpanded,
          onCriticalPathChanged: _setCriticalPathOnly,
          onPreviousSignal: _signalSpans.isEmpty
              ? null
              : () => _openSignalSpan(-1),
          onNextSignal: _signalSpans.isEmpty ? null : () => _openSignalSpan(1),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final compact = viewportWidth < 520;
              final labelColumnWidth = _labelColumnWidthFor(viewportWidth);
              final timelineWidth =
                  max(
                    (viewportWidth - labelColumnWidth).clamp(
                      compact ? 220.0 : 300.0,
                      double.infinity,
                    ),
                    compact ? viewportWidth * 1.2 : 300.0,
                  ) *
                  _timelineScale;
              final contentWidth = labelColumnWidth + timelineWidth;
              _lastTimelineWidth = timelineWidth;
              _lastLabelColumnWidth = labelColumnWidth;
              _lastCompactLayout = compact;

              return GestureDetector(
                onDoubleTap: _resetZoom,
                onScaleStart: (_) {
                  _gestureStartTimelineScale = _timelineScale;
                },
                onScaleUpdate: (details) {
                  if ((details.scale - 1).abs() > 0.02) {
                    _applyScaleGesture(details.scale);
                  }
                },
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        _TimelineAxisHeader(
                          durationUs: _traceDurationUs,
                          width: timelineWidth,
                          labelColumnWidth: labelColumnWidth,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: visibleSpans.isEmpty
                              ? const Center(child: Text('No spans match'))
                              : ListView.builder(
                                  controller: _verticalScrollController,
                                  itemCount: visibleSpans.length,
                                  itemBuilder: (context, index) {
                                    final item = visibleSpans[index];
                                    final service =
                                        _serviceNames[item.span.spanID]!;
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
                                        onOpen: () =>
                                            _openSpanDetails(item.span),
                                        traceStartUs: _traceStartUs,
                                        traceDurationUs: _traceDurationUs,
                                        timelineWidth: timelineWidth,
                                        labelColumnWidth: labelColumnWidth,
                                        labelScrollOffset:
                                            _timelineScrollOffset,
                                        service: service,
                                        serviceColor: serviceColor(service),
                                        isSignal: signalSpanIds.contains(
                                          item.span.spanID,
                                        ),
                                        isSelected:
                                            item.span.spanID ==
                                            _lastOpenedSpanId,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
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
    required this.scrollFraction,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onPanLeft,
    required this.onPanRight,
    required this.onSeekTimeline,
    required this.onCopyTraceId,
    required this.onCopyTraceJson,
    required this.spanQueryController,
    required this.spanQuery,
    required this.onSpanQueryChanged,
    required this.criticalPathOnly,
    required this.mobileToolsExpanded,
    required this.onToggleMobileToolsExpanded,
    required this.onCriticalPathChanged,
    required this.onPreviousSignal,
    required this.onNextSignal,
  });

  final Trace trace;
  final String title;
  final int startUs;
  final int durationUs;
  final int servicesCount;
  final int depth;
  final double scale;
  final double scrollFraction;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onPanLeft;
  final VoidCallback onPanRight;
  final ValueChanged<double> onSeekTimeline;
  final VoidCallback onCopyTraceId;
  final VoidCallback onCopyTraceJson;
  final TextEditingController spanQueryController;
  final String spanQuery;
  final ValueChanged<String> onSpanQueryChanged;
  final bool criticalPathOnly;
  final bool mobileToolsExpanded;
  final VoidCallback onToggleMobileToolsExpanded;
  final ValueChanged<bool> onCriticalPathChanged;
  final VoidCallback? onPreviousSignal;
  final VoidCallback? onNextSignal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, compact ? 10 : 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  title,
                  maxLines: compact ? 2 : 3,
                  style: (compact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(
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
          SizedBox(height: compact ? 8 : 12),
          _TraceMetrics(
            startUs: startUs,
            durationUs: durationUs,
            spanCount: trace.spans.length,
            servicesCount: servicesCount,
            depth: depth,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 12),
          RepaintBoundary(
            child: _MiniTraceTimeline(
              trace: trace,
              traceStartUs: startUs,
              traceDurationUs: durationUs,
              scale: scale,
              scrollFraction: scrollFraction,
              compact: compact,
              onSeek: onSeekTimeline,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.zoom_out),
                  tooltip: 'Zoom out',
                  onPressed: scale > 1.0 ? onZoomOut : null,
                ),
                SizedBox(
                  width: 52,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        '${(scale * 100).toStringAsFixed(0)}%',
                        key: ValueKey<double>(scale),
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom in',
                  onPressed: scale < 20.0 ? onZoomIn : null,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.keyboard_arrow_left),
                  tooltip: 'Pan timeline left',
                  onPressed: onPanLeft,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.keyboard_arrow_right),
                  tooltip: 'Pan timeline right',
                  onPressed: onPanRight,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  onPressed: scale > 1.0 ? onResetZoom : null,
                  label: const Text('Reset'),
                ),
                if (compact)
                  IconButton.filledTonal(
                    icon: Icon(
                      mobileToolsExpanded
                          ? Icons.expand_less
                          : Icons.manage_search,
                    ),
                    tooltip: mobileToolsExpanded
                        ? 'Hide trace tools'
                        : 'Show trace tools',
                    onPressed: onToggleMobileToolsExpanded,
                  ),
              ],
            ),
          ),
          _TraceToolPanel(
            visible: !compact || mobileToolsExpanded,
            spanQueryController: spanQueryController,
            spanQuery: spanQuery,
            onSpanQueryChanged: onSpanQueryChanged,
            criticalPathOnly: criticalPathOnly,
            onCriticalPathChanged: onCriticalPathChanged,
            onPreviousSignal: onPreviousSignal,
            onNextSignal: onNextSignal,
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

class _TraceToolPanel extends StatelessWidget {
  const _TraceToolPanel({
    required this.visible,
    required this.spanQueryController,
    required this.spanQuery,
    required this.onSpanQueryChanged,
    required this.criticalPathOnly,
    required this.onCriticalPathChanged,
    required this.onPreviousSignal,
    required this.onNextSignal,
  });

  final bool visible;
  final TextEditingController spanQueryController;
  final String spanQuery;
  final ValueChanged<String> onSpanQueryChanged;
  final bool criticalPathOnly;
  final ValueChanged<bool> onCriticalPathChanged;
  final VoidCallback? onPreviousSignal;
  final VoidCallback? onNextSignal;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: spanQueryController,
                    onChanged: onSpanQueryChanged,
                    decoration: InputDecoration(
                      hintText: 'Find spans, tags, or services',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: spanQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear span search',
                              onPressed: () {
                                spanQueryController.clear();
                                onSpanQueryChanged('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: 'Previous signal span',
                  onPressed: onPreviousSignal,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: 'Next signal span',
                  onPressed: onNextSignal,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilterChip(
              avatar: const Icon(Icons.route_outlined, size: 16),
              label: const Text('Critical path'),
              selected: criticalPathOnly,
              onSelected: onCriticalPathChanged,
            ),
          ],
        ),
      ),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 160),
      sizeCurve: Curves.easeOutCubic,
    );
  }
}

class _TraceMetrics extends StatelessWidget {
  const _TraceMetrics({
    required this.startUs,
    required this.durationUs,
    required this.spanCount,
    required this.servicesCount,
    required this.depth,
    required this.compact,
  });

  final int startUs;
  final int durationUs;
  final int spanCount;
  final int servicesCount;
  final int depth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Wrap(
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
            label: '$spanCount spans',
          ),
          _MetaChip(icon: Icons.dns_outlined, label: '$servicesCount services'),
          _MetaChip(icon: Icons.layers_outlined, label: 'depth $depth'),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.timer_outlined,
            value: formatDuration(durationUs),
            label: 'duration',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MetricTile(
            icon: Icons.account_tree_outlined,
            value: '$spanCount',
            label: 'spans',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MetricTile(
            icon: Icons.dns_outlined,
            value: '$servicesCount',
            label: 'services',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MetricTile(
            icon: Icons.layers_outlined,
            value: '$depth',
            label: 'depth',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniTraceTimeline extends StatelessWidget {
  const _MiniTraceTimeline({
    required this.trace,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.scale,
    required this.scrollFraction,
    required this.compact,
    required this.onSeek,
  });

  final Trace trace;
  final int traceStartUs;
  final int traceDurationUs;
  final double scale;
  final double scrollFraction;
  final bool compact;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void seek(Offset localPosition) {
          final width = constraints.maxWidth;
          if (width <= 0) return;
          onSeek((localPosition.dx / width).clamp(0.0, 1.0).toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => seek(details.localPosition),
          onHorizontalDragUpdate: (details) => seek(details.localPosition),
          child: SizedBox(
            height: compact ? 40 : 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniTimelinePainter(
                trace: trace,
                traceStartUs: traceStartUs,
                traceDurationUs: traceDurationUs,
                scale: scale,
                scrollFraction: scrollFraction,
                viewportColor: Theme.of(context).colorScheme.primary,
                outlineColor: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniTimelinePainter extends CustomPainter {
  _MiniTimelinePainter({
    required this.trace,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.scale,
    required this.scrollFraction,
    required this.viewportColor,
    required this.outlineColor,
  });

  final Trace trace;
  final int traceStartUs;
  final int traceDurationUs;
  final double scale;
  final double scrollFraction;
  final Color viewportColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (traceDurationUs <= 0 || trace.spans.isEmpty) return;

    final sorted = trace.spans.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final services = <String>[];
    for (final span in sorted) {
      final service =
          trace.processes[span.processID]?.serviceName ?? span.processID;
      if (!services.contains(service)) services.add(service);
    }
    final laneCount = services.isEmpty ? 1 : min(services.length, 8);
    final serviceLane = <String, int>{
      for (var i = 0; i < services.length; i++) services[i]: i % laneCount,
    };
    final rowHeight = size.height / laneCount;
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      outlinePaint,
    );

    final lanePaint = Paint()..style = PaintingStyle.fill;
    final separatorPaint = Paint()
      ..color = outlineColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var lane = 0; lane < laneCount; lane++) {
      final service = services[lane];
      lanePaint.color = serviceColor(service).withValues(alpha: 0.08);
      canvas.drawRect(
        Rect.fromLTWH(0, lane * rowHeight, size.width, rowHeight),
        lanePaint,
      );
      if (lane > 0) {
        final y = lane * rowHeight;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), separatorPaint);
      }
    }

    for (final span in sorted) {
      final left =
          ((span.startTime - traceStartUs) / traceDurationUs) * size.width;
      final width = (span.duration / traceDurationUs) * size.width;
      final service =
          trace.processes[span.processID]?.serviceName ?? span.processID;
      final lane = serviceLane[service] ?? 0;
      final y = lane * rowHeight;
      final paint = Paint()
        ..color = serviceColor(service)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          y + 2,
          width.clamp(1, double.infinity),
          max(2.0, rowHeight - 4),
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }

    final visibleFraction = (1 / scale).clamp(0.05, 1.0).toDouble();
    final viewportWidth = size.width * visibleFraction;
    final viewportLeft = (size.width - viewportWidth) * scrollFraction;
    final viewportPaint = Paint()
      ..color = viewportColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final viewportStroke = Paint()
      ..color = viewportColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final viewportRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(viewportLeft, 0, viewportWidth, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(viewportRect, viewportPaint);
    canvas.drawRRect(viewportRect, viewportStroke);
  }

  @override
  bool shouldRepaint(covariant _MiniTimelinePainter oldDelegate) {
    return oldDelegate.trace != trace ||
        oldDelegate.traceStartUs != traceStartUs ||
        oldDelegate.traceDurationUs != traceDurationUs ||
        oldDelegate.scale != scale ||
        oldDelegate.scrollFraction != scrollFraction ||
        oldDelegate.viewportColor != viewportColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}

class _TimelineAxisHeader extends StatelessWidget {
  const _TimelineAxisHeader({
    required this.durationUs,
    required this.width,
    required this.labelColumnWidth,
  });

  final int durationUs;
  final double width;
  final double labelColumnWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(width: labelColumnWidth),
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

class _TimelineGridPainter extends CustomPainter {
  _TimelineGridPainter({required this.durationUs, required this.lineColor});

  final int durationUs;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (durationUs <= 0) return;

    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (final tick in timelineTicks(durationUs)) {
      final x = (tick / durationUs) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) {
    return oldDelegate.durationUs != durationUs ||
        oldDelegate.lineColor != lineColor;
  }
}

const double _desktopLabelColumnWidth = 260;

double _labelColumnWidthFor(double viewportWidth) {
  if (viewportWidth < 520) {
    return (viewportWidth * 0.4).clamp(132.0, 172.0).toDouble();
  }
  return _desktopLabelColumnWidth;
}

class _SpanNode extends StatelessWidget {
  const _SpanNode({
    required this.span,
    required this.depth,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpen,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.timelineWidth,
    required this.labelColumnWidth,
    required this.labelScrollOffset,
    required this.service,
    required this.serviceColor,
    required this.isSignal,
    required this.isSelected,
  });

  final Span span;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final int traceStartUs;
  final int traceDurationUs;
  final double timelineWidth;
  final double labelColumnWidth;
  final double labelScrollOffset;
  final String service;
  final Color serviceColor;
  final bool isSignal;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = labelColumnWidth < 190;
    final rowHeight = compact ? 46.0 : 48.0;
    final indent = compact ? 10.0 : 16.0;
    final leftPadding = compact ? 8.0 : 12.0;
    final maxTreeOffset = compact ? 34.0 : double.infinity;
    final treeOffset = min(depth * indent, maxTreeOffset).toDouble();
    final signalColor = _signalColorFor(context, span);
    final durationUs = traceDurationUs;
    final left = durationUs <= 0
        ? 0.0
        : ((span.startTime - traceStartUs) / durationUs) * timelineWidth;
    final barWidth = durationUs <= 0
        ? 2.0
        : (span.duration / durationUs * timelineWidth)
              .clamp(2.0, timelineWidth)
              .toDouble();
    final label = _SpanLabel(
      span: span,
      hasChildren: hasChildren,
      isExpanded: isExpanded,
      onToggle: onToggle,
      service: service,
      serviceColor: serviceColor,
      signalColor: signalColor,
      isSignal: isSignal,
      compact: compact,
      width: labelColumnWidth,
      leftPadding: leftPadding,
      treeOffset: treeOffset,
    );

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          width: labelColumnWidth + timelineWidth,
          height: rowHeight,
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(width: labelColumnWidth),
                  SizedBox(
                    width: timelineWidth,
                    height: rowHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TimelineGridPainter(
                              durationUs: traceDurationUs,
                              lineColor: colorScheme.outlineVariant,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 1,
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: left,
                          top: compact ? 15 : 14,
                          width: barWidth,
                          child: Container(
                            height: compact ? 14 : 18,
                            decoration: BoxDecoration(
                              color: serviceColor,
                              borderRadius: BorderRadius.circular(3),
                              border: isSignal
                                  ? Border.all(color: signalColor, width: 1.5)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: serviceColor.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: left + barWidth + 4,
                          top: compact ? 12 : 13,
                          child: Text(
                            formatDuration(span.duration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: labelScrollOffset,
                top: 0,
                bottom: 0,
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpanLabel extends StatelessWidget {
  const _SpanLabel({
    required this.span,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.service,
    required this.serviceColor,
    required this.signalColor,
    required this.isSignal,
    required this.compact,
    required this.width,
    required this.leftPadding,
    required this.treeOffset,
  });

  final Span span;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String service;
  final Color serviceColor;
  final Color signalColor;
  final bool isSignal;
  final bool compact;
  final double width;
  final double leftPadding;
  final double treeOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding + treeOffset,
          top: 8,
          bottom: 8,
          right: compact ? 4 : 8,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 3,
              height: compact ? 24 : 30,
              decoration: BoxDecoration(
                color: isSignal ? signalColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            if (hasChildren)
              GestureDetector(
                onTap: onToggle,
                child: AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              const SizedBox(width: 18),
            SizedBox(width: compact ? 4 : 6),
            if (!compact) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: serviceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    span.operationName,
                    style: (compact
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$service · ${formatDuration(span.duration)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpanDetailsSheet extends StatelessWidget {
  const _SpanDetailsSheet({
    required this.span,
    required this.service,
    required this.color,
    required this.signalSpans,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.onOpenSpan,
  });

  final Span span;
  final String service;
  final Color color;
  final List<Span> signalSpans;
  final int traceStartUs;
  final int traceDurationUs;
  final ValueChanged<Span> onOpenSpan;

  @override
  Widget build(BuildContext context) {
    final priorityTags = span.tags.where(_isPriorityTag).toList();
    final otherTags = span.tags.where((tag) => !_isPriorityTag(tag)).toList();
    final signalIndex = signalSpans.indexWhere(
      (item) => item.spanID == span.spanID,
    );
    final previousSignal = signalIndex > 0
        ? signalSpans[signalIndex - 1]
        : null;
    final nextSignal = signalIndex >= 0 && signalIndex < signalSpans.length - 1
        ? signalSpans[signalIndex + 1]
        : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _SpanDetailHeader(span: span, service: service, color: color),
          const SizedBox(height: 8),
          _SelectedSpanTimeline(
            span: span,
            traceStartUs: traceStartUs,
            traceDurationUs: traceDurationUs,
            color: color,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  label: const Text('Previous signal'),
                  onPressed: previousSignal == null
                      ? null
                      : () => _openFromSheet(context, previousSignal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  label: const Text('Next signal'),
                  onPressed: nextSignal == null
                      ? null
                      : () => _openFromSheet(context, nextSignal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Summary',
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
          if (span.warnings?.isNotEmpty ?? false)
            _DetailSection(
              title: 'Warnings',
              rows: span.warnings!
                  .map(
                    (warning) => _DetailRow(label: 'Warning', value: warning),
                  )
                  .toList(),
            ),
          if (priorityTags.isNotEmpty)
            _DetailSection(
              title: 'Key fields',
              rows: priorityTags
                  .map(
                    (tag) => _DetailRow(
                      label: tag.key,
                      value: tag.value?.toString() ?? '',
                    ),
                  )
                  .toList(),
            ),
          if (otherTags.isNotEmpty)
            _DetailSection(
              title: 'Tags',
              rows: otherTags
                  .map(
                    (tag) => _DetailRow(
                      label: tag.key,
                      value: tag.value?.toString() ?? '',
                    ),
                  )
                  .toList(),
            ),
          if (span.logs.isNotEmpty)
            _DetailSection(
              title: 'Logs',
              rows: span.logs
                  .map(
                    (log) => _DetailRow(
                      label: formatTimeOfDay(log.timestamp),
                      value: log.fields
                          .map((field) => '${field.key}=${field.value}')
                          .join(', '),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _openFromSheet(BuildContext context, Span target) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => onOpenSpan(target));
  }
}

class _SelectedSpanTimeline extends StatelessWidget {
  const _SelectedSpanTimeline({
    required this.span,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.color,
  });

  final Span span;
  final int traceStartUs;
  final int traceDurationUs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      width: double.infinity,
      child: CustomPaint(
        painter: _SelectedSpanTimelinePainter(
          span: span,
          traceStartUs: traceStartUs,
          traceDurationUs: traceDurationUs,
          color: color,
          trackColor: colorScheme.surfaceContainerHighest,
          outlineColor: colorScheme.outlineVariant,
          signalColor: _signalColorFor(context, span),
        ),
      ),
    );
  }
}

class _SelectedSpanTimelinePainter extends CustomPainter {
  _SelectedSpanTimelinePainter({
    required this.span,
    required this.traceStartUs,
    required this.traceDurationUs,
    required this.color,
    required this.trackColor,
    required this.outlineColor,
    required this.signalColor,
  });

  final Span span;
  final int traceStartUs;
  final int traceDurationUs;
  final Color color;
  final Color trackColor;
  final Color outlineColor;
  final Color signalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 10, size.width, 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (traceDurationUs <= 0) return;

    final left = (((span.startTime - traceStartUs) / traceDurationUs) *
            size.width)
        .clamp(0.0, size.width)
        .toDouble();
    final width = (span.duration / traceDurationUs * size.width)
        .clamp(3.0, max(3.0, size.width - left))
        .toDouble();
    final spanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 7, width, 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      spanRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      spanRect,
      Paint()
        ..color = signalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectedSpanTimelinePainter oldDelegate) {
    return oldDelegate.span != span ||
        oldDelegate.traceStartUs != traceStartUs ||
        oldDelegate.traceDurationUs != traceDurationUs ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.signalColor != signalColor;
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
        borderRadius: BorderRadius.circular(8),
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
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 16),
            tooltip: 'Copy value',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Value copied')));
              }
            },
          ),
        ],
      ),
    );
  }
}

bool _isPriorityTag(KeyValue tag) {
  final key = tag.key.toLowerCase();
  return key == 'error' ||
      key.contains('status') ||
      key.startsWith('http.') ||
      key.startsWith('db.') ||
      key.startsWith('rpc.') ||
      key.contains('exception');
}

Color _signalColorFor(BuildContext context, Span span) {
  if (_spanHasError(span)) return Theme.of(context).colorScheme.error;
  if (span.warnings?.isNotEmpty ?? false) return const Color(0xFFB45309);
  return Theme.of(context).colorScheme.tertiary;
}

bool _spanHasError(Span span) {
  for (final tag in span.tags) {
    final key = tag.key.toLowerCase();
    final value = tag.value?.toString().toLowerCase() ?? '';
    if (key == 'error' && value == 'true') return true;
    if (key.contains('status_code')) {
      final code = int.tryParse(value);
      if (code != null && code >= 500) return true;
    }
  }
  return false;
}
