import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_with_pockets_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cuentas')),
      body: accountsAsync.when(
        data: (accounts) => accounts.isEmpty
            ? EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Sin cuentas',
                subtitle: 'Agrega tu primera cuenta para comenzar',
                actionLabel: 'Agregar Cuenta',
                onAction: () => _showCreateDialog(context, ref),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: accounts.length,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = accounts.removeAt(oldIndex);
                  accounts.insert(newIndex, item);
                  ref.read(accountRepositoryProvider).reorderAccounts(accounts);
                },
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return FadeSlideTransition(
                    key: ValueKey(acc.id),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AccountTileWithPockets(
                        account: acc,
                        showDragHandle: true,
                        onTap: () => _showEditDialog(context, ref, acc),
                      ),
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

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash';
    bool includeInNetWorth = true;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Cuenta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Balance Inicial',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cuenta',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ['cash', 'savings', 'credit', 'investment']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getAccountIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(_translateAccountType(type)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: const Text('Incluir en Patrimonio'),
                value: includeInNetWorth,
                onChanged: (val) {
                  includeInNetWorth = val;
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final balance = double.tryParse(balanceController.text) ?? 0.0;

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);
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
                  ref.invalidate(accountsListProvider);
                } catch (e) {
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

  void _showEditDialog(BuildContext context, WidgetRef ref, Account account) {
    final nameController = TextEditingController(text: account.name);
    String selectedType = account.type;
    bool includeInNetWorth = account.includeInNetWorth;
    int? cutoffDay = account.cutoffDay;
    final cutoffController = TextEditingController(
      text: cutoffDay?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Cuenta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cuenta',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ['cash', 'savings', 'credit', 'investment']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getAccountIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(_translateAccountType(type)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Mostrar campo de fecha de corte solo para cuentas de crédito
              if (selectedType == 'credit') ...[
                TextField(
                  controller: cutoffController,
                  decoration: const InputDecoration(
                    labelText: 'Día de corte (1-31)',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'Ej: 20',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final day = int.tryParse(value);
                    if (day != null && day >= 1 && day <= 31) {
                      cutoffDay = day;
                    } else if (value.isEmpty) {
                      cutoffDay = null;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SwitchListTile(
                title: const Text('Incluir en Patrimonio'),
                value: includeInNetWorth,
                onChanged: (val) {
                  includeInNetWorth = val;
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('Bóveda'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Eliminar cuenta'),
                  content: const Text(
                    '¿Seguro que deseas eliminar esta cuenta?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.expense,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;
              try {
                await ref
                    .read(accountRepositoryProvider)
                    .deleteAccount(account.id);
                ref.invalidate(accountsListProvider);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Eliminar'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
                    cutoffDay: selectedType == 'credit' ? cutoffDay : null,
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

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'checking':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

// Widget que muestra la cuenta con sus bolsillos
class _AccountTileWithPockets extends ConsumerWidget {
  final Account account;
  final bool showDragHandle;
  final VoidCallback? onTap;

  const _AccountTileWithPockets({
    required this.account,
    this.showDragHandle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocketsAsync = ref.watch(pocketsProvider(account.id));

    return pocketsAsync.when(
      data: (pockets) {
        final pocketsTotal = pockets.fold<double>(
          0,
          (sum, p) => sum + p.balance,
        );
        final totalValue = account.balance + pocketsTotal;

        return AccountWithPocketsTile(
          name: account.name,
          type: account.type,
          balance: account.balance,
          totalValue: totalValue,
          pocketsCount: pockets.length,
          pocketsTotal: pocketsTotal,
          showDragHandle: showDragHandle,
          onTap: onTap,
        );
      },
      loading: () => AccountTile(
        name: account.name,
        type: account.type,
        balance: account.balance,
        showDragHandle: showDragHandle,
        onTap: onTap,
      ),
      error: (e, s) => AccountTile(
        name: account.name,
        type: account.type,
        balance: account.balance,
        showDragHandle: showDragHandle,
        onTap: onTap,
      ),
    );
  }
}
