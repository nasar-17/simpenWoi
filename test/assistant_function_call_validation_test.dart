import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/assistant_validator.dart';
import 'package:simpen_woi/features/assistant/data/function_gemma_action_mapper.dart';
import 'package:simpen_woi/features/assistant/data/function_gemma_model_storage.dart';

import 'assistant_test_support.dart';

void main() {
  const FunctionGemmaActionMapper mapper = FunctionGemmaActionMapper();
  const Map<String, dynamic> valid = <String, dynamic>{
    'amount': 15000, 'transaction_type': 'expense', 'wallet_id': 1, 'category_id': 1,
  };

  test('compatible SDK identity includes the model file extension', () {
    expect(FunctionGemmaModelStorage.modelId, FunctionGemmaModelStorage.fileName);
  });

  test('accepts a schema-valid action with an existing category', () {
    const FunctionCallResponse call = FunctionCallResponse(
      name: 'add_transaction', args: valid,
    );
    expect(mapper.map(call, testContext())?.action, isA<AddTransactionAction>());
  });

  for (final ({String reason, Map<String, dynamic> args}) item in <({String reason, Map<String, dynamic> args})>[
    (reason: 'fractional amount', args: <String, dynamic>{...valid, 'amount': 15000.9}),
    (reason: 'string amount', args: <String, dynamic>{...valid, 'amount': '15rb'}),
    (reason: 'unknown category', args: <String, dynamic>{...valid, 'category_id': 999}),
    (reason: 'income category for expense', args: <String, dynamic>{...valid, 'category_id': 2}),
    (reason: 'unknown wallet', args: <String, dynamic>{...valid, 'wallet_id': 999}),
    (reason: 'unknown field', args: <String, dynamic>{...valid, 'created_at': '2020-01-01'}),
    (reason: 'non-string note', args: <String, dynamic>{...valid, 'note': 42}),
    (reason: 'unknown transaction type', args: <String, dynamic>{...valid, 'transaction_type': 'debit'}),
  ]) {
    test('rejects ${item.reason}', () {
      expect(mapper.map(FunctionCallResponse(name: 'add_transaction', args: item.args),
          testContext()), isNull);
    });
  }

  test('missing balance cannot silently become zero', () {
    expect(mapper.map(const FunctionCallResponse(
      name: 'set_wallet_balance', args: <String, dynamic>{'wallet_id': 1},
    ), testContext()), isNull);
  });

  test('invalid target months cannot pass action or model validation', () {
    for (final String month in <String>['2026-00', '2026-13', '2026-99', '0000-01']) {
      expect(validateAssistantAction(SetSpendingTargetAction(month: month, amount: 100),
          testContext()), isNotNull);
      expect(mapper.map(FunctionCallResponse(name: 'set_spending_target',
          args: <String, dynamic>{'month': month, 'amount': 100}), testContext()), isNull);
    }
    expect(validateAssistantAction(const SetSpendingTargetAction(month: '2026-12', amount: 100),
        testContext()), isNull);
  });

  test('unknown period cannot silently become monthly', () {
    expect(mapper.map(const FunctionCallResponse(
      name: 'query_total', args: <String, dynamic>{'period': 'year'},
    ), testContext()), isNull);
  });
}
