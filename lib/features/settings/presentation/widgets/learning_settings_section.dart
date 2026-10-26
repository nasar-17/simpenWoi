import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../learning/domain/learning_stats.dart';
import '../../../learning/presentation/providers/learning_providers.dart';

class LearningSettingsSection extends ConsumerStatefulWidget {
  const LearningSettingsSection({super.key});

  @override
  ConsumerState<LearningSettingsSection> createState() =>
      _LearningSettingsSectionState();
}

class _LearningSettingsSectionState
    extends ConsumerState<LearningSettingsSection> {
  Future<LearningStats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ref.read(learningRepositoryProvider).stats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = ref.read(learningRepositoryProvider).stats();
    });
  }

  Future<void> _resetStats() async {
    await ref.read(learningRepositoryProvider).resetStats();
    _refreshStats();
  }

  Future<void> _clearLog() async {
    await ref.read(learningRepositoryProvider).clearLog();
    _refreshStats();
  }

  void _showGoldenSetDebug() {
    unawaited(context.push('/settings/golden-set-debug'));
  }

  Future<void> _exportLearningLog() async {
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export log pembelajaran',
        fileName: 'learning_log_export.jsonl',
        type: FileType.custom,
        allowedExtensions: <String>['jsonl'],
      );
      if (outputPath == null) {
        return;
      }
      final List<LearningLogEntry> entries =
          await ref.read(learningRepositoryProvider).allEntries();
      final IOSink sink = File(outputPath).openWrite();
      for (final LearningLogEntry entry in entries) {
        sink.writeln(
          jsonEncode(<String, dynamic>{
            'id': entry.id,
            'input_text': entry.inputText,
            'action_json': entry.actionJson,
            'outcome': entry.outcome,
            'created_at': entry.createdAt.toIso8601String(),
          }),
        );
      }
      await sink.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log pembelajaran berhasil diekspor.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor: $error')),
        );
      }
    }
  }

  Future<bool> _confirm(String title, String content) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmReset() async {
    if (await _confirm(
      'Reset statistik',
      'Data pembelajaran akan dihapus. Tindakan tidak bisa dibatalkan.',
    )) {
      await _resetStats();
    }
  }

  Future<void> _confirmClearLog() async {
    if (await _confirm(
      'Hapus log pembelajaran',
      'Catatan pembelajaran akan dihapus. Tindakan tidak bisa dibatalkan.',
    )) {
      await _clearLog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Pembelajaran'),
      subtitle: const Text('Statistik dan pengaturan pembelajaran'),
      children: <Widget>[
        ListTile(
          title: const Text('Statistik pembelajaran'),
          subtitle: _statsFuture == null
              ? const Text('Memuat...')
              : FutureBuilder<LearningStats>(
                  future: _statsFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<LearningStats> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Memuat...');
                        }
                        if (snapshot.hasError) {
                          return const Text('Gagal memuat.');
                        }
                        final LearningStats stats = snapshot.data!;
                        return Text(
                          '${stats.words} kata | '
                          '${stats.guesses7d} usulan | '
                          '${stats.correctFirstGuess7d} benar | '
                          '${(stats.accuracy7d * 100).toStringAsFixed(1)}%',
                        );
                      },
                ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
          ),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Reset statistik'),
          subtitle: const Text('Hapus semua data pembelajaran'),
          trailing: const Icon(Icons.delete_outline),
          onTap: _confirmReset,
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Hapus log pembelajaran'),
          subtitle: const Text('Hapus semua catatan pembelajaran'),
          trailing: const Icon(Icons.delete_outline),
          onTap: _confirmClearLog,
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Debug golden set'),
          subtitle: const Text('Uji prediksi kategori'),
          trailing: const Icon(Icons.bug_report),
          onTap: _showGoldenSetDebug,
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Ekspor log pembelajaran'),
          subtitle: const Text('Simpan data pembelajaran ke file'),
          trailing: const Icon(Icons.file_download_outlined),
          onTap: _exportLearningLog,
        ),
      ],
    );
  }
}
