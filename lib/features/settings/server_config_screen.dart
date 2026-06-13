import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/server_config.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _verifying = false;
  String? _resultMessage;
  bool _resultIsError = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final serverConfig = ref.read(serverConfigProvider);
    final url = await serverConfig.getServerUrl();
    if (mounted) {
      _urlController.text = url;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _verifying = true;
      _resultMessage = null;
    });

    final result = await verifyServerUrl(_urlController.text);

    if (!mounted) return;

    if (result is ServerUrlVerified) {
      await ref.read(serverConfigProvider).setServerUrl(result.url);
      await ref.read(servicesNotifierProvider.notifier).refresh();
      setState(() {
        _verifying = false;
        _resultMessage = 'Saved and verified: ${result.url}';
        _resultIsError = false;
      });
    } else if (result is ServerUrlFailed) {
      setState(() {
        _verifying = false;
        _resultMessage = result.error;
        _resultIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final certStatus = ref.watch(certificateStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jaeger server',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'http://jaeger.example.com:16686',
                        labelText: 'Server URL',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Server URL is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _verifying ? null : _verifyAndSave,
                        child: _verifying
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify & save'),
                      ),
                    ),
                    if (_resultMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _resultIsError
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: certStatus.when(
                data: (status) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User certificates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: ${status.supported ? 'yes' : 'no'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Certificate status error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
