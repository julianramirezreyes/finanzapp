import 'package:finanzapp_v2/features/budgets/data/budget_config_repository.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the config for a specific context (household or personal)
final budgetConfigProvider =
    FutureProvider.family<BudgetConfig, ({String type, String? householdId})>((
      ref,
      params,
    ) async {
      return ref
          .read(budgetConfigRepositoryProvider)
          .getConfig(params.type, householdId: params.householdId);
    });
