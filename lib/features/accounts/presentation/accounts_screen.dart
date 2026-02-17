import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash'; // Default valid type
    bool includeInNetWorth = true;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Cuenta'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Balance Inicial',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['cash', 'savings', 'credit', 'investment']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_translateAccountType(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Incluir en Patrimonio'),
                  value: includeInNetWorth,
                  onChanged: (val) {
                    setState(() => includeInNetWorth = val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text;
              final balance = double.tryParse(balanceController.text) ?? 0.0;

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext); // Close dialog first
                try {
                  await ref
                      .read(accountRepositoryProvider)
                      .createAccount(
                        name,
                        selectedType,
                        'USD',
                        balance,
                        includeInNetWorth: includeInNetWorth,
                      );
                  // Refresh provider after successful creation
                  ref.invalidate(accountsListProvider);
                } catch (e) {
                  // Handle error if needed, maybe show snackbar if context is mounted
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear cuenta: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
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
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuentas')),
      body: accountsAsync.when(
        data: (accounts) => accounts.isEmpty
            ? const Center(child: Text("Aún no tienes cuentas."))
            : ReorderableListView.builder(
                itemCount: accounts.length,
                onReorder: (oldIndex, newIndex) {
                  // Reorder logic
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = accounts.removeAt(oldIndex);
                  accounts.insert(newIndex, item);

                  // Update Backend
                  ref.read(accountRepositoryProvider).reorderAccounts(accounts);
                },
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return Container(
                    key: ValueKey(acc.id),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_translateAccountType(acc.type)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${acc.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showEditDialog(context, ref, acc),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Account account) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = account.type;
    bool includeInNetWorth = account.includeInNetWorth;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Cuenta'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: ['cash', 'savings', 'credit', 'investment']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_translateAccountType(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Incluir en Patrimonio'),
                  value: includeInNetWorth,
                  onChanged: (val) {
                    setState(() => includeInNetWorth = val);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Bóveda'),
            style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VaultScreen(
                    accountId: account.id,
                    accountName: account.name,
                  ),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text;

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);
                try {
                  final updatedAccount = Account(
                    id: account.id,
                    name: name,
                    type: selectedType,
                    balance: account.balance,
                    currency: account.currency,
                    includeInNetWorth: includeInNetWorth,
                    displayOrder: account.displayOrder,
                  );

                  await ref
                      .read(accountRepositoryProvider)
                      .updateAccount(updatedAccount);
                  ref.invalidate(accountsListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
