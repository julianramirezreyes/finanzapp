import 'package:finanzapp_v2/core/invalidation/data_invalidator.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:finanzapp_v2/shared/ui/dialogs/confirm_dialog.dart';

class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allRecurringPaymentsProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos Automáticos')),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return EmptyState(
              icon: Icons.autorenew_outlined,
              title: 'Sin pagos automáticos',
              subtitle:
                  'Configura pagos recurrentes para automatizar tus finanzas',
              actionLabel: 'Agregar Pago',
              onAction: () async {
                final accounts = accountsAsync.valueOrNull ?? const [];
                await _openUpsertDialog(
                  context: context,
                  ref: ref,
                  accounts: accounts,
                );
              },
            );
          }

          return ListView.builder(
            itemCount: payments.length,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final isDue = !payment.nextExecutionDate.isAfter(DateTime.now());

              return FadeSlideTransition(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.stateFill(
                              isDue ? AppColors.warning : AppColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          child: Icon(
                            Icons.autorenew,
                            color: isDue
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.description.isEmpty
                                    ? payment.category
                                    : payment.description,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Próximo: ${DateFormat.yMMMd().format(payment.nextExecutionDate)} • ${_translateFrequency(payment.frequency)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(payment.amount),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDue
                                    ? context.stateFill(AppColors.income)
                                    : context.subtleFill(),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.xs,
                                ),
                              ),
                              child: Text(
                                isDue ? 'Vence' : 'Programado',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isDue
                                          ? AppColors.income
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'execute') {
                              _confirmExecution(context, ref, payment);
                            } else if (value == 'edit') {
                              final accounts =
                                  accountsAsync.valueOrNull ?? const [];
                              _openUpsertDialog(
                                context: context,
                                ref: ref,
                                accounts: accounts,
                                existing: payment,
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(context, ref, payment);
                            }
                          },
                          itemBuilder: (context) => [
                            if (isDue)
                              const PopupMenuItem(
                                value: 'execute',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                      color: AppColors.income,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Ejecutar'),
                                  ],
                                ),
                              ),
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
                                    color: AppColors.expense,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: AppColors.expense),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final accounts = accountsAsync.valueOrNull ?? const [];
          await _openUpsertDialog(
            context: context,
            ref: ref,
            accounts: accounts,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmExecution(
    BuildContext context,
    WidgetRef ref,
    RecurringPayment payment,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Ejecutar Pago',
      message:
          '¿Confirmas el pago de ${payment.amount} para "${payment.description}"?',
      confirmText: 'Ejecutar',
      icon: Icons.play_arrow,
    );

    if (confirmed == true) {
      try {
        await ref.read(automationRepositoryProvider).executePayment(payment.id);
        // Executing a recurring payment posts a real transaction, so refresh the
        // full tx effect set (balances, history, budgets, snapshot). The two
        // automation lists are not part of any effect group, so keep invalidating
        // them explicitly here.
        invalidateAfterMutation(ref, scope: {DataMutation.txEffects});
        ref.invalidate(pendingPaymentsProvider);
        ref.invalidate(allRecurringPaymentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago ejecutado exitosamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  String _translateFrequency(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Semanal';
      case 'yearly':
        return 'Anual';
      case 'monthly':
      default:
        return 'Mensual';
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringPayment payment,
  ) async {
    final confirmed = await DeleteConfirmDialog.show(
      context,
      itemName: payment.description.isEmpty
          ? payment.category
          : payment.description,
    );

    if (confirmed == true) {
      try {
        await ref.read(automationRepositoryProvider).deletePayment(payment.id);
        ref.invalidate(allRecurringPaymentsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _openUpsertDialog({
    required BuildContext context,
    required WidgetRef ref,
    required List<Account> accounts,
    RecurringPayment? existing,
  }) async {
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crea una cuenta primero.')));
      return;
    }

    final isEditing = existing != null;
    String accountId = existing?.accountId ?? accounts.first.id;
    String contextValue = existing?.context ?? 'personal';
    String? householdId = existing?.householdId;
    String? budgetId = existing?.budgetId;
    String category = existing?.category ?? 'General';
    String description = existing?.description ?? '';
    String frequency = existing?.frequency ?? 'monthly';
    bool isAutoConfirm = existing?.isAutoConfirm ?? false;
    bool isActive = existing?.isActive ?? true;
    double amount = existing?.amount ?? 0;
    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime nextDate = existing?.nextExecutionDate ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Pago' : 'Nuevo Pago'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: contextValue,
                    decoration: const InputDecoration(labelText: 'Contexto'),
                    items: const [
                      DropdownMenuItem(
                        value: 'personal',
                        child: Text('Personal'),
                      ),
                      DropdownMenuItem(
                        value: 'household',
                        child: Text('Hogar'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        contextValue = v;
                        budgetId = null;
                        category = 'General';
                        householdId = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                    items: accounts
                        .map<DropdownMenuItem<String>>(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => accountId = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: amount == 0 ? '' : amount.toString(),
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                    onChanged: (v) => amount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: const [
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Mensual'),
                      ),
                      DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                      DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    ],
                    onChanged: (v) => setState(() => frequency = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                if (contextValue == 'household' && householdId == null) {
                  throw Exception('Debes tener un hogar configurado');
                }

                final payload = RecurringPayment(
                  id: existing?.id ?? '',
                  accountId: accountId,
                  context: contextValue,
                  householdId: householdId,
                  budgetId: budgetId,
                  category: category,
                  description: description,
                  amount: amount,
                  frequency: frequency,
                  startDate: startDate,
                  nextExecutionDate: nextDate,
                  isAutoConfirm: isAutoConfirm,
                  isActive: isActive,
                );

                if (isEditing) {
                  await ref
                      .read(automationRepositoryProvider)
                      .updatePayment(payload);
                } else {
                  await ref
                      .read(automationRepositoryProvider)
                      .createPayment(payload);
                }

                ref.invalidate(allRecurringPaymentsProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
