import 'package:finanzapp_v2/features/household/data/household_repository.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdProvider = FutureProvider.autoDispose<Household?>((ref) async {
  final repository = ref.watch(householdRepositoryProvider);
  return repository.getMyHousehold();
});
