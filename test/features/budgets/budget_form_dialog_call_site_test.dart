import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budgets_tab_harness.dart';
import '../../support/fake_dio_adapter.dart';

/// Call-site tests for `_showGoalDialog`'s own snapshot-building logic on
/// BOTH tabs (design ADR-3): the explicit budgets-snapshot read
/// (`ref.read(budgetsListProvider(...))`), self-exclusion of the edited
/// meta's own quota (spec R11.1), and the loading/error -> no-preview
/// fallback, which must never block dialog open (spec R12.3/R13, ADR-3).
///
/// Distinct from `budget_form_dialog_test.dart`'s "Allocation preview"
/// group, which tests the DIALOG'S OWN rendering given an already-built
/// snapshot — these tests exercise the CALL SITE that builds that snapshot,
/// by pumping the ACTUAL tab widgets and triggering their real edit/create
/// actions.
void main() {
  /// Taps the ⋮ menu on the [BudgetCard] whose category text is [category]
  /// and selects "Editar", opening `_showGoalDialog` in EDIT mode for that
  /// meta — exercising the tab's real edit action end-to-end.
  Future<void> editBudget(WidgetTester tester, String category) async {
    final card = find.ancestor(
      of: find.text(category),
      matching: find.byType(BudgetCard),
    );
    final menuIcon = find.descendant(
      of: card,
      matching: find.byIcon(Icons.more_vert),
    );
    // The card may render below the fold inside the tab's
    // SingleChildScrollView -> scroll it into view before tapping.
    await tester.ensureVisible(menuIcon);
    await tester.pumpAndSettle();
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Personal — editing a meta excludes its own quota from the preview base '
    'sum (R11.1/R7.2)',
    (tester) async {
      // Personal income 1,000,000, pctExpense 50 (harness default) -> expense
      // cap = 500,000.
      final metaEdit = fakeBudgetMeta(
        id: 'p-edit-1',
        type: 'expense',
        monthlyQuota: 200000,
      ).copyWith(category: 'Renta Edit');
      final metaOther = fakeBudgetMeta(
        id: 'p-other-1',
        type: 'expense',
        monthlyQuota: 100000,
      ).copyWith(category: 'Otro Gasto');

      await pumpPersonalBudgetTab(
        tester,
        config: fakePersonalConfig(personalIncome: 1000000),
        budgets: [metaEdit, metaOther],
      );

      await editBudget(tester, 'Renta Edit');

      // Self-exclusion holds: other(expense) = 100,000 (metaOther only) +
      // the preloaded quota 200,000 = 300,000 / 500,000 = 60%. A bug that
      // fails to exclude the edited meta's own quota would instead read
      // other = 300,000 (both metas) + 200,000 = 500,000 -> 100%, a visibly
      // different figure.
      expect(find.textContaining('60% del plan de Gasto'), findsOneWidget);
      expect(find.textContaining('100% del plan de Gasto'), findsNothing);
    },
  );

  testWidgets('Personal — loading budgetsListProvider(null) opens the dialog '
      'immediately with no preview, save still works (ADR-3 fallback)', (
    tester,
  ) async {
    final adapter = FakeDioAdapter(statusCode: 201, responseJson: const {});
    final repo = BudgetRepository(buildFakeDio(adapter));

    await pumpBudgetsScope(
      tester,
      child: const PersonalBudgetTab(),
      overrides: [
        userProvider.overrideWithValue(fakeUser()),
        householdProvider.overrideWith((ref) async => null),
        budgetConfigProvider((
          type: 'personal',
          householdId: null,
        )).overrideWith(
          (ref) async => fakePersonalConfig(personalIncome: 1000000),
        ),
        // Errors -> budgetsListProvider(null).valueOrNull stays null, exercising
        // the loading/error fallback (ADR-3). An error (rather than a
        // perpetually-loading future) keeps both tabs' `error:` branches
        // static (no CircularProgressIndicator animation), so
        // pumpAndSettle() still settles.
        budgetsListProvider(
          null,
        ).overrideWith((ref) async => throw Exception('boom')),
        budgetRepositoryProvider.overrideWithValue(repo),
      ],
    );

    // "Agregar" may render below the fold inside the tab's
    // SingleChildScrollView -> scroll it into view before tapping.
    await tester.ensureVisible(find.text('Agregar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
    expect(find.textContaining('% del plan de'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Meta sin preview',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Monto mensual'),
      '50000',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Save proceeds ungated: the dialog closes and the request reaches
    // the repository exactly as it would with a resolved preview.
    expect(find.widgetWithText(TextField, 'Nombre'), findsNothing);
    expect(adapter.requests, hasLength(1));
  });

  testWidgets(
    'Household — editing a meta excludes its own quota from the preview '
    'base sum, full-household cap basis (R11.1/R6.2)',
    (tester) async {
      final household = fakeHousehold();
      // incomeA + incomeB = 700,000 + 300,000 = 1,000,000 (full household
      // basis, NOT a per-member split) -> expense cap = 500,000.
      final config = fakeHouseholdConfig(
        householdId: household.id,
        incomeA: 700000,
        incomeB: 300000,
      );
      final metaEdit = fakeBudgetMeta(
        id: 'h-edit-1',
        type: 'expense',
        monthlyQuota: 200000,
      ).copyWith(category: 'Renta Hogar');
      final metaOther = fakeBudgetMeta(
        id: 'h-other-1',
        type: 'expense',
        monthlyQuota: 100000,
      ).copyWith(category: 'Otro Gasto Hogar');

      await pumpHouseholdBudgetTab(
        tester,
        household: household,
        config: config,
        budgets: [metaEdit, metaOther],
      );

      await editBudget(tester, 'Renta Hogar');

      expect(find.textContaining('60% del plan de Gasto'), findsOneWidget);
      expect(find.textContaining('100% del plan de Gasto'), findsNothing);
    },
  );

  testWidgets(
    'Household — loading budgetsListProvider(householdId) opens the dialog '
    'immediately with no preview, save still works (ADR-3 fallback)',
    (tester) async {
      final household = fakeHousehold();
      final adapter = FakeDioAdapter(statusCode: 201, responseJson: const {});
      final repo = BudgetRepository(buildFakeDio(adapter));

      await pumpBudgetsScope(
        tester,
        child: const HouseholdBudgetTab(),
        overrides: [
          userProvider.overrideWithValue(fakeUser(id: household.userAId)),
          householdProvider.overrideWith((ref) async => household),
          budgetConfigProvider((
            type: 'household',
            householdId: household.id,
          )).overrideWith(
            (ref) async => fakeHouseholdConfig(householdId: household.id),
          ),
          budgetsListProvider(
            household.id,
          ).overrideWith((ref) async => throw Exception('boom')),
          budgetRepositoryProvider.overrideWithValue(repo),
        ],
      );

      // "Agregar" may render below the fold inside the tab's
      // SingleChildScrollView -> scroll it into view before tapping.
      await tester.ensureVisible(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
      expect(find.textContaining('% del plan de'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre'),
        'Meta hogar sin preview',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Monto mensual'),
        '50000',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Nombre'), findsNothing);
      expect(adapter.requests, hasLength(1));
    },
  );
}
