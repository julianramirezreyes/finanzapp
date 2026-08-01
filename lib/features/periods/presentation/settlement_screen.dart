import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/loading_indicator.dart';
import 'package:finanzapp_v2/features/periods/presentation/settlement_presentation.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  final String householdId;
  final Period period;

  const SettlementScreen({
    super.key,
    required this.householdId,
    required this.period,
  });

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  bool isExecuting = false;

  Future<void> _executeSettlement() async {
    setState(() => isExecuting = true);
    try {
      await ref
          .read(periodRepositoryProvider)
          .executeSettlement(widget.householdId, widget.period.id);
      ref.invalidate(periodsListProvider(widget.householdId));
      ref.invalidate(
        settlementProvider((
          householdId: widget.householdId,
          periodId: widget.period.id,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Periodo Cerrado Exitosamente!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlementAsync = ref.watch(
      settlementProvider((
        householdId: widget.householdId,
        periodId: widget.period.id,
      )),
    );
    final userId = ref.watch(userProvider)?.id;
    final currency = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Cierre ${widget.period.month}/${widget.period.year}"),
      ),
      body: settlementAsync.when(
        data: (settlement) {
          final direction = settlementDirection(
            balance: settlement.balance,
            debtorId: settlement.debtorId,
            creditorId: settlement.creditorId,
            currentUserId: userId,
          );
          final amIDebtor = direction == SettlementDirection.debtor;
          final amICreditor = direction == SettlementDirection.creditor;

          String message = "¡Todo a paz y salvo!";
          Color color = AppColors.textSecondary;

          if (settlement.balance > 0) {
            if (amIDebtor) {
              message = "Debes ${currency.format(settlement.balance)}";
              color = AppColors.expense;
            } else if (amICreditor) {
              message = "Te deben ${currency.format(settlement.balance)}";
              color = AppColors.income;
            } else {
              message =
                  "Deudor debe a Acreedor ${currency.format(settlement.balance)}";
              color = AppColors.info;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  style: AppCardStyle.elevated,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          amIDebtor
                              ? Icons.arrow_upward
                              : amICreditor
                              ? Icons.arrow_downward
                              : Icons.check_circle,
                          size: 48,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gasto Total del Hogar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currency.format(settlement.totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle de Liquidación',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDetailRow(
                        context,
                        'Pagado por Ti',
                        currency.format(settlement.paidByA),
                        Icons.person_outline,
                        AppColors.primary,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildDetailRow(
                        context,
                        'Pagado por tu Pareja',
                        currency.format(settlement.paidByB),
                        Icons.person,
                        AppColors.info,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildDetailRow(
                        context,
                        contributionLabel(
                          'Tu Parte',
                          settlement.shareA,
                          settlement.totalAmount,
                        ),
                        currency.format(settlement.shareA),
                        Icons.calculate,
                        AppColors.savings,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildDetailRow(
                        context,
                        contributionLabel(
                          'Parte de tu Pareja',
                          settlement.shareB,
                          settlement.totalAmount,
                        ),
                        currency.format(settlement.shareB),
                        Icons.calculate_outlined,
                        AppColors.investment,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (widget.period.status != 'settled')
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isExecuting ? null : _executeSettlement,
                      child: isExecuting
                          ? const LoadingIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline),
                                SizedBox(width: 8),
                                Text(
                                  'CERRAR PERIODO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Periodo Cerrado',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
