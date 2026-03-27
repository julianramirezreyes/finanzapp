import 'package:finanzapp_v2/features/tax/data/tax_repository.dart';
import 'package:finanzapp_v2/features/tax/domain/tax_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';

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
      locale: 'es_CO',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Declaración de Renta'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            child: DropdownButton<int>(
              value: _year,
              dropdownColor: AppColors.primary,
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
          ),
        ],
      ),
      body: taxStatusAsync.when(
        data: (status) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              FadeSlideTransition(
                child: _buildSummaryCard(context, status, currencyFormat),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideTransition(
                index: 1,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/assets'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Gestionar Activos'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...status.categories.asMap().entries.map((entry) {
                return FadeSlideTransition(
                  index: 2 + entry.key,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildCategoryCard(
                      context,
                      entry.value,
                      currencyFormat,
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    TaxStatus status,
    NumberFormat format,
  ) {
    final isDeclarable = status.shouldDeclare;

    return AppCard(
      style: AppCardStyle.elevated,
      backgroundColor: isDeclarable
          ? AppColors.expenseLight
          : AppColors.incomeLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (isDeclarable ? AppColors.expense : AppColors.income)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeclarable ? Icons.warning_amber : Icons.check_circle,
              size: 40,
              color: isDeclarable ? AppColors.expense : AppColors.income,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isDeclarable ? 'Debes Declarar Renta' : 'Bajo Topes de Declaración',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDeclarable ? AppColors.expense : AppColors.income,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Año gravable $_year',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () =>
                _showEditUvtDialog(context, ref, status.uvtValue, _year),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UVT: ${format.format(status.uvtValue)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.edit, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    TaxCategoryProgress category,
    NumberFormat format,
  ) {
    final progressColor = category.percentage >= 1.0
        ? AppColors.expense
        : category.percentage >= 0.75
        ? AppColors.warning
        : AppColors.income;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(
                  '${(category.percentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: category.percentage.clamp(0.0, 1.0),
              backgroundColor: progressColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acumulado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    format.format(category.currentValue),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tope (${category.thresholdUvt.toStringAsFixed(0)} UVT)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    format.format(category.thresholdValue),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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

  void _showEditUvtDialog(
    BuildContext context,
    WidgetRef ref,
    double currentValue,
    int year,
  ) {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Valor UVT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Año: $year',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor UVT',
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Ej: 52000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text);
              if (newValue == null || newValue <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingrese un valor válido')),
                );
                return;
              }

              try {
                await ref
                    .read(taxRepositoryProvider)
                    .updateUvtValue(year, newValue);
                ref.invalidate(taxStatusProvider(year));
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
