import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/data/household_snapshot_repository.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:finanzapp_v2/features/household/domain/household_snapshot.dart';
import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

final householdSnapshotProvider = FutureProvider.family
    .autoDispose<
      Map<String, dynamic>,
      ({String householdId, int year, int month})
    >((ref, params) async {
      return ref
          .watch(householdSnapshotRepositoryProvider)
          .getSnapshot(params.householdId, params.year, params.month);
    });

class HouseholdHistoryScreen extends ConsumerStatefulWidget {
  final Household household;

  const HouseholdHistoryScreen({super.key, required this.household});

  @override
  ConsumerState<HouseholdHistoryScreen> createState() =>
      _HouseholdHistoryScreenState();
}

class _HouseholdHistoryScreenState
    extends ConsumerState<HouseholdHistoryScreen> {
  late DateTime _selectedDate;
  bool isSettling = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
  }

  Future<void> _syncSnapshot() async {
    try {
      await ref
          .read(householdSnapshotRepositoryProvider)
          .syncSnapshot(
            widget.household.id,
            _selectedDate.year,
            _selectedDate.month,
          );
      ref.invalidate(householdSnapshotProvider);
      ref.invalidate(periodsListProvider(widget.household.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos cargados/actualizados correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al sincronizar: $e')));
      }
    }
  }

  Future<void> _clearSnapshot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Limpiar historial del mes?"),
        content: const Text(
          "Esto borra TODO el historial copia (editable) de este mes y lo deja en cero.\n\nNo borra tu historial personal.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text("Limpiar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(householdSnapshotRepositoryProvider)
          .clearSnapshot(
            widget.household.id,
            _selectedDate.year,
            _selectedDate.month,
          );

      ref.invalidate(householdSnapshotProvider);
      ref.invalidate(periodsListProvider(widget.household.id));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Historial limpiado")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _executeSettlement(String periodId) async {
    setState(() => isSettling = true);
    try {
      await ref
          .read(periodRepositoryProvider)
          .executeSettlement(widget.household.id, periodId);

      ref.invalidate(periodsListProvider(widget.household.id));
      ref.invalidate(
        settlementProvider((
          householdId: widget.household.id,
          periodId: periodId,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Estado de mes actualizado")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isSettling = false);
    }
  }

  Future<void> _editItem(HouseholdItem item) async {
    final amountController = TextEditingController(
      text: item.amount.toInt().toString(),
    );
    final descController = TextEditingController(text: item.description ?? '');

    final didUpdate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(
          "Editar ${item.type == 'income' ? 'Ingreso' : 'Gasto'}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Valor",
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancelar",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (didUpdate != true) return;

    try {
      final newAmount = double.tryParse(amountController.text) ?? item.amount;
      await ref
          .read(householdSnapshotRepositoryProvider)
          .updateItem(item.id, newAmount, descController.text, item.isExcluded);
      ref.invalidate(householdSnapshotProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text("¿Eliminar del Historial?"),
        content: const Text(
          "Esta acción solo afecta el historial compartido de este mes. \n\nEl registro original en tu cuenta personal NO se borrará.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(householdSnapshotRepositoryProvider).deleteItem(itemId);
      ref.invalidate(householdSnapshotProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _showSplitConfig(BuildContext context, BudgetConfig currentConfig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SplitConfigSheet(
        initialConfig: currentConfig,
        onSave: (newConfig) {
          Navigator.pop(ctx);
          _updateConfig(newConfig);
        },
      ),
    );
  }

  Future<void> _updateConfig(BudgetConfig newConfig) async {
    try {
      if (!mounted) return;
      await ref.read(budgetConfigRepositoryProvider).upsertConfig(newConfig);

      ref.invalidate(
        budgetConfigProvider((
          type: 'household',
          householdId: widget.household.id,
        )),
      );
      ref.invalidate(periodsListProvider(widget.household.id));
      ref.invalidate(settlementProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración actualizada")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al actualizar: $e")));
      }
    }
  }

  void _showInvitationDialog(BuildContext context, String code) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text("Invitar a tu Pareja"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ingresa el correo de tu pareja para enviarle una invitación directa:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    hintText: "pareja@ejemplo.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.inputRadius,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) return;

                            setDialogState(() => isLoading = true);
                            try {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .inviteMember(widget.household.id, email);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "¡Invitación enviada con éxito!",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setDialogState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Enviar Invitación"),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.subtleFill(),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "O comparte este código:",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: SelectableText(
                          code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: Icon(Icons.copy, size: 18),
                label: const Text("Copiar Código"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Código copiado")),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String?>(
          future: ref
              .read(dioProvider)
              .get('/users/me')
              .then((r) => r.data['id'] as String?),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const AlertDialog(
                content: Text("Failed to load user info"),
              );
            }

            final currentUserId = snapshot.data!;
            final isUserA = widget.household.userAId == currentUserId;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              title: Row(
                children: [
                  Icon(Icons.people, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text("Gestionar Miembros"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text(widget.household.userAEmail),
                    subtitle: const Text("Administrador"),
                    trailing: isUserA
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Tú",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (widget.household.userBEmail != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: context.stateFill(AppColors.savings),
                        child: Icon(Icons.person, color: AppColors.savings),
                      ),
                      title: Text(widget.household.userBEmail!),
                      subtitle: const Text("Miembro"),
                      trailing: IconButton(
                        icon: Icon(
                          isUserA
                              ? Icons.remove_circle
                              : (widget.household.userBId == currentUserId
                                    ? Icons.exit_to_app
                                    : Icons.info),
                          color: AppColors.expense,
                        ),
                        onPressed: () async {
                          if (isUserA) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                ),
                                title: const Text("¿Eliminar Miembro?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    widget.household.userBId!,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          } else if (widget.household.userBId ==
                              currentUserId) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                ),
                                title: const Text("¿Salir del Hogar?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text("Salir"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(householdRepositoryProvider)
                                  .removeMember(
                                    widget.household.id,
                                    currentUserId,
                                  );
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        _showInvitationDialog(context, widget.household.id);
                      },
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Invitar Pareja",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    "Cupo disponible",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(
      householdSnapshotProvider((
        householdId: widget.household.id,
        year: _selectedDate.year,
        month: _selectedDate.month,
      )),
    );

    final periodsAsync = ref.watch(periodsListProvider(widget.household.id));
    final userId = ref.watch(userProvider)?.id;

    final budgetConfigAsync = ref.watch(
      budgetConfigProvider((
        type: 'household',
        householdId: widget.household.id,
      )),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Finanzas del Hogar"),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: "Miembros",
            onPressed: _showMembersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
            onPressed: () {
              ref.invalidate(householdSnapshotProvider);
              ref.invalidate(periodsListProvider(widget.household.id));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MonthButton(
                  icon: Icons.chevron_left,
                  onPressed: () => _changeMonth(-1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  ),
                  child: Text(
                    DateFormat.yMMMM(
                      'es_CO',
                    ).format(_selectedDate).toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                _MonthButton(
                  icon: Icons.chevron_right,
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: snapshotAsync.when(
              data: (data) {
                final items = data['items'] as List<HouseholdItem>;

                double incomeA = 0;
                double incomeB = 0;
                double expenseA = 0;
                double expenseB = 0;

                for (var item in items) {
                  if (item.isExcluded) continue;

                  if (item.type == 'income') {
                    if (item.userId == widget.household.userAId) {
                      incomeA += item.amount;
                    } else {
                      incomeB += item.amount;
                    }
                  } else {
                    if (item.userId == widget.household.userAId) {
                      expenseA += item.amount;
                    } else {
                      expenseB += item.amount;
                    }
                  }
                }

                final totalIncome = incomeA + incomeB;
                final totalExpenses = expenseA + expenseB;
                final balance = totalIncome - totalExpenses;

                double pctA = totalIncome > 0
                    ? (incomeA / totalIncome) * 100
                    : 0;
                double pctB = totalIncome > 0
                    ? (incomeB / totalIncome) * 100
                    : 0;

                double expPctA = totalExpenses > 0
                    ? (expenseA / totalExpenses) * 100
                    : 0;
                double expPctB = totalExpenses > 0
                    ? (expenseB / totalExpenses) * 100
                    : 0;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (budgetConfigAsync.value != null)
                      _SplitMethodSelector(
                        config: budgetConfigAsync.value!,
                        onChanged: (newMethod) {
                          final newConfig = budgetConfigAsync.value!.copyWith(
                            splitMethod: newMethod,
                          );
                          _updateConfig(newConfig);
                        },
                        onCustomTap: () =>
                            _showSplitConfig(context, budgetConfigAsync.value!),
                      ),
                    if (budgetConfigAsync.isLoading)
                      const LinearProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    _SummaryCard(
                      incomeA: incomeA,
                      incomeB: incomeB,
                      expenseA: expenseA,
                      expenseB: expenseB,
                      pctA: pctA,
                      pctB: pctB,
                      expPctA: expPctA,
                      expPctB: expPctB,
                      totalExpenses: totalExpenses,
                      balance: balance,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    periodsAsync.when(
                      data: (periods) {
                        final period = periods
                            .where(
                              (p) =>
                                  p.year == _selectedDate.year &&
                                  p.month == _selectedDate.month,
                            )
                            .firstOrNull;

                        if (period == null) {
                          return const SizedBox.shrink();
                        }

                        final isClosed = period.status == 'settled';

                        return Consumer(
                          builder: (context, ref, _) {
                            final settlementAsync = ref.watch(
                              settlementProvider((
                                householdId: widget.household.id,
                                periodId: period.id,
                              )),
                            );

                            return settlementAsync.when(
                              data: (settlement) {
                                final amIDebtor = settlement.debtorId == userId;
                                final amICreditor =
                                    settlement.creditorId == userId;

                                final displayBalance = isClosed
                                    ? 0.0
                                    : settlement.balance;

                                String msg = "¡Todo en paz y salvo!";
                                Color msgColor = AppColors.textMuted;

                                if (displayBalance > 0) {
                                  if (amIDebtor) {
                                    msg = "Debes ajustar a tu pareja";
                                    msgColor = AppColors.expense;
                                  } else if (amICreditor) {
                                    msg = "Tu pareja debe ajustarte";
                                    msgColor = AppColors.income;
                                  } else {
                                    msg = "Ajuste Pendiente";
                                  }
                                }

                                final currency = NumberFormat("#,##0", "es_CO");

                                return Container(
                                  margin: const EdgeInsets.only(
                                    top: AppSpacing.lg,
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: isClosed
                                        ? AppColors.textMuted.withValues(
                                            alpha: 0.1,
                                          )
                                        : context.stateFill(
                                            AppColors.investment,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius,
                                    ),
                                    border: Border.all(
                                      color: isClosed
                                          ? AppColors.textMuted.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.investment.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet,
                                            size: 18,
                                            color: isClosed
                                                ? AppColors.textMuted
                                                : AppColors.investment,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "LIQUIDACIÓN",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              fontSize: 12,
                                              color: isClosed
                                                  ? AppColors.textMuted
                                                  : AppColors.investment,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        msg,
                                        style: TextStyle(
                                          color: msgColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (displayBalance > 0 || isClosed) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          "\$ ${currency.format(displayBalance)}",
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: msgColor,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.lg),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton.icon(
                                          onPressed: isSettling
                                              ? null
                                              : () => _executeSettlement(
                                                  period.id,
                                                ),
                                          icon: isSettling
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Icon(
                                                  isClosed
                                                      ? Icons.lock_open
                                                      : Icons.lock_clock,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            isClosed
                                                ? "REABRIR MES"
                                                : "CERRAR MES",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isClosed
                                                ? AppColors.textMuted
                                                : AppColors.investment,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppSpacing.buttonRadius,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, s) => const SizedBox.shrink(),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_sync,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "HISTORIAL COPIA (Editable)",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _syncSnapshot,
                                  icon: const Icon(
                                    Icons.cloud_download,
                                    size: 18,
                                  ),
                                  label: const Text("Cargar Datos"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    side: BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.buttonRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _clearSnapshot,
                                  icon: const Icon(
                                    Icons.delete_sweep,
                                    size: 18,
                                  ),
                                  label: const Text("Limpiar"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    side: BorderSide(color: AppColors.expense),
                                    foregroundColor: AppColors.expense,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.buttonRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Al cargar, se copian los datos actuales. Modificar esta lista NO afecta el historial personal.",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.md,
                      ),
                      child: Text(
                        "Detalle de Movimientos",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.onSurface,
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              "No hay datos cargados para este mes.",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: _syncSnapshot,
                              icon: const Icon(Icons.cloud_download),
                              label: const Text("Cargar Datos Ahora"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.buttonRadius,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...items.map((item) {
                        final currency = NumberFormat("#,##0", "es_CO");
                        final ownerLabel = item.userId == null
                            ? 'Hogar'
                            : (item.userId == userId ? 'Tú' : 'Pareja');
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.cardRadius,
                            ),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: context.stateFill(
                                item.type == 'income'
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                              child: Icon(
                                item.type == 'income'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: item.type == 'income'
                                    ? AppColors.income
                                    : AppColors.expense,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.category ?? 'Sin categoría',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.description != null &&
                                    item.description!.isNotEmpty)
                                  Text(
                                    item.description!,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  "${DateFormat.yMMMd('es_CO').format(item.date)} • $ownerLabel",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "\$ ${currency.format(item.amount)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: item.type == 'income'
                                        ? AppColors.income
                                        : context.onSurface,
                                  ),
                                ),
                                if (!item.isExcluded) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppColors.info,
                                    ),
                                    onPressed: () => _editItem(item),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => _deleteItem(item.id),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.expense,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (e.toString().contains('404'))
                      Column(
                        children: [
                          const Text("Este mes no ha sido iniciado."),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            onPressed: _syncSnapshot,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text("Iniciar Historial"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "Error: $e",
                        style: TextStyle(color: AppColors.expense),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MonthButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double incomeA;
  final double incomeB;
  final double expenseA;
  final double expenseB;
  final double pctA;
  final double pctB;
  final double expPctA;
  final double expPctB;
  final double totalExpenses;
  final double balance;

  const _SummaryCard({
    required this.incomeA,
    required this.incomeB,
    required this.expenseA,
    required this.expenseB,
    required this.pctA,
    required this.pctB,
    required this.expPctA,
    required this.expPctB,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat("#,##0", "es_CO");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.surfaceDark, AppColors.surfaceVariantDark]
              : [AppColors.surfaceLight, AppColors.backgroundLight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "RESUMEN DEL MES",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: "Ingresos Tú (${pctA.toStringAsFixed(0)}%)",
                  value: incomeA,
                  color: AppColors.income,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              Expanded(
                child: _SummaryItem(
                  label: "Ingresos Pareja (${pctB.toStringAsFixed(0)}%)",
                  value: incomeB,
                  color: AppColors.investment,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: "Gastos Tú (${expPctA.toStringAsFixed(0)}%)",
                  value: expenseA,
                  color: AppColors.expense,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              Expanded(
                child: _SummaryItem(
                  label: "Gastos Pareja (${expPctB.toStringAsFixed(0)}%)",
                  value: expenseB,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: "Total Gastos",
                value: totalExpenses,
                color: AppColors.expense,
                isBold: true,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Balance Final",
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    "\$ ${currency.format(balance)}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color = Colors.black,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat("#,##0", "es_CO");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          "\$ ${currency.format(value)}",
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}

class _SplitMethodSelector extends StatelessWidget {
  final BudgetConfig config;
  final Function(String) onChanged;
  final VoidCallback onCustomTap;

  const _SplitMethodSelector({
    required this.config,
    required this.onChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.stateFill(AppColors.info),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                "MÉTODO DE DIVISIÓN: ${config.splitMethod.toUpperCase()}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MethodButton(
                  label: "50 / 50",
                  isSelected: config.splitMethod == 'equal',
                  onTap: () => onChanged('equal'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MethodButton(
                  label: "Proporcional",
                  isSelected: config.splitMethod == 'proportional',
                  onTap: () => onChanged('proportional'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MethodButton(
                  label: "Personalizado",
                  isSelected: config.splitMethod == 'custom',
                  onTap: () {
                    onChanged('custom');
                    onCustomTap();
                  },
                ),
              ),
            ],
          ),
          if (config.splitMethod == 'custom')
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tú: ${(config.customSplitA * 100).round()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Ajuste manual activado",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    "Pareja: ${(config.customSplitB * 100).round()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: isSelected ? AppColors.info : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.info : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SplitConfigSheet extends StatefulWidget {
  final BudgetConfig initialConfig;
  final Function(BudgetConfig) onSave;

  const _SplitConfigSheet({required this.initialConfig, required this.onSave});

  @override
  State<_SplitConfigSheet> createState() => _SplitConfigSheetState();
}

class _SplitConfigSheetState extends State<_SplitConfigSheet> {
  late String _method;
  late double _splitA;

  @override
  void initState() {
    super.initState();
    _method = widget.initialConfig.splitMethod;
    _splitA = widget.initialConfig.customSplitA;
    if (_splitA == 0 && _method == 'custom') _splitA = 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.stateFill(AppColors.info),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune, color: AppColors.info, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                "Configuración de Reparto",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Define cómo se dividirán los gastos compartidos este mes.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tú (A)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        Text(
                          "${(_splitA * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.swap_horiz,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Pareja (B)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.savings,
                          ),
                        ),
                        Text(
                          "${((1 - _splitA) * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.info,
                    inactiveTrackColor: context.stateFill(AppColors.savings),
                    thumbColor: AppColors.info,
                    overlayColor: AppColors.info.withValues(alpha: 0.2),
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: _splitA,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (val) => setState(() => _splitA = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final newConfig = widget.initialConfig.copyWith(
                  splitMethod: 'custom',
                  customSplitA: _splitA,
                  customSplitB: 1 - _splitA,
                );
                widget.onSave(newConfig);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: const Text(
                "Guardar Configuración",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
