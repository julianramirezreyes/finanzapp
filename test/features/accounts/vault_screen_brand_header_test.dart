import 'dart:async';

import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';
import 'package:finanzapp_v2/shared/ui/widgets/branded_screen_background.dart';
import 'package:finanzapp_v2/shared/ui/widgets/branded_vault_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

/// boveda-brand-backdrop [auto]: VaultScreen INTEGRA el hero de marca
/// (BrandedVaultHeader) arriba y envuelve el body en BrandedScreenBackground
/// (wash sin watermark). El header reemplaza el AppBar plano y se ve SIEMPRE
/// (incluso en loading), con el nombre de la cuenta y, cuando hay datos de la
/// cuenta, el subtítulo `Bóveda · {tipo}` y el total formateado.
class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

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

Account _account() => Account(
  id: 'acc-1',
  name: 'Bancolombia',
  type: 'savings',
  balance: 1234567,
  currency: 'COP',
);

Future<void> _pumpVault(
  WidgetTester tester, {
  String? accountType,
  double? accountBalance,
  bool itemsLoading = false,
}) async {
  _ignoreBenignListTileAssertion();
  const accountId = 'acc-1';

  final adapter = FakeDioAdapter(statusCode: 200);
  final dio = buildFakeDio(adapter);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
        pocketsProvider(accountId).overrideWith((ref) async => []),
        vaultDebtSummaryProvider(accountId).overrideWith((ref) async => []),
        vaultItemsProvider(accountId).overrideWith((ref) {
          if (itemsLoading) {
            // Never completes (no pending timer) → stays in loading.
            return Completer<List<VaultItem>>().future;
          }
          return Future.value(<VaultItem>[]);
        }),
        accountsListProvider.overrideWith((ref) async => [_account()]),
      ],
      child: MaterialApp(
        home: VaultScreen(
          accountId: accountId,
          accountName: 'Bancolombia',
          accountType: accountType,
          accountBalance: accountBalance,
        ),
      ),
    ),
  );
  // Pump one frame; do NOT settle when loading (provider never resolves).
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders BrandedVaultHeader with the account name and NO flat AppBar',
    (tester) async {
      await _pumpVault(tester, accountType: 'savings', accountBalance: 1234567);
      await tester.pumpAndSettle();

      // Hero header present, AppBar gone.
      expect(find.byType(BrandedVaultHeader), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);

      final header = tester.widget<BrandedVaultHeader>(
        find.byType(BrandedVaultHeader),
      );
      expect(header.name, 'Bancolombia');
      // Subtitle "Bóveda · <tipo legible>" and a formatted total.
      expect(header.subtitle, contains('Bóveda'));
      expect(header.subtitle, contains('Ahorros'));
      expect(header.total, isNotNull);
      expect(header.total, contains('1.234.567'));
      // Back arrow wired.
      expect(header.onBack, isNotNull);
    },
  );

  testWidgets('wraps the body in BrandedScreenBackground without watermark', (
    tester,
  ) async {
    await _pumpVault(tester, accountType: 'savings', accountBalance: 1234567);
    await tester.pumpAndSettle();

    expect(find.byType(BrandedScreenBackground), findsOneWidget);
    final bg = tester.widget<BrandedScreenBackground>(
      find.byType(BrandedScreenBackground),
    );
    // The body wash must NOT duplicate the header watermark.
    expect(bg.showLogo, isFalse);
    expect(bg.name, 'Bancolombia');
  });

  testWidgets('header is visible even while items are loading', (tester) async {
    await _pumpVault(
      tester,
      accountType: 'savings',
      accountBalance: 1234567,
      itemsLoading: true,
    );

    // Header shows immediately; the body is still the loading spinner.
    expect(find.byType(BrandedVaultHeader), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets(
    'falls back to accountsListProvider lookup when type/balance not passed',
    (tester) async {
      // No accountType/accountBalance passed (go_router default path).
      await _pumpVault(tester);
      await tester.pumpAndSettle();

      final header = tester.widget<BrandedVaultHeader>(
        find.byType(BrandedVaultHeader),
      );
      // Resolved from the accounts list (type savings, balance 1.234.567).
      expect(header.subtitle, contains('Ahorros'));
      expect(header.total, contains('1.234.567'));
    },
  );
}
