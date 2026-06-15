import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Builds a RecurringPayment with LOCAL (naive) dates so the test proves
/// `toJson()` applies `.toUtc()` before serializing.
RecurringPayment _localDatedPayment({String id = 'rp-1'}) {
  return RecurringPayment(
    id: id,
    accountId: 'acc-1',
    context: 'personal',
    category: 'utilities',
    description: 'internet',
    amount: 50000,
    frequency: 'monthly',
    startDate: DateTime(2026, 1, 1, 8, 0),
    nextExecutionDate: DateTime(2026, 2, 1, 8, 0),
    isAutoConfirm: true,
    isActive: true,
  );
}

/// A valid JSON the backend would return; needed because create/update
/// repositories parse the response into a RecurringPayment.
Map<String, dynamic> _responseJson() => {
      'id': 'rp-1',
      'account_id': 'acc-1',
      'context': 'personal',
      'category': 'utilities',
      'description': 'internet',
      'amount': 50000,
      'frequency': 'monthly',
      'start_date': '2026-01-01T08:00:00Z',
      'next_date': '2026-02-01T08:00:00Z',
      'is_auto_confirm': true,
      'is_active': true,
    };

void main() {
  group('AutomationRepository date serialization (UTC offset)', () {
    test(
      'Scenario 3a.2: creating a payment serializes start_date and next_date with Z',
      () async {
        final adapter =
            FakeDioAdapter(statusCode: 201, responseJson: _responseJson());
        final repo = AutomationRepository(buildFakeDio(adapter));

        await repo.createPayment(_localDatedPayment());

        expect(adapter.requests, hasLength(1));
        final req = adapter.lastRequest;
        expect(req.method, 'POST');
        expect(req.path, '/automation/payments');

        final body = req.json;
        expect(
          (body['start_date'] as String).endsWith('Z'),
          isTrue,
          reason: 'start_date must be serialized as UTC with the Z offset',
        );
        expect(
          (body['next_date'] as String).endsWith('Z'),
          isTrue,
          reason: 'next_date must be serialized as UTC with the Z offset',
        );
      },
    );

    test(
      'Scenario 3a.3: updating a payment serializes next_date with Z',
      () async {
        final adapter =
            FakeDioAdapter(statusCode: 200, responseJson: _responseJson());
        final repo = AutomationRepository(buildFakeDio(adapter));

        await repo.updatePayment(_localDatedPayment(id: 'rp-9'));

        expect(adapter.requests, hasLength(1));
        final req = adapter.lastRequest;
        expect(req.method, 'PUT');
        expect(req.path, '/automation/payments/rp-9');

        final body = req.json;
        expect(
          (body['next_date'] as String).endsWith('Z'),
          isTrue,
          reason: 'next_date must be serialized as UTC with the Z offset',
        );
        expect((body['start_date'] as String).endsWith('Z'), isTrue);
      },
    );
  });
}
