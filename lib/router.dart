import 'dart:async';

import 'package:finanzapp_v2/features/accounts/presentation/accounts_screen.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/auth/presentation/login_screen.dart';
import 'package:finanzapp_v2/features/auth/presentation/register_screen.dart';
import 'package:finanzapp_v2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finanzapp_v2/features/household/presentation/household_screen.dart';
import 'package:finanzapp_v2/features/transactions/presentation/transactions_screen.dart';
import 'package:finanzapp_v2/features/transactions/presentation/add_transaction_screen.dart';
import 'package:finanzapp_v2/features/budgets/presentation/financial_planning_screen.dart';
import 'package:finanzapp_v2/features/tax/presentation/tax_screen.dart';
import 'package:finanzapp_v2/features/assets/presentation/assets_screen.dart';
import 'package:finanzapp_v2/features/history/presentation/personal_history_screen.dart';
import 'package:finanzapp_v2/features/automation/presentation/recurring_payments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // authState logic handled by GoRouterRefreshStream listening to supabase stream directly
  final supabase = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginRoute = state.uri.path == '/login';
      final isRegisterRoute = state.uri.path == '/register';

      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }

      if (isLoggedIn && (isLoginRoute || isRegisterRoute)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddTransactionScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/household',
        builder: (context, state) => const HouseholdScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const FinancialPlanningScreen(),
      ),
      GoRoute(path: '/tax', builder: (context, state) => const TaxScreen()),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const AssetsScreen(),
      ),
      GoRoute(
        path: '/history/personal',
        builder: (context, state) => const PersonalHistoryScreen(),
      ),
      GoRoute(
        path: '/automation',
        builder: (context, state) => const RecurringPaymentsScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
