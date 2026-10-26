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
        .map(
          (ProposedAction proposal) => ChatProposal(
            proposal: proposal,
            originalCategoryId: proposalCategoryId(proposal),
          ),
        )
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
    clearSuggestedCategory: true,
    summary:
        '$typeLabel ${formatRupiah(action.amount)} \u2014 '
        '${option.name}',
  );
}

int? proposalCategoryId(ProposedAction proposal) {
  final AssistantAction action = proposal.action;
  return action is AddTransactionAction ? action.categoryId : null;
}

Future<void> recordLearning(
  LearningRepository repository,
  String input,
  ProposedAction proposal,
  String outcome, {
  int? originalCategoryId,
}) async {
  final AssistantAction action = proposal.action;
  await repository.record(
    inputText: input,
    actionJson: jsonEncode(actionToJson(action)),
    outcome: outcome,
  );
  await repository.applyFeedback(
    inputText: input,
    outcome: outcome,
    oldCategoryId: originalCategoryId,
    newCategoryId: outcome == 'rejected' || action is! AddTransactionAction
        ? null
        : action.categoryId,
    merchant: action is AddTransactionAction ? action.merchant : null,
  );
}

Future<ProposedAction?> createCategoryForProposal({
  required AssistantExecutor executor,
  required ProposedAction proposal,
}) async {
  final AssistantAction action = proposal.action;
  final String? name = proposal.suggestedCategoryName?.trim();
  if (action is! AddTransactionAction || name == null || name.isEmpty) {
    return null;
  }
  final AssistantExecution result = await executor.execute(
    CreateCategoryAction(name: name, type: action.type),
  );
  final int? categoryId = result.createdCategoryId;
  if (categoryId == null) {
    return null;
  }
  final AddTransactionAction updated = AddTransactionAction(
    amount: action.amount,
    type: action.type,
    walletId: action.walletId,
    categoryId: categoryId,
    note: action.note,
    merchant: action.merchant,
    excludeFromTarget: action.excludeFromTarget,
    createdAt: action.createdAt,
  );
  final String typeLabel = action.type == TransactionType.income
      ? 'Tambah pemasukan'
      : 'Tambah pengeluaran';
  return ProposedAction(
    action: updated,
    confidence: 1,
    source: proposal.source,
    summary:
        '$typeLabel ${formatRupiah(action.amount)} \u2014 $name',
    details: proposal.details,
  );
}

String chatErrorMessage(Object error) {
  if (error is AssistantExecutionException) {
    return error.message;
  }
  return 'Tidak dapat memproses usulan. Coba lagi.';
}
