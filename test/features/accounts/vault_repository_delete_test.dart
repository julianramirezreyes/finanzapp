import 'package:dio/dio.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  group('VaultRepository.deleteVaultItem (delete card 409)', () {
    test('rethrows the DioException so the 409 status survives', () async {
      // The backend uses Go's http.Error -> plain-text body with a newline.
      final adapter = FakeDioAdapter(
        statusCode: 409,
        responseText:
            'No puedes eliminar una tarjeta con movimientos asociados\n',
      );
      final repo = VaultRepository(buildFakeDio(adapter));

      DioException? caught;
      try {
        await repo.deleteVaultItem('acc-1', 'card-1');
      } on DioException catch (e) {
        caught = e;
      }

      expect(
        caught,
        isNotNull,
        reason: 'must rethrow DioException, not a generic Exception',
      );
      expect(caught!.response?.statusCode, 409);
      expect(
        caught.response?.data.toString().trim(),
        'No puedes eliminar una tarjeta con movimientos asociados',
      );
    });

    test('issues a DELETE to the vault item endpoint on success', () async {
      final adapter = FakeDioAdapter(statusCode: 204);
      final repo = VaultRepository(buildFakeDio(adapter));

      await repo.deleteVaultItem('acc-1', 'card-1');

      expect(adapter.requests, hasLength(1));
      expect(adapter.lastRequest.method, 'DELETE');
      expect(adapter.lastRequest.path, '/accounts/acc-1/vault/card-1');
    });
  });
}
