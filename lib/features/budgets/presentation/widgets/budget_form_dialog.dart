import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// Point-in-time, provider-agnostic snapshot used to render the dialog's live
/// "Presupuestado vs Plan" preview while creating/editing a meta (ADR-3). The
/// dialog NEVER reads Riverpod providers itself — the caller (`_showGoalDialog`,
/// PR4) builds this plain object from data it already has (or explicitly
/// reads) and injects it.
///
/// [otherAllocatedByType] MUST already exclude the meta currently being
/// edited (`existing?.id`) — that self-exclusion is the CALLER's
/// responsibility (spec R11.1), not something this dialog re-derives.
class AllocationPreviewData {
  const AllocationPreviewData({
    required this.planCapByType,
    required this.otherAllocatedByType,
  });

  /// Category cap (`income × pct/100`), keyed by `Budget.type`
  /// (`expense`/`saving`/`investment`).
  final Map<String, double> planCapByType;

  /// Σ `monthlyQuota` of all OTHER non-archived, same-scope metas per
  /// category, keyed by `Budget.type`. Excludes the meta being edited, if any.
  final Map<String, double> otherAllocatedByType;
}

/// Diálogo compartido (Personal y Hogar) para crear y editar una meta.
///
/// Es AGNÓSTICO del repositorio: recolecta y valida la entrada y, al guardar,
/// llama [onSubmit] con un [BudgetFormResult] ya mapeado vía [mapBudgetAmounts].
/// Cada tab decide cómo persistir (create/update + householdId + invalidación).
class BudgetFormDialog extends StatefulWidget {
  const BudgetFormDialog({
    super.key,
    this.existing,
    this.allocationPreview,
    required this.onSubmit,
  });

  /// null => crear; no-null => editar (precarga el formulario).
  final Budget? existing;

  /// Snapshot opcional (ADR-3) para la vista previa "Presupuestado vs Plan".
  /// null => sin snapshot disponible (loading/error del caller) => la vista
  /// previa se degrada por completo (no bloquea la apertura del diálogo).
  final AllocationPreviewData? allocationPreview;

  final void Function(BudgetFormResult) onSubmit;

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _monthsController;

  late bool _isRecurrent;
  late String _type;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    // Default crear = Fijo Mensual (el caso común "Didi").
    _isRecurrent = existing?.isRecurrent ?? true;
    _type = existing?.type ?? 'expense';

    _nameController = TextEditingController(text: existing?.category ?? '');

    // Recurrente -> precargar la cuota; acumulativa -> precargar el total.
    final double? preloadAmount = existing == null
        ? null
        : (existing.isRecurrent ? existing.monthlyQuota : existing.limitAmount);
    _amountController = TextEditingController(
      text: preloadAmount == null ? '' : preloadAmount.toStringAsFixed(0),
    );

    _monthsController = TextEditingController(
      text: (existing?.months ?? 1).toString(),
    );

    _amountController.addListener(_onInputChanged);
    _monthsController.addListener(_onInputChanged);
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  String get _amountLabel => _isRecurrent ? 'Monto mensual' : 'Objetivo total';

  void _submit() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (name.isEmpty || amount <= 0) return;
    if (!_isRecurrent && months < 1) return;

    widget.onSubmit(
      mapBudgetAmounts(
        name: name,
        type: _type,
        isRecurrent: _isRecurrent,
        months: months,
        amount: amount,
      ),
    );
  }

  String _categoryLabel(String type) {
    switch (type) {
      case 'saving':
        return 'Ahorro';
      case 'investment':
        return 'Inversión';
      case 'expense':
      default:
        return 'Gasto';
    }
  }

  /// Live "Presupuestado vs Plan" preview line for the CURRENTLY selected
  /// category (R10/R11), or `null` when there is nothing to show: no
  /// snapshot (`allocationPreview == null`, ADR-3 degrade), an unknown
  /// category key, or the transient goal-type `months < 1` window (ADR-4,
  /// mirrors the existing "Cuota mensual" hint's own gate).
  Widget? _buildAllocationPreview(double amount, int months) {
    final preview = widget.allocationPreview;
    if (preview == null) return null;

    final cap = preview.planCapByType[_type];
    if (cap == null) return null;

    if (!_isRecurrent && months < 1) return null;

    final projectedQuota = mapBudgetAmounts(
      name: _nameController.text,
      type: _type,
      isRecurrent: _isRecurrent,
      months: months,
      amount: amount,
    ).monthlyQuota;

    final otherAllocated = preview.otherAllocatedByType[_type] ?? 0;
    final projectedTotal = otherAllocated + projectedQuota;
    final categoryLabel = _categoryLabel(_type);

    // R10.5/R2.3 zero-cap display guard: NEVER evaluate `.../cap` when
    // cap == 0 (would render `Infinity` in Dart). Warn via MESSAGE only when
    // something is actually projected against a plan that grants nothing;
    // otherwise mirror R2.2 and show nothing.
    if (cap == 0) {
      if (projectedTotal <= 0) return null;
      return Text(
        'Sin plan asignado a $categoryLabel: esta meta lo supera',
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isOver = projectedTotal > cap;
    final pct = (projectedTotal / cap * 100).toStringAsFixed(0);
    final toneColor = isOver ? AppColors.expense : AppColors.textSecondary;

    return Text(
      '$pct% del plan de $categoryLabel',
      style: AppTypography.captionSmall.copyWith(
        color: toneColor,
        fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final amount = double.tryParse(_amountController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final quota = (!_isRecurrent && months >= 1) ? amount / months : 0;
    final allocationPreview = _buildAllocationPreview(amount, months);

    return AlertDialog(
      title: Text(widget.existing == null ? 'Nueva Meta' : 'Editar Meta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                DropdownMenuItem(value: 'saving', child: Text('Ahorro')),
                DropdownMenuItem(value: 'investment', child: Text('Inversión')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'expense'),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Fijo Mensual')),
                ButtonSegment(value: false, label: Text('Meta (X meses)')),
              ],
              selected: {_isRecurrent},
              onSelectionChanged: (selection) {
                setState(() => _isRecurrent = selection.first);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_isRecurrent) ...[
              TextField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Meses'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _amountLabel),
            ),
            if (!_isRecurrent) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cuota mensual: ${currency.format(quota)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (allocationPreview != null) ...[
              const SizedBox(height: AppSpacing.sm),
              allocationPreview,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
