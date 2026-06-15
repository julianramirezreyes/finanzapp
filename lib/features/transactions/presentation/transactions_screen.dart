import 'package:finanzapp_v2/core/invalidation/data_invalidator.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/balance_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/summary_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_skeleton.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:finanzapp_v2/shared/ui/dialogs/confirm_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      personalHistoryProvider((
        month: _selectedDate.month,
        year: _selectedDate.year,
      )),
    );
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (summary) {
          final currency = NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 0,
            locale: 'es_CO',
          );

          final accounts = accountsAsync.valueOrNull ?? const [];
          final accountsById = {for (final a in accounts) a.id: a};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideTransition(child: _buildMonthHeader(context)),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideTransition(
                  index: 1,
                  child: SummaryRow(
                    items: [
                      SummaryTileData(
                        title: 'Ingresos',
                        amount: summary.totalIncome,
                        icon: Icons.arrow_upward_rounded,
                        type: SummaryTileType.income,
                        format: currency,
                      ),
                      SummaryTileData(
                        title: 'Gastos',
                        amount: summary.totalExpense,
                        icon: Icons.arrow_downward_rounded,
                        type: SummaryTileType.expense,
                        format: currency,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideTransition(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: SummaryRow(
                          items: [
                            SummaryTileData(
                              title: 'Personal',
                              amount: summary.expensePersonal,
                              icon: Icons.person_outline,
                              type: SummaryTileType.expense,
                              format: currency,
                            ),
                            SummaryTileData(
                              title: 'Hogar',
                              amount: summary.expenseHousehold,
                              icon: Icons.home_outlined,
                              type: SummaryTileType.neutral,
                              format: currency,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideTransition(
                  index: 3,
                  child: BalanceCard(
                    label: 'Balance del Mes',
                    amount: summary.balance,
                    format: currency,
                    isPositive: summary.balance >= 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideTransition(
                  index: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transacciones (${summary.count})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (summary.transactions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    subtitle: 'No hay transacciones este mes',
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.transactions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == summary.transactions.length) {
                        return const SizedBox(height: 80);
                      }

                      final tMap =
                          summary.transactions[index] as Map<String, dynamic>;
                      final t = Transaction.fromJson(tMap);
                      final accountName = accountsById[t.accountId]?.name;
                      final contextLabel = t.context == 'household'
                          ? 'Hogar'
                          : 'Personal';

                      return FadeSlideTransition(
                        index: 5 + index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: TransactionTile(
                            description: t.description,
                            category: t.category,
                            amount: t.amount,
                            type: t.type,
                            date: t.date,
                            accountName: accountName,
                            contextLabel: contextLabel,
                            onEdit: () => _editTransaction(context, t),
                            onDelete: () => _deleteTransaction(context, t.id),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const SkeletonList(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month - 1,
              );
            });
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.stateFill(AppColors.primary),
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          child: Text(
            DateFormat.yMMMM('es_CO').format(_selectedDate).toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              _selectedDate.month < DateTime.now().month ||
                  _selectedDate.year < DateTime.now().year
              ? () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                  });
                }
              : null,
        ),
      ],
    );
  }

  void _editTransaction(BuildContext context, Transaction t) {
    context.push('/transactions/add', extra: t);
  }

  Future<void> _deleteTransaction(BuildContext context, String id) async {
    final confirmed = await DeleteConfirmDialog.show(
      context,
      itemName: 'esta transacción',
    );

    if (confirmed == true) {
      try {
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
        // Deleting a tx changes balances, history, budgets and the household
        // snapshot (txEffects) AND, if it touched a credit card, the card debt
        // rollups (debtEffects) — refresh the whole set so nothing stays stale.
        invalidateAfterMutation(
          ref,
          scope: {DataMutation.txEffects, DataMutation.debtEffects},
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
