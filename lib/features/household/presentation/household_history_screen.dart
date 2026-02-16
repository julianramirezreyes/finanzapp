import 'package:finanzapp_v2/features/household/data/household_snapshot_repository.dart';
import 'package:finanzapp_v2/features/household/domain/household_snapshot.dart';
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
  final String householdId;

  const HouseholdHistoryScreen({super.key, required this.householdId});

  @override
  ConsumerState<HouseholdHistoryScreen> createState() =>
      _HouseholdHistoryScreenState();
}

class _HouseholdHistoryScreenState
    extends ConsumerState<HouseholdHistoryScreen> {
  late DateTime _selectedDate;

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
            widget.householdId,
            _selectedDate.year,
            _selectedDate.month,
          );
      ref.invalidate(householdSnapshotProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización completada')),
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

  Future<void> _deleteItem(String itemId) async {
    // Show confirmation dialog explaining that personal record is NOT affected
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

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(
      householdSnapshotProvider((
        householdId: widget.householdId,
        year: _selectedDate.year,
        month: _selectedDate.month,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Hogar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sincronizar con Movimientos",
            onPressed: _syncSnapshot,
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
                final snapshot = data['snapshot'] as HouseholdSnapshot;
                final items = data['items'] as List<HouseholdItem>;

                final totalIncome =
                    snapshot.totalIncomeA + snapshot.totalIncomeB;
                double pctA = totalIncome > 0
                    ? (snapshot.totalIncomeA / totalIncome) * 100
                    : 0;
                double pctB = totalIncome > 0
                    ? (snapshot.totalIncomeB / totalIncome) * 100
                    : 0;

                return Column(
                  children: [
                    // Disclaimer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.amber.shade100,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Este historial es independiente. Editarlo NO afecta tus registros personales.",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label:
                                      "Ingresos A (${pctA.toStringAsFixed(0)}%)",
                                  value: snapshot.totalIncomeA,
                                  color: Colors.green,
                                ),
                                _SummaryItem(
                                  label:
                                      "Ingresos B (${pctB.toStringAsFixed(0)}%)",
                                  value: snapshot.totalIncomeB,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  label: "Gastos Compartidos",
                                  value: snapshot.totalExpenses,
                                  color: Colors.red,
                                ),
                                _SummaryItem(
                                  label: "Balance",
                                  value: snapshot.balance,
                                  color: snapshot.balance >= 0
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

                    const Divider(height: 1),

                    // Items List
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("No hay movimientos registrados."),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _syncSnapshot,
                                    child: const Text("Sincronizar Ahora"),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final currency = NumberFormat.currency(
                                  locale: 'es_CO',
                                  symbol: '\$',
                                  decimalDigits: 0,
                                );

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
                                  title: Text(item.category ?? 'Sin categoría'),
                                  subtitle: Text(item.description ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currency.format(item.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: item.type == 'income'
                                              ? Colors.green
                                              : Colors.black,
                                        ),
                                      ),
                                      if (!item.isExcluded)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => _deleteItem(item.id),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
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
                    // If 404, it means no snapshot exists yet for this month
                    if (e.toString().contains('404'))
                      Column(
                        children: [
                          const Text("Mes no sincronizado"),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _syncSnapshot,
                            child: const Text("Crear Snapshot"),
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
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          currency.format(value),
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
