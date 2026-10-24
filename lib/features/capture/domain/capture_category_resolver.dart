import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../../core/parser/transaction_parser.dart';
import '../data/native_capture_models.dart';

const TransactionParser _parser = TransactionParser();

int? resolveCaptureCategory(NativeCapture capture, List<Category> categories) {
  final int? queuedCategoryId = capture.categoryId;
  if (_isExpenseCategory(queuedCategoryId, categories)) {
    return queuedCategoryId;
  }

  final String? note = capture.note?.trim();
  if (note == null || note.isEmpty) {
    return null;
  }
  final int? parsedCategoryId = _parser.parse(note).categoryId;
  return _isExpenseCategory(parsedCategoryId, categories)
      ? parsedCategoryId
      : null;
}

int? resolveDirtyCaptureCategory(
  DirtyNativeCapture dirty,
  TransactionRecord record,
  List<Category> categories,
) {
  final int? queuedCategoryId = dirty.categoryId;
  if (_isExpenseCategory(queuedCategoryId, categories)) {
    return queuedCategoryId;
  }

  final String? note = dirty.note?.trim();
  if (note != null && note.isNotEmpty) {
    final int? parsedCategoryId = _parser.parse(note).categoryId;
    if (_isExpenseCategory(parsedCategoryId, categories)) {
      return parsedCategoryId;
    }
  }

  return record.categoryId;
}

bool _isExpenseCategory(int? categoryId, List<Category> categories) {
  return categoryId != null &&
      categories.any(
        (Category category) =>
            category.id == categoryId &&
            category.type == TransactionType.expense,
      );
}
