import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final double currentAmount;
  final VoidCallback? onTap; // Tap en la card -> abrir historial de registros
  final double splitRatio;
  final bool showSplit;
  final VoidCallback? onEdit; // Menú ⋮ -> Editar
  final VoidCallback? onDelete; // Menú ⋮ -> Eliminar

  const BudgetCard({
    super.key,
    required this.budget,
    required this.currentAmount,
    this.onTap,
    this.splitRatio = 0.5,
    this.showSplit = false,
    this.onEdit,
    this.onDelete,
  });

  Color _getColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
      case 'expense':
        return AppColors.expense;
      case 'green':
      case 'savings':
        return AppColors.savings;
      case 'blue':
      case 'investment':
        return AppColors.investment;
      case 'purple':
        return AppColors.savings;
      default:
        return AppColors.info;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    // Recurrente -> objetivo = cuota mensual. Acumulativa (Meta) -> objetivo =
    // limitAmount (TOTAL canónico del backend), para CUALQUIER type (incl.
    // expense). Antes la rama excluía expense y caía a monthlyQuota, mostrando
    // la cuota como objetivo para una acumulativa de gasto.
    final double total =
        budget.isRecurrent ? budget.monthlyQuota : budget.limitAmount;

    double progress = total > 0 ? (currentAmount / total) : 0.0;
    final bool isExceeded = currentAmount > total;
    final double displayProgress = progress > 1.0 ? 1.0 : progress;

    final color = _getColor(budget.color);
    final icon = _getIcon(budget.icon);
    final Color alertColor = isExceeded ? AppColors.expense : color;

    return AppCard(
      onTap: onTap,
      style: AppCardStyle.bordered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget.category,
                            style: AppTypography.titleSmall,
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppColors.textMuted,
                            ),
                            tooltip: 'Opciones',
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit?.call();
                              } else if (value == 'delete') {
                                onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                              if (onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: AppColors.expense,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          color: AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.subtleFill(),
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Text(
                            budget.isRecurrent
                                ? 'Fijo Mensual'
                                : 'Meta (${budget.months} meses)',
                            style: AppTypography.labelSmall,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${currency.format(currentAmount)} / ${currency.format(total)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.expense.withValues(alpha: 0.15)
                      : progress >= 1.0
                      ? context.stateFill(AppColors.income)
                      : context.subtleFill(),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  isExceeded
                      ? '+${((progress - 1) * 100).toStringAsFixed(0)}%'
                      : '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: isExceeded
                        ? AppColors.expense
                        : progress >= 1.0
                        ? AppColors.income
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: displayProgress,
              backgroundColor: alertColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(alertColor),
              minHeight: 8,
            ),
          ),
          if (showSplit) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Tú: ${currency.format(total * splitRatio)} | Pareja: ${currency.format(total * (1 - splitRatio))}",
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
