import 'dart:convert';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/pocket.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:intl/intl.dart';

class VaultScreen extends ConsumerStatefulWidget {
  final String accountId;
  final String accountName;

  const VaultScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  List<String>? _savedOrder;

  String get _orderKey => 'vault_order_${widget.accountId}';

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_orderKey);
    if (!mounted) return;
    setState(() {
      _savedOrder = ids;
    });
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _VaultItemDialog(accountId: widget.accountId),
    );
  }

  List<dynamic> _applySavedOrder(List<dynamic> items) {
    final order = _savedOrder;
    if (order == null || order.isEmpty) return items;

    final byId = <String, dynamic>{
      for (final item in items) item.id as String: item,
    };
    final ordered = <dynamic>[];
    for (final id in order) {
      final item = byId.remove(id);
      if (item != null) ordered.add(item);
    }
    ordered.addAll(byId.values);
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(vaultItemsProvider(widget.accountId));
    final debtAsync = ref.watch(vaultDebtSummaryProvider(widget.accountId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Bóveda: ${widget.accountName}')),
      body: itemsAsync.when(
        data: (items) {
          final creditCards = items
              .where((i) => i.isCard && i.cardType == 'credit')
              .toList();
          final hasCreditCards = creditCards.isNotEmpty;

          if (items.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (hasCreditCards) _buildDebtPanel(debtAsync, isDark),
                  EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Bóveda vacía',
                    subtitle: 'Guarda información sensible de tus cuentas',
                    actionLabel: 'Agregar Ítem',
                    onAction: () => _showAddItemDialog(context),
                  ),
                ],
              ),
            );
          }

          final orderedItems = _applySavedOrder(items);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Sección de bolsillos primero
              _buildPocketsSection(),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              if (hasCreditCards) _buildDebtPanel(debtAsync, isDark),

              const SizedBox(height: AppSpacing.lg),

              // Lista de items (tarjetas/cuentas)
              ...orderedItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return FadeSlideTransition(
                  key: ValueKey(item.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _VaultItemCard(
                      item: item,
                      accountId: widget.accountId,
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtPanel(
    AsyncValue<List<Map<String, dynamic>>> debtAsync,
    bool isDark,
  ) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return debtAsync.when(
      data: (debtList) {
        if (debtList.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalDebt = debtList.fold<double>(
          0,
          (sum, d) => sum + ((d['total_debt'] as num?)?.toDouble() ?? 0),
        );
        final monthDebt = debtList.fold<double>(
          0,
          (sum, d) => sum + ((d['month_debt'] as num?)?.toDouble() ?? 0),
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Resumen de Deuda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDebtItem(
                    'Deuda Total',
                    currency.format(totalDebt),
                    AppColors.warning,
                  ),
                  _buildDebtItem(
                    'Este Mes',
                    currency.format(monthDebt),
                    AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Por Tarjeta',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...debtList.map((debt) {
                final cardTitle = debt['card_title'] as String? ?? 'Unknown';
                final cardDebt = (debt['total_debt'] as num?)?.toDouble() ?? 0;
                final cardMonthDebt =
                    (debt['month_debt'] as num?)?.toDouble() ?? 0;
                final cutoffDays = debt['cutoff_days'] as List<dynamic>? ?? [];
                final daysUntilCutoff = debt['days_until_cutoff'] as int? ?? 0;
                final installments = debt['installments'] as int? ?? 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (installments > 1)
                              Text(
                                '$installments cuotas',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.info,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(cardDebt),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Mes: ${currency.format(cardMonthDebt)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.info,
                            ),
                          ),
                          if (cutoffDays.isNotEmpty)
                            Text(
                              '$daysUntilCutoff días',
                              style: TextStyle(
                                fontSize: 10,
                                color: daysUntilCutoff < 5
                                    ? AppColors.expense
                                    : AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDebtItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPocketsSection() {
    final pocketsAsync = ref.watch(pocketsProvider(widget.accountId));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bolsillos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.income),
              onPressed: () => _showCreatePocketDialog(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        pocketsAsync.when(
          data: (pockets) {
            if (pockets.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sin bolsillos aún',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: pockets.map((pocket) {
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
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              _showEditPocketDialog(context, pocket),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.expense,
                          ),
                          onPressed: () => _confirmDeletePocket(
                            context,
                            pocket.id,
                            pocket.name,
                          ),
                          tooltip: 'Eliminar',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.income,
                          ),
                          onPressed: () =>
                              _showAmountDialog(context, pocket.id, true),
                          tooltip: 'Agregar',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.expense,
                          ),
                          onPressed: () =>
                              _showAmountDialog(context, pocket.id, false),
                          tooltip: 'Sacar',
                        ),
                      ],
                    ),
                    onLongPress: () =>
                        _confirmDeletePocket(context, pocket.id, pocket.name),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _showCreatePocketDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Bolsillo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final balance = double.tryParse(balanceController.text) ?? 0;
              if (name.isEmpty) return;

              try {
                await ref
                    .read(pocketRepositoryProvider)
                    .createPocket(widget.accountId, name, balance);
                ref.invalidate(pocketsProvider(widget.accountId));
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    String pocketId,
    bool isDeposit,
  ) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeposit ? 'Agregar' : 'Sacar'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
                      .deposit(widget.accountId, pocketId, amount);
                } else {
                  await ref
                      .read(pocketRepositoryProvider)
                      .withdraw(widget.accountId, pocketId, amount);
                }
                ref.invalidate(pocketsProvider(widget.accountId));
                ref.invalidate(accountsListProvider);
                ref.invalidate(dashboardProvider);
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showEditPocketDialog(BuildContext context, Pocket pocket) {
    final nameController = TextEditingController(text: pocket.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Bolsillo'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Nombre del bolsillo',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              try {
                await ref
                    .read(pocketRepositoryProvider)
                    .updatePocket(widget.accountId, pocket.id, newName);
                ref.invalidate(pocketsProvider(widget.accountId));
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePocket(
    BuildContext context,
    String pocketId,
    String pocketName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Bolsillo'),
        content: Text('¿Eliminar "$pocketName"? Se perderá el saldo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              try {
                await ref
                    .read(pocketRepositoryProvider)
                    .deletePocket(widget.accountId, pocketId);
                ref.invalidate(pocketsProvider(widget.accountId));
                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _VaultItemDialog extends ConsumerStatefulWidget {
  final String accountId;
  const _VaultItemDialog({required this.accountId});

  @override
  ConsumerState<_VaultItemDialog> createState() => _VaultItemDialogState();
}

class _VaultItemDialogState extends ConsumerState<_VaultItemDialog> {
  bool _isCard = true;
  String _cardType = 'debit';
  final _titleController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _accHolderController = TextEditingController();
  final _accTypeController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _cutoffDay1Controller = TextEditingController();
  final _cutoffDay2Controller = TextEditingController();
  late int _installments;

  @override
  void initState() {
    super.initState();
    _installments = 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _accHolderController.dispose();
    _accTypeController.dispose();
    _accNumberController.dispose();
    _cutoffDay1Controller.dispose();
    _cutoffDay2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Ítem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Tarjeta'),
                  icon: Icon(Icons.credit_card),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Cuenta'),
                  icon: Icon(Icons.account_balance),
                ),
              ],
              selected: {_isCard},
              onSelectionChanged: (value) {
                setState(() => _isCard = value.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isCard) ..._buildCardFields() else ..._buildAccountFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  List<Widget> _buildCardFields() {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Alias (ej. Visa Oro)',
          prefixIcon: Icon(Icons.label_outline),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Débito'),
            selected: _cardType == 'debit',
            onSelected: (selected) {
              if (selected) setState(() => _cardType = 'debit');
            },
          ),
          ChoiceChip(
            label: const Text('Crédito'),
            selected: _cardType == 'credit',
            onSelected: (selected) {
              if (selected) setState(() => _cardType = 'credit');
            },
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _cardHolderController,
        decoration: const InputDecoration(labelText: 'Nombre Titular'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _cardNumberController,
        decoration: const InputDecoration(labelText: 'Número de Tarjeta'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cardExpiryController,
              decoration: const InputDecoration(labelText: 'Exp (MM/YY)'),
              keyboardType: TextInputType.datetime,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _cardCvvController,
              decoration: const InputDecoration(labelText: 'CVV'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ),
        ],
      ),
      if (_cardType == 'credit') ...[
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Fecha de Corte (opcional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cutoffDay1Controller,
                decoration: const InputDecoration(
                  labelText: 'Corte 1 (1-31)',
                  hintText: 'ej. 10',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _cutoffDay2Controller,
                decoration: const InputDecoration(
                  labelText: 'Corte 2 (opcional)',
                  hintText: 'ej. 25',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Cuotas por defecto: '),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<int>(
              value: _installments,
              items: List.generate(24, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _installments = v ?? 1),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildAccountFields() {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Banco / Alias',
          prefixIcon: Icon(Icons.account_balance),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accHolderController,
        decoration: const InputDecoration(labelText: 'Nombre Titular'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accTypeController,
        decoration: const InputDecoration(labelText: 'Tipo (Ahorro/Corriente)'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accNumberController,
        decoration: const InputDecoration(labelText: 'Número de Cuenta'),
      ),
    ];
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Map<String, dynamic> dataMap = {};
    if (_isCard) {
      dataMap = {
        'holder': _cardHolderController.text,
        'number': _cardNumberController.text,
        'expiry': _cardExpiryController.text,
        'cvv': _cardCvvController.text,
        'card_type': _cardType,
      };
      if (_cardType == 'credit') {
        final cutoffDays = <int>[];
        if (_cutoffDay1Controller.text.isNotEmpty) {
          final day = int.tryParse(_cutoffDay1Controller.text);
          if (day != null && day >= 1 && day <= 31) cutoffDays.add(day);
        }
        if (_cutoffDay2Controller.text.isNotEmpty) {
          final day = int.tryParse(_cutoffDay2Controller.text);
          if (day != null && day >= 1 && day <= 31) cutoffDays.add(day);
        }
        if (cutoffDays.isNotEmpty) {
          dataMap['cutoff_days'] = cutoffDays;
        }
        dataMap['installments'] = _installments;
        dataMap['total_debt'] = 0.0;
      }
    } else {
      dataMap = {
        'holder': _accHolderController.text,
        'type': _accTypeController.text,
        'number': _accNumberController.text,
      };
    }

    try {
      final jsonStr = jsonEncode(dataMap);
      await ref
          .read(vaultRepositoryProvider)
          .createVaultItem(widget.accountId, title, jsonStr, _isCard);
      ref.invalidate(vaultItemsProvider(widget.accountId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

// Dialog para editar un VaultItem
class _VaultItemEditDialog extends ConsumerStatefulWidget {
  final String accountId;
  final dynamic item;

  const _VaultItemEditDialog({required this.accountId, required this.item});

  @override
  ConsumerState<_VaultItemEditDialog> createState() =>
      _VaultItemEditDialogState();
}

class _VaultItemEditDialogState extends ConsumerState<_VaultItemEditDialog> {
  late bool _isCard;
  late String _cardType;
  late final TextEditingController _titleController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _cardHolderController;
  late final TextEditingController _cardExpiryController;
  late final TextEditingController _cardCvvController;
  late final TextEditingController _accHolderController;
  late final TextEditingController _accTypeController;
  late final TextEditingController _accNumberController;
  late final TextEditingController _cutoffDay1Controller;
  late final TextEditingController _cutoffDay2Controller;
  late int _installments;

  @override
  void initState() {
    super.initState();
    _isCard = widget.item.isCard;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(widget.item.data);
    } catch (_) {
      data = {};
    }

    _titleController = TextEditingController(text: widget.item.title);
    _cardNumberController = TextEditingController(text: data['number'] ?? '');
    _cardHolderController = TextEditingController(text: data['holder'] ?? '');
    _cardExpiryController = TextEditingController(text: data['expiry'] ?? '');
    _cardCvvController = TextEditingController(text: data['cvv'] ?? '');
    _accHolderController = TextEditingController(text: data['holder'] ?? '');
    _accTypeController = TextEditingController(text: data['type'] ?? '');
    _accNumberController = TextEditingController(text: data['number'] ?? '');
    _cardType = data['card_type'] ?? 'debit';

    final cutoffDays = data['cutoff_days'] as List<dynamic>? ?? [];
    _cutoffDay1Controller = TextEditingController(
      text: cutoffDays.isNotEmpty ? cutoffDays[0].toString() : '',
    );
    _cutoffDay2Controller = TextEditingController(
      text: cutoffDays.length > 1 ? cutoffDays[1].toString() : '',
    );
    _installments = (data['installments'] as num?)?.toInt() ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _accHolderController.dispose();
    _accTypeController.dispose();
    _accNumberController.dispose();
    _cutoffDay1Controller.dispose();
    _cutoffDay2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Ítem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Tarjeta'),
                  icon: Icon(Icons.credit_card),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Cuenta'),
                  icon: Icon(Icons.account_balance),
                ),
              ],
              selected: {_isCard},
              onSelectionChanged: (value) {
                setState(() => _isCard = value.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isCard) ..._buildCardFields() else ..._buildAccountFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  List<Widget> _buildCardFields() {
    final isCredit = _cardType == 'credit';
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Alias (ej. Visa Oro)',
          prefixIcon: Icon(Icons.label_outline),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Débito'),
            selected: _cardType == 'debit',
            onSelected: (selected) {
              if (selected) setState(() => _cardType = 'debit');
            },
          ),
          ChoiceChip(
            label: const Text('Crédito'),
            selected: _cardType == 'credit',
            onSelected: (selected) {
              if (selected) setState(() => _cardType = 'credit');
            },
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _cardHolderController,
        decoration: const InputDecoration(labelText: 'Nombre Titular'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _cardNumberController,
        decoration: const InputDecoration(labelText: 'Número de Tarjeta'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cardExpiryController,
              decoration: const InputDecoration(labelText: 'Exp (MM/YY)'),
              keyboardType: TextInputType.datetime,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: _cardCvvController,
              decoration: const InputDecoration(labelText: 'CVV'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ),
        ],
      ),
      if (isCredit) ...[
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Fecha de Corte (opcional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cutoffDay1Controller,
                decoration: const InputDecoration(
                  labelText: 'Corte 1 (1-31)',
                  hintText: 'ej. 10',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _cutoffDay2Controller,
                decoration: const InputDecoration(
                  labelText: 'Corte 2 (opcional)',
                  hintText: 'ej. 25',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Cuotas por defecto: '),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<int>(
              value: _installments,
              items: List.generate(24, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _installments = v ?? 1),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildAccountFields() {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Banco / Alias',
          prefixIcon: Icon(Icons.account_balance),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accHolderController,
        decoration: const InputDecoration(labelText: 'Nombre Titular'),
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accTypeController,
        decoration: const InputDecoration(labelText: 'Tipo (Ahorro/Corriente)'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _accNumberController,
        decoration: const InputDecoration(labelText: 'Número de Cuenta'),
      ),
    ];
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Map<String, dynamic> dataMap = {};
    if (_isCard) {
      dataMap = {
        'holder': _cardHolderController.text,
        'number': _cardNumberController.text,
        'expiry': _cardExpiryController.text,
        'cvv': _cardCvvController.text,
        'card_type': _cardType,
      };
      if (_cardType == 'credit') {
        final cutoffDays = <int>[];
        if (_cutoffDay1Controller.text.isNotEmpty) {
          final day = int.tryParse(_cutoffDay1Controller.text);
          if (day != null && day >= 1 && day <= 31) cutoffDays.add(day);
        }
        if (_cutoffDay2Controller.text.isNotEmpty) {
          final day = int.tryParse(_cutoffDay2Controller.text);
          if (day != null && day >= 1 && day <= 31) cutoffDays.add(day);
        }
        if (cutoffDays.isNotEmpty) {
          dataMap['cutoff_days'] = cutoffDays;
        }
        dataMap['installments'] = _installments;
      }
    } else {
      dataMap = {
        'holder': _accHolderController.text,
        'type': _accTypeController.text,
        'number': _accNumberController.text,
      };
    }

    try {
      final jsonStr = jsonEncode(dataMap);
      await ref
          .read(vaultRepositoryProvider)
          .updateVaultItem(
            widget.accountId,
            widget.item.id,
            title,
            jsonStr,
            _isCard,
          );
      ref.invalidate(vaultItemsProvider(widget.accountId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

class _VaultItemCard extends ConsumerStatefulWidget {
  final dynamic item;
  final String accountId;

  const _VaultItemCard({required this.item, required this.accountId});

  @override
  ConsumerState<_VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends ConsumerState<_VaultItemCard> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(item.data);
    } catch (_) {
      data = {'raw': item.data};
    }

    return AppCard(
      style: AppCardStyle.elevated,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Icon(
            item.isCard ? Icons.credit_card : Icons.account_balance,
            color: AppColors.primary,
          ),
        ),
        title: Text(item.title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          item.isCard ? 'Tarjeta' : 'Cuenta Vinculada',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ),
            const Icon(Icons.drag_handle, color: AppColors.textMuted),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                if (item.isCard) ...[
                  _buildDetailRow("Titular", data['holder']),
                  _buildDetailRow(
                    "Número",
                    data['number'],
                    isSensitive: true,
                    copyable: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          "Vence",
                          data['expiry'],
                          isSensitive: true,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          "CVV",
                          data['cvv'],
                          isSensitive: true,
                          copyable: true,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildDetailRow("Titular", data['holder']),
                  _buildDetailRow("Tipo", data['type']),
                  _buildDetailRow(
                    "Número",
                    data['number'],
                    isSensitive: true,
                    copyable: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context, item),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.info,
                        size: 20,
                      ),
                      label: const Text(
                        'Editar',
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    TextButton.icon(
                      onPressed: () =>
                          _confirmDelete(context, widget.accountId, item.id),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.expense,
                        size: 20,
                      ),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isSensitive = false,
    bool copyable = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final displayValue = (isSensitive && _isObscured) ? '•••• ••••' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                displayValue,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (copyable && (!isSensitive || !_isObscured))
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Copiado"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String accountId,
    String itemId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar ítem"),
        content: const Text("¿Estás seguro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(vaultRepositoryProvider)
          .deleteVaultItem(accountId, itemId);
      ref.invalidate(vaultItemsProvider(accountId));
    }
  }

  void _showEditDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) =>
          _VaultItemEditDialog(accountId: widget.accountId, item: item),
    );
  }
}

// Dialog para pagar tarjeta de crédito
class _PayCardDialog extends ConsumerStatefulWidget {
  final String accountId;
  final String accountName;

  const _PayCardDialog({required this.accountId, required this.accountName});

  @override
  ConsumerState<_PayCardDialog> createState() => _PayCardDialogState();
}

class _PayCardDialogState extends ConsumerState<_PayCardDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Pagar Tarjeta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona la cuenta desde la cual harás el pago:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            accountsAsync.when(
              data: (accounts) {
                // Filtrar cuentas que no sean de crédito (no podemos pagar desde la misma tarjeta)
                final nonCreditAccounts = accounts
                    .where((a) => a.type != 'credit')
                    .toList();

                if (nonCreditAccounts.isEmpty) {
                  return Text(
                    'No hay cuentas disponibles para realizar el pago',
                    style: TextStyle(color: AppColors.warning),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAccountId,
                      isExpanded: true,
                      hint: const Text('Seleccionar cuenta'),
                      items: nonCreditAccounts.map((account) {
                        return DropdownMenuItem<String>(
                          value: account.id,
                          child: Text(
                            '${account.name} (${currency.format(account.balance)})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description),
              ),
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
          onPressed: _selectedAccountId != null ? _pay : null,
          child: const Text('Pagar'),
        ),
      ],
    );
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
      return;
    }

    try {
      await ref
          .read(transactionRepositoryProvider)
          .payCreditCard(
            creditCardAccountId: widget.accountId,
            amount: amount,
            accountId: _selectedAccountId!,
            date: DateTime.now(),
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago realizado correctamente')),
        );
        // Refresh debt summary
        ref.invalidate(debtSummaryProvider(widget.accountId));
        Navigator.pop(context);
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
