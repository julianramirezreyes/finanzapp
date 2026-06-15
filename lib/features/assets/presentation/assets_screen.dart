import 'package:finanzapp_v2/features/assets/data/asset_repository.dart';
import 'package:finanzapp_v2/features/assets/domain/asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_spacing.dart';
import 'package:finanzapp_v2/shared/ui/widgets/empty_state.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/animations/fade_slide.dart';
import 'package:finanzapp_v2/shared/ui/dialogs/confirm_dialog.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activos y Patrimonio')),
      body: assetsAsync.when(
        data: (assets) {
          final totalValue = assets.fold(0.0, (sum, item) => sum + item.value);
          final currency = NumberFormat.currency(
            locale: 'es_CO',
            symbol: '\$',
            decimalDigits: 0,
          );

          return Column(
            children: [
              FadeSlideTransition(
                child: AppCard(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  style: AppCardStyle.elevated,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.stateFill(AppColors.income),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: AppColors.income,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Activos',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              Text(
                                currency.format(totalValue),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.income,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: assets.isEmpty
                    ? EmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'Sin activos',
                        subtitle:
                            'Agrega tus bienes para calcular tu patrimonio',
                        actionLabel: 'Agregar Activo',
                        onAction: () => _showAssetDialog(context, ref),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: assets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == assets.length) {
                            return const SizedBox(height: 80);
                          }
                          final asset = assets[index];
                          return FadeSlideTransition(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _buildAssetTile(
                                context,
                                ref,
                                asset,
                                currency,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAssetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssetTile(
    BuildContext context,
    WidgetRef ref,
    Asset asset,
    NumberFormat currency,
  ) {
    return AppCard(
      onTap: () => _showAssetDialog(context, ref, asset: asset),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.stateFill(AppColors.investment),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Icon(
              asset.type == 'vehicle'
                  ? Icons.directions_car
                  : asset.type == 'real_estate'
                  ? Icons.home
                  : Icons.category,
              color: AppColors.investment,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: asset.isTaxable
                        ? context.stateFill(AppColors.warning)
                        : context.subtleFill(),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    asset.isTaxable ? 'Gravable' : 'No Gravable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: asset.isTaxable
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            currency.format(asset.value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.income,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: () => _confirmDelete(context, ref, asset),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Asset asset) async {
    final confirmed = await DeleteConfirmDialog.show(
      context,
      itemName: asset.name,
    );

    if (confirmed == true) {
      await ref.read(assetRepositoryProvider).deleteAsset(asset.id);
      ref.invalidate(assetsListProvider);
    }
  }

  void _showAssetDialog(BuildContext context, WidgetRef ref, {Asset? asset}) {
    final nameController = TextEditingController(text: asset?.name);
    final valueController = TextEditingController(
      text: asset?.value.toStringAsFixed(0),
    );
    String type = asset?.type ?? 'other';
    bool isTaxable = asset?.isTaxable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(asset == null ? 'Nuevo Activo' : 'Editar Activo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Valor (COP)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'vehicle', child: Text('Vehículo')),
                    DropdownMenuItem(
                      value: 'real_estate',
                      child: Text('Propiedad Raíz'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  title: const Text('Incluir en Patrimonio'),
                  subtitle: const Text('Para cálculo UVT'),
                  value: isTaxable,
                  onChanged: (v) => setState(() => isTaxable = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final value = double.tryParse(valueController.text) ?? 0;

                if (name.isEmpty || value <= 0) return;

                if (asset == null) {
                  await ref
                      .read(assetRepositoryProvider)
                      .createAsset(name, value, type, isTaxable);
                } else {
                  await ref
                      .read(assetRepositoryProvider)
                      .updateAsset(asset.id, name, value, type, isTaxable);
                }
                ref.invalidate(assetsListProvider);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
