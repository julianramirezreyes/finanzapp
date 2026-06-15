import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/ui/ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/splash_state.dart';
import 'splash_health_notifier.dart';

/// Splash screen premium: isotipo animado que respira, fondo con profundidad,
/// un gesto de carga calmado (scanner) y salida elegante (fade + scale) antes
/// de navegar.
///
/// Solo PRESENTACIÓN. La lógica de health-check (polling, backoff, timeout,
/// preload, retry) vive en [SplashHealthNotifier] y NO se toca aquí. La
/// navegación en `ready` ('/'|'/login' según sesión Supabase) se conserva.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry; // entrada scale+fade del isotipo
  late final AnimationController _pulse; // glow pulsante en loop
  late final AnimationController _exit; // salida fade+scale hacia '/'
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only start polling if not already ready.
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
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// Reproduce la transición de salida y navega según la sesión de Supabase.
  ///
  /// `ref.listen(ready)` puede dispararse más de una vez -> el guard [_leaving]
  /// garantiza navegación idempotente (una sola vez). Conserva la lógica
  /// original: '/' si hay sesión, '/login' si no.
  Future<void> _leaveTo(SplashState state) async {
    if (_leaving) return;
    _leaving = true;
    await _exit.forward();
    if (!mounted) return;
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    context.go(session != null ? '/' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.watch(splashHealthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    ref.listen<SplashState>(splashHealthProvider, (previous, next) {
      if (next == SplashState.ready) _leaveTo(next);
    });

    // Fondo con profundidad: gradiente vertical resuelto por brillo. En dark un
    // verde-petróleo derivado, NUNCA un fondo claro hardcodeado.
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [AppColors.backgroundDark, Color(0xFF0B2E22)]
          : const [AppColors.backgroundLight, AppColors.primarySurface],
    );

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final t = _exit.value; // 0 -> 1 al salir
        return Opacity(
          opacity: 1 - t,
          child: Transform.scale(scale: 1 + 0.04 * t, child: child),
        );
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Marca: entrada scale/fade + glow pulsante ---
                    AnimatedBuilder(
                      animation: Listenable.merge([_entry, _pulse]),
                      builder: (context, _) {
                        final e = Curves.easeOutBack.transform(_entry.value);
                        final glow = reduceMotion
                            ? 0.6
                            : 0.4 + 0.6 * _pulse.value;
                        return Opacity(
                          opacity: _entry.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.85 + 0.15 * e,
                            child: BrandMark(
                              size: 88,
                              glow: splashState == SplashState.error
                                  ? 0.25
                                  : glow,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // --- Wordmark: jerarquía y contraste correcto por brillo ---
                    Text(
                      'FinanzApp',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: context.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Gestión financiera inteligente',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                    // --- Estado ---
                    _buildState(splashState, reduceMotion),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildState(SplashState state, bool reduceMotion) {
    switch (state) {
      case SplashState.ready:
        return const SizedBox(height: 60);
      case SplashState.connecting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            reduceMotion
                ? const SizedBox(
                    height: 4,
                    width: 180,
                    child: LinearProgressIndicator(),
                  )
                : const ScannerProgress(width: 180),
            const SizedBox(height: AppSpacing.lg),
            _RotatingMessage(reduceMotion: reduceMotion),
          ],
        );
      case SplashState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chip de error: relleno resuelto por brillo (no pastel claro
            // hardcodeado). Redundancia icono + texto + color (no solo rojo).
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: context.stateFill(AppColors.expense),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: AppSpacing.iconSizeMedium,
                    color: AppColors.expense,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Sin conexión con el servidor',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => ref.read(splashHealthProvider.notifier).retry(),
              icon: const Icon(Icons.refresh_rounded),
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
}

/// Mensaje rotativo con fade + slide. Conserva el gesto de mensajes secuenciales
/// del splash original via un `Timer.periodic` y `AnimatedSwitcher`.
class _RotatingMessage extends StatefulWidget {
  final bool reduceMotion;
  const _RotatingMessage({required this.reduceMotion});

  @override
  State<_RotatingMessage> createState() => _RotatingMessageState();
}

class _RotatingMessageState extends State<_RotatingMessage> {
  static const _messages = [
    'Conectando con el servidor...',
    'Verificando seguridad...',
    'Cargando tu información...',
    'Preparando tu espacio...',
    'Casi listo...',
  ];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (!mounted) return;
        setState(() => _i = (_i + 1) % _messages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        _messages[_i],
        key: ValueKey(_i),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
