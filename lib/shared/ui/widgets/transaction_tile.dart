import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'app_card.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final String description;
  final String category;
  final double amount;
  final String type;
  final DateTime date;
  final String? accountName;
  final String? contextLabel;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.accountName,
    this.contextLabel,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  bool get _isIncome => type == 'income';
  bool get _isTransfer => type == 'transfer';

  Color get _iconColor => _isTransfer
      ? AppColors.info
      : _isIncome
      ? AppColors.income
      : AppColors.expense;

  // Relleno del icono brightness-aware: pastel suave en light, base translúcido
  // en dark (SDD #6, 6a). Usa el color base del estado vía stateFill.
  Color _iconBackgroundColor(BuildContext context) =>
      context.stateFill(_iconColor);

  IconData get _icon => _isTransfer
      ? Icons.swap_horiz_rounded
      : _isIncome
      ? Icons.arrow_upward_rounded
      : Icons.arrow_downward_rounded;

  // Transfers move money between accounts: no +/- sign.
  String get _amountPrefix => _isTransfer
      ? ''
      : _isIncome
      ? '+ '
      : '- ';

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return AppCard(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _iconBackgroundColor(context),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Icon(
              _icon,
              color: _iconColor,
              size: AppSpacing.iconSizeMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : category,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      DateFormat.MMMd('es_CO').format(date),
                      style: AppTypography.labelSmall,
                    ),
                    if (contextLabel != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.stateFill(AppColors.info),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          contextLabel!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.info,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    if (accountName != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '• $accountName',
                          style: AppTypography.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_amountPrefix${currencyFormat.format(amount)}',
                style: AppTypography.amountSmall.copyWith(
                  color: _iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textMuted,
                    size: AppSpacing.iconSizeSmall,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
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
                            style: TextStyle(color: AppColors.expense),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
