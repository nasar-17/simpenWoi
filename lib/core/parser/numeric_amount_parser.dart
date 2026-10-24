import 'amount_match.dart';

/// Hasil pencarian nominal numerik beserta kandidat tanpa satuan.
class NumericAmountResult {
  const NumericAmountResult({this.plain, this.withUnit});

  final AmountMatch? plain;
  final AmountMatch? withUnit;
}

/// Mencari nominal yang ditulis dengan angka, misalnya `15rb` atau `1.5jt`.
class NumericAmountParser {
  const NumericAmountParser();

  static final RegExp _numericPattern = RegExp(
    r'(?:rp\.?\s*)?(\d+(?:[.,]\d+)*)\s*(ribu|rbu|rb|juta|jt|k)?',
    caseSensitive: false,
  );

  NumericAmountResult find(String input) {
    AmountMatch? firstPlain;
    for (final RegExpMatch match in _numericPattern.allMatches(input)) {
      final String rawNumber = match.group(1) ?? '';
      final String? unit = match.group(2);
      final int parsed = _parseNumeric(rawNumber, unit);
      if (parsed <= 0) {
        continue;
      }
      final AmountMatch candidate = AmountMatch(
        start: match.start,
        end: match.end,
        amount: parsed,
      );
      if (unit != null) {
        return NumericAmountResult(plain: firstPlain, withUnit: candidate);
      }
      firstPlain ??= candidate;
    }
    return NumericAmountResult(plain: firstPlain);
  }

  int _parseNumeric(String rawNumber, String? unit) {
    final String normalizedValue = _normalizeSeparators(
      rawNumber,
      hasUnit: unit != null,
    );
    final double? value = double.tryParse(normalizedValue);
    if (value == null) {
      return 0;
    }

    final int factor = switch (unit) {
      'ribu' || 'rbu' || 'rb' || 'k' => 1000,
      'juta' || 'jt' => 1000000,
      _ => 1,
    };
    return (value * factor).round();
  }

  String _normalizeSeparators(String raw, {required bool hasUnit}) {
    final bool hasComma = raw.contains(',');
    final bool hasDot = raw.contains('.');

    if (hasComma && hasDot) {
      return raw.replaceAll('.', '').replaceAll(',', '.');
    }
    if (hasComma) {
      final bool thousands = RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(raw);
      return thousands ? raw.replaceAll(',', '') : raw.replaceAll(',', '.');
    }
    if (hasDot) {
      final bool thousands = RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(raw);
      final bool decimal = hasUnit && RegExp(r'^\d+\.\d{1,2}$').hasMatch(raw);
      if (decimal) {
        return raw;
      }
      return thousands || !hasUnit ? raw.replaceAll('.', '') : raw;
    }
    return raw;
  }
}
