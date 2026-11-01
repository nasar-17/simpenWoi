import 'package:flutter_test/flutter_test.dart';
import 'package:simpen_woi/core/assistant/assistant_action.dart';
import 'package:simpen_woi/core/assistant/assistant_context.dart';
import 'package:simpen_woi/core/assistant/proposed_action.dart';
import 'package:simpen_woi/core/database/app_database.dart';
import 'package:simpen_woi/features/capture/domain/notification_ai_decision.dart';

void main() {
  final AssistantContext context = AssistantContext(
    wallets: <Wallet>[
      Wallet(id: 1, name: 'DANA', balance: 0, isDefault: true,
        createdAt: DateTime(2026)),
    ],
    categories: <Category>[
      Category(id: 7, name: 'Makan', type: 'expense', createdAt: DateTime(2026)),
      Category(id: 8, name: 'Gaji', type: 'income', createdAt: DateTime(2026)),
    ],
  );
  ProposedAction proposal(AssistantAction action, {ActionSource source = ActionSource.ai}) =>
      ProposedAction(action: action, confidence: 1, source: source, summary: 'test');
  NotificationAiDecision decide(AssistantAction action, {ActionSource source = ActionSource.ai}) =>
      NotificationAiDecision.fromProposals(<ProposedAction>[proposal(action, source: source)], context);

  test('valid model expense retains amount, wallet, and category', () {
    final NotificationAiDecision result = decide(const AddTransactionAction(
      amount: 25000, type: 'expense', walletId: 1, categoryId: 7,
    ));
    expect(result.transaction?.amount, 25000);
    expect(result.transaction?.categoryId, 7);
    expect(result.discard, false);
  });
  test('missing model result stays pending, not discarded', () {
    final NotificationAiDecision result = NotificationAiDecision.fromProposals(null, context);
    expect(result.transaction, isNull);
    expect(result.discard, false);
  });
  test('only explicit model non-transaction marker discards', () {
    expect(decide(const AskClarificationAction(question: 'NOT_A_TRANSACTION')).discard, true);
    expect(decide(const AskClarificationAction(question: 'Nominal berapa?')).discard, false);
  });
  test('notification cannot execute wallet, transfer, or query tools', () {
    for (final AssistantAction action in <AssistantAction>[
      const SetWalletBalanceAction(walletId: 1, targetBalance: 999),
      const CreateWalletAction(name: 'Injected'),
      const QueryTotalAction(period: QueryTotalPeriod.today),
      const TransferAction(amount: 10, fromWalletId: 1, toWalletId: 2),
    ]) {
      expect(decide(action).transaction, isNull);
      expect(decide(action).discard, false);
    }
  });
  test('wrong category type, unknown wallet, and nonpositive amounts are rejected', () {
    for (final AddTransactionAction action in <AddTransactionAction>[
      const AddTransactionAction(amount: 20, type: 'income', walletId: 1, categoryId: 7),
      const AddTransactionAction(amount: 20, type: 'expense', walletId: 2, categoryId: 7),
      const AddTransactionAction(amount: 0, type: 'expense', walletId: 1),
      const AddTransactionAction(amount: -1, type: 'expense', walletId: 1),
    ]) {
      expect(decide(action).transaction, isNull);
    }
  });
  test('legacy rules or mixed multi-tool results cannot be auto imported', () {
    const AddTransactionAction action = AddTransactionAction(amount: 20, type: 'expense', walletId: 1);
    expect(decide(action, source: ActionSource.rules).transaction, isNull);
    expect(NotificationAiDecision.fromProposals(
      <ProposedAction>[proposal(action), proposal(const CreateWalletAction(name: 'new'))], context,
    ).transaction, isNull);
  });
}
