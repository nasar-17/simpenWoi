import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/assistant/assistant_action.dart';
import '../../../../core/assistant/assistant_action_codec.dart';
import '../../../../core/assistant/assistant_execution.dart';
import '../../../../core/assistant/assistant_executor.dart';
import '../../../../core/assistant/proposed_action.dart';
import '../../../../core/constants/transaction_values.dart';
import '../../../../core/utils/currency.dart';
import '../../../learning/data/learning_repository.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../state/assistant_chat_models.dart';
import 'assistant_providers.dart';

part 'assistant_chat_support.dart';

final assistantChatControllerProvider = NotifierProvider(
  AssistantChatController.new,
);

class AssistantChatController extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() => const AssistantChatState();

  Future<void> submit(String raw) async {
    final String input = raw.trim();
    if (input.isEmpty || state.busy) {
      return;
    }
    state = state.copyWith(busy: true);
    state = state.add(
      ChatEntry(
        id: state.nextId,
        role: ChatRole.user,
        text: input,
        sourceInput: input,
      ),
    );
    try {
      final List<ProposedAction> proposals = await ref
          .read(inputEngineProvider)
          .process(input);
      await handleAssistantProposals(
        executor: ref.read(assistantExecutorProvider),
        input: input,
        proposals: proposals,
        add: (text, options, proposals, sourceInput, isError) => _addAssistant(
          text,
          options: options,
          proposals: proposals,
          sourceInput: sourceInput,
          isError: isError,
        ),
      );
    } catch (error) {
      _addAssistant(chatErrorMessage(error), isError: true);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> confirm(int entryId, int index) async {
    final ChatProposal? item = proposalAt(state, entryId, index);
    if (item == null || item.status != ProposalStatus.pending) {
      return;
    }
    _setProposal(entryId, index, item.copyWith(status: ProposalStatus.saving));
    try {
      final AssistantExecution result = await ref
          .read(assistantExecutorProvider)
          .execute(item.proposal.action);
      _setProposal(
        entryId,
        index,
        item.copyWith(status: ProposalStatus.saved, undo: result.undo),
      );
      final ChatEntry? entry = state.entryById(entryId);
      if (entry != null) {
        await recordLearning(
          ref.read(learningRepositoryProvider),
          entry.sourceInput,
          item.proposal,
          item.wasCorrected ? 'corrected' : 'accepted',
        );
      }
      _addAssistant(result.message);
    } catch (error) {
      _setProposal(
        entryId,
        index,
        item.copyWith(
          status: ProposalStatus.error,
          error: chatErrorMessage(error),
        ),
      );
      _addAssistant(chatErrorMessage(error), isError: true);
    }
  }

  Future<void> reject(int entryId, int index) async {
    final ChatProposal? item = proposalAt(state, entryId, index);
    if (item == null || item.status != ProposalStatus.pending) {
      return;
    }
    _setProposal(
      entryId,
      index,
      item.copyWith(status: ProposalStatus.rejected),
    );
    final ChatEntry? entry = state.entryById(entryId);
    if (entry != null) {
      await recordLearning(
        ref.read(learningRepositoryProvider),
        entry.sourceInput,
        item.proposal,
        'rejected',
      );
    }
    _addAssistant('Baik, usulan ini tidak disimpan.');
  }

  Future<void> undo(int entryId, int index) async {
    final ChatProposal? item = proposalAt(state, entryId, index);
    if (item == null ||
        item.status != ProposalStatus.saved ||
        item.undo == null) {
      return;
    }
    try {
      await item.undo!();
      _setProposal(
        entryId,
        index,
        item.copyWith(status: ProposalStatus.undone),
      );
      _addAssistant('Perubahan dibatalkan.');
    } catch (error) {
      _addAssistant(chatErrorMessage(error), isError: true);
    }
  }

  void selectCategory(int entryId, int index, CategoryOption option) {
    final ChatProposal? item = proposalAt(state, entryId, index);
    if (item == null || item.status != ProposalStatus.pending) {
      return;
    }
    final ProposedAction? updated = withSelectedCategory(item.proposal, option);
    if (updated != null) {
      _setProposal(
        entryId,
        index,
        item.copyWith(proposal: updated, wasCorrected: true),
      );
    }
  }

  void applyEdit(int entryId, int index, ProposedAction proposal) {
    final ChatProposal? item = proposalAt(state, entryId, index);
    if (item == null || item.status != ProposalStatus.pending) {
      return;
    }
    _setProposal(
      entryId,
      index,
      item.copyWith(proposal: proposal, wasCorrected: true),
    );
  }

  void _addAssistant(
    String text, {
    List<String> options = const <String>[],
    List<ChatProposal> proposals = const <ChatProposal>[],
    String sourceInput = '',
    bool isError = false,
  }) {
    state = state.add(
      ChatEntry(
        id: state.nextId,
        role: ChatRole.assistant,
        text: text,
        options: options,
        proposals: proposals,
        sourceInput: sourceInput,
        isError: isError,
      ),
    );
  }

  void _setProposal(int entryId, int index, ChatProposal item) {
    state = state.updateEntry(entryId, (ChatEntry entry) {
      final List<ChatProposal> proposals = <ChatProposal>[...entry.proposals];
      if (index >= 0 && index < proposals.length) {
        proposals[index] = item;
      }
      return entry.copyWith(proposals: proposals);
    });
  }
}
