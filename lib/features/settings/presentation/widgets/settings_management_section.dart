import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/utils/currency.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../learning/domain/learning_stats.dart';

class SettingsManagementSection extends ConsumerStatefulWidget {
  const SettingsManagementSection({super.key});

  @override
  ConsumerState<SettingsManagementSection> createState() =>
      _SettingsManagementSectionState();
}

class _SettingsManagementSectionState
    extends ConsumerState<SettingsManagementSection> {
  Future<LearningStats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = ref.watch(learningRepositoryProvider).stats();
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

  Future<void> _showGoldenSetDebug() async {
    context.push('/settings/golden-set-debug');
  }

  Future<void> _exportLearningLog() async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export log pembelajaran',
        fileName: 'learning_log_export.jsonl',
        type: FileType.custom,
        allowedExtensions: ['jsonl'],
      );
      if (outputPath == null) {
        return; // User cancelled
      }
      final List<LearningLogEntry> entries =
          await ref.read(learningRepositoryProvider).allEntries();
      final file = File(outputPath);
      await file.openWrite()
        ..writeAll(entries.map((entry) {
          final Map<String, dynamic> json = <String, dynamic>{
            'id': entry.id,
            'input_text': entry.inputText,
            'action_json': entry.actionJson,
            'outcome': entry.outcome,
            'created_at': entry.createdAt.toIso8601String(),
          };
          return jsonEncode(json);
        }))
        ..close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log pembelajaran berhasil diekspor.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: ${error.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Kelola kategori'),
            subtitle: const Text('Tambah, ubah, atau hapus kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/categories'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola dompet'),
            subtitle: const Text('Atur dompet dan dompet utama'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/wallets'),
          ),
          const Divider(height: 1),
          ExpansionTile(
            title: const Text('Pembelajaran'),
            subtitle: const Text('Statistik dan pengaturan pembelajaran'),
            initiallyExpanded: false,
            children: <Widget>[
              ListTile(
                title: const Text('Statistik pembelajaran'),
                subtitle: _statsFuture == null
                    ? const Text('Memuat...')
                    : FutureBuilder<LearningStats>(
                        future: _statsFuture,
                        builder: (BuildContext context,
                            AsyncSnapshot<LearningStats> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Memuat...');
                          }
                          if (snapshot.hasError) {
                            return const Text('Gagal memuat.');
                          }
                          final LearningStats stats = snapshot.data!;
                          return Text(
                            '${stats.words} kata • '
                            '${stats.guesses7d} usulan • '
                            '${stats.correctFirstGuess7d} benar • '
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
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Reset statistik'),
                      content: const Text(
                          'Data pembelungan akan dihapus. Tindakan tidak bisa dibatalkan.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetStats();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Hapus log pembelajaran'),
                subtitle: const Text('Hapus semua catatan pembelajaran'),
                trailing: const Icon(Icons.delete_outline),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Hapus log pembelajaran'),
                      content: const Text(
                          'Catatan pembelajaran akan dihapus. Tindakan tidak bisa dibatalkan.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearLog();
                          },
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
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
          ),
        ],
      ),
    );
  }
}
