import 'package:dio/dio.dart';
import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/pocket.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_repository.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _dummyDio = Dio();

Account _account(String id, String name) =>
    Account(id: id, name: name, type: 'cash', balance: 100000, currency: 'COP');

Pocket _pocket(String id, String accountId, double balance) =>
    Pocket(id: id, accountId: accountId, name: 'Ahorro', balance: balance);

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository(this._accounts) : super(_dummyDio);
  final List<Account> _accounts;
  @override
  Future<List<Account>> getAccounts() async => _accounts;
}

/// Returns pockets for healthy accounts but THROWS for [failingAccountId],
/// reproducing a single account whose vault/pockets call fails (e.g. a 401).
class _FlakyPocketRepository extends PocketRepository {
  _FlakyPocketRepository({
    required this.failingAccountId,
    required this.healthyBalances,
  }) : super(_dummyDio);

  final String failingAccountId;
  final Map<String, double> healthyBalances;

  @override
  Future<List<Pocket>> getPockets(String accountId) async {
    if (accountId == failingAccountId) {
      throw Exception('boom: pockets for $accountId failed');
    }
    final balance = healthyBalances[accountId] ?? 0;
    return [_pocket('p-$accountId', accountId, balance)];
  }
}

class _FakeHistoryRepository extends HistoryRepository {
  _FakeHistoryRepository() : super(_dummyDio);
  @override
  Future<YearlySummary> getYearlySummary({int? year}) async => YearlySummary(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        personalIncome: 0,
        personalExpense: 0,
        householdIncome: 0,
        householdExpense: 0,
      );
}

void main() {
  test(
    '5b.3: a single failing getPockets does NOT empty the pocketsTotals of the '
    'healthy accounts',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            _FakeAccountRepository([
              _account('acc-1', 'Efectivo'),
              _account('acc-2', 'Banco'),
              _account('acc-3', 'Ahorros'),
            ]),
          ),
          pocketRepositoryProvider.overrideWithValue(
            _FlakyPocketRepository(
              failingAccountId: 'acc-2',
              healthyBalances: {'acc-1': 1500.0, 'acc-3': 2500.0},
            ),
          ),
          historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(dashboardProvider.future);

      // The healthy accounts keep their real totals.
      expect(data.pocketsTotals['acc-1'], 1500.0,
          reason: 'acc-1 total must survive acc-2 failing');
      expect(data.pocketsTotals['acc-3'], 2500.0,
          reason: 'acc-3 total must survive acc-2 failing');

      // The failing account degrades to absent/0, not the whole map to empty.
      expect(data.pocketsTotals.containsKey('acc-2'), isFalse,
          reason: 'the failing account has no pocket total');

      // The map is NOT wiped: it still holds the two healthy entries.
      expect(data.pocketsTotals.length, 2,
          reason: 'only the failing account is dropped, not all of them');
    },
  );
}
