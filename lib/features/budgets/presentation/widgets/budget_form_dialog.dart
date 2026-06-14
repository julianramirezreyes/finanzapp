/// Resultado YA mapeado del formulario de meta (budget).
///
/// El diálogo expone campos canónicos (`limitAmount`, `monthlyQuota`, `months`,
/// `isRecurrent`, `targetAmount`) en vez del `amount` crudo, para que la
/// semántica monto -> campos se centralice una sola vez en [mapBudgetAmounts]
/// y cada tab (Personal/Hogar) solo decida cómo persistir.
class BudgetFormResult {
  const BudgetFormResult({
    required this.name,
    required this.type,
    required this.isRecurrent,
    required this.months,
    required this.limitAmount,
    required this.monthlyQuota,
    required this.targetAmount,
  });

  final String name;

  /// expense | saving | investment (sin cambios respecto al modelo actual).
  final String type;

  final bool isRecurrent;

  /// 1 cuando es recurrente; el número de meses elegido en modo Meta.
  final int months;

  /// Objetivo total (acumulativa) o cuota mensual (recurrente).
  final double limitAmount;

  /// Cuota mensual (== limitAmount en recurrente, == total/months en Meta).
  final double monthlyQuota;

  /// Sólo para saving/investment; null para expense.
  final double? targetAmount;
}

/// Helper PURO que centraliza la semántica del monto según el tipo de meta.
///
/// - Fijo Mensual (isRecurrent=true): el monto es la CUOTA MENSUAL ->
///   limitAmount = monthlyQuota = amount, months = 1.
/// - Meta (X meses) (isRecurrent=false): el monto es el OBJETIVO TOTAL ->
///   limitAmount = amount (total), monthlyQuota = amount / months
///   (months < 1 se clampa a 1 para evitar división por cero).
///
/// targetAmount = amount sólo para saving/investment; null para expense.
BudgetFormResult mapBudgetAmounts({
  required String name,
  required String type,
  required bool isRecurrent,
  required int months,
  required double amount,
}) {
  final bool isGoalType = type == 'saving' || type == 'investment';

  if (isRecurrent) {
    return BudgetFormResult(
      name: name,
      type: type,
      isRecurrent: true,
      months: 1,
      limitAmount: amount,
      monthlyQuota: amount,
      targetAmount: isGoalType ? amount : null,
    );
  }

  final int safeMonths = months < 1 ? 1 : months;
  return BudgetFormResult(
    name: name,
    type: type,
    isRecurrent: false,
    months: safeMonths,
    limitAmount: amount,
    monthlyQuota: amount / safeMonths,
    targetAmount: isGoalType ? amount : null,
  );
}
