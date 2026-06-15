import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Avatar de identidad de marca para la lista de cuentas (SDD #8).
///
/// - Marca conocida -> contenedor redondeado con el gradiente de marca y el
///   monograma en BLANCO. El blanco sobre el gradiente garantiza contraste en
///   light y dark, incluso para marcas casi-negras (Nubank, Trii, DolarApp);
///   por eso NO se usa ningún color claro hardcodeado que se pierda en oscuro.
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

    if (brand != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: brand.gradient, borderRadius: radius),
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
