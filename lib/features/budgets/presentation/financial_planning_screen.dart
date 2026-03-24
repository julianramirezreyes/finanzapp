import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';

class FinancialPlanningScreen extends ConsumerStatefulWidget {
  const FinancialPlanningScreen({super.key});

  @override
  ConsumerState<FinancialPlanningScreen> createState() =>
      _FinancialPlanningScreenState();
}

class _FinancialPlanningScreenState
    extends ConsumerState<FinancialPlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificación Financiera'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Hogar'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Personal'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [HouseholdBudgetTab(), PersonalBudgetTab()],
      ),
    );
  }
}
