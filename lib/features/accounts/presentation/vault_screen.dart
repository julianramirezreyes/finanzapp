import 'dart:convert';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _persistOrder(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKey, ids);
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

    return Scaffold(
      appBar: AppBar(title: Text('Bóveda: ${widget.accountName}')),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("La bóveda está vacía."),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar Ítem"),
                  ),
                ],
              ),
            );
          }

          final orderedItems = _applySavedOrder(items);

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderedItems.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final updated = List<dynamic>.from(orderedItems);
              final moved = updated.removeAt(oldIndex);
              updated.insert(newIndex, moved);
              await _persistOrder(
                updated.map((e) => e.id as String).toList(),
              );
              ref.invalidate(vaultItemsProvider(widget.accountId));
            },
            itemBuilder: (context, index) {
              final item = orderedItems[index];
              return _VaultItemCard(
                key: ValueKey(item.id),
                item: item,
                accountId: widget.accountId,
              );
            },
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
}

class _VaultItemDialog extends ConsumerStatefulWidget {
  final String accountId;
  const _VaultItemDialog({required this.accountId});

  @override
  ConsumerState<_VaultItemDialog> createState() => _VaultItemDialogState();
}

class _VaultItemDialogState extends ConsumerState<_VaultItemDialog> {
  bool _isCard = true;
  final _titleController = TextEditingController();

  // Card Fields
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController(); // MM/YY
  final _cardCvvController = TextEditingController();

  // Account Fields
  final _accHolderController = TextEditingController();
  final _accTypeController = TextEditingController();
  final _accNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Ítem en Bóveda'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text("Tarjeta"),
                    icon: Icon(Icons.credit_card),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text("Cuenta"),
                    icon: Icon(Icons.account_balance),
                  ),
                ],
                selected: {_isCard},
                onSelectionChanged: (value) {
                  setState(() => _isCard = value.first);
                },
              ),
            ),
            const Divider(),
            if (_isCard) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Alias (ej. Visa Oro)',
                  icon: Icon(Icons.credit_card),
                ),
              ),
              TextField(
                controller: _cardHolderController,
                decoration: const InputDecoration(labelText: 'Nombre Titular'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                ),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryController,
                      decoration: const InputDecoration(
                        labelText: 'Exp (MM/YY)',
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 16),
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
            ] else ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Banco / Alias',
                  icon: Icon(Icons.account_balance),
                ),
              ),
              TextField(
                controller: _accHolderController,
                decoration: const InputDecoration(labelText: 'Nombre Titular'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _accTypeController,
                decoration: const InputDecoration(
                  labelText: 'Tipo (Ahorro/Corriente)',
                ),
              ),
              TextField(
                controller: _accNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Cuenta',
                ),
                keyboardType: TextInputType.text, // Alphanumeric allowed
              ),
            ],
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    Map<String, String> dataMap = {};
    if (_isCard) {
      dataMap = {
        'holder': _cardHolderController.text,
        'number': _cardNumberController.text,
        'expiry': _cardExpiryController.text,
        'cvv': _cardCvvController.text,
      };
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
      ref.invalidate(
        vaultItemsProvider(widget.accountId),
      ); // Invalidate specific family
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
  final dynamic item; // VaultItem
  final String accountId;

  const _VaultItemCard({
    super.key,
    required this.item,
    required this.accountId,
  });

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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          item.isCard ? Icons.credit_card : Icons.account_balance,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.isCard ? 'Tarjeta' : 'Cuenta Vinculada'),
        trailing: IconButton(
          icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isObscured = !_isObscured),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, widget.accountId, item.id),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    label: const Text(
                      "Eliminar",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable && (!isSensitive || !_isObscured))
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
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
                        size: 14,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String accountId, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar ítem"),
        content: const Text("¿Estás seguro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(vaultRepositoryProvider)
                  .deleteVaultItem(accountId, itemId);
              ref.invalidate(vaultItemsProvider(accountId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
