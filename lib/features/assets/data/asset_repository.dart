import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/assets/domain/asset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(dioProvider));
});

final assetsListProvider = FutureProvider<List<Asset>>((ref) async {
  return ref.watch(assetRepositoryProvider).getAssets();
});

class AssetRepository {
  final Dio _dio;

  AssetRepository(this._dio);

  Future<List<Asset>> getAssets() async {
    try {
      final response = await _dio.get('/assets');
      return (response.data as List).map((e) => Asset.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch assets: $e');
    }
  }

  Future<void> createAsset(
    String name,
    double value,
    String type,
    bool isTaxable,
  ) async {
    try {
      await _dio.post(
        '/assets',
        data: {
          'name': name,
          'value': value,
          'type': type,
          'is_taxable': isTaxable,
        },
      );
    } catch (e) {
      throw Exception('Failed to create asset: $e');
    }
  }

  Future<void> updateAsset(
    String id,
    String name,
    double value,
    String type,
    bool isTaxable,
  ) async {
    try {
      await _dio.put(
        '/assets/$id',
        data: {
          'name': name,
          'value': value,
          'type': type,
          'is_taxable': isTaxable,
        },
      );
    } catch (e) {
      throw Exception('Failed to update asset: $e');
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _dio.delete('/assets/$id');
    } catch (e) {
      throw Exception('Failed to delete asset: $e');
    }
  }
}
