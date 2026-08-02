import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef BudgetOrderChanged = void Function(List<Budget> budgets);

/// Applies a personal-goal reorder without mutating Riverpod's server snapshot.
///
/// The callbacks let the screen render the optimistic order immediately and put
/// the immutable pre-drag snapshot back when the server rejects the batch.
Future<void> reorderBudgetsAction({
  required WidgetRef ref,
  required BuildContext context,
  required List<Budget> budgets,
  required int oldIndex,
  required int newIndex,
  required BudgetOrderChanged onOptimisticOrder,
  required BudgetOrderChanged onRollback,
}) async {
  final snapshot = List<Budget>.unmodifiable(budgets);
  final reordered = List<Budget>.of(snapshot);
  final adjustedIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(adjustedIndex, moved);

  onOptimisticOrder(List<Budget>.unmodifiable(reordered));

  try {
    await ref.read(budgetRepositoryProvider).reorderBudgets(reordered);
    ref.invalidate(budgetsListProvider(null));
  } catch (_) {
    onRollback(snapshot);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al reordenar las metas')),
    );
  }
}
