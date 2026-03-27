import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackendConfigCard extends ConsumerStatefulWidget {
  const BackendConfigCard({super.key});

  @override
  ConsumerState<BackendConfigCard> createState() => _BackendConfigCardState();
}

class _BackendConfigCardState extends ConsumerState<BackendConfigCard> {
  final _urlController = TextEditingController();
  String? _urlError;
  bool _isTesting = false;
  bool? _testResult;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL es requerida';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'URL inválida';
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return 'Debe incluir http:// o https://';
    }
    return null;
  }

  Future<void> _testConnection(BackendConfig config) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final url = config.isOnline
          ? '${BackendConfig.kProdUrl}/health'
          : '${config.localUrl}${config.localUrl.endsWith('/') ? '' : '/'}health';

      await dio.get(url);
      setState(() => _testResult = true);
    } catch (e) {
      setState(() => _testResult = false);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(backendConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (config) {
        _urlController.text = config.localUrl;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dns, color: AppColors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Configuración del Backend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildModeSelector(config),
                const SizedBox(height: AppSpacing.md),
                if (config.isLocal) ...[
                  _buildUrlInput(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTestConnectionButton(config),
                ],
                const SizedBox(height: AppSpacing.md),
                _buildStatusIndicator(config),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(BackendConfig config) {
    return Row(
      children: [
        Text(
          'Modo:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SegmentedButton<BackendMode>(
            segments: const [
              ButtonSegment(
                value: BackendMode.local,
                label: Text('Local'),
                icon: Icon(Icons.computer),
              ),
              ButtonSegment(
                value: BackendMode.online,
                label: Text('Online'),
                icon: Icon(Icons.cloud),
              ),
            ],
            selected: {config.mode},
            onSelectionChanged: (selected) {
              ref.read(backendConfigProvider.notifier).setMode(selected.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'URL del Backend Local',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'http://192.168.40.124:8081',
            errorText: _urlError,
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
          onChanged: (value) {
            if (_urlError != null) {
              setState(() => _urlError = null);
            }
          },
          onSubmitted: (value) {
            _saveUrl(value);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _saveUrl(_urlController.text),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  void _saveUrl(String value) {
    final error = _validateUrl(value);
    if (error != null) {
      setState(() => _urlError = error);
      return;
    }
    final notifier = ref.read(backendConfigProvider.notifier);
    notifier.setLocalUrl(value);
    notifier.applyAndRestartSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada. Presiona Iniciar Sesión de nuevo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTestConnectionButton(BackendConfig config) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: _isTesting ? null : () => _testConnection(config),
          icon: _isTesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(_isTesting ? 'Probando...' : 'Probar Conexión'),
        ),
        if (_testResult != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            _testResult == true ? Icons.check_circle : Icons.error,
            color: _testResult == true ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _testResult == true ? 'Conectado' : 'Sin conexión',
            style: TextStyle(
              color: _testResult == true ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(BackendConfig config) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (config.isOnline ? AppColors.primary : AppColors.info)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        children: [
          Icon(
            config.isOnline ? Icons.cloud_done : Icons.computer,
            size: 16,
            color: config.isOnline ? AppColors.primary : AppColors.info,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Backend actual: ${config.baseUrl}',
            style: TextStyle(
              fontSize: 12,
              color: config.isOnline ? AppColors.primary : AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
