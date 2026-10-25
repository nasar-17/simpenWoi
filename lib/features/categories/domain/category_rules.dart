import '../../../core/database/app_database.dart';
import '../../../core/parser/category_rule.dart';

List<CategoryRule> categoryRulesFrom(Iterable<Category> categories) {
  return categories
      .map(
        (Category category) => CategoryRule(
          id: category.id,
          name: category.name,
          type: category.type,
          keywords: category.keywords,
        ),
      )
      .toList(growable: false);
}
