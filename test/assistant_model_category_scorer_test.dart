import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/assistant_context.dart';
import 'package:simpen_woi/core/assistant/proposed_action.dart';
import 'package:simpen_woi/features/assistant/domain/category_scorer.dart';
import 'package:simpen_woi/features/assistant/domain/model_category_scorer.dart';

import 'assistant_test_support.dart';

void main() {
  test('category comes from a validated model action', () async {
    final AssistantContext context = testContext();
    final RecordingAi ai = RecordingAi(actions: <ProposedAction>[transactionProposal()]);
    final ModelCategoryScorer scorer = ModelCategoryScorer(
      ai: ai, data: ContextRepository(context),
    );
    final List<CategoryScore> result = await scorer.score(
      text: 'restoran baru', type: 'expense', categories: context.categories,
    );
    expect(ai.inputs.single, contains('restoran baru'));
    expect(result.single.categoryId, 1);
  });

  for (final ({String reason, ProposedAction proposal}) item in <({String reason, ProposedAction proposal})>[
    (reason: 'unknown category', proposal: transactionProposal(categoryId: 99)),
    (reason: 'wrong category type', proposal: transactionProposal(categoryId: 2)),
    (reason: 'wrong transaction type', proposal: transactionProposal(type: 'income', categoryId: 2)),
    (reason: 'unknown wallet', proposal: transactionProposal(walletId: 999)),
    (reason: 'missing category', proposal: transactionProposal(categoryId: null)),
    (reason: 'unrelated command', proposal: const ProposedAction(
      action: CreateWalletAction(name: 'Bukan transaksi'), confidence: 1,
      source: ActionSource.ai, summary: 'Tidak boleh dieksekusi',
    )),
  ]) {
    test('rejects ${item.reason}', () async {
      final AssistantContext context = testContext();
      final ModelCategoryScorer scorer = ModelCategoryScorer(
        ai: RecordingAi(actions: <ProposedAction>[item.proposal]),
        data: ContextRepository(context),
      );
      expect(await scorer.score(text: 'catatan', type: 'expense',
          categories: context.categories), isEmpty);
    });
  }

  test('no model means no predicted category', () async {
    final AssistantContext context = testContext();
    final ModelCategoryScorer scorer = ModelCategoryScorer(
      ai: RecordingAi(), data: ContextRepository(context),
    );
    expect(await scorer.score(text: 'bakso', type: 'expense',
        categories: context.categories), isEmpty);
  });
}
