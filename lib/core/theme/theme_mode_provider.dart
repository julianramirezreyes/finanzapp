import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controla el [ThemeMode] de la app.
///
/// Por decisión de producto, la app ARRANCA SIEMPRE en modo claro: el estado
/// nace en [ThemeMode.light] y la elección del usuario NO se persiste. El toggle
/// de Configuración cambia el tema durante la sesión actual; al cerrar y reabrir
/// la app, el provider se reconstruye desde cero y vuelve a claro.
///
/// Por eso es un [Notifier] en memoria (sin SharedPreferences). Si en el futuro
/// se quisiera recordar la elección entre reinicios, este es el único punto a
/// cambiar (leer/escribir SharedPreferences siguiendo el patrón de
/// `backend_config_provider.dart`).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  /// Fija el tema explícitamente (lo usa el selector de Configuración).
  void setMode(ThemeMode mode) => state = mode;

  /// Alterna entre claro y oscuro.
  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
