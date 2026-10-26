import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/assistant/assistant_action.dart';
import '../../../../core/assistant/assistant_context.dart';
import '../../../../core/assistant/proposed_action.dart';
import '../../../../core/constants/transaction_values.dart';
import '../../domain/category_scorer.dart';
import '../providers/assistant_providers.dart';
import '../widgets/model_ai_comparison_card.dart';

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

  final List<({String input, String rules, String ai})> _rows = [];
  AssistantContext? _context;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final AssistantContext context = await ref
          .read(assistantDataRepositoryProvider)
          .loadContext();
      if (mounted) {
        setState(() {
          _context = context;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data pengguna.';
        });
      }
    }
  }

  Future<void> _run() async {
    final AssistantContext? context = _context;
    if (_running || context == null) return;
    final ai = ref.read(aiProviderProvider);
    if (!ai.isAvailable) {
      setState(() {
        _error = 'Model AI belum diimpor atau belum diaktifkan.';
      });
      return;
    }
    setState(() {
      _running = true;
      _error = null;
      _rows.clear();
    });
    try {
      for (final String input in _inputs) {
        final List<CategoryScore> scores = await ref
            .read(categoryScorerProvider)
            .score(
              text: input,
              type: TransactionType.expense,
              categories: context.categories,
            );
        final int? rulesCategoryId = scores.isEmpty
            ? null
            : scores.first.categoryId;
        List<ProposedAction>? proposals;
        try {
          proposals = await ai.propose(input, context);
        } catch (_) {
          proposals = null;
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _rows.add((
            input: input,
            rules: _nameOrDash(rulesCategoryId),
            ai: _aiLabel(proposals),
          ));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Perbandingan gagal dijalankan.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  String _aiLabel(List<ProposedAction>? proposals) {
    if (proposals == null || proposals.isEmpty) {
      return 'fallback';
    }
    final AssistantAction action = proposals.first.action;
    return switch (action) {
      AddTransactionAction(:final categoryId) => _nameOrDash(categoryId),
      CreateCategoryAction() => 'buat kategori',
      SetWalletBalanceAction() => 'ubah saldo',
      TransferAction() => 'transfer',
      CreateWalletAction() => 'buat dompet',
      SetSpendingTargetAction() => 'target',
      QueryTotalAction() => 'query total',
      AskClarificationAction() => 'klarifikasi',
    };
  }

  String _nameOrDash(int? categoryId) {
    if (categoryId == null) {
      return '—';
    }
    return _context?.categoryById(categoryId)?.name ?? 'tidak dikenal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Model AI')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Bandingkan kategori dari rules dan FunctionGemma untuk '
                  'sepuluh input golden set. Proses bisa memakan waktu.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _running || _context == null ? null : _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jalankan perbandingan'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_running) const LinearProgressIndicator(),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Belum ada hasil.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ({String input, String rules, String ai}) row =
                          _rows[index];
                      return ModelAiComparisonCard(
                        input: row.input,
                        rules: row.rules,
                        ai: row.ai,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
