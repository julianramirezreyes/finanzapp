import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Avatar de identidad de marca para la lista de cuentas (SDD #8, Fase 2).
///
/// - Marca conocida CON asset -> chip neutro con el LOGO oficial (SvgPicture
///   para .svg, Image para .png) en `BoxFit.contain` con padding interno. Los
///   logos OSCUROS ([_darkLogos]: bancolombia, nequi, pibank, paypal) usan un
///   chip CLARO garantizado (casi blanco) en ambos temas para no perderse sobre
///   un chip oscuro; el resto usa el chip neutro dark-safe (`subtleFill`).
/// - Marca conocida SIN asset -> contenedor con el gradiente de marca y el
///   monograma en BLANCO (comportamiento de Fase 1, conservado para regresión).
/// - Marca desconocida -> contenedor con el color estable por hash a baja
///   opacidad y el monograma en ese mismo color (legible en ambos brillos).
/// - Nombre vacío -> icono por `type` (preserva el comportamiento previo del
///   leading como fallback final).
class BankAvatar extends StatelessWidget {
  final String name;
  final String type;
  final double size;

  const BankAvatar({
    super.key,
    required this.name,
    required this.type,
    this.size = 44,
  });

  /// Ids cuyo logo es OSCURO sobre transparente: sobre un chip oscuro se
  /// perderían. Se les fuerza un chip claro en ambos temas. (Decisión del
  /// GAP `logoIsDark`: lista const aquí, sin tocar el value object BankBrand.)
  static const Set<String> _darkLogos = {
    'bancolombia',
    'nequi',
    'pibank',
    'paypal',
  };

  IconData _typeIcon() {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'checking':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = detectBrand(name);
    final radius = BorderRadius.circular(AppSpacing.buttonRadius);

    if (brand != null && brand.asset != null) {
      return _LogoChip(
        asset: brand.asset!,
        isDarkLogo: _darkLogos.contains(brand.id),
        size: size,
        radius: radius,
      );
    }

    if (brand != null) {
      // Marca conocida sin asset: monograma blanco sobre el gradiente de marca.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: brand.gradient,
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Text(
          monogramFor(brand.displayName),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );
    }

    // Desconocida: color estable por hash. La baja opacidad del fondo funciona
    // sobre superficies claras y oscuras; el monograma usa el color pleno.
    final c = fallbackColorFor(name);
    final isEmpty = name.trim().isEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? Icon(_typeIcon(), color: c, size: AppSpacing.iconSizeMedium)
          : Text(
              monogramFor(name),
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
    );
  }

  /// Acento de marca para detalles sutiles del tile (barra/borde). Devuelve el
  /// `primary` de la marca detectada, o null si es desconocida.
  static Color? accentFor(String name) => detectBrand(name)?.primary;
}

/// Chip neutro que pinta el logo oficial de una marca con padding interno.
class _LogoChip extends StatelessWidget {
  final String asset;
  final bool isDarkLogo;
  final double size;
  final BorderRadius radius;

  const _LogoChip({
    required this.asset,
    required this.isDarkLogo,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    // Logos oscuros -> chip claro garantizado en ambos temas (casi blanco) para
    // que el logo nunca se pierda. Resto -> chip neutro dark-safe.
    final chipColor = isDarkLogo
        ? const Color(0xFFF5F5F7)
        : context.subtleFill();

    final isSvg = asset.toLowerCase().endsWith('.svg');

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: chipColor, borderRadius: radius),
      alignment: Alignment.center,
      child: isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
