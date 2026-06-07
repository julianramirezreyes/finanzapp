import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Dialog that pays down a single credit-card debt from the vault debt panel.
///
/// It lets the user pick a SOURCE (cash) account and an amount, then records
/// the payment keyed to the card via [vaultCardId]. On success it pops with
/// `true` so the caller can invalidate the owner-account debt summary.
class PayDebtDialog extends ConsumerStatefulWidget {
  const PayDebtDialog({
    super.key,
    required this.vaultCardId,
    required this.cardTitle,
    required this.cardDebt,
  });

  final String vaultCardId;
  final String cardTitle;
  final double cardDebt;

  @override
  ConsumerState<PayDebtDialog> createState() => _PayDebtDialogState();
}

class _PayDebtDialogState extends ConsumerState<PayDebtDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedAccountId;
  bool _submitting = false;

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
              widget.cardTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Deuda actual: ${currency.format(widget.cardDebt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Selecciona la cuenta desde la cual harás el pago:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            accountsAsync.when(
              data: (accounts) {
                // No se puede pagar una tarjeta desde otra cuenta de crédito.
                final sourceAccounts = accounts
                    .where((a) => a.type != 'credit')
                    .toList();

                if (sourceAccounts.isEmpty) {
                  return const Text(
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
                      items: sourceAccounts.map((account) {
                        return DropdownMenuItem<String>(
                          value: account.id,
                          child: Text(
                            '${account.name} '
                            '(${currency.format(account.balance)})',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Error cargando cuentas: $e',
                style: const TextStyle(color: AppColors.expense),
              ),
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
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_selectedAccountId != null && !_submitting) ? _pay : null,
          child: _submitting
              ? const SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pagar'),
        ),
      ],
    );
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(transactionRepositoryProvider)
          .payCreditCard(
            vaultCardId: widget.vaultCardId,
            amount: amount,
            accountId: _selectedAccountId!,
            date: DateTime.now(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
