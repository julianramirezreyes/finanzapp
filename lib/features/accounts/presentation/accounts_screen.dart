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
import 'package:intl/intl.dart';

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
                        onLongPress: (ctx) => _showPocketsDialog(ctx, ref, acc),
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

  void _showPocketsDialog(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PocketsDialog(account: account),
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
  final void Function(BuildContext context)? onLongPress;

  const _AccountTileWithPockets({
    required this.account,
    this.showDragHandle = false,
    this.onTap,
    this.onLongPress,
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
          onLongPress: onLongPress != null ? () => onLongPress!(context) : null,
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

// Dialog para gestionar bolsillos de una cuenta
class _PocketsDialog extends ConsumerWidget {
  final Account account;

  const _PocketsDialog({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocketsAsync = ref.watch(pocketsProvider(account.id));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.savings, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Text('Bolsillos: ${account.name}'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: pocketsAsync.when(
          data: (pockets) {
            if (pockets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sin bolsillos',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Agrega un bolsillo para separar dinero',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: pockets.length,
              itemBuilder: (context, index) {
                final pocket = pockets[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(
                        Icons.savings,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    title: Text(pocket.name),
                    subtitle: Text(currency.format(pocket.balance)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: AppColors.income,
                          ),
                          onPressed: () =>
                              _showAmountDialog(context, ref, pocket.id, true),
                          tooltip: 'Agregar',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.expense,
                          ),
                          onPressed: () =>
                              _showAmountDialog(context, ref, pocket.id, false),
                          tooltip: 'Sacar',
                        ),
                      ],
                    ),
                    onLongPress: () => _confirmDeletePocket(
                      context,
                      ref,
                      pocket.id,
                      pocket.name,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreatePocketDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Agregar Bolsillo'),
        ),
      ],
    );
  }

  void _showCreatePocketDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo Bolsillo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del bolsillo',
                hintText: 'ej: Ahorro Viaje',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: 'Balance inicial (opcional)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final initialBalance =
                  double.tryParse(balanceController.text) ?? 0;

              try {
                await ref
                    .read(pocketRepositoryProvider)
                    .createPocket(account.id, name, initialBalance);
                ref.invalidate(pocketsProvider(account.id));
                ref.invalidate(accountsListProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showAmountDialog(
    BuildContext context,
    WidgetRef ref,
    String pocketId,
    bool isDeposit,
  ) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isDeposit ? 'Agregar dinero' : 'Sacar dinero'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              try {
                if (isDeposit) {
                  await ref
                      .read(pocketRepositoryProvider)
                      .deposit(account.id, pocketId, amount);
                } else {
                  await ref
                      .read(pocketRepositoryProvider)
                      .withdraw(account.id, pocketId, amount);
                }
                ref.invalidate(pocketsProvider(account.id));
                ref.invalidate(accountsListProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isDeposit ? 'Agregar' : 'Sacar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePocket(
    BuildContext context,
    WidgetRef ref,
    String pocketId,
    String pocketName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar bolsillo'),
        content: Text('¿Eliminar "$pocketName"? Se perderá el saldo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () async {
              try {
                await ref
                    .read(pocketRepositoryProvider)
                    .deletePocket(account.id, pocketId);
                ref.invalidate(pocketsProvider(account.id));
                ref.invalidate(accountsListProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
