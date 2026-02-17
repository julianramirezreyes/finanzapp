import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Menú",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, Icons.dashboard, "Resumen", "/"),
                _buildDrawerItem(context, Icons.people, "Hogar", "/household"),
                _buildDrawerItem(
                  context,
                  Icons.savings,
                  "Metas y Presupuestos",
                  "/budgets",
                ),
                _buildDrawerItem(
                  context,
                  Icons.history,
                  "Historial de Transacciones",
                  "/transactions",
                ),
                _buildDrawerItem(
                  context,
                  Icons.account_balance,
                  "Mis Cuentas",
                  "/accounts",
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  Icons.autorenew,
                  "Pagos Automáticos",
                  "/automation",
                ),
                _buildDrawerItem(
                  context,
                  Icons.account_balance_wallet,
                  "Activos y Patrimonio",
                  "/assets",
                ),
                _buildDrawerItem(
                  context,
                  Icons.assignment,
                  "Declaración de Renta",
                  "/tax",
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Cerrar Sesión",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        context.pop(); // Close drawer
        context.push(route);
      },
    );
  }
}
