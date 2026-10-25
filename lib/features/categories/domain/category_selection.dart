import '../../../core/database/app_database.dart';

int? validCategoryId(int? id, String type, Iterable<Category> categories) {
  if (id == null) {
    return null;
  }
  return categories.any(
        (Category category) => category.id == id && category.type == type,
      )
      ? id
      : null;
}
