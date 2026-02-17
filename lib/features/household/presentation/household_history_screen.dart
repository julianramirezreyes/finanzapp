import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/data/household_snapshot_repository.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:finanzapp_v2/features/household/domain/household_snapshot.dart';
import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final householdSnapshotProvider = FutureProvider.family
    .autoDispose<
      Map<String, dynamic>,
      ({String householdId, int year, int month})
    >((ref, params) async {
      return ref
          .watch(householdSnapshotRepositoryProvider)
          .getSnapshot(params.householdId, params.year, params.month);
    });

class HouseholdHistoryScreen extends ConsumerStatefulWidget {
  final Household household;

  const HouseholdHistoryScreen({super.key, required this.household});

  @override
  ConsumerState<HouseholdHistoryScreen> createState() =>
      _HouseholdHistoryScreenState();
}

class _HouseholdHistoryScreenState
    extends ConsumerState<HouseholdHistoryScreen> {
  late DateTime _selectedDate;
  bool isSettling = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
  }

  Future<void> _syncSnapshot() async {
    try {
      await ref
          .read(householdSnapshotRepositoryProvider)
          .syncSnapshot(
            widget.household.id,
            _selectedDate.year,
            _selectedDate.month,
          );
      ref.invalidate(householdSnapshotProvider);
      ref.invalidate(periodsListProvider(widget.household.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos cargados/actualizados correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al sincronizar: $e')));
      }
    }
  }

  Future<void> _executeSettlement(String periodId) async {
    setState(() => isSettling = true);
    try {
      await ref
          .read(periodRepositoryProvider)
          .executeSettlement(widget.household.id, periodId);

      ref.invalidate(periodsListProvider(widget.household.id));
      ref.invalidate(
        settlementProvider((
          householdId: widget.household.id,
          periodId: periodId,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Mes cerrado exitosamente!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isSettling = false);
    }
  }

  Future<void> _editItem(HouseholdItem item) async {
    final amountController = TextEditingController(
      text: item.amount.toInt().toString(),
    );
    final descController = TextEditingController(text: item.description ?? '');

    final didUpdate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar ${item.type == 'income' ? 'Ingreso' : 'Gasto'}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Valor"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (didUpdate != true) return;

    try {
      final newAmount = double.tryParse(amountController.text) ?? item.amount;
      await ref
          .read(householdSnapshotRepositoryProvider)
          .updateItem(item.id, newAmount, descController.text, item.isExcluded);
      ref.invalidate(householdSnapshotProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar del Historial?"),
        content: const Text(
          "Esta acción solo afecta el historial compartido de este mes. \n\nEl registro original en tu cuenta personal NO se borrará.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(householdSnapshotRepositoryProvider).deleteItem(itemId);
      ref.invalidate(householdSnapshotProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  // ... (Rest of code)

  void _showSplitConfig(BuildContext context, BudgetConfig currentConfig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SplitConfigSheet(
        initialConfig: currentConfig,
        onSave: (newConfig) {
          Navigator.pop(ctx);
          _updateConfig(newConfig);
        },
      ),
    );
  }

  Future<void> _updateConfig(BudgetConfig newConfig) async {
    try {
      if (!mounted) return;
      await ref.read(budgetConfigRepositoryProvider).upsertConfig(newConfig);

      ref.invalidate(
        budgetConfigProvider((
          type: 'household',
          householdId: widget.household.id,
        )),
      );
      ref.invalidate(periodsListProvider(widget.household.id));
      ref.invalidate(settlementProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración actualizada")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al actualizar: $e")));
      }
    }
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String?>(
          future: ref
              .read(dioProvider)
              .get('/users/me')
              .then((r) => r.data['id'] as String?),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const AlertDialog(
                content: Text("Failed to load user info"),
              );
            }

            final currentUserId = snapshot.data!;
            final isUserA = widget.household.userAId == currentUserId;

            return AlertDialog(
              title: const Text("Gestionar Miembros"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(widget.household.userAEmail),
                    subtitle: const Text("Administrador"),
                    trailing: isUserA ? const Chip(label: Text("Tú")) : null,
                  ),
                  if (widget.household.userBEmail != null)
                    ListTile(
                      title: Text(widget.household.userBEmail!),
                      subtitle: const Text("Miembro"),
                      trailing: IconButton(
                        icon: Icon(
                          isUserA
                              ? Icons.remove_circle
                              : (widget.household.userBId == currentUserId
                                    ? Icons.exit_to_app
                                    : Icons.info),
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          if (isUserA) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("¿Eliminar Miembro?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    widget.household.userBId!,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          } else if (widget.household.userBId ==
                              currentUserId) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text("¿Salir del Hogar?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Salir"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    currentUserId,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    )
                  else
                    ListTile(
                      tileColor: Colors.grey.shade100,
                      title: const Text("Invitar Pareja"),
                      subtitle: const Text("Cupo disponible"),
                      leading: const Icon(Icons.person_add),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Usa el menú principal para invitar.",
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Snapshot Data
    final snapshotAsync = ref.watch(
      householdSnapshotProvider((
        householdId: widget.household.id,
        year: _selectedDate.year,
        month: _selectedDate.month,
      )),
    );

    // 2. Period/Settlement Data
    final periodsAsync = ref.watch(periodsListProvider(widget.household.id));
    final userId = ref.watch(userProvider)?.id;

    // 3. Budget Config Data
    final budgetConfigAsync = ref.watch(
      budgetConfigProvider((
        type: 'household',
        householdId: widget.household.id,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Finanzas del Hogar"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: "Miembros",
            onPressed: _showMembersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
            onPressed: () {
              ref.invalidate(householdSnapshotProvider);
              ref.invalidate(periodsListProvider(widget.household.id));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat.yMMMM('es_ES').format(_selectedDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: snapshotAsync.when(
              data: (data) {
                // final snapshot = data['snapshot'] as HouseholdSnapshot; // Unused
                final items = data['items'] as List<HouseholdItem>;

                // Calculate Totals Dynamically from Items
                double incomeA = 0;
                double incomeB = 0;
                double expenseA = 0;
                double expenseB = 0;

                for (var item in items) {
                  if (item.isExcluded) continue;

                  if (item.type == 'income') {
                    if (item.userId == widget.household.userAId) {
                      incomeA += item.amount;
                    } else {
                      incomeB += item.amount;
                    }
                  } else {
                    // Expenses
                    if (item.userId == widget.household.userAId) {
                      expenseA += item.amount;
                    } else {
                      expenseB += item.amount;
                    }
                  }
                }

                final totalIncome = incomeA + incomeB;
                final totalExpenses = expenseA + expenseB;
                final balance = totalIncome - totalExpenses;

                double pctA = totalIncome > 0
                    ? (incomeA / totalIncome) * 100
                    : 0;
                double pctB = totalIncome > 0
                    ? (incomeB / totalIncome) * 100
                    : 0;

                return ListView(
                  children: [
                    // 1. Split Method Selector
                    if (budgetConfigAsync.value != null)
                      _SplitMethodSelector(
                        config: budgetConfigAsync.value!,
                        onChanged: (newMethod) {
                          final newConfig = budgetConfigAsync.value!.copyWith(
                            splitMethod: newMethod,
                          );
                          _updateConfig(newConfig);
                        },
                        onCustomTap: () =>
                            _showSplitConfig(context, budgetConfigAsync.value!),
                      ),

                    if (budgetConfigAsync.isLoading)
                      const LinearProgressIndicator(),

                    // 2. Monthly Summary
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "RESUMEN DEL MES",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Incomes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label:
                                      "Ingresos Tú (${pctA.toStringAsFixed(0)}%)",
                                  value: incomeA,
                                  color: Colors.green,
                                ),
                                _SummaryItem(
                                  label:
                                      "Ingresos Pareja (${pctB.toStringAsFixed(0)}%)",
                                  value: incomeB,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // EXPENSES BREAKDOWN
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label: "Gastos Tú",
                                  value: expenseA,
                                  color: Colors.red.shade300,
                                ),
                                _SummaryItem(
                                  label: "Gastos Pareja",
                                  value: expenseB,
                                  color: Colors.red.shade300,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // TOTALS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label: "Total Gastos",
                                  value: totalExpenses,
                                  color: Colors.red,
                                  isBold: true,
                                ),
                                _SummaryItem(
                                  label: "Balance Final",
                                  value: balance,
                                  color: balance >= 0
                                      ? Colors.black
                                      : Colors.red,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Settlement / Closure Section
                    periodsAsync.when(
                      data: (periods) {
                        final period = periods
                            .where(
                              (p) =>
                                  p.year == _selectedDate.year &&
                                  p.month == _selectedDate.month,
                            )
                            .firstOrNull;

                        if (period == null) {
                          return const SizedBox.shrink();
                        }

                        final isClosed = period.status == 'settled';

                        return Consumer(
                          builder: (context, ref, _) {
                            final settlementAsync = ref.watch(
                              settlementProvider((
                                householdId: widget.household.id,
                                periodId: period.id,
                              )),
                            );

                            return settlementAsync.when(
                              data: (settlement) {
                                final amIDebtor = settlement.debtorId == userId;
                                final amICreditor =
                                    settlement.creditorId == userId;

                                String msg = "¡Todo en paz y salvo!";
                                Color msgColor = Colors.grey;

                                if (settlement.balance > 0) {
                                  if (amIDebtor) {
                                    msg = "Debes ajustar a tu pareja";
                                    msgColor = Colors.red;
                                  } else if (amICreditor) {
                                    msg = "Tu pareja debe ajustarte";
                                    msgColor = Colors.green;
                                  } else {
                                    msg = "Ajuste Pendiente";
                                  }
                                }

                                final currency = NumberFormat("#,##0", "es_CO");

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  color: isClosed
                                      ? Colors.grey.shade100
                                      : Colors.blue.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          "LIQUIDACIÓN",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: Colors.blueGrey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          msg,
                                          style: TextStyle(
                                            color: msgColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (settlement.balance > 0)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              "\$ ${currency.format(settlement.balance)}",
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: msgColor,
                                              ),
                                            ),
                                          ),

                                        const SizedBox(height: 12),
                                        if (!isClosed)
                                          ElevatedButton.icon(
                                            onPressed: isSettling
                                                ? null
                                                : () => _executeSettlement(
                                                    period.id,
                                                  ),
                                            icon: isSettling
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(Icons.lock_clock),
                                            label: const Text("CERRAR MES"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade700,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(
                                                double.infinity,
                                                40,
                                              ),
                                            ),
                                          )
                                        else
                                          const Chip(
                                            label: Text("MES CERRADO"),
                                            avatar: Icon(Icons.lock, size: 16),
                                            backgroundColor: Colors.white,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loading: () => const Center(
                                child: LinearProgressIndicator(),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // 4. Loading / Copy Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "HISTORIAL COPIA (Editable)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _syncSnapshot,
                                  icon: const Icon(
                                    Icons.cloud_download,
                                    size: 16,
                                  ),
                                  label: const Text("Cargar Datos"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Al cargar, se copian los datos actuales. Modificar esta lista NO afecta el historial personal.",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        "Detalle de Movimientos",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    if (items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No hay datos cargados para este mes.",
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _syncSnapshot,
                                child: const Text("Cargar Datos Ahora"),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...items.map((item) {
                        final currency = NumberFormat("#,##0", "es_CO");
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.type == 'income'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              item.type == 'income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: item.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(
                            item.category ?? 'Sin categoría',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description != null &&
                                  item.description!.isNotEmpty)
                                Text(item.description!),
                              Text(
                                DateFormat.yMMMd('es_ES').format(item.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "\$ ${currency.format(item.amount)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.type == 'income'
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                              if (!item.isExcluded) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editItem(item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => _deleteItem(item.id),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    if (e.toString().contains('404'))
                      Column(
                        children: [
                          const Text("Este mes no ha sido iniciado."),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _syncSnapshot,
                            child: const Text("Iniciar Historial"),
                          ),
                        ],
                      )
                    else
                      Text("Error: $e"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color = Colors.black,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat("#,##0", "es_CO");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "\$ ${currency.format(value)}",
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SplitMethodSelector extends StatelessWidget {
  final BudgetConfig config;
  final Function(String) onChanged;
  final VoidCallback onCustomTap;

  const _SplitMethodSelector({
    required this.config,
    required this.onChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "MÉTODO DE DIVISIÓN: ${config.splitMethod.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MethodButton(
                  label: "50 / 50",
                  isSelected: config.splitMethod == 'equal',
                  onTap: () => onChanged('equal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MethodButton(
                  label: "Proporcional",
                  isSelected: config.splitMethod == 'proportional',
                  onTap: () => onChanged('proportional'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MethodButton(
                  label: "Personalizado",
                  isSelected: config.splitMethod == 'custom',
                  onTap: () {
                    onChanged('custom');
                    onCustomTap();
                  },
                ),
              ),
            ],
          ),
          if (config.splitMethod == 'custom')
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tú: ${(config.customSplitA * 100).round()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      " Ajuste manual activado",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    "Pareja: ${(config.customSplitB * 100).round()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SplitConfigSheet extends StatefulWidget {
  final BudgetConfig initialConfig;
  final Function(BudgetConfig) onSave;

  const _SplitConfigSheet({required this.initialConfig, required this.onSave});

  @override
  State<_SplitConfigSheet> createState() => _SplitConfigSheetState();
}

class _SplitConfigSheetState extends State<_SplitConfigSheet> {
  late String _method;
  late double _splitA;

  @override
  void initState() {
    super.initState();
    _method = widget.initialConfig.splitMethod;
    _splitA = widget.initialConfig.customSplitA;
    if (_splitA == 0 && _method == 'custom') _splitA = 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Configuración de Reparto",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Define cómo se dividirán los gastos compartidos este mes.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Participación A (Tú): ${(_splitA * 100).toStringAsFixed(0)}%",
              ),
              Text(
                "Participación B (Pareja): ${((1 - _splitA) * 100).toStringAsFixed(0)}%",
              ),
            ],
          ),
          Slider(
            value: _splitA,
            min: 0,
            max: 1,
            divisions: 20,
            label: "${(_splitA * 100).round()}%",
            onChanged: (val) => setState(() => _splitA = val),
            activeColor: Colors.blue.shade700,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final newConfig = widget.initialConfig.copyWith(
                  splitMethod: 'custom',
                  customSplitA: _splitA,
                  customSplitB: 1 - _splitA,
                );
                widget.onSave(newConfig);
              },
              child: const Text("Guardar Configuración Personalizada"),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
