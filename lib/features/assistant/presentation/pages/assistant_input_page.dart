import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/assistant/proposed_action.dart';
import '../providers/assistant_chat_controller.dart';
import '../state/assistant_chat_models.dart';
import '../widgets/assistant_composer.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/edit_transaction_sheet.dart';

class AssistantInputPage extends ConsumerStatefulWidget {
  const AssistantInputPage({super.key});

  @override
  ConsumerState<AssistantInputPage> createState() => _AssistantInputPageState();
}

class _AssistantInputPageState extends ConsumerState<AssistantInputPage> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String input = _text.text.trim();
    if (input.isEmpty) {
      return;
    }
    _text.clear();
    await ref.read(assistantChatControllerProvider.notifier).submit(input);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _editEntry(ChatEntry entry, int index) async {
    final ChatProposal item = entry.proposals[index];
    final ProposedAction? updated = await showEditTransactionSheet(
      context,
      item.proposal,
    );
    if (updated != null && mounted) {
      ref
          .read(assistantChatControllerProvider.notifier)
          .applyEdit(entry.id, index, updated);
    }
  }

  void _useSuggestion(String option) {
    _text.text = option;
    _text.selection = TextSelection.collapsed(offset: option.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AssistantChatState state = ref.watch(assistantChatControllerProvider);
    ref.listen<AssistantChatState>(assistantChatControllerProvider, (
      AssistantChatState? previous,
      AssistantChatState next,
    ) {
      if (previous?.entries.length != next.entries.length) {
        _scrollToBottom();
      }
    });
    final AssistantChatController controller = ref.read(
      assistantChatControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Input')),
      body: Column(
        children: <Widget>[
          if (state.busy) const LinearProgressIndicator(),
          Expanded(
            child: state.entries.isEmpty
                ? const AssistantEmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: state.entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatEntry entry = state.entries[index];
                      return AssistantMessageBubble(
                        entry: entry,
                        onConfirm: (int itemIndex) =>
                            controller.confirm(entry.id, itemIndex),
                        onReject: (int itemIndex) =>
                            controller.reject(entry.id, itemIndex),
                        onUndo: (int itemIndex) =>
                            controller.undo(entry.id, itemIndex),
                        onSelectCategory:
                            (int itemIndex, CategoryOption option) => controller
                                .selectCategory(entry.id, itemIndex, option),
                        onEdit: (int itemIndex) => _editEntry(entry, itemIndex),
                        onSuggestion: _useSuggestion,
                      );
                    },
                  ),
          ),
          AssistantComposer(
            controller: _text,
            focusNode: _focus,
            busy: state.busy,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
