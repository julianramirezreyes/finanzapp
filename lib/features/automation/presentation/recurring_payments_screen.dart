import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Helper provider to fetch all payments (not just pending) - For Management
// We might need a new endpoint for this, but for now let's reuse pending or mock
// Actually, I missed adding a "Get All" endpoint in backend.
// For this MVP, I will just list "Pending" ones in this screen effectively acting as a "Due Soon" list
// Or I can quickly add GET /automation/payments to backend.
// Let's stick to the plan: "CRUD for managing these rules". I need GET /automation/payments.
// Since I can't easily jump back to backend code without switching context too much,
// I will implement the UI to show "Pending Executions" using the existing endpoint for now.
// If the user wants to see *future* ones, that's a nice to have.
// Wait, the USER said: "RecurringPaymentsScreen: CRUD for managing these rules".
// I should probably add GET /automation/payments (all) to backend.
// It's a quick addition.

// Let's implement the UI assuming I have it, or just show pending for now to satisfy the "Trigger" requirement.
// The user emphasis was on the "Trigger/Confirmation".

class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allRecurringPaymentsProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos Automáticos')),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: Text('No tienes pagos automáticos configurados.'),
            );
          }

          return ListView.builder(
            itemCount: payments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final isDue = !payment.nextExecutionDate.isAfter(DateTime.now());

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.autorenew)),
                  title: Text(
                    payment.description.isEmpty
                        ? payment.category
                        : payment.description,
                  ),
                  subtitle: Text(
                    'Próximo: ${DateFormat.yMMMd().format(payment.nextExecutionDate)}  •  ${_translateFrequency(payment.frequency)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormat.format(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (isDue)
                        IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onPressed: () =>
                              _confirmExecution(context, ref, payment),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final accounts = accountsAsync.valueOrNull ?? const [];
                          await _openUpsertDialog(
                            context: context,
                            ref: ref,
                            accounts: accounts,
                            existing: payment,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, payment),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final accounts = accountsAsync.valueOrNull ?? const [];
          await _openUpsertDialog(
            context: context,
            ref: ref,
            accounts: accounts,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmExecution(
    BuildContext context,
    WidgetRef ref,
    RecurringPayment payment,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ejecutar Pago'),
        content: Text(
          '¿Confirmas el pago de ${payment.amount} para "${payment.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(automationRepositoryProvider)
                    .executePayment(payment.id);
                ref.invalidate(pendingPaymentsProvider);
                ref.invalidate(allRecurringPaymentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pago ejecutado exitosamente'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Ejecutar'),
          ),
        ],
      ),
    );
  }

  String _translateFrequency(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Semanal';
      case 'yearly':
        return 'Anual';
      case 'monthly':
      default:
        return 'Mensual';
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringPayment payment,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Pago Automático'),
        content: Text(
          '¿Seguro que deseas eliminar "${payment.description.isEmpty ? payment.category : payment.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(automationRepositoryProvider)
                    .deletePayment(payment.id);
                ref.invalidate(allRecurringPaymentsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpsertDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<Account> accounts,
    RecurringPayment? existing,
  }) async {
    if (accounts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crea una cuenta primero.')),
        );
      }
      return;
    }

    final isEditing = existing != null;

    String accountId = existing?.accountId ?? accounts.first.id;
    String contextValue = existing?.context ?? 'personal';
    String? householdId = existing?.householdId;
    String? budgetId = existing?.budgetId;
    String category = existing?.category ?? 'General';
    String? selectionValue = budgetId != null ? 'budget:$budgetId' : 'static:$category';
    String description = existing?.description ?? '';
    String frequency = existing?.frequency ?? 'monthly';
    bool isAutoConfirm = existing?.isAutoConfirm ?? false;
    bool isActive = existing?.isActive ?? true;
    double amount = existing?.amount ?? 0;
    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime nextDate = existing?.nextExecutionDate ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Pago Automático' : 'Nuevo Pago Automático'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: contextValue,
                    decoration: const InputDecoration(labelText: 'Contexto'),
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
                      if (v == null) return;
                      setState(() {
                        contextValue = v;
                        // reset selection to force user to re-pick from correct budget list
                        selectionValue = null;
                        budgetId = null;
                        category = 'General';
                        householdId = null;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                    items: accounts
                        .map<DropdownMenuItem<String>>(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => accountId = v!),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final householdAsync = ref.watch(householdProvider);
                      final String? currentHouseholdId = householdAsync.valueOrNull?.id;
                      final String? targetHouseholdId =
                          contextValue == 'household' ? currentHouseholdId : null;

                      final budgetsAsync =
                          ref.watch(budgetsListProvider(targetHouseholdId));

                      return budgetsAsync.when(
                        data: (budgets) {
                          final items = <DropdownMenuItem<String>>[];

                          for (final Budget b in budgets) {
                            items.add(
                              DropdownMenuItem(
                                value: 'budget:${b.id}',
                                child: Text(
                                  '🎯 ${b.category} (${b.isRecurrent ? 'Fijo' : 'Meta'})',
                                ),
                              ),
                            );
                          }

                          if (items.isEmpty) {
                            items.add(
                              const DropdownMenuItem(
                                value: 'static:General',
                                child: Text('General'),
                              ),
                            );
                          }

                          if (selectionValue == null ||
                              !items.any((i) => i.value == selectionValue)) {
                            selectionValue = items.first.value;
                          }

                          // keep derived values in sync
                          if (selectionValue != null &&
                              selectionValue!.startsWith('budget:')) {
                            budgetId = selectionValue!.split(':')[1];
                            final Budget selected = budgets.firstWhere(
                              (b) => b.id == budgetId,
                              orElse: () => budgets.first,
                            );
                            category = selected.category;
                          } else {
                            budgetId = null;
                            category = selectionValue!.split(':')[1];
                          }

                          if (contextValue == 'household') {
                            householdId = currentHouseholdId;
                          } else {
                            householdId = null;
                          }

                          return DropdownButtonFormField<String>(
                            key: ValueKey('budget_$contextValue'),
                            initialValue: selectionValue,
                            decoration: const InputDecoration(
                              labelText: 'Categoría / Meta',
                            ),
                            items: items,
                            onChanged: (v) => setState(() => selectionValue = v),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => Text('Error cargando metas: $e'),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: amount == 0 ? '' : amount.toString(),
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) return 'Monto inválido';
                      return null;
                    },
                    onChanged: (v) => amount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                      DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                      DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    ],
                    onChanged: (v) => setState(() => frequency = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha inicio'),
                    subtitle: Text(DateFormat.yMMMd().format(startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                          if (!isEditing) {
                            nextDate = picked;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Próxima ejecución'),
                    subtitle: Text(DateFormat.yMMMd().format(nextDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: nextDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() => nextDate = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-confirmar'),
                    value: isAutoConfirm,
                    onChanged: (v) => setState(() => isAutoConfirm = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activo'),
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                if (contextValue == 'household' && householdId == null) {
                  throw Exception('Debes tener un hogar configurado para usar contexto Hogar');
                }

                final payload = RecurringPayment(
                  id: existing?.id ?? '',
                  accountId: accountId,
                  context: contextValue,
                  householdId: householdId,
                  budgetId: budgetId,
                  category: category,
                  description: description,
                  amount: amount,
                  frequency: frequency,
                  startDate: startDate,
                  nextExecutionDate: nextDate,
                  isAutoConfirm: isAutoConfirm,
                  isActive: isActive,
                );

                if (isEditing) {
                  await ref
                      .read(automationRepositoryProvider)
                      .updatePayment(payload);
                } else {
                  await ref
                      .read(automationRepositoryProvider)
                      .createPayment(payload);
                }

                ref.invalidate(allRecurringPaymentsProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
