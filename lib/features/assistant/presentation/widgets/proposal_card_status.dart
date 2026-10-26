part of 'proposal_card.dart';

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: muted ? scheme.surface : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: muted ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item, required this.onUndo});

  final ChatProposal item;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (item.status) {
      ProposalStatus.saving => const Row(
        children: <Widget>[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Menyimpan...'),
        ],
      ),
      ProposalStatus.saved => Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          const Expanded(child: Text('Tersimpan')),
          if (item.undo != null)
            TextButton(onPressed: onUndo, child: const Text('Batalkan')),
        ],
      ),
      ProposalStatus.rejected => const Text('Dibatalkan'),
      ProposalStatus.undone => const Text('Dibatalkan'),
      ProposalStatus.error => Text(
        item.error ?? 'Gagal menyimpan.',
        style: TextStyle(color: scheme.error),
      ),
      ProposalStatus.pending => const SizedBox.shrink(),
    };
  }
}
