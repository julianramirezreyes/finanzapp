import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final NumberFormat? format;
  final bool showSign;
  final AmountDisplayType type;
  final TextStyle? style;
  final bool compact;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.format,
    this.showSign = false,
    this.type = AmountDisplayType.neutral,
    this.style,
    this.compact = false,
  });

  factory AmountDisplay.income(
    double amount, {
    NumberFormat? format,
    TextStyle? style,
    bool compact = false,
  }) {
    return AmountDisplay(
      amount: amount,
      format: format,
      showSign: true,
      type: AmountDisplayType.income,
      style: style,
      compact: compact,
    );
  }

  factory AmountDisplay.expense(
    double amount, {
    NumberFormat? format,
    TextStyle? style,
    bool compact = false,
  }) {
    return AmountDisplay(
      amount: amount,
      format: format,
      showSign: true,
      type: AmountDisplayType.expense,
      style: style,
      compact: compact,
    );
  }

  Color get _color {
    switch (type) {
      case AmountDisplayType.income:
        return AppColors.income;
      case AmountDisplayType.expense:
        return AppColors.expense;
      case AmountDisplayType.neutral:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        format ??
        NumberFormat.currency(
          symbol: compact ? '' : '\$',
          decimalDigits: 0,
          locale: 'es_CO',
        );

    String formattedAmount;
    if (showSign && amount > 0) {
      formattedAmount = '+${currencyFormat.format(amount)}';
    } else if (showSign && type == AmountDisplayType.expense) {
      formattedAmount = '-${currencyFormat.format(amount.abs())}';
    } else {
      formattedAmount = currencyFormat.format(amount);
    }

    return Text(
      formattedAmount,
      style: (style ?? AppTypography.amount).copyWith(color: _color),
    );
  }
}

enum AmountDisplayType { income, expense, neutral }
