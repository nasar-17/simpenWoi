import '../../../core/database/app_database.dart';
import '../../learning/data/learning_repository.dart';
import '../../learning/data/lexicon_repository.dart';
import '../../learning/domain/damerau_levenshtein.dart';
import '../../learning/domain/lexicon_data.dart';
import '../../learning/domain/text_normalizer.dart';
import 'category_scorer.dart';

class NaiveBayesCategoryScorer implements CategoryScorer {
  const NaiveBayesCategoryScorer({
    required this.learningRepository,
    required this.lexiconRepository,
  });

  final LearningRepository learningRepository;
  final LexiconRepository lexiconRepository;

  @override
  Future<List<CategoryScore>> score({
    required String text,
    required String type,
    required List<Category> categories,
  }) async {
    final LexiconData lexicon = await lexiconRepository.load();
    final List<MlTokenStat> stats = await learningRepository.tokenStats();
    final TextNormalizer normalizer = TextNormalizer(slang: lexicon.slang);
    final String normalizedText = normalizer.normalize(text);
    final List<String> tokens = normalizer.tokenize(text);
    final List<Category> candidates = categories
        .where((Category category) => category.type == type)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return const <CategoryScore>[];
    }
    final Map<int, double> raw = <int, double>{};
    final Map<int, String> keys = <int, String>{};
    for (final Category category in candidates) {
      final String key = normalizer.normalize(category.name);
      if (lexicon.categories.containsKey(key)) {
        keys[category.id] = key;
      }
      if (key.isNotEmpty && normalizedText.contains(key)) {
        raw[category.id] = (raw[category.id] ?? 0) + 3;
      }
      for (final String keyword in _keywords(category.keywords)) {
        final String normalizedKeyword = normalizer.normalize(keyword);
        if (normalizedKeyword.isNotEmpty &&
            normalizedText.contains(normalizedKeyword)) {
          raw[category.id] = (raw[category.id] ?? 0) + 2;
        }
      }
    }

    final Map<String, String> singleTerms = <String, String>{};
    for (final MapEntry<String, LexiconCategory> entry
        in lexicon.categories.entries) {
      if (entry.value.type != type) {
        continue;
      }
      for (final String term in entry.value.terms) {
        final String normalizedTerm = normalizer.normalize(term);
        if (normalizedTerm.isEmpty) {
          continue;
        }
        if (normalizedTerm.contains(' ')) {
          if (normalizedText.contains(normalizedTerm)) {
            _addKey(raw, keys, candidates, entry.key, 1.5);
          }
        } else {
          singleTerms[normalizedTerm] = entry.key;
        }
      }
    }
    for (final String token in tokens) {
      final String? exactKey = singleTerms[token];
      if (exactKey != null) {
        _addKey(raw, keys, candidates, exactKey, 1.5);
      } else {
        final String? fuzzyKey = _fuzzyKey(token, singleTerms);
        if (fuzzyKey != null) {
          _addKey(raw, keys, candidates, fuzzyKey, 1);
        }
      }
    }

    final Map<int, Map<String, int>> counts = <int, Map<String, int>>{};
    final Map<int, int> totals = <int, int>{};
    for (final MlTokenStat stat in stats) {
      counts.putIfAbsent(stat.categoryId, () => <String, int>{})[stat.token] =
          stat.count;
      totals[stat.categoryId] = (totals[stat.categoryId] ?? 0) + stat.count;
    }
    for (final String token in tokens) {
      for (final Category category in candidates) {
        final int count = counts[category.id]?[token] ?? 0;
        if (count > 0) {
          final int total = totals[category.id] ?? 1;
          raw[category.id] = (raw[category.id] ?? 0) + count / (total + 1);
        }
      }
    }

    final double total = raw.values.fold<double>(
      0,
      (double sum, double value) => sum + value,
    );
    if (total <= 0) {
      return const <CategoryScore>[];
    }
    final List<CategoryScore> scores = raw.entries
        .map(
          (MapEntry<int, double> entry) => CategoryScore(
            categoryId: entry.key,
            score: entry.value / total,
          ),
        )
        .where((CategoryScore score) => score.score > 0.01)
        .toList(growable: false)
      ..sort((CategoryScore a, CategoryScore b) => b.score.compareTo(a.score));
    return scores.take(3).toList(growable: false);
  }

  void _addKey(
    Map<int, double> raw,
    Map<int, String> keys,
    List<Category> categories,
    String key,
    double weight,
  ) {
    for (final Category category in categories) {
      if (keys[category.id] == key) {
        raw[category.id] = (raw[category.id] ?? 0) + weight;
      }
    }
  }

  String? _fuzzyKey(String token, Map<String, String> terms) {
    if (token.length < 4) {
      return null;
    }
    final int tolerance = token.length <= 6
        ? 1
        : token.length <= 9
        ? 2
        : 3;
    for (final MapEntry<String, String> entry in terms.entries) {
      if ((entry.key.length - token.length).abs() > tolerance) {
        continue;
      }
      if (damerauLevenshtein(token, entry.key) <= tolerance) {
        return entry.value;
      }
    }
    return null;
  }

  List<String> _keywords(String? raw) {
    if (raw == null) {
      return const <String>[];
    }
    return raw
        .split(',')
        .map((String keyword) => keyword.trim())
        .where((String keyword) => keyword.isNotEmpty)
        .toList(growable: false);
  }
}
