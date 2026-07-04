import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Getters NO-semánticos: NO fijan `color` a propósito. Heredan
  // `colorScheme.onSurface` del tema (oscuro en light, blanco en dark) vía
  // DefaultTextStyle. Fijar textPrimary aquí causaba TEXTO INVISIBLE en dark
  // mode (SDD #6, slice 6a). Solo income/expense (semánticos) y los 3
  // secundarios deliberados de abajo conservan color.

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600);

  static TextStyle get headlineLarge =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600);

  static TextStyle get headlineMedium =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get headlineSmall =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get titleLarge =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);

  /// Color secundario DELIBERADO (jerarquía de menor énfasis); NO heredar
  /// onSurface en este slice (SDD #6, 6a). textSecondary es válido en ambos
  /// brillos como texto de soporte.
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get labelLarge =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);

  /// Color secundario DELIBERADO (jerarquía de menor énfasis); NO heredar
  /// onSurface en este slice (SDD #6, 6a).
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Color secundario DELIBERADO (etiqueta de mínimo énfasis); NO heredar
  /// onSurface en este slice (SDD #6, 6a). textMuted es intencional.
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  /// Color secundario DELIBERADO (caption de mínimo énfasis, ej. chips de
  /// asignación de presupuesto); NO heredar onSurface en este slice (SDD #6,
  /// 6a). Usar `copyWith(color: ...)` para el tono de alerta (AppColors.expense).
  static TextStyle get captionSmall => GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get balance => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static TextStyle get balanceSmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get amount =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle get amountSmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get income => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.income,
  );

  static TextStyle get expense => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.expense,
  );
}
