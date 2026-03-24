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
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
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

            final totalIncome =
                (double.tryParse(_incomeAController.text) ?? 0) +
                (double.tryParse(_incomeBController.text) ?? 0);
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
                            color: AppColors.primarySurface,
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
                                color: isInvalid
                                    ? AppColors.expenseLight
                                    : AppColors.incomeLight,
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
                        _buildSlider('Gastos', _pctExpense, AppColors.expense, (
                          v,
                        ) {
                          setState(() => _pctExpense = v);
                        }),
                        _buildSlider('Ahorro', _pctSavings, AppColors.savings, (
                          v,
                        ) {
                          setState(() => _pctSavings = v);
                        }),
                        _buildSlider(
                          'Inversión',
                          _pctInvestment,
                          AppColors.investment,
                          (v) {
                            setState(() => _pctInvestment = v);
                          },
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
                  _buildPreviewBar(totalIncome, currency),
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
            Text('${value.round()}%'),
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

  Widget _buildPreviewBar(double totalIncome, NumberFormat currency) {
    if (totalIncome <= 0) return const SizedBox.shrink();
    final expenseAmt = totalIncome * (_pctExpense / 100);
    final savingAmt = totalIncome * (_pctSavings / 100);
    final investAmt = totalIncome * (_pctInvestment / 100);

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
        ],
      ),
    );
  }

  Widget _buildGoalsSection(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) {
    final budgetsAsync = ref.watch(budgetsListProvider(householdId));

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
                    onTap: () =>
                        _showEditGoalDialog(context, ref, householdId, b),
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
    final nameController = TextEditingController(text: existing?.category);
    final amountController = TextEditingController(
      text: existing?.monthlyQuota.toStringAsFixed(0),
    );
    String type = existing?.type ?? 'expense';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nueva Meta' : 'Editar Meta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto Mensual'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                  DropdownMenuItem(value: 'saving', child: Text('Ahorro')),
                  DropdownMenuItem(
                    value: 'investment',
                    child: Text('Inversión'),
                  ),
                ],
                onChanged: (v) => type = v ?? 'expense',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              if (name.isEmpty || amount <= 0) return;

              if (existing != null) {
                await ref.read(budgetRepositoryProvider).updateBudget(existing);
              } else {
                await ref
                    .read(budgetRepositoryProvider)
                    .createBudget(
                      category: name,
                      amount: amount,
                      period: 'monthly',
                      type: type,
                      householdId: householdId,
                    );
              }
              ref.invalidate(budgetsListProvider(householdId));
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
