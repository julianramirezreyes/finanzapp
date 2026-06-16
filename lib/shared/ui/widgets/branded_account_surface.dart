import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Superficie de tarjeta de cuenta con identidad de marca (SDD #8, Fase 2 —
/// Diseño A). Envuelve el contenido del tile (el `Row`) con:
///
/// 1. Un WASH horizontal del color de la marca (`accentFor` o `fallbackColorFor`)
///    que se difumina desde la izquierda hacia transparente — sutil y
///    brightness-aware (`stateFill`).
/// 2. Una WATERMARK del logo del banco CENTRADA en el espacio vacío de la
///    tarjeta (no sobre el saldo de la derecha), tenue (opacidad ~0.08) y
///    recortada por las esquinas redondeadas.
/// 3. El `child` con padding (que MIGRA aquí desde el AppCard para que el wash y
///    la watermark lleguen al borde de la tarjeta).
///
/// El recorte lo aporta este widget (ClipRRect propio) para no tocar AppCard.
/// Si la marca es desconocida o no tiene asset, degrada a solo wash + child
/// (sin watermark), sin romper.
class BrandedAccountSurface extends StatelessWidget {
  final String name;
  final Widget child;
  final EdgeInsets? padding;

  const BrandedAccountSurface({
    super.key,
    required this.name,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.cardRadius);
    final washColor = context.stateFill(
      BankAvatar.accentFor(name) ?? fallbackColorFor(name),
    );
    final brand = detectBrand(name);
    final asset = brand?.asset;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          // Capa 0: wash difuminado desde la izquierda.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [washColor, Colors.transparent],
                ),
              ),
            ),
          ),
          // Capa 1: watermark del logo CENTRADA en el espacio vacío (no sobre
          // el saldo de la derecha). Tenue y recortada por el ClipRRect.
          if (asset != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.08,
                    child: _Watermark(asset: asset),
                  ),
                ),
              ),
            ),
          // Capa 2: contenido con padding (migrado del AppCard).
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Logo tenue usado como marca de agua, CENTRADO en la tarjeta. SVG y PNG
/// ramifican por extensión; la altura fija mantiene un tamaño consistente entre
/// símbolos (cuadrados) y wordmarks (anchos), recortado por el ClipRRect.
class _Watermark extends StatelessWidget {
  final String asset;

  const _Watermark({required this.asset});

  @override
  Widget build(BuildContext context) {
    const double logoHeight = 46;
    final isSvg = asset.toLowerCase().endsWith('.svg');
    return SizedBox(
      height: logoHeight,
      child: isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
