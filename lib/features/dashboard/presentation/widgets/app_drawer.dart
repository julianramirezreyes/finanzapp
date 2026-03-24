import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg + topPadding,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'FinanzApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gestión financiera personal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildDrawerItem(
                  context,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Resumen',
                  '/',
                  AppColors.primary,
                ),
                _buildDrawerItem(
                  context,
                  Icons.people_outlined,
                  Icons.people,
                  'Hogar',
                  '/household',
                  null,
                ),
                _buildDrawerItem(
                  context,
                  Icons.savings_outlined,
                  Icons.savings,
                  'Metas y Presupuestos',
                  '/budgets',
                  null,
                ),
                _buildDrawerItem(
                  context,
                  Icons.history_outlined,
                  Icons.history,
                  'Historial de Transacciones',
                  '/transactions',
                  null,
                ),
                _buildDrawerItem(
                  context,
                  Icons.account_balance_outlined,
                  Icons.account_balance,
                  'Mis Cuentas',
                  '/accounts',
                  null,
                ),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                _buildDrawerItem(
                  context,
                  Icons.autorenew,
                  Icons.autorenew,
                  'Pagos Automáticos',
                  '/automation',
                  null,
                ),
                _buildDrawerItem(
                  context,
                  Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet,
                  'Activos y Patrimonio',
                  '/assets',
                  null,
                ),
                _buildDrawerItem(
                  context,
                  Icons.assignment_outlined,
                  Icons.assignment,
                  'Declaración de Renta',
                  '/tax',
                  null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.expenseLight,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.expense,
                size: 20,
              ),
            ),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    IconData selectedIcon,
    String label,
    String route,
    Color? color,
  ) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: InkWell(
          onTap: () {
            context.pop();
            if (currentRoute != route) {
              context.push(route);
            }
          },
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (color ?? AppColors.primary).withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? (color ?? AppColors.primary)
                      : (isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary),
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? (color ?? AppColors.primary)
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
