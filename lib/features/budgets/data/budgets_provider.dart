import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetsListProvider = FutureProvider.family<List<Budget>, String?>((
  ref,
  householdId,
) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgets(householdId: householdId);
});
