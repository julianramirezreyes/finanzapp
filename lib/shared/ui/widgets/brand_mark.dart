import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Isotipo de marca: rombo redondeado con [AppColors.primaryGradient], sombra de
/// profundidad y un halo radial pulsante controlado por [glow].
///
/// Sin assets externos ni CustomPainter. El glifo (`Icons.trending_up_rounded`)
/// va sobre el gradiente OSCURO de marca, por lo que [AppColors.textOnPrimary]
/// (#FFFFFF) es el color de contraste CORRECTO aquí — no es un blanco
/// hardcodeado sobre superficie clara.
///
/// [glow] es la opacidad del halo (0..1) y se anima desde el padre (p. ej. un
/// `AnimationController` de pulso) para que el isotipo "respire".
class BrandMark extends StatelessWidget {
  /// Lado del rombo en píxeles lógicos. El widget ocupa `size * 1.6` para dejar
  /// espacio al halo.
  final double size;

  /// Opacidad del halo radial (0..1). Animable desde fuera.
  final double glow;

  const BrandMark({super.key, this.size = 88, this.glow = 0.6});

  @override
  Widget build(BuildContext context) {
    final double clampedGlow = glow.clamp(0.0, 1.0);

    return SizedBox(
      width: size * 1.6,
      height: size * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo / glow pulsante detrás del isotipo.
          Container(
            width: size * 1.6,
            height: size * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.28 * clampedGlow),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // Isotipo: rombo redondeado con gradiente de marca.
          Transform.rotate(
            angle: 0.785398, // 45° -> rombo
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              // Glifo de marca: flecha de crecimiento, sin rotar respecto al eje.
              child: Transform.rotate(
                angle: -0.785398,
                child: Center(
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.textOnPrimary,
                    size: size * 0.5,
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
