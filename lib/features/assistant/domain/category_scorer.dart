import '../../../core/database/app_database.dart';

class CategoryScore {
  const CategoryScore({required this.categoryId, required this.score});

  final int categoryId;
  final double score;
}

abstract interface class CategoryScorer {
  Future<List<CategoryScore>> score({
    required String text,
    required String type,
    required List<Category> categories,
  });
}

class NullCategoryScorer implements CategoryScorer {
  const NullCategoryScorer();

  @override
  Future<List<CategoryScore>> score({
    required String text,
    required String type,
    required List<Category> categories,
  }) async {
    return const <CategoryScore>[];
  }
}
