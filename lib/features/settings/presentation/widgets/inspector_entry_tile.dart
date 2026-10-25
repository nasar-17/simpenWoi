import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../capture/data/native_capture_models.dart';

String formatInspectorEntry(InspectorEntry entry) {
  final List<String> lines = <String>[
    formatDateTimeShort(entry.time),
    entry.packageName,
    if (entry.direction != null) 'Arah: ${entry.direction}',
    if (entry.title?.isNotEmpty ?? false) 'Judul: ${entry.title}',
    if (entry.text?.isNotEmpty ?? false) 'Teks: ${entry.text}',
    if (entry.bigText?.isNotEmpty ?? false) 'Big text: ${entry.bigText}',
    'Hasil: ${entry.result}',
  ];
  return lines.join('\n');
}

class InspectorEntryTile extends StatelessWidget {
  const InspectorEntryTile({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  final InspectorEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool captured = entry.result.startsWith('Ditangkap');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.packageName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Salin entri',
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          Text(
            formatDateTimeShort(entry.time),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (entry.direction != null)
            Text(
              'Arah: ${entry.direction}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (entry.title?.isNotEmpty ?? false)
            Text(
              'Judul: ${entry.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (entry.text?.isNotEmpty ?? false)
            Text(
              'Teks: ${entry.text}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (entry.bigText?.isNotEmpty ?? false)
            Text(
              'Big text: ${entry.bigText}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Text(
            entry.result,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: captured ? scheme.primary : scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
