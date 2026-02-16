import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // Refresh everything to reflect closed status
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Cierre ${widget.period.month}/${widget.period.year}"),
      ),
      body: settlementAsync.when(
        data: (settlement) {
          final amIDebtor = settlement.debtorId == userId;
          final amICreditor = settlement.creditorId == userId;

          String message = "¡Todo a paz y salvo!";
          Color color = Colors.grey;

          if (settlement.balance > 0) {
            if (amIDebtor) {
              message = "Debes \$${settlement.balance.toStringAsFixed(2)}";
              color = Colors.red;
            } else if (amICreditor) {
              message = "Te deben \$${settlement.balance.toStringAsFixed(2)}";
              color = Colors.green;
            } else {
              message =
                  "Deudor debe a Acreedor \$${settlement.balance.toStringAsFixed(2)}";
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: color.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Gasto Total del Hogar: \$${settlement.totalAmount.toStringAsFixed(2)}",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Detalle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Pagado por Usuario A"),
                  trailing: Text("\$${settlement.paidByA.toStringAsFixed(2)}"),
                ),
                ListTile(
                  title: const Text("Pagado por Usuario B"),
                  trailing: Text("\$${settlement.paidByB.toStringAsFixed(2)}"),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Parte Usuario A (50%)"),
                  trailing: Text("\$${settlement.shareA.toStringAsFixed(2)}"),
                ),
                ListTile(
                  title: const Text("Parte Usuario B (50%)"),
                  trailing: Text("\$${settlement.shareB.toStringAsFixed(2)}"),
                ),

                const Spacer(),

                if (widget.period.status != 'settled')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: isExecuting ? null : _executeSettlement,
                    child: isExecuting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CERRAR PERIODO Y LIQUIDAR",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                else
                  const Center(
                    child: Chip(
                      label: Text("Periodo Cerrado"),
                      backgroundColor: Colors.grey,
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
}
