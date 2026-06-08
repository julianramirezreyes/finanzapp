import 'package:finanzapp_v2/core/theme/theme_mode_provider.dart';
import 'package:finanzapp_v2/features/settings/presentation/widgets/theme_toggle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// El toggle de Configuración debe estar cableado al [themeModeProvider]: al
/// elegir "Oscuro" el provider pasa a dark, y al elegir "Claro" vuelve a light.
void main() {
  Future<ProviderContainer> pumpCard(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ThemeToggleCard()),
        ),
      ),
    );
    return container;
  }

  testWidgets('arranca mostrando claro y al tocar "Oscuro" pasa a dark', (
    tester,
  ) async {
    final container = await pumpCard(tester);
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('al tocar "Claro" vuelve a light', (tester) async {
    final container = await pumpCard(tester);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    await tester.pump();

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
