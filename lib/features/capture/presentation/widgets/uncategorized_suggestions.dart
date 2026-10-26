import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../assistant/domain/category_scorer.dart';
import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class UncategorizedSuggestions extends ConsumerStatefulWidget {
  const UncategorizedSuggestions({
    super.key,
    required this.record,
    required this.onSelected,
  });

  final TransactionRecord record;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<UncategorizedSuggestions> createState() =>
      _UncategorizedSuggestionsState();
}

class _UncategorizedSuggestionsState
    extends ConsumerState<UncategorizedSuggestions> {
  late final Future<List<_Suggestion>> _suggestions = _load();

  Future<List<_Suggestion>> _load() async {
    final List<Category> categories;
    try {
      categories = await ref.read(categoriesProvider.future);
    } catch (_) {
      return const <_Suggestion>[];
    }
    if (!mounted) {
      return const <_Suggestion>[];
    }
    final String text = <String>[
      if ((widget.record.note ?? '').trim().isNotEmpty)
        widget.record.note!.trim(),
      if ((widget.record.merchant ?? '').trim().isNotEmpty)
        widget.record.merchant!.trim(),
    ].join(' ');
    if (text.isEmpty) {
      return const <_Suggestion>[];
    }
    final List<CategoryScore> scores = await ref
        .read(categoryScorerProvider)
        .score(text: text, type: widget.record.type, categories: categories);
    final Map<int, String> names = <int, String>{
      for (final Category category in categories) category.id: category.name,
    };
    return scores
        .where((CategoryScore score) => names.containsKey(score.categoryId))
        .take(3)
        .map(
          (CategoryScore score) =>
              _Suggestion(id: score.categoryId, name: names[score.categoryId]!),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Suggestion>>(
      future: _suggestions,
      builder: (BuildContext context, AsyncSnapshot<List<_Suggestion>> snap) {
        final List<_Suggestion> suggestions =
            snap.data ?? const <_Suggestion>[];
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final _Suggestion suggestion in suggestions)
                ActionChip(
                  label: Text(suggestion.name),
                  onPressed: () => widget.onSelected(suggestion.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Suggestion {
  const _Suggestion({required this.id, required this.name});

  final int id;
  final String name;
}
