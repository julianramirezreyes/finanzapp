import 'package:flutter/material.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/core/theme/app_typography.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:intl/intl.dart';

class AccountWithPocketsTile extends StatelessWidget {
  final String name;
  final String type;
  final double balance;
  final double totalValue;
  final int pocketsCount;
  final double pocketsTotal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showDragHandle;

  const AccountWithPocketsTile({
    super.key,
    required this.name,
    required this.type,
    required this.balance,
    required this.totalValue,
    required this.pocketsCount,
    required this.pocketsTotal,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.showDragHandle = false,
  });

  String get _typeLabel {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'savings':
        return 'Ahorros';
      case 'checking':
        return 'Corriente';
      case 'credit':
        return 'Crédito';
      case 'investment':
        return 'Inversión';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    final isCredit = type.toLowerCase() == 'credit';
    final balanceColor = isCredit && balance < 0
        ? AppColors.expense
        : context.onSurface;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          BankAvatar(name: name, type: type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_typeLabel, style: AppTypography.labelSmall),
                if (pocketsCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 14,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pocketsCount bolsillo${pocketsCount > 1 ? 's' : ''} (${currencyFormat.format(pocketsTotal)})',
                        style: TextStyle(fontSize: 11, color: AppColors.info),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(balance),
                style: AppTypography.amountSmall.copyWith(
                  color: balanceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (pocketsCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Total: ${currencyFormat.format(totalValue)}',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          if (showDragHandle) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.drag_handle,
              color: AppColors.textMuted,
              size: AppSpacing.iconSizeMedium,
            ),
          ],
        ],
      ),
    );
  }
}
