import 'package:finanzapp_v2/features/periods/data/period_repository.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final periodsListProvider = FutureProvider.family
    .autoDispose<List<Period>, String>((ref, householdId) async {
      final repository = ref.watch(periodRepositoryProvider);
      return repository.getPeriods(householdId);
    });
