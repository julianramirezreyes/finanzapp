import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal ProviderScope-based fixtures + pump helpers for
/// `PersonalBudgetTab` / `HouseholdBudgetTab` tests.
///
/// Lives at the TOP-LEVEL `test/support/`, mirroring the repo's established
/// shared-test-infra convention (`fake_dio_adapter.dart`) rather than a
/// feature-scoped `test/features/budgets/support/`.
///
/// **Household-provider note (MANDATORY):** `PersonalBudgetTab.build()`
/// unconditionally renders `_buildPersonalAvailableBanner` whenever
/// `householdProvider` resolves non-null AND `userProvider` is non-null;
/// that banner watches a SECOND `budgetConfigProvider` family instance
/// (type `'household'`) and a SECOND `budgetsListProvider(household.id)`
/// instance, both unrelated to a Personal-scope assertion. [pumpPersonalBudgetTab]
/// defaults `household` to `null`, suppressing that banner path. Pass a
/// non-null `household` ONLY when a cross-tab/banner case is intentionally
/// exercised — the second family instances are then stubbed automatically
/// via `householdBudgetOverrides`.

/// A minimal, deterministic Supabase [User] fixture — `id` is the only field
/// the budgets feature consumes (household income-share lookup).
User fakeUser({String id = 'user-a'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime(2024, 1, 1).toIso8601String(),
  );
}

/// A minimal [Household] fixture.
Household fakeHousehold({
  String id = 'house-1',
  String userAId = 'user-a',
  String? userBId = 'user-b',
}) {
  return Household(
    id: id,
    userAId: userAId,
    userBId: userBId,
    userAEmail: 'a@test.local',
    userBEmail: userBId == null ? null : 'b@test.local',
    status: 'active',
    createdAt: DateTime(2024, 1, 1),
  );
}

/// A minimal Personal [BudgetConfig] fixture.
BudgetConfig fakePersonalConfig({
  String id = 'cfg-personal',
  double personalIncome = 1000000,
  int pctExpense = 50,
  int pctSavings = 30,
  int pctInvestment = 20,
}) {
  return BudgetConfig(
    id: id,
    userId: 'user-a',
    personalIncome: personalIncome,
    pctExpense: pctExpense,
    pctSavings: pctSavings,
    pctInvestment: pctInvestment,
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// A minimal Household [BudgetConfig] fixture.
BudgetConfig fakeHouseholdConfig({
  String id = 'cfg-household',
  String householdId = 'house-1',
  double incomeA = 1000000,
  double incomeB = 1000000,
  int pctExpense = 50,
  int pctSavings = 30,
  int pctInvestment = 20,
}) {
  return BudgetConfig(
    id: id,
    householdId: householdId,
    incomeA: incomeA,
    incomeB: incomeB,
    pctExpense: pctExpense,
    pctSavings: pctSavings,
    pctInvestment: pctInvestment,
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Builds a fixture [Budget] meta for allocation/consumption tests.
Budget fakeBudgetMeta({
  required String id,
  required String type,
  double monthlyQuota = 0,
  double currentAmount = 0,
  bool isRecurrent = true,
  int months = 1,
}) {
  return Budget(
    id: id,
    userId: 'user-a',
    category: 'cat-$type-$id',
    limitAmount: monthlyQuota,
    period: 'monthly',
    type: type,
    currentAmount: currentAmount,
    monthlyQuota: monthlyQuota,
    isRecurrent: isRecurrent,
    months: months,
  );
}

/// Overrides for the Personal scope's OWN `budgetConfigProvider`/
/// `budgetsListProvider(null)` family instances.
List<Override> personalBudgetOverrides({
  required BudgetConfig config,
  required List<Budget> budgets,
}) {
  return [
    budgetConfigProvider((
      type: 'personal',
      householdId: null,
    )).overrideWith((ref) async => config),
    budgetsListProvider(null).overrideWith((ref) async => budgets),
  ];
}

/// Overrides for a Hogar scope's OWN `budgetConfigProvider`/
/// `budgetsListProvider(householdId)` family instances.
List<Override> householdBudgetOverrides({
  required Household household,
  required BudgetConfig config,
  required List<Budget> budgets,
}) {
  return [
    budgetConfigProvider((
      type: 'household',
      householdId: household.id,
    )).overrideWith((ref) async => config),
    budgetsListProvider(household.id).overrideWith((ref) async => budgets),
  ];
}

/// Pumps [child] inside a [ProviderScope] with [overrides], under a bare
/// [MaterialApp] + [Scaffold]. Shared by every tab test, the call-site test,
/// and the cross-contamination test.
Future<void> pumpBudgetsScope(
  WidgetTester tester, {
  required Widget child,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps [PersonalBudgetTab] with [config]/[budgets] deterministically
/// overridden. Defaults `household` to `null` — see the harness note above.
Future<void> pumpPersonalBudgetTab(
  WidgetTester tester, {
  required BudgetConfig config,
  required List<Budget> budgets,
  Household? household,
  BudgetConfig? householdConfig,
  List<Budget> householdBudgets = const [],
  User? user,
}) async {
  final overrides = <Override>[
    userProvider.overrideWithValue(user ?? fakeUser()),
    householdProvider.overrideWith((ref) async => household),
    ...personalBudgetOverrides(config: config, budgets: budgets),
  ];
  if (household != null) {
    overrides.addAll(
      householdBudgetOverrides(
        household: household,
        config:
            householdConfig ?? fakeHouseholdConfig(householdId: household.id),
        budgets: householdBudgets,
      ),
    );
  }
  await pumpBudgetsScope(
    tester,
    child: const PersonalBudgetTab(),
    overrides: overrides,
  );
}

/// Pumps [HouseholdBudgetTab] with [household]/[config]/[budgets]
/// deterministically overridden.
Future<void> pumpHouseholdBudgetTab(
  WidgetTester tester, {
  required Household household,
  required BudgetConfig config,
  required List<Budget> budgets,
  User? user,
}) async {
  await pumpBudgetsScope(
    tester,
    child: const HouseholdBudgetTab(),
    overrides: [
      userProvider.overrideWithValue(user ?? fakeUser(id: household.userAId)),
      householdProvider.overrideWith((ref) async => household),
      ...householdBudgetOverrides(
        household: household,
        config: config,
        budgets: budgets,
      ),
    ],
  );
}
