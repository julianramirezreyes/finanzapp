import 'package:flutter/material.dart';

/// Cómo se compara un alias de marca contra el nombre normalizado de la cuenta.
///
/// - [exact]: el nombre normalizado es idéntico al alias (ej. 'nu' SOLO si la
///   cuenta se llama exactamente "nu", nunca dentro de "menu").
/// - [word]: el alias aparece como palabra completa `(^|\s)alias(\s|$)`
///   (ej. 'paypal' matchea "paypal personal" pero NO "mipaypalito"). Default.
/// - [contains]: substring libre. Solo para marcas largas e inequívocas
///   (ej. 'mercadopago', 'davivienda').
enum MatchKind { exact, word, contains }

/// Una regla de detección para una marca. El [alias] ya viene normalizado
/// (minúsculas, sin acentos, separadores colapsados a un espacio).
class BrandMatcher {
  final String alias;
  final MatchKind kind;

  const BrandMatcher(this.alias, [this.kind = MatchKind.word]);
}

/// Value object inmutable que describe la identidad visual de una entidad
/// financiera. Agregar un banco = una línea de datos en `kBankBrands`, sin
/// tocar lógica.
class BankBrand {
  /// Identificador estable y único (ej. 'nequi'). NO es el displayName.
  final String id;

  /// Nombre presentable de la marca (ej. 'Nequi', 'DaviPlata').
  final String displayName;

  /// Color principal de la marca.
  final Color primary;

  /// Segundo stop del gradiente. Si es null se deriva oscureciendo [primary].
  final Color? secondary;

  /// Color seguro para texto/icono sobre una superficie clara (separado de
  /// [primary] para marcas cuyo color principal no contrasta, ej. amarillo
  /// Bancolombia).
  final Color accent;

  /// Path a un asset (SVG/PNG) de logo oficial. Fase 1 = null (monograma-first,
  /// cero assets binarios, cero riesgo de trademark).
  final String? asset;

  /// Reglas de detección, evaluadas en orden.
  final List<BrandMatcher> matchers;

  const BankBrand({
    required this.id,
    required this.displayName,
    required this.primary,
    this.secondary,
    required this.accent,
    this.asset,
    required this.matchers,
  });

  /// Gradiente de marca para el avatar (topLeft -> bottomRight). Si no hay
  /// [secondary], oscurece [primary] para mantener un degradado legible.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary ?? _darken(primary, 0.14)],
      );

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
