import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat? format;
  final bool isPositive;
  final double? trend;
  final String? trendLabel;
  final Widget? trailing;

  const BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    this.format,
    this.isPositive = true,
    this.trend,
    this.trendLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        format ??
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: isPositive
            ? AppColors.balancePositiveGradient
            : AppColors.balanceNegativeGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primary : AppColors.expense)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            currencyFormat.format(amount),
            style: AppTypography.balance.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: AppSpacing.iconSizeSmall,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${trend! >= 0 ? '+' : ''}${currencyFormat.format(trend!.abs())}',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (trendLabel != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          trendLabel!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
