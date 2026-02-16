import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/periods/domain/settlement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Check Equatable or simple record for family key
typedef SettlementKey = ({String householdId, String periodId});

final settlementProvider = FutureProvider.family
    .autoDispose<Settlement, SettlementKey>((ref, key) async {
      final repository = ref.watch(periodRepositoryProvider);
      return repository.getSettlement(key.householdId, key.periodId);
    });
