import 'amount_match.dart';
import 'amount_parser.dart';
import 'category_matcher.dart';
import 'note_cleaner.dart';
import 'parsed_entry.dart';
import 'type_detector.dart';

/// Mengubah teks bebas menjadi nominal, tipe, kategori, dan catatan.
class TransactionParser {
  const TransactionParser();

  static const TypeDetector _typeDetector = TypeDetector();
  static const AmountParser _amountParser = AmountParser();
  static const CategoryMatcher _categoryMatcher = CategoryMatcher();
  static const NoteCleaner _noteCleaner = NoteCleaner();

  ParsedEntry parse(String input) {
    final String original = input.trim();
    final String normalized = original
        .toLowerCase()
        .replaceAll('\u00A0', ' ')
        .replaceAll('\n', ' ');

    final String type = _typeDetector.detect(normalized);
    final AmountMatch? match = _amountParser.find(normalized);
    final int amount = match?.amount ?? 0;
    final int? categoryId = _categoryMatcher.match(normalized, type);
    final String? note = match == null
        ? _noteCleaner.clean(original)
        : _noteCleaner.build(original, match);

    return ParsedEntry(
      amount: amount,
      type: type,
      categoryId: categoryId,
      merchant: null,
      note: note,
    );
  }
}
