import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the "Eliminar Meta" confirmation dialog and, if the user confirms,
/// deletes the budget and invalidates [invalidateTarget] so the corresponding
/// list (Personal -> `budgetsListProvider(null)`, Hogar ->
/// `budgetsListProvider(householdId)`) refreshes.
///
/// This is a top-level function (not a [State] method), so it guards with
/// `context.mounted` instead of `State.mounted`.
Future<void> confirmDeleteBudget(
  BuildContext context,
  WidgetRef ref,
  Budget budget, {
  required ProviderOrFamily invalidateTarget,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar Meta'),
      content: Text(
        '¿Estás seguro de eliminar la meta "${budget.category}"?\n\n'
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await ref.read(budgetRepositoryProvider).deleteBudget(budget.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meta eliminada')));
      ref.invalidate(invalidateTarget);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
