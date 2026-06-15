import 'package:finanzapp_v2/features/budgets/domain/budget.dart';

/// Aggregated consumption of a set of budgets versus the monthly plan.
///
/// "Consumption" is the REAL spend of the current month (`Budget.currentAmount`,
/// already computed by the backend: America/Bogota month boundary, excluding
/// credit-card purchases) — NOT the planned assignment (`Budget.monthlyQuota`).
/// The summary bar uses this so it shows "Gastado vs Plan", not assignment.
class BudgetConsumptionSummary {
  final double consumedExpense;
  final double consumedSaving;
  final double consumedInvestment;

  /// Σ currentAmount across all types (= expense + saving + investment).
  final double totalConsumed;

  /// The planned total (Σ income × pct). Carried through so callers can render
  /// the denominator without recomputing it.
  final double totalBudgeted;

  /// totalBudgeted − totalConsumed. Negative when spend exceeds the plan.
  final double remaining;

  /// totalConsumed / totalBudgeted, clamped to [0, 1.5]; 0 when totalBudgeted
  /// is 0 (no plan ⇒ no division by zero, and an empty bar instead of a full one).
  final double progress;

  const BudgetConsumptionSummary({
    required this.consumedExpense,
    required this.consumedSaving,
    required this.consumedInvestment,
    required this.totalConsumed,
    required this.totalBudgeted,
    required this.remaining,
    required this.progress,
  });
}

/// Builds a [BudgetConsumptionSummary] from the current month's real spend.
///
/// The consumption of a household is the TOTAL aggregate of both members
/// (currentAmount already arrives aggregated from the backend); it is NOT split
/// by contribution ratios — those describe planned contribution, not executed
/// spend.
BudgetConsumptionSummary summarizeBudgetConsumption({
  required List<Budget> budgets,
  required double totalBudgeted,
}) {
  double consumedOf(String type) => budgets
      .where((b) => b.type == type)
      .fold<double>(0, (sum, b) => sum + b.currentAmount);

  final consumedExpense = consumedOf('expense');
  final consumedSaving = consumedOf('saving');
  final consumedInvestment = consumedOf('investment');
  final totalConsumed = consumedExpense + consumedSaving + consumedInvestment;

  final remaining = totalBudgeted - totalConsumed;
  final progress = totalBudgeted > 0
      ? (totalConsumed / totalBudgeted).clamp(0.0, 1.5)
      : 0.0;

  return BudgetConsumptionSummary(
    consumedExpense: consumedExpense,
    consumedSaving: consumedSaving,
    consumedInvestment: consumedInvestment,
    totalConsumed: totalConsumed,
    totalBudgeted: totalBudgeted,
    remaining: remaining,
    progress: progress,
  );
}
