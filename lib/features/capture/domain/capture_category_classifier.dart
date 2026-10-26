import '../../../core/database/app_database.dart';
import '../../assistant/domain/category_scorer.dart';

class CaptureCategoryResult {
  const CaptureCategoryResult({
    this.categoryId,
    this.confidence = 0,
    this.suggestions = const <CategoryScore>[],
  });

  final int? categoryId;
  final double confidence;
  final List<CategoryScore> suggestions;
}

class CaptureCategoryClassifier {
  const CaptureCategoryClassifier({required this.scorer});

  final CategoryScorer scorer;

  Future<CaptureCategoryResult> classify({
    required String text,
    required String type,
    required List<Category> categories,
    int? queuedCategoryId,
    String? merchant,
  }) async {
    if (_isCategoryOfType(queuedCategoryId, type, categories)) {
      return CaptureCategoryResult(categoryId: queuedCategoryId, confidence: 1);
    }
    final String? merchantText = merchant?.trim();
    final String input = <String>[
      if (text.trim().isNotEmpty) text.trim(),
      if (merchantText != null && merchantText.isNotEmpty) merchantText,
    ].join(' ');
    if (input.isEmpty) {
      return const CaptureCategoryResult();
    }
    final List<CategoryScore> scores = await scorer.score(
      text: input,
      type: type,
      categories: categories,
    );
    if (scores.isEmpty) {
      return const CaptureCategoryResult();
    }
    final CategoryScore best = scores.first;
    if (best.score >= 0.75) {
      return CaptureCategoryResult(
        categoryId: best.categoryId,
        confidence: best.score,
      );
    }
    return CaptureCategoryResult(
      confidence: best.score,
      suggestions: scores.take(3).toList(growable: false),
    );
  }

  bool _isCategoryOfType(
    int? categoryId,
    String type,
    List<Category> categories,
  ) {
    return categoryId != null &&
        categories.any(
          (Category category) =>
              category.id == categoryId && category.type == type,
        );
  }
}
