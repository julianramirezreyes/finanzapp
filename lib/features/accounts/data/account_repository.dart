import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(dioProvider));
});

class AccountRepository {
  final Dio _dio;

  AccountRepository(this._dio);

  Future<List<Account>> getAccounts() async {
    try {
      final response = await _dio.get('/accounts');
      final List data = response.data;
      return data.map((json) => Account.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch accounts: $e');
    }
  }

  Future<void> createAccount(
    String name,
    String type,
    String currency,
    double initialBalance, {
    bool includeInNetWorth = true,
  }) async {
    try {
      await _dio.post(
        '/accounts',
        data: {
          'name': name,
          'type': type,
          'currency': currency,
          'initial_balance': initialBalance,
          'include_in_net_worth': includeInNetWorth,
        },
      );
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _dio.put(
        '/accounts/${account.id}',
        data: {
          'name': account.name,
          'type': account.type,
          'currency': account.currency,
          'include_in_net_worth': account.includeInNetWorth,
        },
      );
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  Future<void> reorderAccounts(List<Account> accounts) async {
    try {
      final items = accounts
          .asMap()
          .entries
          .map((e) => {'id': e.value.id, 'order': e.key})
          .toList();

      await _dio.post('/accounts/reorder', data: items);
    } catch (e) {
      throw Exception('Failed to reorder accounts: $e');
    }
  }
}
