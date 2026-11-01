import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/proposed_action.dart';
import 'package:simpen_woi/features/assistant/domain/input_engine.dart';

import 'assistant_test_support.dart';

void main() {
  test('every natural-language intent reaches the model despite stale availability', () async {
    final RecordingAi ai = RecordingAi(actions: <ProposedAction>[transactionProposal()]);
    final InputEngine engine = InputEngine(
      dataRepository: ContextRepository(testContext()), aiProvider: ai,
    );
    const List<String> inputs = <String>[
      'bakso 15rb', 'saldo tunai jadi 100rb', 'total makan bulan ini',
      'transfer tunai ke BCA 20rb', 'batal', 'beli sesuatu yang belum ada di kamus',
    ];
    for (final String input in inputs) {
      final List<ProposedAction> result = await engine.process(input);
      expect(result.single.source, ActionSource.ai);
      expect(result.single.action, isA<AddTransactionAction>());
    }
    expect(ai.inputs, inputs);
  });

  test('missing model never falls back to keyword parsing or guessed amounts', () async {
    final RecordingAi ai = RecordingAi();
    final InputEngine engine = InputEngine(
      dataRepository: ContextRepository(testContext()), aiProvider: ai,
    );
    final List<ProposedAction> result = await engine.process('bakso 15rb');
    expect(ai.inputs, <String>['bakso 15rb']);
    expect(result.single.action, isA<AskClarificationAction>());
    expect(result.single.summary, contains('Model AI'));
  });

  test('invalid model category cannot reach financial execution', () async {
    final InputEngine engine = InputEngine(
      dataRepository: ContextRepository(testContext()),
      aiProvider: RecordingAi(actions: <ProposedAction>[
        transactionProposal(categoryId: 999),
      ]),
    );
    expect((await engine.process('bakso 15rb')).single.action,
        isA<AskClarificationAction>());
  });

  test('inference failure is surfaced and never creates a rule-based proposal', () async {
    final InputEngine engine = InputEngine(
      dataRepository: ContextRepository(testContext()),
      aiProvider: RecordingAi(failure: StateError('native generation failed')),
    );
    await expectLater(engine.process('bakso 15rb'), throwsStateError);
  });

  test('empty input does not load or invoke a model', () async {
    final RecordingAi ai = RecordingAi();
    final InputEngine engine = InputEngine(
      dataRepository: ContextRepository(testContext()), aiProvider: ai,
    );
    expect(await engine.process('   '), isEmpty);
    expect(ai.inputs, isEmpty);
  });
}
