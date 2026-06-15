import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primarySurface = Color(0xFFECFDF5);

  static const Color income = Color(0xFF10B981);
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color savings = Color(0xFF8B5CF6);
  static const Color savingsLight = Color(0xFFEDE9FE);
  static const Color investment = Color(0xFF3B82F6);
  static const Color investmentLight = Color(0xFFDBEAFE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF6366F1);
  static const Color infoLight = Color(0xFFE0E7FF);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0xFF334155);

  static const Color cardShadow = Color(0x0A000000);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient balanceNegativeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );
}

/// Helpers semánticos brightness-aware (SDD #6, slice 6a).
///
/// Resuelven el token correcto según el brillo del tema activo, replicando el
/// patrón `isDark ? dark : light` que ya usa AppCard. Reemplazan los literales
/// claros hardcodeados (surfaceLight/backgroundLight/pasteles) que causaban
/// fondos chillones y texto invisible en dark mode.
///
/// En DARK, los rellenos de estado (`stateFill`) usan el color base a baja
/// opacidad en lugar del pastel claro; en LIGHT mantienen el pastel suave
/// (base a baja opacidad), conservando la estética original.
extension AppColorsX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Superficie de tarjeta/contenedor según el brillo.
  Color get surface =>
      _isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  /// Borde sutil según el brillo.
  Color get border => _isDark ? AppColors.borderDark : AppColors.borderLight;

  /// Color de texto/icono principal sobre la superficie, legible en ambos
  /// brillos. Resuelve `colorScheme.onSurface` del tema.
  Color get onSurface => Theme.of(this).colorScheme.onSurface;

  /// Relleno tenue de fondo (zonas de respiro / chips neutros). En light usa el
  /// fondo claro de la app; en dark un gris elevado, NUNCA un pastel claro.
  Color subtleFill() => _isDark
      ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
      : AppColors.backgroundLight;

  /// Relleno de estado de color (income/expense/info/savings/...). En light es
  /// el color base a baja opacidad (pastel suave); en dark el mismo color base
  /// a una opacidad aún menor, evitando el parche claro chillón.
  Color stateFill(Color base) =>
      base.withValues(alpha: _isDark ? 0.18 : 0.12);
}
