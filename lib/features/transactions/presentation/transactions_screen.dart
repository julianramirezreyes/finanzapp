import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: transactionsAsync.when(
        data: (transactions) => transactions.isEmpty
            ? const Center(child: Text("Aún no tienes movimientos."))
            : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  // Basic formatting
                  // Ideally use Internationalization for currencies/dates
                  return ListTile(
                    leading: Icon(
                      tx.type == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: tx.type == 'income' ? Colors.green : Colors.red,
                    ),
                    title: Text(tx.category),
                    subtitle: Text(
                      tx.description.isNotEmpty
                          ? tx.description
                          : 'Sin descripción',
                    ),
                    trailing: Text(
                      '\$${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.type == 'income' ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
