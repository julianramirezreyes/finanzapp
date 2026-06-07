import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

VaultItem _item(String id, String accountId) => VaultItem(
  id: id,
  accountId: accountId,
  title: 'Mi Item',
  data: '{}',
  isCard: false,
  createdAt: DateTime.utc(2026, 1, 1),
);

void _ignoreBenignListTileAssertion() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    previous?.call(details);
  };
}

Future<({int itemFetches})> _pumpAndDelete(
  WidgetTester tester, {
  required int deleteStatusCode,
  String? deleteText,
}) async {
  _ignoreBenignListTileAssertion();
  const accountId = 'acc-1';
  const itemId = 'item-1';

  final adapter = FakeDioAdapter(
    statusCode: deleteStatusCode,
    responseText: deleteText,
  );
  final dio = buildFakeDio(adapter);
  var itemFetches = 0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
        pocketsProvider(accountId).overrideWith((ref) async => []),
        vaultDebtSummaryProvider(accountId).overrideWith((ref) async => []),
        vaultItemsProvider(accountId).overrideWith((ref) async {
          itemFetches++;
          return [_item(itemId, accountId)];
        }),
      ],
      child: const MaterialApp(
        home: VaultScreen(accountId: accountId, accountName: 'Cuenta'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Expand the item card to reveal the Editar / Eliminar actions.
  await tester.tap(find.text('Mi Item'));
  await tester.pumpAndSettle();

  // Tap the card's Eliminar action (icon button), which opens the confirm dialog.
  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();

  // Confirm deletion in the dialog (the AlertDialog's "Eliminar" action).
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Eliminar'),
    ),
  );
  await tester.pumpAndSettle();

  return (itemFetches: itemFetches);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'delete blocked with 409 shows the backend message and does NOT invalidate '
    'the items list',
    (tester) async {
      final result = await _pumpAndDelete(
        tester,
        deleteStatusCode: 409,
        deleteText:
            'No puedes eliminar una tarjeta con movimientos asociados\n',
      );

      // The backend message must be surfaced in a SnackBar.
      expect(
        find.text('No puedes eliminar una tarjeta con movimientos asociados'),
        findsOneWidget,
      );
      // The list was loaded once and NOT invalidated (no re-fetch).
      expect(result.itemFetches, 1);
    },
  );

  testWidgets('clean delete (204) invalidates the items list (refresh)', (
    tester,
  ) async {
    final result = await _pumpAndDelete(tester, deleteStatusCode: 204);

    // No error SnackBar.
    expect(
      find.text('No puedes eliminar una tarjeta con movimientos asociados'),
      findsNothing,
    );
    // The list was invalidated → re-fetched at least once more.
    expect(result.itemFetches, greaterThan(1));
  });
}
