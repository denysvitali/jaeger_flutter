import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ignore_for_file: deprecated_member_use

import '../../core/api/jaeger_api.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _service = widget.params.service;
    _operation = widget.params.operation;
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

  Future<void> _search() async {
    final limit = int.tryParse(_limitController.text) ?? 20;
    final request = TraceSearchRequest(
      service: _service,
      operation: _operation,
      tags: _parseTags(_tagsController.text),
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
              decoration: const InputDecoration(
                labelText: 'Service',
                border: OutlineInputBorder(),
              ),
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
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Limit',
                    border: OutlineInputBorder(),
                  ),
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
        decoration: const InputDecoration(
          labelText: 'Operation',
          border: OutlineInputBorder(),
        ),
        items: const [],
        onChanged: null,
      );
    }

    final operations = ref.watch(operationsProvider(service));

    return operations.when(
      data: (items) => DropdownButtonFormField<String?>(
        value: operation,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Operation',
          border: OutlineInputBorder(),
        ),
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
      itemCount: traces.length,
      itemBuilder: (context, index) {
        final trace = traces[index];
        final rootSpan = trace.spans.isNotEmpty ? trace.spans.first : null;
        final service = rootSpan != null
            ? trace.processes[rootSpan.processID]?.serviceName ?? ''
            : '';
        final durationMs = trace.spans.isNotEmpty
            ? trace.spans
                      .map((s) => s.duration)
                      .reduce((a, b) => a > b ? a : b) /
                  1000
            : 0.0;

        return ListTile(
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(rootSpan?.operationName ?? trace.traceID),
          subtitle: Text(
            '$service · ${trace.spans.length} spans · '
            '${durationMs.toStringAsFixed(2)} ms',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/traces/${trace.traceID}'),
        );
      },
    );
  }
}
