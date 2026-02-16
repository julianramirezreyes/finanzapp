import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final double currentAmount; // Spent or Saved so far
  final VoidCallback onTap;
  final double splitRatio; // Share for User A (0.0 - 1.0)
  final bool showSplit;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.currentAmount,
    required this.onTap,
    this.splitRatio = 0.5,
    this.showSplit = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    double total = budget.monthlyQuota;
    // For non-recurrent goals, show target amount as total
    if (budget.type != 'expense' &&
        !budget.isRecurrent &&
        (budget.targetAmount ?? 0) > 0) {
      total = budget.targetAmount!;
    }

    // Safety check for div by zero
    double progress = total > 0 ? (currentAmount / total) : 0.0;
    if (progress > 1.0) progress = 1.0;

    final color = _getColor(budget.color);
    final icon = _getIcon(budget.icon);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          budget.isRecurrent
                              ? 'Fijo Mensual'
                              : 'Meta (${budget.months} meses)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (showSplit) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Tú: ${currency.format(total * splitRatio)} | Pareja: ${currency.format(total * (1 - splitRatio))}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currency.format(currentAmount)} / ${currency.format(total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: progress >= 1.0 ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String? colorName) {
    return Colors.blue;
  }

  IconData _getIcon(String? iconName) {
    return Icons.category;
  }
}
