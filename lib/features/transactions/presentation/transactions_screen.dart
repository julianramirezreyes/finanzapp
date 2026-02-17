import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      personalHistoryProvider((
        month: _selectedDate.month,
        year: _selectedDate.year,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (summary) {
          final currency = NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Header
                Text(
                  DateFormat.yMMMM('es_ES').format(_selectedDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 16),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Ingresos",
                        summary.totalIncome,
                        Colors.green,
                        Icons.arrow_upward,
                        currency,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        "Gastos",
                        summary.totalExpense,
                        Colors.red,
                        Icons.arrow_downward,
                        currency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBalanceCard(summary.balance, currency),

                const SizedBox(height: 24),
                Text(
                  "Transacciones (${summary.count})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (summary.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text("No hay movimientos en este mes."),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.transactions.length,
                    itemBuilder: (context, index) {
                      final tMap =
                          summary.transactions[index] as Map<String, dynamic>;
                      final t = Transaction.fromJson(tMap);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.type == 'income'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              t.type == 'income'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: t.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            t.description.isNotEmpty
                                ? t.description
                                : t.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${DateFormat.MMMd('es_ES').format(t.date)} • ${t.category}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${t.type == 'income' ? '+' : '-'} ${currency.format(t.amount)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: t.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editTransaction(context, t);
                                  } else if (value == 'delete') {
                                    _deleteTransaction(context, t.id);
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction t) {
    context.push('/transactions/add', extra: t);
  }

  Future<void> _deleteTransaction(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Transacción"),
        content: const Text(
          "¿Estás seguro? Esta acción revertirá el saldo de tus cuentas.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
        // Refresh history
        ref.invalidate(personalHistoryProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transacción eliminada")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // Helper Widgets (Same as PersonalHistoryScreen)
  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    NumberFormat fmt,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            fmt.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, NumberFormat fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Balance Mensual",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
