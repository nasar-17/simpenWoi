import 'category_keywords.dart';
import 'keyword_matcher.dart';

/// Mencocokkan kata kunci dengan kategori bawaan sesuai tipe transaksi.
class CategoryMatcher {
  const CategoryMatcher();

  int? match(String input, String type) {
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
}
