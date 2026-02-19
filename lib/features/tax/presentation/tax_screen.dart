import 'package:finanzapp_v2/features/tax/data/tax_repository.dart';
import 'package:finanzapp_v2/features/tax/domain/tax_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});

  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final taxStatusAsync = ref.watch(taxStatusProvider(_year));
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Declaración de Renta'),
        actions: [
          DropdownButton<int>(
            value: _year,
            dropdownColor: Theme.of(context).primaryColor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            items: [2024, 2025, 2026].map((y) {
              return DropdownMenuItem(value: y, child: Text(y.toString()));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _year = val);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: taxStatusAsync.when(
        data: (status) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Card(
                color: status.shouldDeclare
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        status.shouldDeclare
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        size: 48,
                        color: status.shouldDeclare ? Colors.red : Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.shouldDeclare
                            ? "Debes Declarar Renta"
                            : "Bajo Topes de Declaración",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: status.shouldDeclare
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Año gravable $_year"),
                      const SizedBox(height: 8),
                      Text(
                        "Valor UVT: ${currencyFormat.format(status.uvtValue)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/assets'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text("Gestionar Activos y Patrimonio"),
                ),
              ),

              const SizedBox(height: 16),

              // Categories
              ...status.categories.map(
                (category) =>
                    _buildCategoryCard(context, category, currencyFormat),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    TaxCategoryProgress category,
    NumberFormat format,
  ) {
    final progressColor = category.percentage >= 1.0
        ? Colors.red
        : category.percentage >= 0.75
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  "${(category.percentage * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: category.percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: progressColor,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Acumulado",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      format.format(category.currentValue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Tope (${category.thresholdUvt.toStringAsFixed(0)} UVT)",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      format.format(category.thresholdValue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
