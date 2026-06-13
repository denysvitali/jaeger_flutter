import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/jaeger_api.dart';
import '../../core/providers/app_providers.dart';

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
            itemCount: items.length,
            itemBuilder: (context, index) {
              final service = items[index];
              return ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(service),
                onTap: () {
                  ref
                      .read(traceSearchParamsProvider.notifier)
                      .update(TraceSearchRequest(service: service, limit: 20));
                  // The bottom navigation shell keeps its own state; switching
                  // branches programmatically is not exposed here, so we show a
                  // snackbar and let the user switch to the Traces tab.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service "$service" selected')),
                  );
                },
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
