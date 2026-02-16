import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Total Balance Card
              _buildBalanceCard(context, data.totalBalance, currencyFormat),
              const SizedBox(height: 16),

              // Monthly Summary Card
              _buildMonthlySummary(context, data, currencyFormat),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Accesos Rápidos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    context,
                    Icons.people,
                    'Hogar',
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.blue,
                    () => context.push('/household'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.savings,
                    'Metas',
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.purple,
                    () => context.push('/budgets'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.assignment,
                    'Declaración',
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.orange,
                    () => context.push('/tax'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.autorenew,
                    'Automático',
                    Colors.teal.withValues(alpha: 0.1),
                    Colors.teal,
                    () => context.push('/automation'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.account_balance,
                    'Activos',
                    Colors.indigo.withValues(alpha: 0.1),
                    Colors.indigo,
                    () => context.push('/assets'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Accounts Section
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
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
                      // Navigate to details if needed
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

              const SizedBox(height: 80), // Space for FAB
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
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
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
    // Translate Month Name
    String monthName = DateFormat('MMMM', 'es_ES').format(DateTime.now());
    // Capitalize first letter
    monthName = monthName[0].toUpperCase() + monthName.substring(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este Mes ($monthName)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              'Ingresos',
              data.monthlyIncome,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Gastos',
              data.monthlyExpense,
              Colors.red,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              'Balance Neto',
              data.monthlyBalance,
              data.monthlyBalance >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        Text(
          format.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
