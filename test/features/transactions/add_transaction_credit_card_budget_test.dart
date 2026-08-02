import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/transactions/presentation/add_transaction_screen.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Account _account() => Account(
  id: 'account-1',
  name: 'Cash',
  type: 'cash',
  balance: 100000,
  currency: 'COP',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  Transaction? transactionToEdit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsListProvider.overrideWith((ref) async => [_account()]),
        householdProvider.overrideWith((ref) async => null),
        budgetsListProvider(null).overrideWith(
          (ref) async => [
            Budget(
              id: 'goal-1',
              userId: 'user-1',
              category: 'Mercado',
              limitAmount: 100000,
              period: 'monthly',
            ),
          ],
        ),
        creditCardsWithDebtProvider.overrideWith(
          (ref) async => [
            {
              'id': 'card-1',
              'account_id': 'account-1',
              'title': 'Visa',
              'total_debt': 50000,
            },
          ],
        ),
      ],
      child: MaterialApp(
        home: AddTransactionScreen(transactionToEdit: transactionToEdit),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  testWidgets(
    'canonical card payment exposes General Expense, no goal selector, and an accessible double-counting callout',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpScreen(tester);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Gasto General'), findsOneWidget);
      expect(find.text('Esta selección no consume una meta.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Pago de tarjeta: las compras ya consumen sus metas'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'editing a card purchase restores its context-valid goal and installments',
    (tester) async {
      await _pumpScreen(
        tester,
        transactionToEdit: Transaction(
          id: 'transaction-1',
          accountId: 'account-1',
          amount: 50000,
          type: 'expense',
          category: 'Mercado',
          description: 'Compra',
          date: DateTime(2026, 8, 1),
          context: 'personal',
          budgetId: 'goal-1',
          userId: 'user-1',
          paidWithCreditCard: true,
          vaultCardId: 'card-1',
          installments: 3,
        ),
      );

      expect(find.text('Mercado'), findsOneWidget);
      final installments = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(installments.value, 3);
    },
  );
}
