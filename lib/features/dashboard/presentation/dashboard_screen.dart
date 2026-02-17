import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/dashboard/presentation/widgets/app_drawer.dart'; // Import AppDrawer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/presentation/responsive_layout.dart';

// State for customizing quick actions
final quickActionsStateProvider = StateProvider<List<String>>((ref) {
  return [
    'Historial',
    'Metas',
    'Hogar',
    'Automático',
    'Activos',
    'Declaración',
  ];
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final enabledActions = ref.watch(quickActionsStateProvider);

    // Startup Check for Pending Payments
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
      decimalDigits: 2,
    );

    return ResponsiveLayout(
      mobileBody: Scaffold(
        appBar: AppBar(
          title: const Text('Resumen'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(dashboardProvider),
            ),
            // The EndDrawer hamburger icon appears automatically here
          ],
        ),
        drawer: const AppDrawer(), // Left-side Drawer
        body: dashboardAsync.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async => ref.refresh(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildBalanceCard(context, data.totalBalance, currencyFormat),
                const SizedBox(height: 16),
                _buildMonthlySummary(context, data, currencyFormat),
                const SizedBox(height: 24),

                // Quick Actions Header with Edit Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accesos Rápidos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: "Personalizar",
                      onPressed: () => _showQuickActionsConfig(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (enabledActions.isEmpty)
                  Center(
                    child: Text(
                      "No hay accesos visibles.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 400 ? 4 : 3;

                      // Define all possible actions
                      final allActions = [
                        _QuickActionItem(
                          Icons.history,
                          'Historial',
                          Colors.blueGrey,
                          '/transactions',
                        ),
                        _QuickActionItem(
                          Icons.savings,
                          'Metas',
                          Colors.purple,
                          '/budgets',
                        ),
                        _QuickActionItem(
                          Icons.people,
                          'Hogar',
                          Colors.blue,
                          '/household',
                        ),
                        _QuickActionItem(
                          Icons.autorenew,
                          'Automático',
                          Colors.teal,
                          '/automation',
                        ),
                        _QuickActionItem(
                          Icons.account_balance,
                          'Activos',
                          Colors.indigo,
                          '/assets',
                        ),
                        _QuickActionItem(
                          Icons.assignment,
                          'Declaración',
                          Colors.orange,
                          '/tax',
                        ),
                      ];

                      // Filter visible ones
                      final visibleActions = allActions
                          .where((a) => enabledActions.contains(a.label))
                          .toList();

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: visibleActions
                            .map(
                              (action) => _buildQuickAction(
                                context,
                                action.icon,
                                action.label,
                                action.color.withOpacity(
                                  0.1,
                                ), // Changed withValues to withOpacity
                                action.color,
                                () => context.push(action.route),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mis Cuentas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/accounts'),
                      child: const Text('Gestionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.accounts.map(
                  (acc) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary
                            .withOpacity(
                              0.1,
                            ), // Changed withValues to withOpacity
                        child: Icon(
                          Icons.account_balance,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(translationAccountType(acc.type)),
                      trailing: Text(
                        currencyFormat.format(acc.balance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        context.push(
                          '/accounts/${acc.id}/vault',
                          extra: {'name': acc.name},
                        );
                      },
                    ),
                  ),
                ),
                if (data.accounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Aún no tienes cuentas. ¡Agrega una para comenzar!',
                      ),
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
                Text('Error: $err', textAlign: TextAlign.center),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/transactions/add'),
          child: const Icon(Icons.add),
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
                  icon: Icon(Icons.dashboard),
                  label: Text('Resumen'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Hogar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.savings),
                  label: Text('Metas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('Historial'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance),
                  label: Text('Cuentas'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: dashboardAsync.when(
                data: (data) => ListView(
                  padding: const EdgeInsets.all(32.0),
                  children: [
                    Text(
                      'Resumen Financiero',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        SizedBox(
                          width: 400,
                          child: _buildBalanceCard(
                            context,
                            data.totalBalance,
                            currencyFormat,
                          ),
                        ),
                        SizedBox(
                          width: 400,
                          child: _buildMonthlySummary(
                            context,
                            data,
                            currencyFormat,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Mis Cuentas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: data.accounts
                          .map(
                            (acc) => SizedBox(
                              width: 300,
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    translationAccountType(acc.type),
                                  ),
                                  trailing: Text(
                                    currencyFormat.format(acc.balance),
                                  ),
                                  onTap: () => context.push('/accounts'),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsConfig(BuildContext context, WidgetRef ref) {
    final currentActions = List<String>.from(
      ref.read(quickActionsStateProvider),
    ); // Create a mutable copy
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Personalizar Accesos"),
              content: SingleChildScrollView(
                child: Column(
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
                          // Sort based on original list to keep order consistent
                          currentActions.sort(
                            (a, b) => allLabels
                                .indexOf(a)
                                .compareTo(allLabels.indexOf(b)),
                          );

                          // Update provider
                          ref.read(quickActionsStateProvider.notifier).state = [
                            ...currentActions,
                          ];
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Listo"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String translationAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'savings':
        return 'Ahorros';
      case 'checking':
        return 'Corriente'; // Though not in DB constraints, mapping just in case
      case 'credit':
        return 'Crédito';
      case 'investment':
        return 'Inversión';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    NumberFormat format,
  ) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BALANCE TOTAL',
              style: TextStyle(
                color: Colors.white.withOpacity(
                  0.8,
                ), // Changed withValues to withOpacity
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(
    BuildContext context,
    DashboardData data,
    NumberFormat format,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              context,
              'Ingresos',
              data.monthlyIncome,
              Colors.green,
              format,
            ),
            _buildSummaryItem(
              context,
              'Gastos',
              data.monthlyExpense,
              Colors.red,
              format,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat format,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  _QuickActionItem(this.icon, this.label, this.color, this.route);
}
