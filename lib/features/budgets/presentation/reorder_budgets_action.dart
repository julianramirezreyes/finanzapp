import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';

/// A drag request expressed with a durable identity rather than a stale object.
class BudgetReorderIntent {
  const BudgetReorderIntent({
    required this.movedBudgetId,
    required this.destinationIndex,
  });

  final String movedBudgetId;
  final int destinationIndex;

  static BudgetReorderIntent? tryFromDrag({
    required List<Budget> budgets,
    required int oldIndex,
    required int newIndex,
  }) {
    if (budgets.length < 2 ||
        oldIndex < 0 ||
        oldIndex >= budgets.length ||
        newIndex < 0 ||
        newIndex > budgets.length) {
      return null;
    }
    return BudgetReorderIntent.fromDrag(
      budgets: budgets,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  factory BudgetReorderIntent.fromDrag({
    required List<Budget> budgets,
    required int oldIndex,
    required int newIndex,
  }) {
    final adjustedIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    return BudgetReorderIntent(
      movedBudgetId: budgets[oldIndex].id,
      destinationIndex: adjustedIndex,
    );
  }

  List<Budget>? applyTo(List<Budget> canonicalBudgets) {
    final reordered = List<Budget>.of(canonicalBudgets);
    final currentIndex = reordered.indexWhere(
      (budget) => budget.id == movedBudgetId,
    );
    if (currentIndex < 0 ||
        destinationIndex < 0 ||
        destinationIndex >= reordered.length) {
      return null;
    }
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(destinationIndex, moved);
    return List<Budget>.unmodifiable(reordered);
  }
}

class BudgetReorderResult {
  const BudgetReorderResult._({
    required this.budgets,
    required this.isSuccess,
    required this.isConflict,
  });

  const BudgetReorderResult.success(List<Budget> budgets)
    : this._(budgets: budgets, isSuccess: true, isConflict: false);

  const BudgetReorderResult.failure(
    List<Budget> budgets, {
    required bool isConflict,
  }) : this._(budgets: budgets, isSuccess: false, isConflict: isConflict);

  final List<Budget> budgets;
  final bool isSuccess;
  final bool isConflict;
}

typedef RefreshCanonicalBudgets = Future<List<Budget>> Function();

/// Persists one reorder attempt and performs a single, conflict-only recovery.
///
/// This executor deliberately has no widget, provider, or snackbar ownership.
/// Its caller owns attempt generation, rendering, and mounted checks.
Future<BudgetReorderResult> executeBudgetReorder({
  required BudgetRepository repository,
  required List<Budget> budgets,
  required BudgetReorderIntent intent,
  required RefreshCanonicalBudgets refreshCanonical,
}) async {
  final initial = List<Budget>.unmodifiable(budgets);
  final optimistic = intent.applyTo(initial);
  if (optimistic == null) {
    return BudgetReorderResult.failure(initial, isConflict: false);
  }

  try {
    await repository.reorderBudgets(optimistic);
    return BudgetReorderResult.success(
      List<Budget>.unmodifiable(await refreshCanonical()),
    );
  } on BudgetRepositoryFailure catch (failure) {
    if (!failure.isConflict) {
      return BudgetReorderResult.failure(initial, isConflict: false);
    }

    late List<Budget> refreshed;
    try {
      refreshed = List<Budget>.unmodifiable(await refreshCanonical());
    } catch (_) {
      return BudgetReorderResult.failure(initial, isConflict: true);
    }
    final retry = intent.applyTo(refreshed);
    if (retry == null) {
      return BudgetReorderResult.failure(refreshed, isConflict: true);
    }

    try {
      await repository.reorderBudgets(retry);
      return BudgetReorderResult.success(
        List<Budget>.unmodifiable(await refreshCanonical()),
      );
    } on BudgetRepositoryFailure {
      return BudgetReorderResult.failure(refreshed, isConflict: true);
    } catch (_) {
      return BudgetReorderResult.failure(refreshed, isConflict: true);
    }
  } catch (_) {
    return BudgetReorderResult.failure(initial, isConflict: false);
  }
}
