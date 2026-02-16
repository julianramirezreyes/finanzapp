import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _type = 'expense'; // expense, income, transfer
  double _amount = 0;
  String _description = '';
  DateTime _date = DateTime.now();
  String _context = 'personal'; // personal, household
  String? _accountId;
  String? _destinationAccountId; // For transfers

  // Selection Logic for Category/Budget
  // Value format: "static:Name" or "budget:UUID"
  String? _selectionValue;

  // Categorías estáticas

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Transacción')),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text('Por favor, crea una cuenta primero.'),
            );
          }
          // Set default account if not set
          if (_accountId == null && accounts.isNotEmpty) {
            _accountId = accounts.first.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Selector (Segmented Button or Dropdown)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Gasto'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Ingreso'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text('Transferencia'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                        // Reset category based on type potentially
                        if (_type == 'transfer') {
                          _selectionValue = null;
                        }
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          if (_type == 'expense') {
                            return Colors.red.shade100;
                          }
                          if (_type == 'income') {
                            return Colors.green.shade100;
                          }
                          return Colors.blue.shade100;
                        }
                        return null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un monto';
                      }
                      final v = double.tryParse(value);
                      if (v == null || v <= 0) return 'Monto inválido';
                      return null;
                    },
                    onSaved: (value) => _amount = double.parse(value!),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSaved: (value) => _description = value ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Context & Date Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat.yMMMd('es_ES').format(_date),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_context),
                          initialValue: _context,
                          decoration: const InputDecoration(
                            labelText: 'Contexto',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'personal',
                              child: Text('Personal'),
                            ),
                            DropdownMenuItem(
                              value: 'household',
                              child: Text('Hogar'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _context = v!;
                              _selectionValue =
                                  null; // Reset category on context switch
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Category/Budget Selector
                  _buildCategorySelector(ref),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Account Selector
                  DropdownButtonFormField<String>(
                    key: ValueKey(_accountId),
                    initialValue: _accountId,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta',
                      helperText: 'Cuenta origen',
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${_translateAccountType(a.type)})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _accountId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),

                  // Destination Account (Only for Transfer)
                  if (_type == 'transfer') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_destinationAccountId),
                      initialValue: _destinationAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta Destino',
                        helperText: 'A donde envías el dinero',
                      ),
                      items: accounts
                          .where((a) => a.id != _accountId) // Exclude source
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (${_translateAccountType(a.type)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _destinationAccountId = v),
                      validator: (v) =>
                          _type == 'transfer' && v == null ? 'Requerido' : null,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _translateAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'savings':
        return 'Ahorros';
      case 'checking':
        return 'Corriente';
      case 'credit':
        return 'Crédito';
      case 'investment':
        return 'Inversión';
      default:
        return type;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Widget _buildCategorySelector(WidgetRef ref) {
    // Determine Target Household ID
    final householdAsync = ref.watch(householdProvider);
    final String? currentHouseholdId = householdAsync.valueOrNull?.id;
    final String? targetHouseholdId = _context == 'household'
        ? currentHouseholdId
        : null;

    // Fetch Budgets
    final budgetsAsync = ref.watch(budgetsListProvider(targetHouseholdId));

    return budgetsAsync.when(
      data: (budgets) {
        final List<DropdownMenuItem<String>> items = [];

        if (_type == 'income') {
          // For Income, give relevant static options
          items.add(
            const DropdownMenuItem(
              value: "static:Salario",
              child: Text("Salario"),
            ),
          );
          items.add(
            const DropdownMenuItem(
              value: "static:Honorarios",
              child: Text("Honorarios"),
            ),
          );
          items.add(
            const DropdownMenuItem(
              value: "static:Regalo",
              child: Text("Regalo"),
            ),
          );
          items.add(
            const DropdownMenuItem(
              value: "static:Inversión",
              child: Text("Rendimiento Inversión"),
            ),
          );
          items.add(
            const DropdownMenuItem(
              value: "static:Otros",
              child: Text("Otros Ingresos"),
            ),
          );
        } else {
          // For Expense AND Transfer: SHOW BUDGETS/GOALS
          // User asked to see categories/goals for transfers too.
          if (budgets.isNotEmpty) {
            for (var b in budgets) {
              items.add(
                DropdownMenuItem(
                  value: "budget:${b.id}",
                  child: Text(
                    "🎯 ${b.category} (${b.isRecurrent ? 'Fijo' : 'Meta'})",
                  ),
                ),
              );
            }
          }

          if (_type == 'transfer') {
            items.insert(
              0,
              const DropdownMenuItem(
                value: "static:Transferencia",
                child: Text("Transferencia General"),
              ),
            );
          }

          // Fallback only if items is empty (meaning no budgets/goals & no transfer default)
          if (items.isEmpty) {
            items.add(
              const DropdownMenuItem(
                value: "static:General",
                child: Text("General"),
              ),
            );
            items.add(
              const DropdownMenuItem(
                value: "static:Otros",
                child: Text("Otros Gastos"),
              ),
            );
          }
        }

        // Auto-select first if null or invalid
        if (_selectionValue == null ||
            !items.any((i) => i.value == _selectionValue)) {
          _selectionValue = items.first.value;
        }

        return InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Categoría / Meta',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey("cat_$_context$_type"),
              value: _selectionValue,
              isExpanded: true,
              isDense: true,
              items: items,
              onChanged: (v) => setState(() => _selectionValue = v),
            ),
          ),
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (e, s) => Text("Error cargando categorías: $e"),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Resolve Category and BudgetID
      String finalCategory = 'General';
      String? finalBudgetId;

      if (_selectionValue != null) {
        if (_selectionValue!.startsWith("budget:")) {
          finalBudgetId = _selectionValue!.split(":")[1];
          final householdAsync = ref.read(householdProvider);
          final String? targetAuthId = _context == 'household'
              ? householdAsync.valueOrNull?.id
              : null;
          final budgets = await ref.read(
            budgetsListProvider(targetAuthId).future,
          );
          final budget = budgets.firstWhere(
            (b) => b.id == finalBudgetId,
            orElse: () => Budget(
              id: '',
              userId: '',
              category: 'General',
              limitAmount: 0,
              period: '',
            ),
          );
          finalCategory = budget.category;
        } else {
          finalCategory = _selectionValue!.split(":")[1];
        }
      } else {
        finalCategory = _type == 'transfer' ? 'Transferencia' : 'General';
      }

      // Resolve HouseholdID
      String? finalHouseholdId;
      if (_context == 'household') {
        final householdAsync = ref.read(householdProvider);
        if (householdAsync.value != null) {
          finalHouseholdId = householdAsync.value!.id;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes un hogar configurado.')),
            );
          }
          return;
        }
      }

      try {
        await ref
            .read(transactionRepositoryProvider)
            .createTransaction(
              accountId: _accountId!,
              amount: _amount,
              type: _type,
              category: finalCategory,
              description: _description,
              date: _date,
              context: _context,
              householdId: finalHouseholdId,
              budgetId: finalBudgetId,
              destinationAccountId: _destinationAccountId,
            );

        // Refresh providers
        ref.invalidate(transactionsListProvider);
        ref.invalidate(accountsListProvider);
        // Also invalidate budget lists as spent amount might change (if we tracked it there, but we calculate it on fly)
        // Ensure budgets screen updates
        if (_context == 'household') {
          ref.invalidate(budgetsListProvider(finalHouseholdId));
        } else {
          ref.invalidate(budgetsListProvider(null));
        }

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
