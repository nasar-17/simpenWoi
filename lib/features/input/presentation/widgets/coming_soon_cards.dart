import 'package:flutter/material.dart';

class ComingSoonCards extends StatelessWidget {
  const ComingSoonCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _ComingSoonCard(
            icon: Icons.receipt_long_outlined,
            label: 'Scan struk',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ComingSoonCard(icon: Icons.mic_none_outlined, label: 'Suara'),
        ),
      ],
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: <Widget>[
            Icon(icon, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'Segera hadir',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
