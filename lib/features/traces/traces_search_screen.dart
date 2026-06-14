import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/jaeger_api.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ui_helpers.dart';

const _recentSearchesKey = 'recent_trace_searches_v1';
const _maxRecentSearches = 6;

class TracesSearchScreen extends ConsumerStatefulWidget {
  const TracesSearchScreen({super.key});

  @override
  ConsumerState<TracesSearchScreen> createState() => _TracesSearchScreenState();
}

class _TracesSearchScreenState extends ConsumerState<TracesSearchScreen> {
  List<TraceSearchRequest> _recentSearches = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = SharedPreferencesAsync();
      final raw = await prefs.getString(_recentSearchesKey);
      if (!mounted || raw == null || raw.isEmpty) return;

      final Object? decoded;
      decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final recentItems = decoded;

      setState(() {
        _recentSearches = recentItems
            .whereType<Map>()
            .map((item) => _requestFromJson(Map<String, dynamic>.from(item)))
            .whereType<TraceSearchRequest>()
            .toList(growable: false);
      });
    } on FormatException {
      return;
    } on StateError {
      return;
    } on TypeError {
      return;
    }
  }

  Future<void> _saveRecentSearch(TraceSearchRequest request) async {
    if (request.service.isEmpty) return;

    final next = <TraceSearchRequest>[
      request,
      ..._recentSearches.where((item) => !_sameSearch(item, request)),
    ].take(_maxRecentSearches).toList(growable: false);

    setState(() => _recentSearches = next);
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        _recentSearchesKey,
        jsonEncode(next.map(_requestToJson).toList(growable: false)),
      );
    } on StateError {
      return;
    }
  }

  Future<void> _runSearch(TraceSearchRequest request) async {
    await ref.read(tracesNotifierProvider.notifier).search(request);
    await _saveRecentSearch(request);
  }

  Future<void> _openFilters(TraceSearchRequest params) async {
    final request = await showModalBottomSheet<TraceSearchRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TraceFilterSheet(initial: params),
    );
    if (request != null) {
      await _runSearch(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(traceSearchParamsProvider);
    final traces = ref.watch(tracesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: () => _openFilters(params),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: params.service.isEmpty
                ? null
                : () => ref.read(tracesNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _TraceSearchStrip(
            params: params,
            recentSearches: _recentSearches,
            onEditFilters: () => _openFilters(params),
            onApplySearch: _runSearch,
          ),
          const Divider(height: 1),
          Expanded(
            child: traces.when(
              data: (items) => _TraceList(params: params, traces: items),
              loading: () => const _TraceListSkeleton(),
              error: (e, _) =>
                  _TraceError(message: 'Failed to load traces: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceSearchStrip extends StatelessWidget {
  const _TraceSearchStrip({
    required this.params,
    required this.recentSearches,
    required this.onEditFilters,
    required this.onApplySearch,
  });

  final TraceSearchRequest params;
  final List<TraceSearchRequest> recentSearches;
  final VoidCallback onEditFilters;
  final ValueChanged<TraceSearchRequest> onApplySearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasService = params.service.isNotEmpty;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEditFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasService ? params.service : 'Choose a service',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasService
                                ? _requestSummary(params)
                                : 'Filters open in a sheet so results stay visible.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onEditFilters,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(hasService ? 'Refine' : 'Search'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickSearchChip(
                  label: 'Last 15m',
                  enabled: hasService,
                  onPressed: () =>
                      onApplySearch(_withTimeRange(params, 15.minutes)),
                ),
                _QuickSearchChip(
                  label: 'Last 1h',
                  enabled: hasService,
                  onPressed: () =>
                      onApplySearch(_withTimeRange(params, 1.hours)),
                ),
                _QuickSearchChip(
                  label: 'Last 24h',
                  enabled: hasService,
                  onPressed: () =>
                      onApplySearch(_withTimeRange(params, 24.hours)),
                ),
                _QuickSearchChip(
                  label: 'Errors',
                  enabled: hasService,
                  icon: Icons.error_outline,
                  onPressed: () => onApplySearch(
                    _withTags(_withTimeRange(params, 1.hours), {
                      'error': 'true',
                    }),
                  ),
                ),
                for (final recent in recentSearches.take(3))
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(_recentLabel(recent)),
                    onPressed: () => onApplySearch(recent),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchChip extends StatelessWidget {
  const _QuickSearchChip({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      onPressed: enabled ? onPressed : null,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TraceFilterSheet extends ConsumerStatefulWidget {
  const _TraceFilterSheet({required this.initial});

  final TraceSearchRequest initial;

  @override
  ConsumerState<_TraceFilterSheet> createState() => _TraceFilterSheetState();
}

class _TraceFilterSheetState extends ConsumerState<_TraceFilterSheet> {
  final _serviceController = TextEditingController();
  final _serviceFocusNode = FocusNode();
  final _tagsController = TextEditingController();
  final _statusCodeController = TextEditingController();
  final _limitController = TextEditingController();
  final _minDurationController = TextEditingController();
  final _maxDurationController = TextEditingController();

  String? _operation;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _errorOnly = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _serviceController.text = initial.service;
    _operation = initial.operation;
    _startTime = initial.startTime;
    _endTime = initial.endTime;
    _limitController.text = initial.limit.toString();
    _minDurationController.text = _durationInputText(initial.minDuration);
    _maxDurationController.text = _durationInputText(initial.maxDuration);

    final tags = Map<String, String>.of(initial.tags ?? const {});
    _errorOnly = tags.remove('error') == 'true';
    _statusCodeController.text = tags.remove('http.status_code') ?? '';
    _tagsController.text = tags.entries
        .map((e) => '${e.key}=${e.value}')
        .join(',');
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _serviceFocusNode.dispose();
    _tagsController.dispose();
    _statusCodeController.dispose();
    _limitController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }

  Map<String, String>? _parseTags(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final map = <String, String>{};
    for (final pair in text.split(',')) {
      final index = pair.indexOf('=');
      if (index <= 0) continue;
      final key = pair.substring(0, index).trim();
      final value = pair.substring(index + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) map[key] = value;
    }
    return map.isEmpty ? null : map;
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _applyRange(Duration duration) {
    final now = DateTime.now();
    setState(() {
      _endTime = now;
      _startTime = now.subtract(duration);
    });
  }

  void _submit() {
    final service = _serviceController.text.trim();
    if (service.isEmpty) return;

    final tags = _parseTags(_tagsController.text) ?? <String, String>{};
    if (_errorOnly) tags['error'] = 'true';
    final statusCode = _statusCodeController.text.trim();
    if (statusCode.isNotEmpty) {
      tags['http.status_code'] = statusCode;
    }

    Navigator.of(context).pop(
      TraceSearchRequest(
        service: service,
        operation: (_operation?.isEmpty ?? true) ? null : _operation,
        tags: tags.isEmpty ? null : tags,
        startTime: _startTime,
        endTime: _endTime,
        limit: int.tryParse(_limitController.text) ?? 20,
        minDuration: _parseDuration(_minDurationController.text),
        maxDuration: _parseDuration(_maxDurationController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final service = _serviceController.text.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trace search',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              services.when(
                data: (items) => RawAutocomplete<String>(
                  textEditingController: _serviceController,
                  focusNode: _serviceFocusNode,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return items.take(8);
                    return items
                        .where((item) => item.toLowerCase().contains(query))
                        .take(8);
                  },
                  onSelected: (value) {
                    setState(() {
                      _serviceController.text = value;
                      _operation = null;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Service',
                            hintText: 'Search services',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() => _operation = null),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _OperationDropdown(
                service: service,
                operation: _operation,
                onChanged: (op) => setState(() => _operation = op),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeField(
                      label: 'Start',
                      value: _startTime,
                      onTap: () async {
                        final picked = await _pickDateTime(
                          _startTime ?? DateTime.now().subtract(1.hours),
                        );
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeField(
                      label: 'End',
                      value: _endTime,
                      onTap: () async {
                        final picked = await _pickDateTime(
                          _endTime ?? DateTime.now(),
                        );
                        if (picked != null) setState(() => _endTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Last 15m'),
                    onPressed: () => _applyRange(15.minutes),
                  ),
                  ActionChip(
                    label: const Text('Last 1h'),
                    onPressed: () => _applyRange(1.hours),
                  ),
                  ActionChip(
                    label: const Text('Last 24h'),
                    onPressed: () => _applyRange(24.hours),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'key=value,key2=value2',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Min duration',
                        hintText: '10ms',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Max duration',
                        hintText: '2s',
                        prefixIcon: Icon(Icons.timer_off_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Errors only'),
                      value: _errorOnly,
                      onChanged: (value) => setState(() => _errorOnly = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 132,
                    child: TextFormField(
                      controller: _statusCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        hintText: '500',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _operation = null;
                          _startTime = null;
                          _endTime = null;
                          _tagsController.clear();
                          _statusCodeController.clear();
                          _limitController.text = '20';
                          _minDurationController.clear();
                          _maxDurationController.clear();
                          _errorOnly = false;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: service.isEmpty ? null : _submit,
                      icon: const Icon(Icons.search),
                      label: const Text('Search traces'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: status and error helpers are added as Jaeger tag filters.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationDropdown extends ConsumerWidget {
  const _OperationDropdown({
    required this.service,
    required this.operation,
    required this.onChanged,
  });

  final String service;
  final String? operation;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (service.isEmpty) {
      return DropdownButtonFormField<String>(
        initialValue: null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Operation',
          prefixIcon: Icon(Icons.code_outlined),
        ),
        items: const [],
        onChanged: null,
      );
    }

    final operations = ref.watch(operationsProvider(service));

    return operations.when(
      data: (items) => DropdownButtonFormField<String?>(
        initialValue: operation,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Operation',
          prefixIcon: Icon(Icons.code_outlined),
        ),
        hint: const Text('All operations'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All operations')),
          ...items.map((op) => DropdownMenuItem(value: op, child: Text(op))),
        ],
        onChanged: onChanged,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => const Text('Could not load operations'),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value != null ? _dateTimeFormat.format(value!) : 'Any';
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: value != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TraceList extends ConsumerWidget {
  const _TraceList({required this.params, required this.traces});

  final TraceSearchRequest params;
  final List<Trace> traces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (params.service.isEmpty) {
      return const _TraceEmptyState(
        icon: Icons.manage_search,
        title: 'Pick a service to start',
        message: 'Use Search to choose a service, time window, and filters.',
      );
    }

    if (traces.isEmpty) {
      return const _TraceEmptyState(
        icon: Icons.search_off,
        title: 'No traces match this search',
        message: 'Try a wider time range, fewer tags, or a higher limit.',
      );
    }

    final summaries = traces
        .map((trace) => _TraceSummary.fromTrace(trace))
        .toList(growable: false);
    final maxDuration = summaries.fold<int>(
      0,
      (current, item) => current > item.durationUs ? current : item.durationUs,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await HapticFeedback.lightImpact();
        await ref.read(tracesNotifierProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          final durationRatio = maxDuration > 0
              ? summary.durationUs / maxDuration
              : 0.0;
          return _TraceCard(
            summary: summary,
            durationRatio: durationRatio,
            slow: durationRatio >= 0.75 && maxDuration > 0,
          );
        },
      ),
    );
  }
}

class _TraceCard extends StatelessWidget {
  const _TraceCard({
    required this.summary,
    required this.durationRatio,
    required this.slow,
  });

  final _TraceSummary summary;
  final double durationRatio;
  final bool slow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = serviceColor(summary.service);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push('/traces/${summary.trace.traceID}'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary.operation,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SignalPill(
                      label: formatDuration(summary.durationUs),
                      icon: Icons.timer_outlined,
                      color: slow
                          ? const Color(0xFFB45309)
                          : colorScheme.primary,
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${summary.service} · ${formatTimestamp(summary.startUs)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summary.spanCount} spans',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: durationRatio.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      summary.hasError
                          ? colorScheme.error
                          : slow
                          ? const Color(0xFFB45309)
                          : accent,
                    ),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (summary.hasError)
                      _SignalPill(
                        label: 'Error',
                        icon: Icons.error_outline,
                        color: colorScheme.error,
                      ),
                    if (summary.hasWarning)
                      _SignalPill(
                        label: 'Warning',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFB45309),
                      ),
                    if (slow)
                      _SignalPill(
                        label: 'Slowest',
                        icon: Icons.speed,
                        color: const Color(0xFFB45309),
                      ),
                    _SignalPill(
                      label: '${summary.serviceCount} svc',
                      icon: Icons.dns_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    _SignalPill(
                      label: 'depth ${summary.depth}',
                      icon: Icons.account_tree_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceSummary {
  const _TraceSummary({
    required this.trace,
    required this.operation,
    required this.service,
    required this.startUs,
    required this.durationUs,
    required this.spanCount,
    required this.serviceCount,
    required this.depth,
    required this.hasError,
    required this.hasWarning,
  });

  factory _TraceSummary.fromTrace(Trace trace) {
    final spans = trace.spans;
    final rootSpan = spans.isNotEmpty ? spans.first : null;
    final service = rootSpan == null
        ? ''
        : trace.processes[rootSpan.processID]?.serviceName ??
              rootSpan.processID;
    final startUs = spans.isEmpty
        ? 0
        : spans.map((span) => span.startTime).reduce((a, b) => a < b ? a : b);
    final endUs = spans.isEmpty
        ? 0
        : spans
              .map((span) => span.startTime + span.duration)
              .reduce((a, b) => a > b ? a : b);

    return _TraceSummary(
      trace: trace,
      operation: rootSpan?.operationName ?? trace.traceID,
      service: service,
      startUs: startUs,
      durationUs: endUs > startUs ? endUs - startUs : 0,
      spanCount: spans.length,
      serviceCount: trace.processes.values
          .map((process) => process.serviceName)
          .toSet()
          .length,
      depth: _traceDepth(spans),
      hasError: spans.any(_spanHasError),
      hasWarning: spans.any((span) => span.warnings?.isNotEmpty ?? false),
    );
  }

  final Trace trace;
  final String operation;
  final String service;
  final int startUs;
  final int durationUs;
  final int spanCount;
  final int serviceCount;
  final int depth;
  final bool hasError;
  final bool hasWarning;
}

class _TraceEmptyState extends StatelessWidget {
  const _TraceEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceError extends StatelessWidget {
  const _TraceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TraceListSkeleton extends StatelessWidget {
  const _TraceListSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: 220,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

extension on int {
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
}

TraceSearchRequest _withTimeRange(TraceSearchRequest request, Duration range) {
  final now = DateTime.now();
  return TraceSearchRequest(
    service: request.service,
    operation: request.operation,
    tags: request.tags,
    startTime: now.subtract(range),
    endTime: now,
    limit: request.limit,
    offset: request.offset,
    minDuration: request.minDuration,
    maxDuration: request.maxDuration,
  );
}

TraceSearchRequest _withTags(
  TraceSearchRequest request,
  Map<String, String> tags,
) {
  return TraceSearchRequest(
    service: request.service,
    operation: request.operation,
    tags: {...?request.tags, ...tags},
    startTime: request.startTime,
    endTime: request.endTime,
    limit: request.limit,
    offset: request.offset,
    minDuration: request.minDuration,
    maxDuration: request.maxDuration,
  );
}

String _requestSummary(TraceSearchRequest request) {
  final parts = <String>[];
  if (request.operation?.isNotEmpty ?? false) parts.add(request.operation!);
  if (request.startTime != null && request.endTime != null) {
    parts.add(
      '${_dateTimeFormat.format(request.startTime!)} - ${_dateTimeFormat.format(request.endTime!)}',
    );
  } else {
    parts.add('Any time');
  }
  if (request.tags?.isNotEmpty ?? false) {
    parts.add('${request.tags!.length} tags');
  }
  if (request.minDuration != null || request.maxDuration != null) {
    parts.add(
      '${_durationInputText(request.minDuration)}-${_durationInputText(request.maxDuration)}',
    );
  }
  parts.add('limit ${request.limit}');
  return parts.join(' · ');
}

String _recentLabel(TraceSearchRequest request) {
  final operation = request.operation;
  if (operation != null && operation.isNotEmpty) {
    return '${request.service} / $operation';
  }
  return request.service;
}

bool _sameSearch(TraceSearchRequest a, TraceSearchRequest b) {
  return jsonEncode(_requestToJson(a)) == jsonEncode(_requestToJson(b));
}

Map<String, Object?> _requestToJson(TraceSearchRequest request) {
  return {
    'service': request.service,
    'operation': request.operation,
    'tags': request.tags,
    'startTime': request.startTime?.toIso8601String(),
    'endTime': request.endTime?.toIso8601String(),
    'limit': request.limit,
    'offset': request.offset,
    'minDurationUs': request.minDuration?.inMicroseconds,
    'maxDurationUs': request.maxDuration?.inMicroseconds,
  };
}

TraceSearchRequest? _requestFromJson(Map<String, dynamic> json) {
  final service = json['service'];
  if (service is! String || service.isEmpty) return null;
  final tags = json['tags'];
  return TraceSearchRequest(
    service: service,
    operation: json['operation'] as String?,
    tags: tags is Map
        ? {
            for (final entry in tags.entries)
              entry.key.toString(): entry.value.toString(),
          }
        : null,
    startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
    endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
    limit: json['limit'] is int ? json['limit'] as int : 20,
    offset: json['offset'] is int ? json['offset'] as int : 0,
    minDuration: json['minDurationUs'] is int
        ? Duration(microseconds: json['minDurationUs'] as int)
        : null,
    maxDuration: json['maxDurationUs'] is int
        ? Duration(microseconds: json['maxDurationUs'] as int)
        : null,
  );
}

Duration? _parseDuration(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d+(?:\.\d+)?)(us|µs|ms|s|m)?$').firstMatch(text);
  if (match == null) return null;
  final value = double.tryParse(match.group(1)!);
  if (value == null) return null;
  final unit = match.group(2) ?? 'ms';
  return switch (unit) {
    'us' || 'µs' => Duration(microseconds: value.round()),
    'ms' => Duration(microseconds: (value * 1000).round()),
    's' => Duration(milliseconds: (value * 1000).round()),
    'm' => Duration(seconds: (value * 60).round()),
    _ => null,
  };
}

String _durationInputText(Duration? duration) {
  if (duration == null) return '';
  if (duration.inMicroseconds < 1000) {
    return '${duration.inMicroseconds}us';
  }
  if (duration.inMilliseconds < 1000) {
    return '${duration.inMilliseconds}ms';
  }
  if (duration.inSeconds < 60) return '${duration.inSeconds}s';
  return '${duration.inMinutes}m';
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

int _traceDepth(List<Span> spans) {
  if (spans.isEmpty) return 0;
  final children = <String, List<Span>>{};
  final referenced = <String>{};
  for (final span in spans) {
    for (final ref in span.references) {
      children.putIfAbsent(ref.spanID, () => <Span>[]).add(span);
      referenced.add(span.spanID);
    }
  }

  final roots = spans.where((span) => !referenced.contains(span.spanID));
  var maxDepth = 0;
  final stack = roots.map((span) => (span: span, depth: 1)).toList();
  while (stack.isNotEmpty) {
    final item = stack.removeLast();
    if (item.depth > maxDepth) maxDepth = item.depth;
    for (final child in children[item.span.spanID] ?? const <Span>[]) {
      stack.add((span: child, depth: item.depth + 1));
    }
  }
  return maxDepth;
}
