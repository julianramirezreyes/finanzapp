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
import 'package:finanzapp_v2/features/budgets/presentation/reorder_budgets_action.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';

class PersonalBudgetTab extends ConsumerStatefulWidget {
  const PersonalBudgetTab({super.key});

  @override
  ConsumerState<PersonalBudgetTab> createState() => _PersonalBudgetTabState();
}

enum _ReorderPhase { idle, saving }

class _PersonalBudgetTabState extends ConsumerState<PersonalBudgetTab> {
  final _incomeController = TextEditingController();
  double _pctExpense = 50;
  double _pctSavings = 30;
  double _pctInvestment = 20;
  bool _isInit = false;
  List<Budget>? _confirmedBudgets;
  List<String>? _optimisticOrderIds;
  _ReorderPhase _reorderPhase = _ReorderPhase.idle;
  int _reorderGeneration = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _initializeValues(BudgetConfig config) {
    if (_isInit) return;
    _incomeController.text = config.personalIncome.toStringAsFixed(0);
    _pctExpense = config.pctExpense.toDouble();
    _pctSavings = config.pctSavings.toDouble();
    _pctInvestment = config.pctInvestment.toDouble();
    _isInit = true;
  }

  bool get _isReordering => _reorderPhase != _ReorderPhase.idle;

  List<Budget> _visibleBudgets(List<Budget> canonicalBudgets) {
    _confirmedBudgets = List<Budget>.unmodifiable(canonicalBudgets);
    final optimisticOrderIds = _optimisticOrderIds;
    if (optimisticOrderIds == null) return canonicalBudgets;

    final budgetsById = {
      for (final budget in canonicalBudgets) budget.id: budget,
    };
    final rebased = optimisticOrderIds
        .map((budgetId) => budgetsById[budgetId])
        .whereType<Budget>()
        .toList(growable: false);
    if (rebased.length != canonicalBudgets.length) {
      _optimisticOrderIds = null;
      return canonicalBudgets;
    }
    return rebased;
  }

  void _acceptCanonicalBudgets(List<Budget> budgets) {
    if (!mounted) return;
    setState(() {
      _confirmedBudgets = List<Budget>.unmodifiable(budgets);
      if (!_isReordering) _optimisticOrderIds = null;
    });
  }

  Future<List<Budget>> _refreshCanonicalBudgets() async {
    ref.invalidate(budgetsListProvider(null));
    return ref.read(budgetsListProvider(null).future);
  }

  void _startReorder({
    required List<Budget> visibleBudgets,
    required int oldIndex,
    required int newIndex,
  }) {
    if (_isReordering) return;
    final confirmedBudgets =
        _confirmedBudgets ?? List<Budget>.unmodifiable(visibleBudgets);
    final intent = BudgetReorderIntent.tryFromDrag(
      budgets: visibleBudgets,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    final optimistic = intent?.applyTo(visibleBudgets);
    if (intent == null || optimistic == null) return;

    final generation = ++_reorderGeneration;
    setState(() {
      _reorderPhase = _ReorderPhase.saving;
      _optimisticOrderIds = optimistic
          .map((budget) => budget.id)
          .toList(growable: false);
    });
    _persistReorder(
      generation: generation,
      budgets: confirmedBudgets,
      intent: intent,
    );
  }

  Future<void> _persistReorder({
    required int generation,
    required List<Budget> budgets,
    required BudgetReorderIntent intent,
  }) async {
    final result = await executeBudgetReorder(
      repository: ref.read(budgetRepositoryProvider),
      budgets: budgets,
      intent: intent,
      refreshCanonical: _refreshCanonicalBudgets,
    );
    if (!mounted || generation != _reorderGeneration) return;

    setState(() {
      _reorderPhase = _ReorderPhase.idle;
      _optimisticOrderIds = null;
      if (result.isSuccess) {
        _confirmedBudgets = List<Budget>.unmodifiable(result.budgets);
      }
    });
    if (result.isSuccess || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isConflict
              ? 'La lista cambió. Actualiza e intenta reordenar de nuevo.'
              : 'No se pudo guardar el orden. Intenta nuevamente.',
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final currentConfig = await ref.read(
      budgetConfigProvider((type: 'personal', householdId: null)).future,
    );

    final newConfig = BudgetConfig(
      id: currentConfig.id,
      userId: currentConfig.userId,
      personalIncome: income,
      pctExpense: _pctExpense.round(),
      pctSavings: _pctSavings.round(),
      pctInvestment: _pctInvestment.round(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(budgetConfigRepositoryProvider).upsertConfig(newConfig);
      ref.invalidate(budgetConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración Personal Guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(
      budgetConfigProvider((type: 'personal', householdId: null)),
    );
    final currentUser = ref.watch(userProvider);
    final householdAsync = ref.watch(householdProvider);
    final currency = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return configAsync.when(
      data: (config) {
        _initializeValues(config);
        final totalIncome = double.tryParse(_incomeController.text) ?? 0;
        final totalPct = _pctExpense + _pctSavings + _pctInvestment;
        final isInvalid = totalPct != 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              householdAsync.when(
                data: (household) {
                  if (household == null || currentUser == null) {
                    return _buildNoHouseholdBanner(context);
                  }
                  final householdConfigAsync = ref.watch(
                    budgetConfigProvider((
                      type: 'household',
                      householdId: household.id,
                    )),
                  );
                  return householdConfigAsync.when(
                    data: (householdConfig) {
                      return _buildPersonalAvailableBanner(
                        context,
                        household,
                        currentUser,
                        currency,
                        ref,
                        householdConfig,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const SizedBox.shrink(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Ingreso Proyectado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Ingreso Mensual',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.inputRadius,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
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
                            'Total: ${currency.format(totalIncome)}',
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
                              isInvalid ? AppColors.expense : AppColors.income,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.expense,
                        ),
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
                        onPressed: isInvalid ? null : _saveConfig,
                        child: const Text('Guardar Configuración'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPreviewBar(context, totalIncome, currency, ref),
              const SizedBox(height: AppSpacing.xl),
              _buildBudgetsSection(context, ref),
            ],
          ),
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
    WidgetRef ref,
  ) {
    if (totalIncome <= 0) return const SizedBox.shrink();
    final expenseAmt = totalIncome * (_pctExpense / 100);
    final savingAmt = totalIncome * (_pctSavings / 100);
    final investAmt = totalIncome * (_pctInvestment / 100);

    final budgetsAsync = ref.watch(budgetsListProvider(null));

    return budgetsAsync.when(
      data: (budgets) {
        // The bar shows REAL consumption of the month (Σ currentAmount), not the
        // assignment (Σ monthlyQuota). The colored top bar still renders the plan
        // per type (expenseAmt/savingAmt/investAmt = income × pct).
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
        // same category caps — independent of the consumption summary above.
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
                'Tu Plan Mensual',
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
                              ? 'Te has pasado del plan'
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
                children: [
                  _buildPersonalConsumedChip(
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
                  _buildPersonalConsumedChip(
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
                  _buildPersonalConsumedChip(
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

  Widget _buildPersonalConsumedChip(
    String label,
    double consumed,
    double budgeted,
    Color color,
    NumberFormat currency, {
    required double allocated,
    required double allocatedCap,
    required bool isAllocationOver,
  }) {
    final isOver = consumed > budgeted && budgeted > 0;
    final allocationToneColor = isAllocationOver
        ? AppColors.expense
        : AppColors.textSecondary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
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
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isOver ? AppColors.expense : color,
              ),
            ),
            Text(
              currency.format(consumed),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOver ? AppColors.expense : color,
              ),
            ),
            Text(
              'de ${currency.format(budgeted)}',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  Widget _buildBudgetsSection(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider(null));
    ref.listen<AsyncValue<List<Budget>>>(budgetsListProvider(null), (_, next) {
      next.whenData(_acceptCanonicalBudgets);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tus Metas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Agregar'),
              onPressed: () => _showGoalDialog(context, ref, null),
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
                          'No tienes metas personales',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final displayedBudgets = _visibleBudgets(budgets);
            return Column(
              children: [
                if (_isReordering) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Guardando orden...',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                IgnorePointer(
                  ignoring: _isReordering,
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) => _startReorder(
                      visibleBudgets: displayedBudgets,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                    children: displayedBudgets.map((b) {
                      return Padding(
                        key: ValueKey('personal-budget-${b.id}'),
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: BudgetCard(
                          budget: b,
                          currentAmount: b.currentAmount,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BudgetHistoryScreen(budget: b),
                            ),
                          ),
                          onEdit: () => _showGoalDialog(context, ref, b),
                          onDelete: () => confirmDeleteBudget(
                            context,
                            ref,
                            b,
                            invalidateTarget: budgetsListProvider(null),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text("Error: $e"),
        ),
      ],
    );
  }

  /// Builds the [AllocationPreviewData] snapshot `_showGoalDialog` injects
  /// into [BudgetFormDialog] (design ADR-3). `planCapByType` is already
  /// buildable from the instance's cached pct/income fields (no new read);
  /// `otherAllocatedByType` is NOT already in scope, so this method
  /// explicitly `ref.read`s the current `budgetsListProvider(null)` snapshot
  /// (state already fetched elsewhere, not a new network call) and folds it
  /// (minus `existing?.id`) per category. Returns `null` when that snapshot
  /// is still loading or errored (`.valueOrNull == null`) — the dialog must still
  /// open immediately in that case, with no preview (spec R12.3/R13).
  AllocationPreviewData? _buildAllocationPreviewData(
    WidgetRef ref,
    Budget? existing,
  ) {
    // NOTE: `.value` rethrows the underlying error when the AsyncValue is an
    // AsyncError with no cached previous data — `.valueOrNull` is the
    // correct null-safe accessor for the loading/error degrade path here.
    final budgets = ref.read(budgetsListProvider(null)).valueOrNull;
    if (budgets == null) return null;

    final totalIncome = double.tryParse(_incomeController.text) ?? 0;
    final planCapByType = <String, double>{
      'expense': totalIncome * (_pctExpense / 100),
      'saving': totalIncome * (_pctSavings / 100),
      'investment': totalIncome * (_pctInvestment / 100),
    };

    double otherAllocatedOf(String type) => budgets
        .where((b) => b.type == type && b.id != existing?.id)
        .fold<double>(0, (sum, b) => sum + b.monthlyQuota);
    final otherAllocatedByType = <String, double>{
      'expense': otherAllocatedOf('expense'),
      'saving': otherAllocatedOf('saving'),
      'investment': otherAllocatedOf('investment'),
    };

    return AllocationPreviewData(
      planCapByType: planCapByType,
      otherAllocatedByType: otherAllocatedByType,
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, Budget? existing) {
    final allocationPreview = _buildAllocationPreviewData(ref, existing);
    showDialog(
      context: context,
      builder: (ctx) => BudgetFormDialog(
        existing: existing,
        allocationPreview: allocationPreview,
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
                );
          }
          ref.invalidate(budgetsListProvider(null));
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildNoHouseholdBanner(BuildContext context) {
    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.stateFill(AppColors.info),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Creá un hogar para ver tu disponibilidad personal',
                style: TextStyle(color: AppColors.info),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalAvailableBanner(
    BuildContext context,
    dynamic household,
    dynamic currentUser,
    NumberFormat currency,
    WidgetRef ref,
    BudgetConfig householdConfig,
  ) {
    final budgetsAsync = ref.watch(budgetsListProvider(household.id));

    return budgetsAsync.when(
      data: (budgets) {
        final isUserA = currentUser.id == household.userAId;
        final incomeA = householdConfig.incomeA;
        final incomeB = householdConfig.incomeB;
        final myIncome = isUserA ? incomeA : incomeB;
        final totalHouseholdIncome = incomeA + incomeB;
        final myRatio = totalHouseholdIncome > 0
            ? myIncome / totalHouseholdIncome
            : 0.5;

        final expenseShare = budgets
            .where((b) => b.type == 'expense')
            .fold<double>(0, (sum, b) => sum + b.monthlyQuota);
        final savingShare = budgets
            .where((b) => b.type == 'saving')
            .fold<double>(0, (sum, b) => sum + b.monthlyQuota);
        final investmentShare = budgets
            .where((b) => b.type == 'investment')
            .fold<double>(0, (sum, b) => sum + b.monthlyQuota);

        final myExpense = expenseShare * myRatio;
        final mySaving = savingShare * myRatio;
        final myInvestment = investmentShare * myRatio;
        final myTotalContribution = myExpense + mySaving + myInvestment;
        final available = myIncome - myTotalContribution;

        final isNegative = available < 0;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: isNegative ? AppColors.expense : AppColors.income,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Disponible para Presupuesto Personal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.stateFill(
                    isNegative ? AppColors.expense : AppColors.income,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Column(
                  children: [
                    Text(
                      currency.format(available),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                    ),
                    Text(
                      isNegative
                          ? 'Te estás pasando de tu ingreso'
                          : 'Después de aportar al hogar',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _buildContributionRow(
                context,
                'Tu ingreso en Hogar',
                myIncome,
                currency,
                false,
              ),
              _buildContributionRow(
                context,
                '- Tu parte Gastos',
                myExpense,
                currency,
                true,
              ),
              _buildContributionRow(
                context,
                '- Tu parte Ahorro',
                mySaving,
                currency,
                true,
              ),
              _buildContributionRow(
                context,
                '- Tu parte Inversión',
                myInvestment,
                currency,
                true,
              ),
              const Divider(),
              _buildContributionRow(
                context,
                'Total aporte Hogar',
                myTotalContribution,
                currency,
                true,
                isBold: true,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text("Error: $e"),
    );
  }

  Widget _buildContributionRow(
    BuildContext context,
    String label,
    double amount,
    NumberFormat currency,
    bool isSubtraction, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${isSubtraction ? '-' : ''}${currency.format(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isSubtraction ? AppColors.expense : context.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
