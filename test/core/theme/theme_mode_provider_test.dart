import 'package:finanzapp_v2/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// El requisito del usuario: la app debe ARRANCAR SIEMPRE en modo claro.
/// El toggle permite cambiar a oscuro durante la sesión, pero la elección NO se
/// persiste — al reabrir la app vuelve a claro. Por eso el provider es un
/// `Notifier<ThemeMode>` en memoria, sin SharedPreferences.
void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('arranca SIEMPRE en claro (default = ThemeMode.light)', () {
    final container = makeContainer();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('setMode cambia el tema en la sesión actual', () {
    final container = makeContainer();

    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('toggle alterna entre claro y oscuro', () {
    final container = makeContainer();
    final notifier = container.read(themeModeProvider.notifier);

    notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('un nuevo arranque vuelve a claro: la elección NO se persiste', () {
    // Sesión 1: el usuario activa el modo oscuro.
    final session1 = ProviderContainer();
    session1.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(session1.read(themeModeProvider), ThemeMode.dark);
    session1.dispose();

    // Sesión 2 (la app se reabre): el tema debe volver a claro.
    final session2 = makeContainer();
    expect(
      session2.read(themeModeProvider),
      ThemeMode.light,
      reason: 'al reabrir la app el tema vuelve a claro porque no se persiste',
    );
  });
}
