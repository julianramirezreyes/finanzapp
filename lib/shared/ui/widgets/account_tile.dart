import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'app_card.dart';
import 'bank_avatar.dart';
import 'package:intl/intl.dart';

class AccountTile extends StatelessWidget {
  final String name;
  final String type;
  final double balance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showDragHandle;

  const AccountTile({
    super.key,
    required this.name,
    required this.type,
    required this.balance,
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
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            currencyFormat.format(balance),
            style: AppTypography.amountSmall.copyWith(
              color: balanceColor,
              fontWeight: FontWeight.w600,
            ),
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
