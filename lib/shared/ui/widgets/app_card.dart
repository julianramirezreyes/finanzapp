import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum AppCardStyle { elevated, bordered, filled }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final AppCardStyle style;
  final double? elevation;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.style = AppCardStyle.bordered,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppSpacing.cardRadius;

    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: style == AppCardStyle.filled
            ? bgColor.withValues(alpha: 0.5)
            : bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: style != AppCardStyle.elevated
            ? Border.all(color: borderColor, width: 1)
            : null,
        boxShadow: style == AppCardStyle.elevated
            ? [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: elevation ?? 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(radius),
            child: cardContent,
          ),
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}
