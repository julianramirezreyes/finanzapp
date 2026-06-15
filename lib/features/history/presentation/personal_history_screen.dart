import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/balance_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/summary_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';

class PersonalHistoryScreen extends ConsumerStatefulWidget {
  const PersonalHistoryScreen({super.key});

  @override
  ConsumerState<PersonalHistoryScreen> createState() =>
      _PersonalHistoryScreenState();
}

class _PersonalHistoryScreenState extends ConsumerState<PersonalHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      personalHistoryProvider((
        month: _selectedDate.month,
        year: _selectedDate.year,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Personal'),
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
                  child: BalanceCard(
                    label: 'Balance Mensual',
                    amount: summary.balance,
                    format: currency,
                    isPositive: summary.balance >= 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideTransition(
                  index: 3,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desglose de Gastos',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRow(
                          context,
                          'Personal',
                          summary.expensePersonal,
                          currency,
                          AppColors.expense,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _buildRow(
                          context,
                          'Hogar (Aporte)',
                          summary.expenseHousehold,
                          currency,
                          AppColors.info,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideTransition(
                  index: 4,
                  child: Text(
                    'Movimientos (${summary.count})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                    itemCount: summary.transactions.length,
                    itemBuilder: (context, index) {
                      final tMap =
                          summary.transactions[index] as Map<String, dynamic>;
                      final t = Transaction.fromJson(tMap);

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
                            contextLabel: t.context == 'household'
                                ? 'Hogar'
                                : 'Personal',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
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

  Widget _buildRow(
    BuildContext context,
    String label,
    double amount,
    NumberFormat format,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
        ),
        Text(
          format.format(amount),
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
