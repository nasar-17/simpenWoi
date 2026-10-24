import 'amount_match.dart';
import 'numeric_amount_parser.dart';
import 'word_amount_parser.dart';

/// Menggabungkan pencarian nominal angka dan nominal kata.
class AmountParser {
  const AmountParser();

  static const NumericAmountParser _numericParser = NumericAmountParser();
  static const WordAmountParser _wordParser = WordAmountParser();

  AmountMatch? find(String input) {
    final NumericAmountResult numeric = _numericParser.find(input);
    if (numeric.withUnit != null) {
      return numeric.withUnit;
    }
    final AmountMatch? wordMatch = _wordParser.find(input);
    if (wordMatch != null) {
      return wordMatch;
    }
    return numeric.plain;
  }
}
