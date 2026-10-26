part of 'assistant_chat_controller.dart';

typedef AssistantMessageSink =
    void Function(
      String text,
      List<String> options,
      List<ChatProposal> proposals,
      String sourceInput,
      bool isError,
    );

Future<void> handleAssistantProposals({
  required AssistantExecutor executor,
  required String input,
  required List<ProposedAction> proposals,
  required AssistantMessageSink add,
}) async {
  if (proposals.isEmpty) {
    add(
      'Saya belum yakin maksudnya. Coba tulis nominal dan keterangannya.',
      const <String>[],
      const <ChatProposal>[],
      '',
      false,
    );
    return;
  }
  for (final ProposedAction proposal in proposals) {
    final AssistantAction action = proposal.action;
    if (action is AskClarificationAction) {
      add(action.question, action.options, const <ChatProposal>[], '', false);
    } else if (action is QueryTotalAction) {
      try {
        final AssistantExecution result = await executor.execute(action);
        add(
          result.message,
          const <String>[],
          const <ChatProposal>[],
          '',
          false,
        );
      } catch (error) {
        add(
          chatErrorMessage(error),
          const <String>[],
          const <ChatProposal>[],
          '',
          true,
        );
      }
    }
  }
  final List<ProposedAction> actionable = proposals
      .where(
        (ProposedAction proposal) =>
            proposal.action is! AskClarificationAction &&
            proposal.action is! QueryTotalAction,
      )
      .toList(growable: false);
  if (actionable.isEmpty) {
    return;
  }
  add(
    actionable.length == 1
        ? 'Periksa dulu sebelum disimpan.'
        : 'Saya menemukan ${actionable.length} usulan. Periksa dulu.',
    const <String>[],
    actionable
        .map((ProposedAction proposal) => ChatProposal(proposal: proposal))
        .toList(growable: false),
    input,
    false,
  );
}

ChatProposal? proposalAt(AssistantChatState state, int entryId, int index) {
  final ChatEntry? entry = state.entryById(entryId);
  return entry == null || index < 0 || index >= entry.proposals.length
      ? null
      : entry.proposals[index];
}

ProposedAction? withSelectedCategory(
  ProposedAction proposal,
  CategoryOption option,
) {
  final AssistantAction action = proposal.action;
  if (action is! AddTransactionAction) {
    return null;
  }
  final AddTransactionAction updated = AddTransactionAction(
    amount: action.amount,
    type: action.type,
    walletId: action.walletId,
    categoryId: option.id,
    note: action.note,
    merchant: action.merchant,
    excludeFromTarget: action.excludeFromTarget,
    createdAt: action.createdAt,
  );
  final String typeLabel = action.type == TransactionType.income
      ? 'Tambah pemasukan'
      : 'Tambah pengeluaran';
  return proposal.copyWith(
    action: updated,
    confidence: 1,
    options: const <CategoryOption>[],
    summary:
        '$typeLabel ${formatRupiah(action.amount)} \u2014 '
        '${option.name}',
  );
}

Future<void> recordLearning(
  LearningRepository repository,
  String input,
  ProposedAction proposal,
  String outcome,
) {
  return repository.record(
    inputText: input,
    actionJson: jsonEncode(actionToJson(proposal.action)),
    outcome: outcome,
  );
}

String chatErrorMessage(Object error) {
  if (error is AssistantExecutionException) {
    return error.message;
  }
  return 'Tidak dapat memproses usulan. Coba lagi.';
}
