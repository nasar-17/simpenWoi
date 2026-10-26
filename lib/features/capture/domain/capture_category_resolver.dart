import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../data/native_capture_models.dart';
import 'capture_category_classifier.dart';
import 'capture_direction.dart';

Future<int?> resolveCaptureCategory(
  NativeCapture capture,
  List<Category> categories,
  CaptureCategoryClassifier classifier,
) async {
  final String type = _typeForDirection(capture.direction);
  final CaptureCategoryResult result = await classifier.classify(
    text: capture.note ?? '',
    type: type,
    categories: categories,
    queuedCategoryId: capture.categoryId,
    merchant: capture.merchant,
  );
  return result.categoryId;
}

Future<int?> resolveDirtyCaptureCategory(
  DirtyNativeCapture dirty,
  TransactionRecord record,
  List<Category> categories,
  CaptureCategoryClassifier classifier,
) async {
  if (_isCategoryOfType(dirty.categoryId, record.type, categories)) {
    return dirty.categoryId;
  }
  final String? note = dirty.note?.trim();
  if (note != null && note.isNotEmpty) {
    final CaptureCategoryResult result = await classifier.classify(
      text: note,
      type: record.type,
      categories: categories,
      merchant: record.merchant,
    );
    if (result.categoryId != null) {
      return result.categoryId;
    }
  }
  return _isCategoryOfType(record.categoryId, record.type, categories)
      ? record.categoryId
      : null;
}

String _typeForDirection(String direction) {
  return direction == CaptureDirection.incoming
      ? TransactionType.income
      : TransactionType.expense;
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
