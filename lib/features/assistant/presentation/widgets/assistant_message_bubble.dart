import 'package:flutter/material.dart';

import '../../../../core/assistant/assistant_action.dart';
import '../../../../core/assistant/proposed_action.dart';
import '../state/assistant_chat_models.dart';
import 'proposal_card.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.entry,
    required this.onConfirm,
    required this.onReject,
    required this.onUndo,
    required this.onSelectCategory,
    required this.onEdit,
    required this.onCreateCategory,
    required this.onSuggestion,
  });

  final ChatEntry entry;
  final void Function(int index) onConfirm;
  final void Function(int index) onReject;
  final void Function(int index) onUndo;
  final void Function(int index, CategoryOption option) onSelectCategory;
  final void Function(int index) onEdit;
  final void Function(int index) onCreateCategory;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final bool user = entry.role == ChatRole.user;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = user
        ? scheme.primaryContainer
        : scheme.surfaceContainerLow;
    final Color foreground = user
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: entry.isError ? scheme.errorContainer : background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              entry.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: entry.isError ? scheme.onErrorContainer : foreground,
              ),
            ),
            if (entry.options.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.options
                    .map(
                      (String option) => ActionChip(
                        label: Text(option),
                        onPressed: () => onSuggestion(option),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            for (int i = 0; i < entry.proposals.length; i++)
              ProposalCard(
                item: entry.proposals[i],
                onConfirm: () => onConfirm(i),
                onReject: () => onReject(i),
                onUndo: () => onUndo(i),
                onSelectCategory: (CategoryOption option) =>
                    onSelectCategory(i, option),
                onEdit: _canEdit(entry.proposals[i]) ? () => onEdit(i) : null,
                onCreateCategory: entry.proposals[i].status ==
                        ProposalStatus.pending
                    ? () => onCreateCategory(i)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  bool _canEdit(ChatProposal item) {
    return item.status == ProposalStatus.pending &&
        item.proposal.action is AddTransactionAction;
  }
}
