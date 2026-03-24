import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class AppActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isSelected;
  final double? width;

  const AppActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.isSelected = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.backgroundLight;

    final selectedBg = isDark
        ? AppColors.primaryDark.withValues(alpha: 0.2)
        : AppColors.primarySurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : defaultBg,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSpacing.iconSizeSmall,
                color:
                    iconColor ??
                    (isSelected ? AppColors.primary : AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionChipGroup extends StatelessWidget {
  final List<ActionChipData> items;
  final bool scrollable;
  final MainAxisAlignment mainAxisAlignment;

  const ActionChipGroup({
    super.key,
    required this.items,
    this.scrollable = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          children: items.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                right: entry.key < items.length - 1 ? AppSpacing.sm : 0,
              ),
              child: AppActionChip(
                icon: entry.value.icon,
                label: entry.value.label,
                onTap: entry.value.onTap,
                isSelected: entry.value.isSelected,
              ),
            );
          }).toList(),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.asMap().entries.map((entry) {
        return AppActionChip(
          icon: entry.value.icon,
          label: entry.value.label,
          onTap: entry.value.onTap,
          isSelected: entry.value.isSelected,
        );
      }).toList(),
    );
  }
}

class ActionChipData {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;

  const ActionChipData({
    required this.icon,
    required this.label,
    this.onTap,
    this.isSelected = false,
  });
}
