import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
      ref.invalidate(budgetConfigProvider); // Refresh
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

  void _updateDistribution(String type, double value) {
    setState(() {
      if (type == 'expense') {
        _pctExpense = value;
      } else if (type == 'savings') {
        _pctSavings = value;
      } else {
        _pctInvestment = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(
      budgetConfigProvider((type: 'personal', householdId: null)),
    );

    return configAsync.when(
      data: (config) {
        _initializeValues(config);

        final totalPct = _pctExpense + _pctSavings + _pctInvestment;
        final isInvalid = totalPct != 100;
        final totalIncome = double.tryParse(_incomeController.text) ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INCOME ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    "Mi Presupuesto Personal (Residual)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.indigo),
                    onPressed: () => context.push('/history/personal'),
                    tooltip: "Ver Historial",
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Insight Widget
              _buildResidualInsight(ref),

              const SizedBox(height: 16),

              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Ingreso Personal Disponible",
                  helperText: "Lo que te sobra del hogar o ingresos extra",
                  border: OutlineInputBorder(),
                  prefixText: "\$",
                ),
                onChanged: (_) => setState(() {}),
              ),

              const Divider(height: 32),

              // --- DISTRIBUTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Distribución (%)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "${totalPct.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: isInvalid ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isInvalid)
                const Text(
                  "La suma debe ser 100%",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),

              _buildSlider(
                "Gastos Personales",
                _pctExpense,
                Colors.red,
                (v) => _updateDistribution('expense', v),
              ),
              _buildSlider(
                "Ahorro Personal",
                _pctSavings,
                Colors.blue,
                (v) => _updateDistribution('savings', v),
              ),
              _buildSlider(
                "Inversión ",
                _pctInvestment,
                Colors.purple,
                (v) => _updateDistribution('investment', v),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isInvalid ? null : _saveConfig,
                  child: const Text("Guardar Mi Plan"),
                ),
              ),

              const Divider(height: 32),

              // --- PREVIEW ---
              _buildPreviewBar(totalIncome),

              const SizedBox(height: 32),

              // --- GOALS ---
              _buildGoalsSection(context, ref),
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
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text("${value.round()}%"),
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

  Widget _buildPreviewBar(double totalIncome) {
    if (totalIncome <= 0) return const SizedBox.shrink();

    final expenseAmt = totalIncome * (_pctExpense / 100);
    final savingAmt = totalIncome * (_pctSavings / 100);
    final investAmt = totalIncome * (_pctInvestment / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Disponibilidad Personal",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          child: Row(
            children: [
              if (_pctExpense > 0)
                Expanded(
                  flex: _pctExpense.round(),
                  child: Container(
                    color: Colors.red,
                    child: Center(
                      child: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(expenseAmt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (_pctSavings > 0)
                Expanded(
                  flex: _pctSavings.round(),
                  child: Container(
                    color: Colors.blue,
                    child: Center(
                      child: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(savingAmt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (_pctInvestment > 0)
                Expanded(
                  flex: _pctInvestment.round(),
                  child: Container(
                    color: Colors.purple,
                    child: Center(
                      child: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(investAmt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResidualInsight(WidgetRef ref) {
    final householdAsync = ref.watch(householdProvider);
    final householdId = householdAsync.valueOrNull?.id;

    if (householdId != null) {
      final hhConfigAsync = ref.watch(
        budgetConfigProvider((type: 'household', householdId: householdId)),
      );
      final hhBudgetsAsync = ref.watch(budgetsListProvider(householdId));

      return hhConfigAsync.when(
        data: (config) {
          return hhBudgetsAsync.maybeWhen(
            data: (budgets) {
              double totalHhExpenses = 0;
              for (var b in budgets) {
                totalHhExpenses += b.monthlyQuota;
              }

              final incomeA = config.incomeA;
              final incomeB = config.incomeB;
              final totalIncome = incomeA + incomeB;

              if (totalIncome <= 0) return const SizedBox.shrink();

              // Default to Income A for user context
              final myRatio = incomeA / totalIncome;
              final myShare = totalHhExpenses * myRatio;
              final residual = incomeA - myShare;

              if (residual > 0) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Tu aporte al hogar (${(myRatio * 100).toStringAsFixed(0)}%) cubre ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(myShare)} de gastos.",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Te sobran ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(residual)} de tu ingreso registrado (${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(incomeA)}).",
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, s) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGoalsSection(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider(null));
    final double totalIncome = double.tryParse(_incomeController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Mis Metas Personales",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () => _showAddGoalDialog(context, ref),
            ),
          ],
        ),
        budgetsAsync.when(
          data: (budgets) {
            double usedExpense = 0;
            double usedSavings = 0;
            double usedInvestment = 0;

            for (var b in budgets) {
              if (b.type == 'expense') usedExpense += b.monthlyQuota;
              if (b.type == 'saving' || b.type == 'savings') {
                usedSavings += b.monthlyQuota;
              }
              if (b.type == 'investment') usedInvestment += b.monthlyQuota;
            }

            final totalExpense = totalIncome * (_pctExpense / 100);
            final totalSavings = totalIncome * (_pctSavings / 100);
            final totalInvestment = totalIncome * (_pctInvestment / 100);

            return Column(
              children: [
                const SizedBox(height: 8),
                _buildAllocationRow(
                  "Gastos",
                  usedExpense,
                  totalExpense,
                  Colors.red,
                ),
                _buildAllocationRow(
                  "Ahorro",
                  usedSavings,
                  totalSavings,
                  Colors.blue,
                ),
                _buildAllocationRow(
                  "Inversión",
                  usedInvestment,
                  totalInvestment,
                  Colors.purple,
                ),
                const Divider(),
                if (budgets.isEmpty)
                   const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No tienes metas personales",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: budgets.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = budgets.removeAt(oldIndex);
                      budgets.insert(newIndex, item);
                      
                      // Optimize update: Update only if needed or just sync
                      // Can't update the provider list directly as it's immutable usually from network?
                      // Actually riverpod AsyncValue data is not mutable directly for the provider unless using a class notifier.
                      // But effectively we can trigger the API call.
                      // The list here is a local copy since when().
                      // Actually, 'budgets' list from when(data:) is just a valid List.
                      
                      ref.read(budgetRepositoryProvider).reorderBudgets(budgets)
                         .then((_) => ref.invalidate(budgetsListProvider(null)));
                    },
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return Container(
                        key: ValueKey(budget.id),
                         margin: const EdgeInsets.only(bottom: 8),
                        child: BudgetCard(
                          budget: budget,
                          currentAmount: budget.currentAmount,
                          onTap: () => _showEditGoalDialog(context, ref, budget),
                        ),
                      );
                    },
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

  Widget _buildAllocationRow(
    String label,
    double used,
    double total,
    Color color,
  ) {
    final remaining = total - used;
    final isOver = remaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            "Usado: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(used)} / ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(total)}  (Quedan: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(remaining)})",
            style: TextStyle(
              color: isOver ? Colors.red : Colors.grey[700],
              fontSize: 11,
              fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'expense';
    int months = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            "Nueva Meta Personal",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: "Nombre de la Meta / Gasto",
                    hintText: "Ej: Gimnasio, Ahorro Carro",
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Valor Mensual / Total",
                    prefixText: "\$",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: "Tipo",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text("Gasto Fijo"),
                    ),
                    DropdownMenuItem(value: 'saving', child: Text("Ahorro")),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text("Inversión"),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                if (selectedType != 'expense') ...[
                  const SizedBox(height: 16),
                  Text("Plazo: $months meses"),
                  Slider(
                    value: months.toDouble(),
                    min: 1,
                    max: 36,
                    divisions: 35,
                    label: "$months meses",
                    onChanged: (val) => setState(() => months = val.round()),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = categoryController.text;
                final amount = double.tryParse(amountController.text) ?? 0;

                if (category.isEmpty || amount <= 0) return;

                try {
                  await ref
                      .read(budgetRepositoryProvider)
                      .createBudget(
                        category: category,
                        amount: amount,
                        period: 'monthly',
                        type: selectedType,
                        months: selectedType == 'expense' ? 1 : months,
                        isRecurrent: selectedType == 'expense',
                        householdId: null, // Personal
                      );

                  ref.invalidate(budgetsListProvider(null));
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, Budget budget) {
    final nameController = TextEditingController(text: budget.category);
    final amountController = TextEditingController(
      text: budget.limitAmount.toStringAsFixed(0),
    );
    String selectedType = budget.type;
    int months = budget.months > 0 ? budget.months : 1;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        title: const Text("Editar Meta"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Valor Mensual / Total",
                  prefixText: "\$",
                ),
              ),
               const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType, // Ensure this matches allowed items
                  decoration: const InputDecoration(
                    labelText: "Tipo",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text("Gasto Fijo"),
                    ),
                    DropdownMenuItem(value: 'saving', child: Text("Ahorro")),
                    DropdownMenuItem(value: 'savings', child: Text("Ahorro (Legacy)")), // Handle potential legacy strings
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text("Inversión"),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                if (selectedType != 'expense') ...[
                  const SizedBox(height: 16),
                  Text("Plazo: $months meses"),
                  Slider(
                    value: months.toDouble(),
                    min: 1,
                    max: 36,
                    divisions: 35,
                    label: "$months meses",
                    onChanged: (val) => setState(() => months = val.round()),
                  ),
                ],
              const SizedBox(height: 12),
              if (budget.currentAmount > 0)
                Text(
                  "Progreso actual: \$${budget.currentAmount.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.green),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Delete
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("¿Eliminar?"),
                  content: const Text("Esta acción es irreversible."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Sí"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(budgetRepositoryProvider)
                    .deleteBudget(budget.id);
                ref.invalidate(budgetsListProvider(null));
                if (context.mounted) {
                  Navigator.pop(context); // Close Edit Dialog
                }
              }
            },
            child: const Text("Eliminar"),
          ),
          ElevatedButton(
            onPressed: () async {
               final name = nameController.text;
               final amount = double.tryParse(amountController.text) ?? 0;
               if (name.isEmpty || amount <= 0) return;

               final updatedBudget = budget.copyWith(
                 category: name,
                 limitAmount: amount,
                 type: selectedType,
                 months: months,
                 isRecurrent: selectedType == 'expense',
                 // Recalculate monthly quota handled by backend usually or simple logic here?
                 // Backend handles it based on isRecurrent and amount.
               );

               try {
                 await ref.read(budgetRepositoryProvider).updateBudget(updatedBudget);
                 ref.invalidate(budgetsListProvider(null));
                 if (context.mounted) Navigator.pop(context);
               } catch (e) {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                 }
               }
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
      ),
    );
  }
}
