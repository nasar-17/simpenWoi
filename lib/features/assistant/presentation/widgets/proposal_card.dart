import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/assistant/assistant_action.dart';
import '../../../../core/assistant/proposed_action.dart';
import '../state/assistant_chat_models.dart';

part 'proposal_card_status.dart';

class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.item,
    required this.onConfirm,
    required this.onReject,
    required this.onUndo,
    required this.onSelectCategory,
    this.onEdit,
    this.onCreateCategory,
  });

  final ChatProposal item;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onUndo;
  final ValueChanged<CategoryOption> onSelectCategory;
  final VoidCallback? onEdit;
  final VoidCallback? onCreateCategory;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ProposedAction proposal = item.proposal;
    final bool pending = item.status == ProposalStatus.pending;
    final bool needsCategory =
        proposal.options.isNotEmpty &&
        proposal.action is AddTransactionAction &&
        (proposal.action as AddTransactionAction).categoryId == null;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    proposal.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (proposal.source == ActionSource.ai)
                  const _Badge(label: 'AI'),
                if (proposal.confidence < 0.75)
                  _Badge(
                    label: '${(proposal.confidence * 100).round()}%',
                    muted: true,
                  ),
              ],
            ),
            if (proposal.details.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                proposal.details.join(' • '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (_date(proposal.action) != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                DateFormat(
                  'dd MMM yyyy',
                  'id_ID',
                ).format(_date(proposal.action)!),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (proposal.options.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Pilih kategori:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: proposal.options
                    .map(
                      (CategoryOption option) => ActionChip(
                        label: Text(option.name),
                        onPressed: () => onSelectCategory(option),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (proposal.suggestedCategoryName != null) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Saran kategori baru: ${proposal.suggestedCategoryName}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.primary),
                    ),
                  ),
                  if (pending && onCreateCategory != null)
                    TextButton(
                      onPressed: onCreateCategory,
                      child: const Text('Buat kategori'),
                    ),
                ],
              ),
            ],
            if (needsCategory) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Pilih kategori dulu sebelum menyimpan.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 8),
            if (pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(onPressed: onReject, child: const Text('Batal')),
                  if (onEdit != null)
                    TextButton(onPressed: onEdit, child: const Text('Ubah')),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: needsCategory ? null : onConfirm,
                    child: const Text('Simpan'),
                  ),
                ],
              )
            else
              _StatusRow(item: item, onUndo: onUndo),
          ],
        ),
      ),
    );
  }

  DateTime? _date(AssistantAction action) {
    return action is AddTransactionAction ? action.createdAt : null;
  }
}
