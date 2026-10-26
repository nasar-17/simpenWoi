import '../../../../core/assistant/proposed_action.dart';

enum ChatRole { user, assistant }

enum ProposalStatus { pending, saving, saved, rejected, undone, error }

class ChatProposal {
  const ChatProposal({
    required this.proposal,
    this.status = ProposalStatus.pending,
    this.wasCorrected = false,
    this.error,
    this.undo,
  });

  final ProposedAction proposal;
  final ProposalStatus status;
  final bool wasCorrected;
  final String? error;
  final Future<void> Function()? undo;

  ChatProposal copyWith({
    ProposedAction? proposal,
    ProposalStatus? status,
    bool? wasCorrected,
    String? error,
    Future<void> Function()? undo,
  }) {
    return ChatProposal(
      proposal: proposal ?? this.proposal,
      status: status ?? this.status,
      wasCorrected: wasCorrected ?? this.wasCorrected,
      error: error ?? this.error,
      undo: undo ?? this.undo,
    );
  }
}

class ChatEntry {
  const ChatEntry({
    required this.id,
    required this.role,
    required this.text,
    this.proposals = const <ChatProposal>[],
    this.options = const <String>[],
    this.sourceInput = '',
    this.isError = false,
  });

  final int id;
  final ChatRole role;
  final String text;
  final List<ChatProposal> proposals;
  final List<String> options;
  final String sourceInput;
  final bool isError;

  ChatEntry copyWith({
    String? text,
    List<ChatProposal>? proposals,
    List<String>? options,
    bool? isError,
  }) {
    return ChatEntry(
      id: id,
      role: role,
      text: text ?? this.text,
      proposals: proposals ?? this.proposals,
      options: options ?? this.options,
      sourceInput: sourceInput,
      isError: isError ?? this.isError,
    );
  }
}

class AssistantChatState {
  const AssistantChatState({
    this.entries = const <ChatEntry>[],
    this.busy = false,
    this.nextId = 1,
  });

  final List<ChatEntry> entries;
  final bool busy;
  final int nextId;

  AssistantChatState copyWith({
    List<ChatEntry>? entries,
    bool? busy,
    int? nextId,
  }) {
    return AssistantChatState(
      entries: entries ?? this.entries,
      busy: busy ?? this.busy,
      nextId: nextId ?? this.nextId,
    );
  }

  AssistantChatState add(ChatEntry entry) {
    return copyWith(
      entries: <ChatEntry>[...entries, entry],
      nextId: nextId + 1,
    );
  }

  AssistantChatState updateEntry(
    int id,
    ChatEntry Function(ChatEntry entry) update,
  ) {
    return copyWith(
      entries: entries
          .map((ChatEntry entry) => entry.id == id ? update(entry) : entry)
          .toList(growable: false),
    );
  }

  ChatEntry? entryById(int id) {
    for (final ChatEntry entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }
}
