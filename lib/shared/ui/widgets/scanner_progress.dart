import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barra indeterminada "scanner" premium: un track sutil más un gradiente de
/// marca que viaja de izquierda a derecha en loop.
///
/// El track resuelve su color por brillo via `context.onSurface` a baja
/// opacidad (no usa `Colors.white` hardcodeado), por lo que se ve correcto en
/// light y dark.
///
/// El [AnimationController] usa `.repeat()` (animación infinita): en tests usa
/// `pump(Duration)`, NUNCA `pumpAndSettle` (nunca llega a reposo). `dispose()`
/// cancela el controller para no dejar tickers colgando.
class ScannerProgress extends StatefulWidget {
  /// Ancho total de la barra en píxeles lógicos.
  final double width;

  const ScannerProgress({super.key, this.width = 180});

  @override
  State<ScannerProgress> createState() => _ScannerProgressState();
}

class _ScannerProgressState extends State<ScannerProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Track resuelto por brillo (NO Colors.white hardcodeado): onSurface es
    // oscuro en light y claro en dark, a baja opacidad queda sutil en ambos.
    final Color track = context.onSurface.withValues(alpha: 0.12);

    return SizedBox(
      width: widget.width,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: track)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Align(
                  alignment: Alignment(-1.0 + 2.0 * _controller.value, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.4,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x0010B981), // primary @ alpha 0
                            AppColors.primary,
                            AppColors.primaryLight,
                            Color(0x0010B981), // primary @ alpha 0
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
