import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';

class PersonalBudgetTab extends ConsumerStatefulWidget {
  const PersonalBudgetTab({super.key});

  @override
  ConsumerState<PersonalBudgetTab> createState() => _PersonalBudgetTabState();
}

class _PersonalBudgetTabState extends ConsumerState<PersonalBudgetTab> {
  final _incomeController = TextEditingController();
  double _pctExpense = 50;
  double _pctSavings = 30;
  double _pctInvestment = 20;
  bool _isInit = false;

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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildSlider('Gastos', _pctExpense, AppColors.expense, (v) {
                      setState(() => _pctExpense = v);
                    }),
                    _buildSlider('Ahorro', _pctSavings, AppColors.savings, (v) {
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
                        onPressed: isInvalid ? null : _saveConfig,
                        child: const Text('Guardar Configuración'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPreviewBar(totalIncome, currency),
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
        ],
      ),
    );
  }

  Widget _buildBudgetsSection(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider(null));

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
            return Column(
              children: budgets.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: BudgetCard(
                    budget: b,
                    currentAmount: b.currentAmount,
                    onTap: () => _showGoalDialog(context, ref, b),
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

  void _showGoalDialog(BuildContext context, WidgetRef ref, Budget? existing) {
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
                    );
              }
              ref.invalidate(budgetsListProvider(null));
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
