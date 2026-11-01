import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/assistant/proposed_action.dart';
import '../../data/function_gemma_model_status.dart';
import '../providers/assistant_providers.dart';
import '../widgets/model_ai_comparison_card.dart';

/// Runs real local inference without executing any returned action.
class ModelAiDebugPage extends ConsumerStatefulWidget {
  const ModelAiDebugPage({super.key});

  @override
  ConsumerState<ModelAiDebugPage> createState() => _ModelAiDebugPageState();
}

class _ModelAiDebugPageState extends ConsumerState<ModelAiDebugPage> {
  static const List<String> _inputs = <String>[
    'makan siang 50rb',
    'beli bensin 100rb',
    'belanja indomaret 150rb',
    'tagihan listrik 200rb',
    'nonton film 75rb',
    'gym bulanan 500rb',
    'beli obat di apotek 25rb',
    'gaji bulanan 5jt',
    'transfer ke rekening 2jt',
    'bayar internet 150rb',
  ];

  final List<({String input, String result, int milliseconds})> _rows = [];
  bool _running = false;
  String? _error;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
      _rows.clear();
    });
    try {
      final FunctionGemmaModelStatus status = await ref
          .read(functionGemmaModelManagerProvider)
          .status();
      if (!status.installed || !status.enabled) {
        throw StateError('Impor dan aktifkan model AI terlebih dahulu.');
      }
      for (final String input in _inputs) {
        if (!mounted) return;
        final Stopwatch stopwatch = Stopwatch()..start();
        final List<ProposedAction> proposals = await ref
            .read(inputEngineProvider)
            .process(input);
        stopwatch.stop();
        if (!mounted) return;
        setState(() {
          _rows.add((
            input: input,
            result: proposals.map((ProposedAction p) => p.summary).join('\n'),
            milliseconds: stopwatch.elapsedMilliseconds,
          ));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Uji inferensi belum selesai. Pastikan model yang kompatibel '
              'sudah diimpor, aktif, dan perangkat memiliki memori cukup.';
        });
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uji AI lokal')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Jalankan model pada sepuluh contoh input. '
                    'Hasil hanya ditampilkan; tidak ada transaksi yang disimpan. '
                    'Periksa nominal, jenis, dompet, dan kategori setiap usulan.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jalankan inferensi'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_running) const LinearProgressIndicator(),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Belum ada hasil inferensi.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ({String input, String result, int milliseconds}) row =
                          _rows[index];
                      return ModelAiComparisonCard(
                        input: row.input,
                        result: row.result,
                        milliseconds: row.milliseconds,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
