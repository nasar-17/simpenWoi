import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../../core/parser/category_rule.dart';
import '../../../core/parser/parsed_entry.dart';
import '../../../core/parser/transaction_parser.dart';
import '../../categories/domain/category_rules.dart';
import '../data/native_capture_models.dart';
import 'capture_direction.dart';

const TransactionParser _parser = TransactionParser();

int? resolveCaptureCategory(NativeCapture capture, List<Category> categories) {
  final String type = _typeForDirection(capture.direction);
  final int? queuedCategoryId = capture.categoryId;
  if (_isCategoryOfType(queuedCategoryId, type, categories)) {
    return queuedCategoryId;
  }

  final String? note = capture.note?.trim();
  if (note == null || note.isEmpty) {
    return null;
  }
  final List<CategoryRule> rules = categoryRulesFrom(categories);
  final ParsedEntry parsed = _parser.parse(note, categories: rules);
  return parsed.type == type &&
          _isCategoryOfType(parsed.categoryId, type, categories)
      ? parsed.categoryId
      : null;
}

int? resolveDirtyCaptureCategory(
  DirtyNativeCapture dirty,
  TransactionRecord record,
  List<Category> categories,
) {
  final String type = record.type;
  final int? queuedCategoryId = dirty.categoryId;
  if (_isCategoryOfType(queuedCategoryId, type, categories)) {
    return queuedCategoryId;
  }

  final String? note = dirty.note?.trim();
  if (note != null && note.isNotEmpty) {
    final List<CategoryRule> rules = categoryRulesFrom(categories);
    final ParsedEntry parsed = _parser.parse(note, categories: rules);
    if (parsed.type == type &&
        _isCategoryOfType(parsed.categoryId, type, categories)) {
      return parsed.categoryId;
    }
  }

  return _isCategoryOfType(record.categoryId, type, categories)
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
