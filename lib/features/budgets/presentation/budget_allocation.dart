import 'package:finanzapp_v2/features/budgets/domain/budget.dart';

/// Aggregated PLANNED allocation of a set of budgets versus each category's
/// plan cap.
///
/// "Allocation" is the SUM of `Budget.monthlyQuota` (what has been assigned
/// to metas) — NOT the real spend (`Budget.currentAmount`, already summarized
/// by `summarizeBudgetConsumption` in `budget_consumption.dart`). This type
/// answers "Presupuestado vs Plan"; the consumption type answers
/// "Gastado vs Plan" — they are deliberately separate files/types so neither
/// name lies about what it sums.
///
/// Input contract (spec R6/R7/R8, enforced by the CALLER, not this type):
/// the `budgets` list passed to [summarizeBudgetAllocation] MUST already be
/// scoped to the correct Personal/Hogar `budgetsListProvider` instance and
/// already exclude archived metas. `Budget` has NO `isArchived` field and NO
/// `householdId` field — there is nothing for the function to filter by;
/// archival exclusion (R8) is a server-side guarantee with no automated
/// frontend test (verified by backend/documentation review only).
class BudgetAllocationSummary {
  final double allocatedExpense;
  final double allocatedSaving;
  final double allocatedInvestment;

  /// Category caps, carried through so callers can render the denominator
  /// without recomputing it.
  final double expensePlan;
  final double savingPlan;
  final double investPlan;

  /// Per-category over-allocated flags: `allocated > cap`, raw comparison,
  /// no ratio, no epsilon. See [summarizeBudgetAllocation] doc for the
  /// zero-cap rationale.
  final bool isExpenseOver;
  final bool isSavingOver;
  final bool isInvestmentOver;

  /// Σ allocated across all types (= expense + saving + investment).
  final double totalAllocated;

  /// Σ of the three category caps.
  final double totalPlan;

  /// totalPlan − totalAllocated. GLOBAL ONLY — there is no per-category
  /// `remaining` field, matching `summarizeBudgetConsumption`'s own shape.
  final double remaining;

  /// totalAllocated / totalPlan, clamped to [0, 1.5]; 0 when totalPlan is 0
  /// (no plan ⇒ no division by zero).
  final double progress;

  /// true when ANY of the three categories is over-allocated.
  final bool hasAnyCategoryOver;

  const BudgetAllocationSummary({
    required this.allocatedExpense,
    required this.allocatedSaving,
    required this.allocatedInvestment,
    required this.expensePlan,
    required this.savingPlan,
    required this.investPlan,
    required this.isExpenseOver,
    required this.isSavingOver,
    required this.isInvestmentOver,
    required this.totalAllocated,
    required this.totalPlan,
    required this.remaining,
    required this.progress,
    required this.hasAnyCategoryOver,
  });
}

/// Builds a [BudgetAllocationSummary] from the current PLANNED allocation
/// (Σ `monthlyQuota`) of a set of budgets, versus each category's plan cap.
///
/// The over-allocated flag per category is a RAW comparison, `allocated >
/// cap` — no ratio, no division, no epsilon guard. Caps are guaranteed
/// non-negative (`income × pct/100` with non-negative inputs), so this single
/// condition already covers the zero-cap case: `allocated > 0` counts as over
/// when `cap == 0`, since `allocated > 0 == allocated > cap` at that point.
/// This is a DELIBERATE divergence from `summarizeBudgetConsumption`'s chip
/// guard (`consumed > budgeted && budgeted > 0`) — the allocation indicator
/// applies no `cap > 0` suppression, so any allocation against a 0% plan
/// share is unconditionally flagged as over-allocated.
///
/// Accepted risk (floating-point boundary, no epsilon): both operands of
/// `allocated > cap` derive from prior float arithmetic (division for goal
/// metas; `income × pct/100` for caps). At the exact "mathematically at cap"
/// boundary, rounding could tip an equal value to compare as slightly
/// over/under — no epsilon guard is applied. This mirrors the existing
/// consumption indicator's identical raw-double comparison, which has run in
/// production with no reported drift issues; accepted, not a defect.
BudgetAllocationSummary summarizeBudgetAllocation({
  required List<Budget> budgets,
  required double expensePlan,
  required double savingPlan,
  required double investPlan,
}) {
  double allocatedOf(String type) => budgets
      .where((b) => b.type == type)
      .fold<double>(0, (sum, b) => sum + b.monthlyQuota);

  final allocatedExpense = allocatedOf('expense');
  final allocatedSaving = allocatedOf('saving');
  final allocatedInvestment = allocatedOf('investment');

  final isExpenseOver = allocatedExpense > expensePlan;
  final isSavingOver = allocatedSaving > savingPlan;
  final isInvestmentOver = allocatedInvestment > investPlan;

  final totalAllocated =
      allocatedExpense + allocatedSaving + allocatedInvestment;
  final totalPlan = expensePlan + savingPlan + investPlan;

  final remaining = totalPlan - totalAllocated;
  final progress = totalPlan > 0
      ? (totalAllocated / totalPlan).clamp(0.0, 1.5)
      : 0.0;

  return BudgetAllocationSummary(
    allocatedExpense: allocatedExpense,
    allocatedSaving: allocatedSaving,
    allocatedInvestment: allocatedInvestment,
    expensePlan: expensePlan,
    savingPlan: savingPlan,
    investPlan: investPlan,
    isExpenseOver: isExpenseOver,
    isSavingOver: isSavingOver,
    isInvestmentOver: isInvestmentOver,
    totalAllocated: totalAllocated,
    totalPlan: totalPlan,
    remaining: remaining,
    progress: progress,
    hasAnyCategoryOver: isExpenseOver || isSavingOver || isInvestmentOver,
  );
}
