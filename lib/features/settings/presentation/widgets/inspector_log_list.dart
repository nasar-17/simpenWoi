import 'package:flutter/material.dart';

import '../../../capture/data/native_capture_models.dart';
import 'inspector_entry_tile.dart';

class InspectorLogList extends StatelessWidget {
  const InspectorLogList({
    super.key,
    required this.entries,
    required this.loading,
    required this.error,
    required this.onCopy,
  });

  final List<InspectorEntry> entries;
  final bool loading;
  final Object? error;
  final ValueChanged<InspectorEntry> onCopy;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (error != null) {
      return const ListTile(title: Text('Gagal memuat log inspektor.'));
    }
    if (entries.isEmpty) {
      return const ListTile(title: Text('Belum ada notifikasi tercatat.'));
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < entries.length; index++) ...<Widget>[
          if (index > 0) const Divider(height: 1),
          InspectorEntryTile(
            entry: entries[index],
            onCopy: () => onCopy(entries[index]),
          ),
        ],
      ],
    );
  }
}
