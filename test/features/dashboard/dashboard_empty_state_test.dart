import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6c.2 [auto] — el empty state de cuentas del dashboard usa el
/// componente [EmptyState] del design system (con tokens de spacing), NO un
/// `Card` artesanal a mano.
///
/// Se extrajo a [DashboardAccountsEmptyState] (Extract-Before-Mock): el bloque
/// vivía inline dentro de `_buildAccountsSection`, condicionado a
/// `data.accounts.isEmpty` y dependiente de providers. El widget extraído es
/// puro y se testea en aislamiento.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: DashboardAccountsEmptyState()),
      ),
    );
  }

  testWidgets('usa EmptyState del design system, no Card artesanal', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('muestra el mensaje de "sin cuentas"', (tester) async {
    await pump(tester);

    expect(find.text('Aún no tienes cuentas'), findsOneWidget);
    expect(find.text('Agrega una cuenta para comenzar'), findsOneWidget);
  });
}
