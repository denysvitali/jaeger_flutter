import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/jaeger_api.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/ui_helpers.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: services.when(
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(servicesNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final service = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: serviceColor(service),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(service),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref
                          .read(traceSearchParamsProvider.notifier)
                          .update(TraceSearchRequest(service: service, limit: 20));
                      context.go('/traces');
                    },
                  ),
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load services: $e')),
      ),
    );
  }
}
