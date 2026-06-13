import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';

/// Read-only history of the records linked to a single budget/goal.
/// Opened when the user taps a budget card in the planning screen.
class BudgetHistoryScreen extends ConsumerWidget {
  final Budget budget;

  const BudgetHistoryScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(budgetTransactionsProvider(budget.id));
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    double total = budget.monthlyQuota;
    if (budget.type != 'expense' &&
        !budget.isRecurrent &&
        (budget.targetAmount ?? 0) > 0) {
      total = budget.targetAmount!;
    }

    final typeLabel = budget.isRecurrent
        ? 'Fijo Mensual'
        : 'Meta (${budget.months} meses)';
    final amountLabel = budget.isRecurrent
        ? 'Gastado este mes'
        : 'Acumulado';

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.category),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(typeLabel, style: AppTypography.labelSmall),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amountLabel, style: AppTypography.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${currency.format(budget.currentAmount)} / ${currency.format(total)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: txAsync.when(
              data: (txs) {
                if (txs.isEmpty) {
                  return _EmptyHistory();
                }
                final sorted = [...txs]
                  ..sort((a, b) => b.date.compareTo(a.date));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final t = sorted[i];
                    return TransactionTile(
                      description: t.description,
                      category: t.category,
                      amount: t.amount,
                      type: t.type,
                      date: t.date,
                      contextLabel: t.paidWithCreditCard ? 'Tarjeta' : null,
                      onTap: () async {
                        await context.push('/transactions/add', extra: t);
                        ref.invalidate(budgetTransactionsProvider(budget.id));
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No se pudo cargar el historial.\n$e',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aún no hay registros en esta meta',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
