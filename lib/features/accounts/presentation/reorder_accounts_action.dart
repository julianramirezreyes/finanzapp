import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';

/// Persists a drag-reorder of the account list robustly (new-b7-3).
///
/// The previous implementation mutated the provider's list IN PLACE and called
/// `reorderAccounts` fire-and-forget: a network failure was lost silently and
/// the optimistic UI kept the wrong order. This action instead:
///
/// 1. Works on an IMMUTABLE COPY of [accounts] (never mutates the provider's
///    list), so the optimistic move and any rollback stay consistent.
/// 2. `await`s the repository call inside a try/catch.
/// 3. On success invalidates [accountsListProvider] so the UI re-reads the
///    server-confirmed order.
/// 4. On failure shows an error SnackBar; because the provider list was never
///    mutated, the next build naturally renders the original order (rollback).
///
/// [oldIndex]/[newIndex] come straight from the reorderable list callback
/// (caller passes them unadjusted; the standard `oldIndex < newIndex` shift is
/// applied here).
Future<void> reorderAccountsAction({
  required WidgetRef ref,
  required BuildContext context,
  required List<Account> accounts,
  required int oldIndex,
  required int newIndex,
}) async {
  // Snapshot first: an immutable copy we can safely reorder without touching
  // the provider's state (R3).
  final reordered = List<Account>.of(accounts);
  var target = newIndex;
  if (oldIndex < target) {
    target -= 1;
  }
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(target, moved);

  try {
    await ref.read(accountRepositoryProvider).reorderAccounts(reordered);
    // Re-read the server-confirmed order.
    ref.invalidate(accountsListProvider);
  } catch (_) {
    // The provider list was never mutated, so the UI already shows the original
    // order — just tell the user the move did not stick.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al reordenar las cuentas')),
    );
  }
}
