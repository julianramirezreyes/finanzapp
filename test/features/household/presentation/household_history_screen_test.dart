import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:finanzapp_v2/features/periods/domain/settlement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'household-1';
const _selectedPeriodId = 'period-1';
const _otherPeriodId = 'period-2';

final _settlement = Settlement(
  totalAmount: 100,
  shareA: 60,
  shareB: 40,
  paidByA: 100,
  paidByB: 0,
  diffA: 40,
  diffB: -40,
  debtorId: 'user-b',
  creditorId: 'user-a',
  balance: 40,
);

void main() {
  test(
    'refreshes only the selected settlement after a successful mutation',
    () async {
      var selectedFetches = 0;
      var otherFetches = 0;
      final container = ProviderContainer(
        overrides: [
          periodsListProvider(_householdId).overrideWith(
            (ref) async => [
              _period(_selectedPeriodId, 2026, 8),
              _period(_otherPeriodId, 2026, 7),
            ],
          ),
          settlementProvider((
            householdId: _householdId,
            periodId: _selectedPeriodId,
          )).overrideWith((ref) async {
            selectedFetches++;
            return _settlement;
          }),
          settlementProvider((
            householdId: _householdId,
            periodId: _otherPeriodId,
          )).overrideWith((ref) async {
            otherFetches++;
            return _settlement;
          }),
        ],
      );
      addTearDown(container.dispose);
      final selectedProvider = settlementProvider((
        householdId: _householdId,
        periodId: _selectedPeriodId,
      ));
      final otherProvider = settlementProvider((
        householdId: _householdId,
        periodId: _otherPeriodId,
      ));
      container.listen(selectedProvider, (_, _) {});
      container.listen(otherProvider, (_, _) {});
      await container.read(selectedProvider.future);
      await container.read(otherProvider.future);

      await container.read(_runMutationProvider((action: () async {})).future);
      await Future<void>.delayed(Duration.zero);

      expect(selectedFetches, 2);
      expect(otherFetches, 1);
    },
  );

  test('does not refresh a settlement when the mutation fails', () async {
    var selectedFetches = 0;
    final container = ProviderContainer(
      overrides: [
        periodsListProvider(
          _householdId,
        ).overrideWith((ref) async => [_period(_selectedPeriodId, 2026, 8)]),
        settlementProvider((
          householdId: _householdId,
          periodId: _selectedPeriodId,
        )).overrideWith((ref) async {
          selectedFetches++;
          return _settlement;
        }),
      ],
    );
    addTearDown(container.dispose);
    final selectedProvider = settlementProvider((
      householdId: _householdId,
      periodId: _selectedPeriodId,
    ));
    container.listen(selectedProvider, (_, _) {});
    await container.read(selectedProvider.future);

    await expectLater(
      container.read(
        _runMutationProvider((
          action: () async => throw StateError('mutation failed'),
        )).future,
      ),
      throwsA(isA<StateError>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(selectedFetches, 1);
  });
}

final _runMutationProvider =
    FutureProvider.family<void, ({Future<void> Function() action})>((
      ref,
      params,
    ) {
      return refreshSettlementAfterSnapshotMutation(
        loadPeriods: () => ref.read(periodsListProvider(_householdId).future),
        selectedDate: DateTime.utc(2026, 8, 1),
        mutation: params.action,
        invalidateSettlement: (key) => ref.invalidate(settlementProvider(key)),
      );
    });

Period _period(String id, int year, int month) => Period(
  id: id,
  householdId: _householdId,
  year: year,
  month: month,
  startDate: DateTime.utc(year, month, 1),
  endDate: DateTime.utc(year, month + 1, 1),
  status: 'open',
);
