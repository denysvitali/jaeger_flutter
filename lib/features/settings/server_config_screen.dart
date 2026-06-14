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
  bool _loadingUrl = true;

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
      setState(() {
        _urlController.text = url;
        _loadingUrl = false;
      });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final certStatus = ref.watch(certificateStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Primary card: Server URL
          Card(
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jaeger server', style: textTheme.titleMedium),
                            const SizedBox(height: 12),
                            if (_loadingUrl)
                              _SkeletonUrlField(colorScheme: colorScheme)
                            else
                              TextFormField(
                                controller: _urlController,
                                decoration: const InputDecoration(
                                  hintText: 'http://jaeger.example.com:16686',
                                  labelText: 'Server URL',
                                  prefixIcon: Icon(Icons.link),
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
                              child: FilledButton.icon(
                                onPressed: _verifying ? null : _verifyAndSave,
                                icon: _verifying
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: const Text('Verify & save'),
                              ),
                            ),
                            if (_resultMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _resultIsError
                                      ? colorScheme.errorContainer
                                      : colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _resultMessage!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _resultIsError
                                        ? colorScheme.onErrorContainer
                                        : colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Secondary card: Certificates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: certStatus.when(
                data: (status) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User certificates', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(status.message, style: textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: ${status.supported ? 'yes' : 'no'}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  'Certificate status error: $e',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonUrlField extends StatefulWidget {
  const _SkeletonUrlField({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_SkeletonUrlField> createState() => _SkeletonUrlFieldState();
}

class _SkeletonUrlFieldState extends State<_SkeletonUrlField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: widget.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
