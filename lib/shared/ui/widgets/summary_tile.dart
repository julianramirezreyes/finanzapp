import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'app_card.dart';

enum SummaryTileType { income, expense, neutral }

class SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final SummaryTileType type;
  final NumberFormat? format;
  final VoidCallback? onTap;

  const SummaryTile({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.type = SummaryTileType.neutral,
    this.format,
    this.onTap,
  });

  Color get _color {
    switch (type) {
      case SummaryTileType.income:
        return AppColors.income;
      case SummaryTileType.expense:
        return AppColors.expense;
      case SummaryTileType.neutral:
        return AppColors.info;
    }
  }

  // Relleno brightness-aware del icono: pastel suave en light, base translúcido
  // en dark (SDD #6, 6a). _color ya resuelve income/expense/info.
  Color _backgroundColor(BuildContext context) => context.stateFill(_color);

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        format ??
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _backgroundColor(context),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Icon(icon, color: _color, size: AppSpacing.iconSizeMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currencyFormat.format(amount),
            style: AppTypography.amountSmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final List<SummaryTileData> items;
  final MainAxisAlignment mainAxisAlignment;

  const SummaryRow({
    super.key,
    required this.items,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item != items.last ? AppSpacing.md : 0,
                ),
                child: SummaryTile(
                  title: item.title,
                  amount: item.amount,
                  icon: item.icon,
                  type: item.type,
                  format: item.format,
                  onTap: item.onTap,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class SummaryTileData {
  final String title;
  final double amount;
  final IconData icon;
  final SummaryTileType type;
  final NumberFormat? format;
  final VoidCallback? onTap;

  const SummaryTileData({
    required this.title,
    required this.amount,
    required this.icon,
    this.type = SummaryTileType.neutral,
    this.format,
    this.onTap,
  });
}
