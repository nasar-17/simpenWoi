import 'category_keywords.dart';
import 'category_rule.dart';
import 'keyword_matcher.dart';

/// Mencocokkan nama/kata kunci kategori pengguna lalu kamus bawaan.
class CategoryMatcher {
  const CategoryMatcher();

  int? match(String input, String type, List<CategoryRule> categories) {
    for (final CategoryRule category in categories) {
      if (category.type != type) {
        continue;
      }
      final String name = category.name.trim().toLowerCase();
      if (name.isNotEmpty && containsKeyword(input, name)) {
        return category.id;
      }
    }

    for (final CategoryRule category in categories) {
      if (category.type != type) {
        continue;
      }
      for (final String keyword in _splitKeywords(category.keywords)) {
        if (containsKeyword(input, keyword)) {
          return category.id;
        }
      }
    }

    for (final CategoryKeywordGroup group in categoryKeywords) {
      if (group.type != type) {
        continue;
      }
      for (final String keyword in group.keywords) {
        if (containsKeyword(input, keyword)) {
          return group.categoryId;
        }
      }
    }
    return null;
  }

  List<String> _splitKeywords(String? raw) {
    if (raw == null) {
      return const <String>[];
    }
    return raw
        .split(',')
        .map((String keyword) => keyword.trim().toLowerCase())
        .where((String keyword) => keyword.isNotEmpty)
        .toList(growable: false);
  }
}
