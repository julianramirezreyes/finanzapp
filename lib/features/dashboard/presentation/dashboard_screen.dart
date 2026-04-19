import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart'
    show householdSnapshotProvider;
import 'package:finanzapp_v2/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/presentation/responsive_layout.dart';
import 'package:finanzapp_v2/shared/ui/widgets/balance_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/summary_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_with_pockets_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/action_chip.dart' as app_ui;
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuickActionsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  _QuickActionsNotifier() : super(const AsyncValue.loading()) {
    _loadFromStorage();
  }

  static const _storageKey = 'quick_actions_enabled';

  static const List<String> _defaultActions = [
    'Historial',
    'Metas',
    'Hogar',
    'Automático',
    'Activos',
    'Declaración',
  ];

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey);
    state = AsyncValue.data(
      (saved != null && saved.isNotEmpty)
          ? List<String>.from(saved)
          : List<String>.from(_defaultActions),
    );
  }

  void setActions(List<String> actions) {
    state = AsyncValue.data(List<String>.from(actions));
  }

  Future<void> persistActions(List<String> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, List<String>.from(actions));
  }
}

final quickActionsStateProvider =
    StateNotifierProvider<_QuickActionsNotifier, AsyncValue<List<String>>>((
      ref,
    ) {
      return _QuickActionsNotifier();
    });

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final quickActionsAsync = ref.watch(quickActionsStateProvider);

    ref.listen(pendingPaymentsProvider, (previous, next) {
      next.whenData((payments) {
        if (payments.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tienes ${payments.length} pagos automáticos pendientes.',
                  ),
                  action: SnackBarAction(
                    label: 'Ver',
                    onPressed: () => context.push('/automation'),
                  ),
                  duration: const Duration(seconds: 10),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      });
    });

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return ResponsiveLayout(
      mobileBody: Scaffold(
        appBar: AppBar(
          title: const Text('FinanzApp'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(dashboardProvider);
                ref.invalidate(accountsListProvider);
                ref.invalidate(transactionsListProvider);
                ref.invalidate(personalHistoryProvider);
                ref.invalidate(budgetsListProvider);
                ref.invalidate(householdProvider);
                ref.invalidate(householdSnapshotProvider);
                ref.invalidate(pendingPaymentsProvider);
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: dashboardAsync.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                FadeSlideTransition(
                  child: _buildBalanceCard(
                    context,
                    data.totalBalanceWithPockets,
                    currencyFormat,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideTransition(
                  index: 1,
                  child: _buildSummarySection(context, data, currencyFormat),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideTransition(
                  index: 2,
                  child: _buildQuickActionsSection(
                    context,
                    ref,
                    quickActionsAsync,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideTransition(
                  index: 3,
                  child: _buildAccountsSection(
                    context,
                    data,
                    currencyFormat,
                    ref,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.expense,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Error: $err', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 8
                : 8,
          ),
          child: FloatingActionButton(
            onPressed: () => context.push('/transactions/add'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
      desktopBody: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: 0,
              onDestinationSelected: (int index) {
                switch (index) {
                  case 0:
                    break;
                  case 1:
                    context.push('/household');
                    break;
                  case 2:
                    context.push('/budgets');
                    break;
                  case 3:
                    context.push('/transactions');
                    break;
                  case 4:
                    context.push('/accounts');
                    break;
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Resumen'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Hogar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: Text('Metas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('Historial'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_outlined),
                  selectedIcon: Icon(Icons.account_balance),
                  label: Text('Cuentas'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: dashboardAsync.when(
                data: (data) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  children: [
                    Text(
                      'Resumen Financiero',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.xl,
                      children: [
                        SizedBox(
                          width: 400,
                          child: _buildBalanceCard(
                            context,
                            data.totalBalanceWithPockets,
                            currencyFormat,
                          ),
                        ),
                        SizedBox(
                          width: 400,
                          child: _buildSummarySection(
                            context,
                            data,
                            currencyFormat,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Mis Cuentas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.lg,
                      children: data.accounts
                          .map(
                            (acc) => SizedBox(
                              width: 300,
                              child: AccountTile(
                                name: acc.name,
                                type: acc.type,
                                balance: acc.balance,
                                onTap: () => context.push(
                                  '/accounts/${acc.id}/vault',
                                  extra: {'name': acc.name},
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando dashboard...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (e, s) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    NumberFormat format,
  ) {
    return BalanceCard(
      label: 'Tu Patrimonio Neto',
      amount: balance,
      format: format,
      isPositive: balance >= 0,
      trailing: IconButton(
        icon: const Icon(Icons.visibility_off, color: Colors.white70),
        onPressed: () {},
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    DashboardData data,
    NumberFormat format,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del año ${DateTime.now().year}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            SummaryRow(
              items: [
                SummaryTileData(
                  title: 'Ingresos',
                  amount: data.yearlyIncome,
                  icon: Icons.arrow_upward_rounded,
                  type: SummaryTileType.income,
                  format: format,
                ),
                SummaryTileData(
                  title: 'Gastos',
                  amount: data.yearlyExpense,
                  icon: Icons.arrow_downward_rounded,
                  type: SummaryTileType.expense,
                  format: format,
                ),
                SummaryTileData(
                  title: 'Balance',
                  amount: data.yearlyBalance,
                  icon: data.yearlyBalance >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  type: data.yearlyBalance >= 0
                      ? SummaryTileType.income
                      : SummaryTileType.expense,
                  format: format,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<String>> quickActionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Accesos Rápidos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Personalizar',
              onPressed: () => _showQuickActionsConfig(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        quickActionsAsync.when(
          data: (enabledActions) {
            if (enabledActions.isEmpty) {
              return const Center(child: Text('No hay accesos visibles.'));
            }

            final allActions = [
              app_ui.ActionChipData(
                icon: Icons.history,
                label: 'Historial',
                onTap: () => context.push('/transactions'),
              ),
              app_ui.ActionChipData(
                icon: Icons.savings,
                label: 'Metas',
                onTap: () => context.push('/budgets'),
              ),
              app_ui.ActionChipData(
                icon: Icons.people,
                label: 'Hogar',
                onTap: () => context.push('/household'),
              ),
              app_ui.ActionChipData(
                icon: Icons.autorenew,
                label: 'Automático',
                onTap: () => context.push('/automation'),
              ),
              app_ui.ActionChipData(
                icon: Icons.account_balance,
                label: 'Activos',
                onTap: () => context.push('/assets'),
              ),
              app_ui.ActionChipData(
                icon: Icons.assignment,
                label: 'Declaración',
                onTap: () => context.push('/tax'),
              ),
            ];

            final visibleActions = allActions
                .where((a) => enabledActions.contains(a.label))
                .toList();

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: visibleActions
                  .map(
                    (action) => app_ui.AppActionChip(
                      icon: action.icon,
                      label: action.label,
                      onTap: action.onTap,
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(
    BuildContext context,
    DashboardData data,
    NumberFormat format,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Cuentas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => context.push('/accounts'),
              child: const Text('Administrar'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.accounts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Aún no tienes cuentas',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Agrega una cuenta para comenzar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...data.accounts.map((acc) {
            final pocketsTotal = data.pocketsTotals[acc.id] ?? 0.0;
            final pocketsCount = data.pocketsCounts[acc.id] ?? 0;
            final hasPockets = pocketsCount > 0;
            final totalValue = acc.balance + pocketsTotal;

            if (hasPockets) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AccountWithPocketsTile(
                  name: acc.name,
                  type: acc.type,
                  balance: acc.balance,
                  totalValue: totalValue,
                  pocketsCount: pocketsCount,
                  pocketsTotal: pocketsTotal,
                  onTap: () => context.push(
                    '/accounts/${acc.id}/vault',
                    extra: {'name': acc.name},
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AccountTile(
                name: acc.name,
                type: acc.type,
                balance: acc.balance,
                onTap: () => context.push(
                  '/accounts/${acc.id}/vault',
                  extra: {'name': acc.name},
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showQuickActionsConfig(BuildContext context, WidgetRef ref) {
    final currentActions = List<String>.from(
      ref.read(quickActionsStateProvider).value ??
          _QuickActionsNotifier._defaultActions,
    );
    final allLabels = [
      'Historial',
      'Metas',
      'Hogar',
      'Automático',
      'Activos',
      'Declaración',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Personalizar Accesos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allLabels.map((label) {
                    final isSelected = currentActions.contains(label);
                    return CheckboxListTile(
                      title: Text(label),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!currentActions.contains(label)) {
                              currentActions.add(label);
                            }
                          } else {
                            currentActions.remove(label);
                          }
                          currentActions.sort(
                            (a, b) => allLabels
                                .indexOf(a)
                                .compareTo(allLabels.indexOf(b)),
                          );
                          ref
                              .read(quickActionsStateProvider.notifier)
                              .setActions(currentActions);
                        });
                        ref
                            .read(quickActionsStateProvider.notifier)
                            .persistActions(currentActions);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(quickActionsStateProvider.notifier)
                        .persistActions(currentActions);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Listo'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
