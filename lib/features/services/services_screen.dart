import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/jaeger_api.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ui_helpers.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final services = ref.watch(servicesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Services',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: services.when(
        data: (items) {
          final filtered = _filter.isEmpty
              ? items
              : items
                    .where(
                      (s) => s.toLowerCase().contains(_filter.toLowerCase()),
                    )
                    .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await HapticFeedback.lightImpact();
              await ref.read(servicesNotifierProvider.notifier).refresh();
            },
            child: filtered.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dns_outlined,
                                    size: 56,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    items.isEmpty
                                        ? 'No services found'
                                        : 'No services match "$_filter"',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    items.isEmpty
                                        ? 'Make sure your Jaeger server is running and reachable.'
                                        : 'Try a different search term.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() => _filter = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search services…',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        );
                      }
                      final service = filtered[index - 1];
                      final accent = serviceColor(service);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Card(
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text(service),
                                    subtitle: Text(
                                      'View traces',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () {
                                      ref
                                          .read(
                                            traceSearchParamsProvider.notifier,
                                          )
                                          .update(
                                            TraceSearchRequest(
                                              service: service,
                                              limit: 20,
                                            ),
                                          );
                                      context.go('/traces');
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load services: $e',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
