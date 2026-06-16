import 'package:finanzapp_v2/core/branding/bank_brand.dart';
import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// HERO HEADER de marca para la pantalla de bóveda — patrón "header como
/// tarjeta": una banda de color (gradiente de marca) con esquinas inferiores
/// redondeadas que ancla la pantalla con la identidad del banco.
///
/// Reusa el MISMO sistema de branding que el resto de la app:
///  - `detectBrand(name)` para el gradiente y el logo oficial,
///  - `fallbackColorFor(name)` + `monogramFor(name)` cuando la marca es
///    desconocida o no tiene asset.
///
/// Texto onBrand ADAPTATIVO por luminancia: sobre un color base CLARO (amarillo
/// Bancolombia) el texto es OSCURO (`AppColors.textPrimary`); sobre un color
/// base OSCURO (morado Nubank) el texto es BLANCO. Se aplica al back arrow,
/// nombre, subtítulo y total para garantizar contraste en cualquier marca.
///
/// Estructura (`ClipRRect` con esquinas inferiores redondeadas):
///  (a) GRADIENTE de fondo (marca o fallback) en un `Container`.
///  (b) WATERMARK: el logo grande y tenue a la DERECHA, recortado por el clip,
///      sin interceptar gestos. Más visible que en el body (~0.14) porque va
///      sobre color, no sobre superficie neutra.
///  (c) CONTENIDO en `SafeArea`: fila con back arrow + bloque logo-chip /
///      nombre / subtítulo / total.
class BrandedVaultHeader extends StatelessWidget {
  /// Nombre de la cuenta/banco (también la clave de detección de marca).
  final String name;

  /// Línea de soporte bajo el nombre (ej. 'Bóveda · Ahorros').
  final String? subtitle;

  /// Total formateado a mostrar en grande (ej. r'$ 2.217.827'). Opcional.
  final String? total;

  /// Callback del back arrow. Si es null, no se muestra el arrow.
  final VoidCallback? onBack;

  const BrandedVaultHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.total,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final brand = detectBrand(name);

    // Color base para decidir el gradiente y la luminancia del texto onBrand.
    final base = brand?.primary ?? fallbackColorFor(name);
    final gradient = brand?.gradient ?? _fallbackGradient(base);

    // Texto adaptativo: oscuro sobre base clara, blanco sobre base oscura.
    final onBrand = base.computeLuminance() > 0.5
        ? AppColors.textPrimary
        : Colors.white;

    // Esquinas inferiores redondeadas para el look de "tarjeta".
    final radius = BorderRadius.vertical(
      bottom: Radius.circular(AppSpacing.cardRadius * 1.2),
    );

    final asset = brand?.asset;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // (b) WATERMARK del logo, tenue, a la derecha. Recortado por el
            // ClipRRect del header. Degrada sin watermark si no hay asset.
            if (asset != null)
              Positioned(
                top: -8,
                right: -16,
                bottom: -8,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.14,
                    child: _Watermark(asset: asset),
                  ),
                ),
              ),
            // (c) CONTENIDO.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fila superior: back arrow a la izquierda.
                    if (onBack != null)
                      SizedBox(
                        height: AppSpacing.touchTarget,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: onBack,
                            color: onBrand,
                            icon: const Icon(Icons.arrow_back_ios_new),
                            iconSize: AppSpacing.iconSizeMedium - 4,
                            tooltip: 'Volver',
                          ),
                        ),
                      ),
                    // Logo limpio en chip + nombre grande.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LogoChip(name: name, brand: brand),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onBrand,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: onBrand.withValues(alpha: 0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (total != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        total!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onBrand,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gradiente derivado de un color base (marca desconocida): mismo patrón que
  /// `BankBrand.gradient` — del color pleno a una versión más oscura.
  LinearGradient _fallbackGradient(Color base) {
    final hsl = HSLColor.fromColor(base);
    final darker =
        hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, darker],
    );
  }
}

/// Chip redondeado con el logo oficial limpio. El color de fondo es ADAPTATIVO
/// a la luminancia del logo (misma clasificación compartida que `BankAvatar`):
/// logos oscuros -> chip claro; logos CLAROS (trii, payu, dolarapp, arq) ->
/// chip OSCURO, porque sobre el chip claro DESAPARECÍAN (ej. el verde brillante
/// de Trii). El resto cae al chip claro por defecto. Si la marca no tiene asset
/// (o es desconocida) cae a un monograma sobre chip claro.
class _LogoChip extends StatelessWidget {
  final String name;
  final BankBrand? brand;

  const _LogoChip({required this.name, required this.brand});

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.buttonRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Color de chip adaptativo: para logos claros (trii, payu, dolarapp, arq)
    // un chip oscuro; para logos oscuros un chip claro; default chip claro para
    // que cualquier otro logo se lea sobre el gradiente de color del header.
    final chipColor =
        BankAvatar.chipBackgroundColorFor(brand?.id, isDark: isDark) ??
            BankAvatar.darkLogoChipColor;
    final asset = brand?.asset;

    Widget content;
    if (asset != null) {
      final isSvg = asset.toLowerCase().endsWith('.svg');
      content = isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain);
    } else {
      content = Text(
        monogramFor(name),
        style: TextStyle(
          color: brand?.accent ?? fallbackColorFor(name),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      );
    }

    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: chipColor, borderRadius: radius),
      alignment: Alignment.center,
      child: content,
    );
  }
}

/// Logo grande y tenue usado como marca de agua del header. SVG/PNG ramifican
/// por extensión; la altura fija mantiene un tamaño consistente entre símbolos
/// y wordmarks.
class _Watermark extends StatelessWidget {
  final String asset;

  const _Watermark({required this.asset});

  @override
  Widget build(BuildContext context) {
    const double logoHeight = 150;
    final isSvg = asset.toLowerCase().endsWith('.svg');
    return SizedBox(
      height: logoHeight,
      child: isSvg
          ? SvgPicture.asset(asset, fit: BoxFit.contain)
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
