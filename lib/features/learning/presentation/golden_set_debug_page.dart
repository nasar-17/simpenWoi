import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assistant/domain/category_scorer.dart';
import '../../../assistant/domain/naive_bayes_category_scorer.dart';
import '../../../assistant/domain/input_engine.dart';
import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../../../assistant/presentation/providers/assistant_chat_controller.dart';
import '../../../core/assistant/presentation/providers/assistant_data_repository_provider.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/database/app_database.dart';
import '../../../assistant/domain/category_scorer.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../learning/domain/learning_stats.dart';

class GoldenSetDebugPage extends ConsumerStatefulWidget {
  const GoldenSetDebugPage({super.key});

  @override
  ConsumerState<GoldenSetDebugPage> createState() => _GoldenSetDebugPageState();
}

class _GoldenSetDebugPageState extends ConsumerState<GoldenSetDebugPage> {
  final List<String> _testInputs = <String>[
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

  final List<Map<String, dynamic>> _results = <Map<String, dynamic>>[];

  bool _loading = false;
  AssistantContext? _context;

  Future<void> _runTests() async {
    setState(() {
      _loading = true;
      _results.clear();
    });
    try {
      final NaiveBayesCategoryScorer scorer = ref.read(categoryScorerProvider)
          as NaiveBayesCategoryScorer;
      final List<Category> categories = await ref
          .read(assistantDataRepositoryProvider)
          .loadContext()
          .then((context) => context.categories);
      for (final String input in _testInputs) {
        final List<CategoryScore> scores = await scorer.score(
          text: input,
          type: 'expense',
          categories: categories,
        );
        final topScores = scores.take(3).toList();
        _results.add(<String, dynamic>{
          'input': input,
          'scores': topScores,
        });
      }
    } catch (error) {
      // TODO: Show error
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final context = await ref
        .read(assistantDataRepositoryProvider)
        .loadContext();
    if (mounted) {
      setState(() {
        _context = context;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Golden Set'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Jalankan tes'),
              onPressed: _loading ? null : _runTests,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final result = _results[index];
                      final input = result['input'] as String;
                      final scores = result['scores'] as List<CategoryScore>;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                input,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ...scores.map<Widget>((CategoryScore score) {
                                final category = _context?.categoryById(
                                  score.categoryId,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        '${(score.score * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category?.name ?? 'Unknown',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (scores.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Tidak ada kategori yang cocok',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}