import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ignore_for_file: deprecated_member_use

import '../../core/api/jaeger_api.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ui_helpers.dart';

class TracesSearchScreen extends ConsumerWidget {
  const TracesSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(traceSearchParamsProvider);
    final traces = ref.watch(tracesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Traces')),
      body: Column(
        children: [
          _SearchForm(params: params),
          const Divider(height: 1),
          Expanded(
            child: traces.when(
              data: (items) => _TraceList(traces: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load traces: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchForm extends ConsumerStatefulWidget {
  const _SearchForm({required this.params});

  final TraceSearchRequest params;

  @override
  ConsumerState<_SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends ConsumerState<_SearchForm> {
  final _tagsController = TextEditingController();
  final _limitController = TextEditingController();

  String _service = '';
  String? _operation;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _service = widget.params.service;
    _operation = widget.params.operation;
    _startTime = widget.params.startTime;
    _endTime = widget.params.endTime;
    _tagsController.text =
        widget.params.tags?.entries
            .map((e) => '${e.key}=${e.value}')
            .join(',') ??
        '';
    _limitController.text = widget.params.limit.toString();
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Map<String, String>? _parseTags(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final map = <String, String>{};
    for (final pair in text.split(',')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
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

  void _applyPreset(Duration duration) {
    final now = DateTime.now();
    setState(() {
      _endTime = now;
      _startTime = now.subtract(duration);
    });
  }

  Future<void> _search() async {
    final limit = int.tryParse(_limitController.text) ?? 20;
    final request = TraceSearchRequest(
      service: _service,
      operation: _operation,
      tags: _parseTags(_tagsController.text),
      startTime: _startTime,
      endTime: _endTime,
      limit: limit,
    );
    await ref.read(tracesNotifierProvider.notifier).search(request);
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          services.when(
            data: (items) => DropdownButtonFormField<String>(
              value: _service.isEmpty ? null : _service,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Service'),
              hint: const Text('Select a service'),
              items: [
                const DropdownMenuItem(value: '', child: Text('—')),
                ...items.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (value) {
                setState(() {
                  _service = value ?? '';
                  _operation = null;
                });
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const Text('Could not load services'),
          ),
          const SizedBox(height: 12),
          _OperationDropdown(
            service: _service,
            operation: _operation,
            onChanged: (op) => setState(() => _operation = op),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'key=value,key2=value2',
            ),
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
                      _startTime ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startTime = picked);
                    }
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
                    if (picked != null) {
                      setState(() => _endTime = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _PresetChip(
                label: 'Last 1h',
                onPressed: () => _applyPreset(const Duration(hours: 1)),
              ),
              _PresetChip(
                label: 'Last 24h',
                onPressed: () => _applyPreset(const Duration(days: 1)),
              ),
              _PresetChip(
                label: 'Last 7d',
                onPressed: () => _applyPreset(const Duration(days: 7)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _service.isEmpty ? null : _search,
                    child: const Text('Search'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final text = value != null ? _dateTimeFormat.format(value!) : '—';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
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
        value: null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Operation'),
        items: const [],
        onChanged: null,
      );
    }

    final operations = ref.watch(operationsProvider(service));

    return operations.when(
      data: (items) => DropdownButtonFormField<String?>(
        value: operation,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Operation'),
        hint: const Text('All operations'),
        items: [
          const DropdownMenuItem(value: null, child: Text('— all —')),
          ...items.map((op) => DropdownMenuItem(value: op, child: Text(op))),
        ],
        onChanged: onChanged,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => const Text('Could not load operations'),
    );
  }
}

class _TraceList extends StatelessWidget {
  const _TraceList({required this.traces});

  final List<Trace> traces;

  @override
  Widget build(BuildContext context) {
    if (traces.isEmpty) {
      return const Center(child: Text('No traces found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: traces.length,
      itemBuilder: (context, index) {
        final trace = traces[index];
        final rootSpan = trace.spans.isNotEmpty ? trace.spans.first : null;
        final service = rootSpan != null
            ? trace.processes[rootSpan.processID]?.serviceName ?? ''
            : '';
        final startUs = trace.spans
            .map((s) => s.startTime)
            .fold(0, (a, b) => a == 0 || b < a ? b : a);
        final durationUs = trace.spans.isNotEmpty
            ? trace.spans.map((s) => s.duration).reduce((a, b) => a > b ? a : b)
            : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Card(
            child: InkWell(
              onTap: () => context.push('/traces/${trace.traceID}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: serviceColor(service),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rootSpan?.operationName ?? trace.traceID,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$service · ${trace.spans.length} spans · '
                            '${formatTimestamp(startUs)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(formatDuration(durationUs)),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
