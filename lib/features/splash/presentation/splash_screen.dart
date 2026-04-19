import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/ui/widgets/financial_loading_indicator.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/splash_state.dart';
import 'splash_health_notifier.dart';

/// Splash screen that displays while connecting to the backend.
/// Automatically navigates to the appropriate screen once the backend is ready.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only start polling if not already ready
      final currentState = ref.read(splashHealthProvider);
      if (currentState != SplashState.ready) {
        try {
          ref.read(splashHealthProvider.notifier).startPolling();
        } catch (e) {
          debugPrint('SplashScreen init error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.watch(splashHealthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navigate when backend is ready
    ref.listen<SplashState>(splashHealthProvider, (previous, next) {
      if (next == SplashState.ready) {
        _navigateToMain();
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/title
                Text(
                  'FinanzApp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Gestión Financiera',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // State-dependent content
                _buildStateContent(splashState, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(SplashState state, bool isDark) {
    switch (state) {
      case SplashState.connecting:
        return const FinancialLoadingIndicator();

      case SplashState.ready:
        return const SizedBox.shrink();

      case SplashState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.expense),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No se pudo conectar al servidor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.expense,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(splashHealthProvider.notifier).retry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _navigateToMain() async {
    final supabase = ref.read(supabaseClientProvider);
    final session = supabase.auth.currentSession;

    if (session != null) {
      // Dashboard is already preloaded, go directly
      if (mounted) {
        context.go('/');
      }
    } else {
      // Not logged in, go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
