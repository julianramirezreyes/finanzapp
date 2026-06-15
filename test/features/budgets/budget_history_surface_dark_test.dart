import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slice 6a-W1 [auto] — regresión de dark mode: la tarjeta-resumen de la
/// pantalla de historial de presupuesto NO debe quedar con fondo blanco
/// (`surfaceLight`) en dark, porque su texto hereda `onSurface` claro y quedaría
/// invisible. Tras el fix usa `context.surface`, que resuelve `surfaceDark`.
///
/// Esta es una pantalla REAL (no un repro): se monta BudgetHistoryScreen con el
/// único provider que observa (`budgetTransactionsProvider`) sobrescrito a lista
/// vacía, para evitar tiles y el gotcha de DateFormat('es_CO').
void main() {
  Budget budget() => Budget(
        id: 'goal-1',
        userId: 'user-1',
        category: 'Mercado',
        limitAmount: 100000,
        period: 'monthly',
        isRecurrent: true,
      );

  /// Monta la pantalla bajo el tema indicado y devuelve el color de superficie
  /// resuelto de la tarjeta-resumen (la del bug surfaceLight sin guard).
  Future<Color?> summaryColorUnder(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetTransactionsProvider(budget().id).overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: theme,
          home: BudgetHistoryScreen(budget: budget()),
        ),
      ),
    );
    // MaterialApp envuelve el theme en AnimatedTheme (200ms): sin settle el
    // brillo aún no se propaga. La lista resuelve vacía, sin tiles.
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('budget-history-summary-surface')),
    );
    final decoration = container.decoration as BoxDecoration;
    return decoration.color;
  }

  testWidgets(
    'tarjeta-resumen del historial: dark -> surfaceDark (no surfaceLight)',
    (tester) async {
      final color = await summaryColorUnder(tester, AppTheme.darkTheme);
      expect(color, AppColors.surfaceDark);
      expect(color, isNot(AppColors.surfaceLight));
    },
  );

  testWidgets(
    'tarjeta-resumen del historial: light -> surfaceLight (sin regresión)',
    (tester) async {
      final color = await summaryColorUnder(tester, AppTheme.lightTheme);
      expect(color, AppColors.surfaceLight);
    },
  );
}
