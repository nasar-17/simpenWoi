import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../capture/data/native_capture_models.dart';

class InspectorControls extends StatelessWidget {
  const InspectorControls({
    super.key,
    required this.enabled,
    required this.busy,
    required this.status,
    required this.filterController,
    required this.canCopyAll,
    required this.canClearAll,
    required this.onEnabledChanged,
    required this.onRefresh,
    required this.onCopyAll,
    required this.onClearAll,
  });

  final bool enabled;
  final bool busy;
  final InspectorListenerStatus? status;
  final TextEditingController filterController;
  final bool canCopyAll;
  final bool canClearAll;
  final ValueChanged<bool>? onEnabledChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCopyAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: const Text('Aktifkan inspektor'),
          subtitle: const Text(
            'Mencatat notifikasi masuk untuk diagnosis (khusus debug).',
          ),
          value: enabled,
          onChanged: busy ? null : onEnabledChanged,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            status?.connected == true ? Icons.link : Icons.link_off,
            color: status?.connected == true
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          title: const Text('Status listener'),
          subtitle: Text(_statusText(status)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Isi notifikasi disimpan lokal selama inspektor aktif.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: filterController,
            decoration: InputDecoration(
              labelText: 'Filter package/title',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filterController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Bersihkan filter',
                      onPressed: filterController.clear,
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
              TextButton(
                onPressed: canCopyAll ? onCopyAll : null,
                child: const Text('Salin semua'),
              ),
              TextButton(
                onPressed: canClearAll ? onClearAll : null,
                child: const Text('Hapus semua'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusText(InspectorListenerStatus? status) {
    if (status == null) {
      return 'Memeriksa status...';
    }
    if (status.updatedAt.millisecondsSinceEpoch == 0) {
      return 'Belum ada status listener.';
    }
    final String state = status.connected ? 'Terhubung' : 'Terputus';
    return '$state \u2022 ${formatDateTimeShort(status.updatedAt)}';
  }
}
