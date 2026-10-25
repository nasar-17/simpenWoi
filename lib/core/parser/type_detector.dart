import '../constants/transaction_values.dart';
import 'category_keywords.dart';
import 'keyword_matcher.dart';

/// Menentukan tipe transaksi dari kata kunci pemasukan.
class TypeDetector {
  const TypeDetector();

  String detect(String input) {
    for (final String keyword in incomeKeywords) {
      if (containsKeyword(input, keyword)) {
        return TransactionType.income;
      }
    }
    return TransactionType.expense;
  }
}
