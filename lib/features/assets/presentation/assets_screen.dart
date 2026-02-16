import 'package:finanzapp_v2/features/assets/data/asset_repository.dart';
import 'package:finanzapp_v2/features/assets/domain/asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Total Activos Adicionales",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(totalValue),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return ListTile(
                      leading: Icon(
                        asset.type == 'vehicle'
                            ? Icons.directions_car
                            : asset.type == 'real_estate'
                            ? Icons.home
                            : Icons.category,
                      ),
                      title: Text(asset.name),
                      subtitle: Text(
                        asset.isTaxable ? "Gravable" : "No Gravable",
                        style: TextStyle(
                          color: asset.isTaxable ? Colors.orange : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency.format(asset.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () =>
                                _confirmDelete(context, ref, asset),
                          ),
                        ],
                      ),
                      onTap: () => _showAssetDialog(context, ref, asset: asset),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Asset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Activo"),
        content: Text("¿Estás seguro de eliminar '${asset.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(assetRepositoryProvider).deleteAsset(asset.id);
              ref.invalidate(assetsListProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
          title: Text(asset == null ? "Nuevo Activo" : "Editar Activo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: "Valor COP"),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'vehicle', child: Text("Vehículo")),
                    DropdownMenuItem(
                      value: 'real_estate',
                      child: Text("Propiedad Raíz"),
                    ),
                    DropdownMenuItem(value: 'other', child: Text("Otro")),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                  decoration: const InputDecoration(labelText: "Tipo"),
                ),
                SwitchListTile(
                  title: const Text("Calculo UVT (Impuestos)"),
                  subtitle: const Text("Incluir en patrimonio bruto"),
                  value: isTaxable,
                  onChanged: (v) => setState(() => isTaxable = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
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
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}
