import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_form_dialog.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_allocation.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_consumption.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_history_screen.dart';
import 'package:finanzapp_v2/features/budgets/presentation/helpers/confirm_delete_budget.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';

class HouseholdBudgetTab extends ConsumerStatefulWidget {
  const HouseholdBudgetTab({super.key});

  @override
  ConsumerState<HouseholdBudgetTab> createState() => _HouseholdBudgetTabState();
}

class _HouseholdBudgetTabState extends ConsumerState<HouseholdBudgetTab> {
  final _incomeAController = TextEditingController();
  final _incomeBController = TextEditingController();
  double _pctExpense = 50;
  double _pctSavings = 30;
  double _pctInvestment = 20;
  bool _isInit = false;

  @override
  void dispose() {
    _incomeAController.dispose();
    _incomeBController.dispose();
    super.dispose();
  }

  void _initializeValues({
    required BudgetConfig config,
    required String currentUserId,
    required String householdUserAId,
  }) {
    if (_isInit) return;
    final isUserA = currentUserId == householdUserAId;
    _incomeAController.text = (isUserA ? config.incomeA : config.incomeB)
        .toStringAsFixed(0);
    _incomeBController.text = (isUserA ? config.incomeB : config.incomeA)
        .toStringAsFixed(0);
    _pctExpense = config.pctExpense.toDouble();
    _pctSavings = config.pctSavings.toDouble();
    _pctInvestment = config.pctInvestment.toDouble();
    _isInit = true;
  }

  Future<void> _saveConfig({
    required String householdId,
    required BudgetConfig existingConfig,
    required String currentUserId,
    required String householdUserAId,
  }) async {
    final myIncome = double.tryParse(_incomeAController.text) ?? 0;
    final isUserA = currentUserId == householdUserAId;
    final newConfig = BudgetConfig(
      id: '',
      householdId: householdId,
      incomeA: isUserA ? myIncome : existingConfig.incomeA,
      incomeB: isUserA ? existingConfig.incomeB : myIncome,
      pctExpense: _pctExpense.round(),
      pctSavings: _pctSavings.round(),
      pctInvestment: _pctInvestment.round(),
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(budgetConfigRepositoryProvider).upsertConfig(newConfig);
      ref.invalidate(budgetConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(householdProvider);
    final currentUser = ref.watch(userProvider);

    return householdAsync.when(
      data: (household) {
        if (household == null) {
          return const Center(child: Text("No tienes un hogar activo."));
        }
        if (currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final configAsync = ref.watch(
          budgetConfigProvider((type: 'household', householdId: household.id)),
        );

        return configAsync.when(
          data: (config) {
            _initializeValues(
              config: config,
              currentUserId: currentUser.id,
              householdUserAId: household.userAId,
            );

            final incomeA = double.tryParse(_incomeAController.text) ?? 0;
            final incomeB = double.tryParse(_incomeBController.text) ?? 0;
            final totalIncome = incomeA + incomeB;
            final totalPct = _pctExpense + _pctSavings + _pctInvestment;
            final isInvalid = totalPct != 100;
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
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingresos Proyectados',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _incomeAController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Tu Ingreso',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.inputRadius,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextField(
                                controller: _incomeBController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Ingreso Pareja',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.inputRadius,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.stateFill(AppColors.primary),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Total Hogar: ${currency.format(totalIncome)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distribución',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: context.stateFill(
                                  isInvalid
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.chipRadius,
                                ),
                              ),
                              child: Text(
                                '${totalPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: isInvalid
                                      ? AppColors.expense
                                      : AppColors.income,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isInvalid) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'La suma debe ser 100%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.expense),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildSlider(
                          'Gastos',
                          _pctExpense,
                          AppColors.expense,
                          (v) {
                            setState(() => _pctExpense = v);
                          },
                          totalIncome * (_pctExpense / 100),
                          currency,
                        ),
                        _buildSlider(
                          'Ahorro',
                          _pctSavings,
                          AppColors.savings,
                          (v) {
                            setState(() => _pctSavings = v);
                          },
                          totalIncome * (_pctSavings / 100),
                          currency,
                        ),
                        _buildSlider(
                          'Inversión',
                          _pctInvestment,
                          AppColors.investment,
                          (v) {
                            setState(() => _pctInvestment = v);
                          },
                          totalIncome * (_pctInvestment / 100),
                          currency,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isInvalid
                                ? null
                                : () => _saveConfig(
                                    householdId: household.id,
                                    existingConfig: config,
                                    currentUserId: currentUser.id,
                                    householdUserAId: household.userAId,
                                  ),
                            child: const Text('Guardar Configuración'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPreviewBar(
                    context,
                    totalIncome,
                    currency,
                    household.id,
                    ref,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildGoalsSection(context, ref, household.id),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Error: $e")),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
    double amount,
    NumberFormat currency,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w500, color: color),
                ),
              ],
            ),
            Text(
              '${value.round()}% (${currency.format(amount)})',
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewBar(
    BuildContext context,
    double totalIncome,
    NumberFormat currency,
    String householdId,
    WidgetRef ref,
  ) {
    if (totalIncome <= 0) return const SizedBox.shrink();
    final expenseAmt = totalIncome * (_pctExpense / 100);
    final savingAmt = totalIncome * (_pctSavings / 100);
    final investAmt = totalIncome * (_pctInvestment / 100);

    final budgetsAsync = ref.watch(budgetsListProvider(householdId));

    return budgetsAsync.when(
      data: (budgets) {
        // The bar shows REAL household consumption of the month (Σ currentAmount),
        // which already arrives aggregated across BOTH members from the backend.
        // It is NOT split by myRatio/partnerRatio: those describe planned
        // contribution, not executed spend (R3). The colored top bar still shows
        // the plan per type (expenseAmt/savingAmt/investAmt = income × pct).
        final totalBudgeted = expenseAmt + savingAmt + investAmt;
        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: totalBudgeted,
        );
        final consumedExpense = summary.consumedExpense;
        final consumedSaving = summary.consumedSaving;
        final consumedInvestment = summary.consumedInvestment;
        final totalConsumed = summary.totalConsumed;
        final remaining = summary.remaining;
        final isOverBudget = remaining < 0;
        final progress = summary.progress;

        // "Presupuestado vs Plan": PLANNED allocation (Σ monthlyQuota) vs the
        // FULL household caps — independent of the consumption summary above.
        final allocationSummary = summarizeBudgetAllocation(
          budgets: budgets,
          expensePlan: expenseAmt,
          savingPlan: savingAmt,
          investPlan: investAmt,
        );

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disponibilidad Mensual',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      if (_pctExpense > 0)
                        Expanded(
                          flex: _pctExpense.round(),
                          child: Container(
                            color: AppColors.expense,
                            child: Center(
                              child: Text(
                                currency.format(expenseAmt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      if (_pctSavings > 0)
                        Expanded(
                          flex: _pctSavings.round(),
                          child: Container(
                            color: AppColors.savings,
                            child: Center(
                              child: Text(
                                currency.format(savingAmt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      if (_pctInvestment > 0)
                        Expanded(
                          flex: _pctInvestment.round(),
                          child: Container(
                            color: AppColors.investment,
                            child: Center(
                              child: Text(
                                currency.format(investAmt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? AppColors.expense.withValues(alpha: 0.1)
                      : AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: isOverBudget ? AppColors.expense : AppColors.income,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isOverBudget
                              ? '⚠️ Te has pasado del plan'
                              : 'Gastado vs Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverBudget
                                ? AppColors.expense
                                : context.onSurface,
                          ),
                        ),
                        Text(
                          '${currency.format(totalConsumed)} / ${currency.format(totalBudgeted)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverBudget
                                ? AppColors.expense
                                : context.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: isOverBudget
                            ? AppColors.expense.withValues(alpha: 0.2)
                            : AppColors.textMuted.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget
                              ? AppColors.expense
                              : progress >= 1.0
                              ? AppColors.income
                              : AppColors.primary,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% del plan gastado',
                          style: AppTypography.labelSmall,
                        ),
                        Text(
                          isOverBudget
                              ? '${currency.format(remaining.abs())} sobre el plan'
                              : '${currency.format(remaining)} disponible',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isOverBudget
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildAllocationRow(allocationSummary, currency),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConsumedChip(
                    'Gastos',
                    consumedExpense,
                    expenseAmt,
                    AppColors.expense,
                    currency,
                    allocated: allocationSummary.allocatedExpense,
                    allocatedCap: allocationSummary.expensePlan,
                    isAllocationOver: allocationSummary.isExpenseOver,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildConsumedChip(
                    'Ahorro',
                    consumedSaving,
                    savingAmt,
                    AppColors.savings,
                    currency,
                    allocated: allocationSummary.allocatedSaving,
                    allocatedCap: allocationSummary.savingPlan,
                    isAllocationOver: allocationSummary.isSavingOver,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildConsumedChip(
                    'Inversión',
                    consumedInvestment,
                    investAmt,
                    AppColors.investment,
                    currency,
                    allocated: allocationSummary.allocatedInvestment,
                    allocatedCap: allocationSummary.investPlan,
                    isAllocationOver: allocationSummary.isInvestmentOver,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text("Error: $e"),
    );
  }

  /// "Presupuestado vs Plan": a QUIET, TEXT-ONLY subordinate row placed below
  /// "Gastado vs Plan" (ADR-5). Never a new progress bar. Healthy state is
  /// NEUTRAL/MUTED (deliberately NOT income-green); alert tone is driven by
  /// `hasAnyCategoryOver` (ADR-6), independent of the consumption state above.
  /// Caps reflect the FULL household plan `(incomeA + incomeB) × pct` — never
  /// a per-member split (resolved decision #4).
  Widget _buildAllocationRow(
    BudgetAllocationSummary summary,
    NumberFormat currency,
  ) {
    final toneColor = summary.hasAnyCategoryOver
        ? AppColors.expense
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Presupuestado vs Plan',
              style: AppTypography.labelSmall.copyWith(color: toneColor),
            ),
            Text(
              '${currency.format(summary.totalAllocated)} / ${currency.format(summary.totalPlan)}',
              style: AppTypography.labelSmall.copyWith(
                color: toneColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${(summary.progress * 100).toStringAsFixed(0)}% del plan presupuestado',
          style: AppTypography.labelSmall.copyWith(color: toneColor),
        ),
      ],
    );
  }

  Widget _buildConsumedChip(
    String label,
    double consumed,
    double budgeted,
    Color color,
    NumberFormat currency, {
    required double allocated,
    required double allocatedCap,
    required bool isAllocationOver,
  }) {
    // R3: household consumption is the TOTAL aggregate; it is not split by
    // contribution ratio (that describes planned aporte, not executed spend).
    final isOver = consumed > budgeted && budgeted > 0;
    final allocationToneColor = isAllocationOver
        ? AppColors.expense
        : AppColors.textSecondary;
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isOver
              ? AppColors.expense.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: Border.all(
            color: isOver ? AppColors.expense : color,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isOver ? AppColors.expense : color,
                fontSize: 10,
              ),
            ),
            Text(
              currency.format(consumed),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOver ? AppColors.expense : color,
              ),
            ),
            Text(
              'de ${currency.format(budgeted)}',
              style: TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
            Text(
              'Presup: ${currency.format(allocated)} / ${currency.format(allocatedCap)}',
              style: AppTypography.captionSmall.copyWith(
                fontWeight: isAllocationOver
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: allocationToneColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) {
    final budgetsAsync = ref.watch(budgetsListProvider(householdId));

    final incomeA = double.tryParse(_incomeAController.text) ?? 0;
    final incomeB = double.tryParse(_incomeBController.text) ?? 0;
    final totalIncome = incomeA + incomeB;
    final splitRatio = totalIncome > 0 ? incomeA / totalIncome : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Metas y Gastos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Agregar'),
              onPressed: () => _showAddGoalDialog(context, ref, householdId),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No hay metas configuradas',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: budgets.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: BudgetCard(
                    budget: b,
                    currentAmount: b.currentAmount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BudgetHistoryScreen(budget: b),
                      ),
                    ),
                    onEdit: () =>
                        _showEditGoalDialog(context, ref, householdId, b),
                    onDelete: () => confirmDeleteBudget(
                      context,
                      ref,
                      b,
                      invalidateTarget: budgetsListProvider(householdId),
                    ),
                    splitRatio: splitRatio,
                    showSplit: true,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text("Error: $e"),
        ),
      ],
    );
  }

  void _showAddGoalDialog(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) {
    _showGoalDialog(context, ref, householdId, null);
  }

  void _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    Budget budget,
  ) {
    _showGoalDialog(context, ref, householdId, budget);
  }

  void _showGoalDialog(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    Budget? existing,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => BudgetFormDialog(
        existing: existing,
        onSubmit: (result) async {
          if (existing != null) {
            final updatedBudget = existing.copyWith(
              category: result.name,
              limitAmount: result.limitAmount,
              monthlyQuota: result.monthlyQuota,
              type: result.type,
              months: result.months,
              isRecurrent: result.isRecurrent,
              targetAmount: result.targetAmount,
            );
            // Hogar: updateBudget SIN householdId (comportamiento actual).
            await ref
                .read(budgetRepositoryProvider)
                .updateBudget(updatedBudget);
          } else {
            await ref
                .read(budgetRepositoryProvider)
                .createBudget(
                  category: result.name,
                  amount: result.limitAmount,
                  period: 'monthly',
                  type: result.type,
                  months: result.months,
                  isRecurrent: result.isRecurrent,
                  targetAmount: result.targetAmount,
                  householdId: householdId,
                );
          }
          ref.invalidate(budgetsListProvider(householdId));
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}
