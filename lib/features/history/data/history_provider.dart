import 'package:finanzapp_v2/features/history/data/history_repository.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final personalHistoryProvider =
    FutureProvider.family<PersonalHistorySummary, ({int? month, int? year})>((
      ref,
      params,
    ) async {
      return ref
          .watch(historyRepositoryProvider)
          .getPersonalHistory(month: params.month, year: params.year);
    });
