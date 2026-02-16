import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart'; // We'll create this later
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text("Planificación Financiera"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Hogar", icon: Icon(Icons.house)),
            Tab(text: "Personal", icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HouseholdBudgetTab(),
          PersonalBudgetTab(), // Placeholder for now
        ],
      ),
      // floatingActionButton removed as per user feedback
    );
  }
}
