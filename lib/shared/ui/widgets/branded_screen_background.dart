import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Backdrop de marca para una PANTALLA completa (bóveda "Bóveda: `banco`").
/// Mantiene la identidad del banco al ENTRAR a la cuenta — sutil, "le da vida"
/// — sin competir con la legibilidad de las tarjetas opacas que van encima.
///
/// Reusa las MISMAS piezas que `BrandedAccountSurface` (detectBrand,
/// `BankAvatar.accentFor`, `stateFill`, ramificación SVG/PNG del watermark),
/// pero adaptadas a una pantalla: wash VERTICAL full-screen (el color vive
/// arriba ~40% y se desvanece hacia abajo) y watermark grande en la ZONA
/// SUPERIOR (header) — las cards opacas tapan el centro, así que el logo vive
/// donde se ve.
///
/// Estructura (`Stack`):
///  (a) WASH: `Positioned.fill` + gradiente vertical `topCenter -> bottomCenter`
///      de `stateFill(accent)` a transparente. Brightness-aware (dark-safe).
///  (b) WATERMARK: si la marca tiene asset Y `showLogo` es true, el logo grande
///      tenue (opacidad ~0.06) en la zona superior derecha, dentro de
///      `IgnorePointer`. Si no hay marca/asset, degrada (sin watermark) sin
///      romper. Cuando esta pantalla YA tiene un hero con watermark propio
///      (p.ej. `BrandedVaultHeader`), pasar `showLogo: false` evita duplicar la
///      marca de agua: solo queda el wash.
///  (c) `child` por encima.
class BrandedScreenBackground extends StatelessWidget {
  final String name;
  final Widget child;

  /// Cuando es false, omite el watermark del logo y deja SOLO el wash. Útil para
  /// pantallas que ya muestran la marca de agua en un hero header propio y no
  /// quieren duplicarla en el fondo.
  final bool showLogo;

  const BrandedScreenBackground({
    super.key,
    required this.name,
    required this.child,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final washColor = context.stateFill(
      BankAvatar.accentFor(name) ?? fallbackColorFor(name),
    );
    final brand = detectBrand(name);
    final asset = showLogo ? brand?.asset : null;

    return Stack(
      children: [
        // (a) Capa 0: wash VERTICAL — el color vive arriba y se desvanece hacia
        // abajo. `stateFill` lo mantiene tenue y dark-safe.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [washColor, Colors.transparent],
                // El color domina el ~40% superior y luego se difumina.
                stops: const [0.0, 0.4],
              ),
            ),
          ),
        ),
        // (b) Capa 1: watermark del logo en la ZONA SUPERIOR (header). Tenue y
        // sin interceptar gestos. Degrada sin watermark si no hay asset.
        if (asset != null)
          Positioned(
            top: 8,
            right: 12,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: _Watermark(asset: asset),
              ),
            ),
          ),
        // (c) Capa 2: contenido por encima.
        child,
      ],
    );
  }
}

/// Logo tenue usado como marca de agua de PANTALLA, en la zona superior. SVG y
/// PNG ramifican por extensión; la altura fija (grande) mantiene un tamaño
/// consistente entre símbolos (cuadrados) y wordmarks (anchos).
class _Watermark extends StatelessWidget {
  final String asset;

  const _Watermark({required this.asset});

  @override
  Widget build(BuildContext context) {
    const double logoHeight = 160;
    final isSvg = asset.toLowerCase().endsWith('.svg');
    return SizedBox(
      height: logoHeight,
      child: isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
