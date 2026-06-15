import 'package:flutter/material.dart';

/// Paleta curada que armoniza con AppColors (NO HSL aleatorio, que genera
/// colores feos/ilegibles). 9 colores -> índice estable por hash del nombre.
const List<Color> kFallbackPalette = [
  Color(0xFF6366F1), // indigo
  Color(0xFF8B5CF6), // violet
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFFEF4444), // red
  Color(0xFF14B8A6), // teal
  Color(0xFFEC4899), // pink
  Color(0xFF0EA5E9), // sky
];

/// Color estable para una entidad desconocida: mismo nombre -> mismo color
/// SIEMPRE (escenario 8.4). Insensible a mayúsculas/espacios mediante
/// `trim().toLowerCase()`.
Color fallbackColorFor(String name) {
  final h = name.trim().toLowerCase().hashCode;
  return kFallbackPalette[h.abs() % kFallbackPalette.length];
}

/// Monograma de 1-2 letras para el avatar de fallback:
/// - 2+ palabras -> iniciales de las dos primeras (ej. 'Mi Nequi' -> 'MN').
/// - 1 palabra -> sus 2 primeras letras (ej. 'Bancolombia' -> 'BA').
/// - 1 letra -> esa letra.
/// - vacío -> '?'.
String monogramFor(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return t.substring(0, t.length >= 2 ? 2 : 1).toUpperCase();
}
