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

class HouseholdBudgetTab extends ConsumerStatefulWidget {
  const HouseholdBudgetTab({super.key});

  @override
  ConsumerState<HouseholdBudgetTab> createState() => _HouseholdBudgetTabState();
}

class _HouseholdBudgetTabState extends ConsumerState<HouseholdBudgetTab> {
  // Local controllers for immediate UI feedback (debounce later if needed)
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

  void _initializeValues(BudgetConfig config) {
    if (_isInit) return;
    _incomeAController.text = config.incomeA.toStringAsFixed(0);
    _incomeBController.text = config.incomeB.toStringAsFixed(0);
    _pctExpense = config.pctExpense.toDouble();
    _pctSavings = config.pctSavings.toDouble();
    _pctInvestment = config.pctInvestment.toDouble();
    _isInit = true;
  }

  Future<void> _saveConfig(String householdId) async {
    final incomeA = double.tryParse(_incomeAController.text) ?? 0;
    final incomeB = double.tryParse(_incomeBController.text) ?? 0;

    final newConfig = BudgetConfig(
      id: '', // Service handles ID
      householdId: householdId,
      incomeA: incomeA,
      incomeB: incomeB,
      pctExpense: _pctExpense.round(),
      pctSavings: _pctSavings.round(),
      pctInvestment: _pctInvestment.round(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(budgetConfigRepositoryProvider).upsertConfig(newConfig);
      ref.invalidate(budgetConfigProvider); // Refresh
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
    final householdAsync = ref.watch(householdProvider);

    return householdAsync.when(
      data: (household) {
        if (household == null) {
          return const Center(child: Text("No tienes un hogar activo."));
        }

        final configAsync = ref.watch(
          budgetConfigProvider((type: 'household', householdId: household.id)),
        );

        return configAsync.when(
          data: (config) {
            _initializeValues(config);

            final totalPct = _pctExpense + _pctSavings + _pctInvestment;
            final isInvalid = totalPct != 100;
            final totalIncome =
                (double.tryParse(_incomeAController.text) ?? 0) +
                (double.tryParse(_incomeBController.text) ?? 0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INCOMES ---
                  const Text(
                    "Ingresos Proyectados (Mensual)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _incomeAController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Tu Ingreso",
                            border: OutlineInputBorder(),
                            prefixText: "\$",
                          ),
                          onChanged: (_) => setState(() {}), // Refresh total
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _incomeBController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Ingreso de tu pareja",
                            border: OutlineInputBorder(),
                            prefixText: "\$",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total Hogar: \$${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(totalIncome)}",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Divider(height: 32),

                  // --- DISTRIBUTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Distribución (%)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                    "Gastos",
                    _pctExpense,
                    Colors.red,
                    (v) => _updateDistribution('expense', v),
                  ),
                  _buildSlider(
                    "Ahorro",
                    _pctSavings,
                    Colors.blue,
                    (v) => _updateDistribution('savings', v),
                  ),
                  _buildSlider(
                    "Inversión",
                    _pctInvestment,
                    Colors.purple,
                    (v) => _updateDistribution('investment', v),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isInvalid
                          ? null
                          : () => _saveConfig(household.id),
                      child: const Text("Guardar Configuración"),
                    ),
                  ),

                  const Divider(height: 32),

                  // --- PREVIEW ---
                  _buildPreviewBar(totalIncome),

                  const SizedBox(height: 32),
                  // LIST OF GOALS
                  _buildGoalsSection(context, ref, household.id, totalIncome),
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
          "Disponibilidad Mensual",
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
                        "\$${(expenseAmt / 1000).toStringAsFixed(1)}k",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
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
                        "\$${(savingAmt / 1000).toStringAsFixed(1)}k",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
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
                        "\$${(investAmt / 1000).toStringAsFixed(1)}k",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendItem("Gastos", Colors.red),
            _LegendItem("Ahorro", Colors.blue),
            _LegendItem("Inversión", Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsSection(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    double totalIncome,
  ) {
    final budgetsAsync = ref.watch(budgetsListProvider(householdId));

    // Calculate ratio outside collection if
    final totalInc =
        (double.tryParse(_incomeAController.text) ?? 0) +
        (double.tryParse(_incomeBController.text) ?? 0);
    final ratio = totalInc > 0
        ? (double.tryParse(_incomeAController.text) ?? 0) / totalInc
        : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                "Metas y Gastos Fijos",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle),
              label: const Text("Agregar Meta/Gasto"),
              onPressed: () => _showAddGoalDialog(context, ref, householdId),
            ),
          ],
        ),
        budgetsAsync.when(
          data: (budgets) {
            // Calculate Usage
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
                // Allocation Summary
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
                        "No hay metas configuradas",
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
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = budgets.removeAt(oldIndex);
                      budgets.insert(newIndex, item);
                      ref
                          .read(budgetRepositoryProvider)
                          .reorderBudgets(budgets);
                    },
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return Container(
                        key: ValueKey(budget.id),
                        child: BudgetCard(
                          budget: budget,
                          currentAmount: budget.currentAmount,
                          showSplit: true,
                          splitRatio: ratio,
                          onTap: () => _showEditGoalDialog(
                            context,
                            ref,
                            budget,
                            householdId,
                          ),
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
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    // final remaining = total - used;

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
            "Usado: ${currency.format(used)} / ${currency.format(total)}",
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final monthsController = TextEditingController(text: '1');
    bool isRecurrent = true;
    String type = 'expense'; // expense, savings

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Meta / Gasto Fijo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text("Gasto")),
                    DropdownMenuItem(value: 'savings', child: Text("Ahorro")),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text("Inversión"),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                  decoration: const InputDecoration(labelText: "Tipo"),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre / Categoría',
                  ),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto Total / Mensual',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text("¿Es Gasto Fijo Mensual?"),
                  value: isRecurrent,
                  onChanged: (v) => setState(() => isRecurrent = v),
                ),
                if (!isRecurrent)
                  TextField(
                    controller: monthsController,
                    decoration: const InputDecoration(
                      labelText: 'Plazo (Meses)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = categoryController.text;
                final amount = double.tryParse(amountController.text) ?? 0;
                final months = int.tryParse(monthsController.text) ?? 1;

                if (category.isNotEmpty && amount > 0) {
                  try {
                    await ref
                        .read(budgetRepositoryProvider)
                        .createBudget(
                          householdId: householdId,
                          category: category,
                          amount: amount,
                          period: 'monthly', // default
                          type: type,
                          months: months,
                          isRecurrent: isRecurrent,
                        );
                    ref.invalidate(budgetsListProvider(householdId));
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    String householdId,
  ) {
    final categoryController = TextEditingController(text: budget.category);
    final amountController = TextEditingController(
      text: budget.limitAmount.toStringAsFixed(0),
    );
    final monthsController = TextEditingController(
      text: budget.months.toString(),
    );

    // State variables
    bool isRecurrent = budget.isRecurrent;
    String type = budget.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Editar Meta Hogar"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text("Gasto")),
                    DropdownMenuItem(value: 'savings', child: Text("Ahorro")),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text("Inversión"),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                  decoration: const InputDecoration(labelText: "Tipo"),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre / Categoría',
                  ),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto Total / Mensual',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text("¿Es Gasto Fijo Mensual?"),
                  value: isRecurrent,
                  onChanged: (v) => setState(() => isRecurrent = v),
                ),
                if (!isRecurrent)
                  TextField(
                    controller: monthsController,
                    decoration: const InputDecoration(
                      labelText: 'Plazo (Meses)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 12),
                if (budget.currentAmount > 0)
                  Text(
                    "Progreso actual: \$${budget.currentAmount.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
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
                  ref.invalidate(budgetsListProvider(householdId));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Eliminar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = categoryController.text;
                final amount = double.tryParse(amountController.text) ?? 0;
                final months = int.tryParse(monthsController.text) ?? 1;

                if (category.isNotEmpty && amount > 0) {
                  try {
                    final updatedBudget = Budget(
                      id: budget.id,
                      userId: budget.userId, // Keep original
                      category: category,
                      limitAmount: amount,
                      period: budget.period,
                      type: type,
                      months: months,
                      isRecurrent: isRecurrent,
                      icon: budget.icon,
                      color: budget.color,
                      targetAmount: budget.targetAmount,
                      targetDate: budget.targetDate,
                      currentAmount: budget.currentAmount,
                      displayOrder: budget.displayOrder,
                    );

                    await ref
                        .read(budgetRepositoryProvider)
                        .updateBudget(updatedBudget, householdId: householdId);
                    ref.invalidate(budgetsListProvider(householdId));
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
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

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
