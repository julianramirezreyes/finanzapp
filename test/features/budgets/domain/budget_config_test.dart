import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetConfig split method defaults', () {
    test('uses proportional for a newly created config', () {
      final config = BudgetConfig(id: '', updatedAt: DateTime.utc(2026, 8, 1));

      expect(config.splitMethod, 'proportional');
    });

    test('uses proportional when split_method is absent from JSON', () {
      final config = BudgetConfig.fromJson({
        'id': 'config-1',
        'updated_at': '2026-08-01T00:00:00.000Z',
      });

      expect(config.splitMethod, 'proportional');
    });

    test('preserves explicitly persisted equal and custom methods', () {
      final equal = BudgetConfig.fromJson({
        'id': 'equal',
        'split_method': 'equal',
        'updated_at': '2026-08-01T00:00:00.000Z',
      });
      final custom = BudgetConfig.fromJson({
        'id': 'custom',
        'split_method': 'custom',
        'updated_at': '2026-08-01T00:00:00.000Z',
      });

      expect(equal.splitMethod, 'equal');
      expect(custom.splitMethod, 'custom');
    });
  });
}
