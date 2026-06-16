import 'package:finanzapp_v2/core/branding/bank_brands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'empty_state.dart';

/// Estado VACÍO de la bóveda con una marca de agua TENUE de la entidad detrás.
///
/// Cuando `accountName` detecta una marca CON asset (SVG/PNG), se pinta el logo
/// grande y MUY tenue (opacidad ~0.06) CENTRADO en el espacio vacío, detrás del
/// [EmptyState] "Bóveda vacía" — le da identidad sin competir con la
/// legibilidad del título ni del botón. Si la marca es desconocida o no tiene
/// asset, degrada: no muestra watermark y solo queda el [EmptyState].
///
/// Diseñado como widget EXTRAÍDO y testeable (no depende de providers): la
/// pantalla de bóveda lo usa solo en la rama del estado vacío.
class VaultEmptyState extends StatelessWidget {
  /// Nombre de la cuenta/banco — clave de detección de marca para el watermark.
  final String accountName;

  /// Acción del botón "Agregar Ítem".
  final VoidCallback onAddItem;

  const VaultEmptyState({
    super.key,
    required this.accountName,
    required this.onAddItem,
  });

  /// Opacidad del watermark de marca: MUY tenue para no competir con el texto.
  static const double _watermarkOpacity = 0.06;

  /// Altura del logo tenue (grande, pero contenido en el espacio vacío).
  static const double _watermarkHeight = 180;

  @override
  Widget build(BuildContext context) {
    final brand = detectBrand(accountName);
    final asset = brand?.asset;

    final emptyState = EmptyState(
      icon: Icons.lock_outline,
      title: 'Bóveda vacía',
      subtitle: 'Guarda información sensible de tus cuentas',
      actionLabel: 'Agregar Ítem',
      onAction: onAddItem,
    );

    // Sin marca/asset -> degrada: solo el EmptyState, sin watermark.
    if (asset == null) return emptyState;

    final isSvg = asset.toLowerCase().endsWith('.svg');

    return Stack(
      alignment: Alignment.center,
      children: [
        // (a) Watermark de marca CENTRADO y muy tenue, detrás del contenido.
        // IgnorePointer para no interceptar el tap del botón.
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: _watermarkOpacity,
                child: SizedBox(
                  height: _watermarkHeight,
                  child: isSvg
                      ? SvgPicture.asset(asset, fit: BoxFit.contain)
                      : Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
        // (b) EmptyState por encima — título + subtítulo + botón legibles.
        emptyState,
      ],
    );
  }
}
