import '../transaction_values.dart';
import 'category_keywords.dart';
import 'parsed_entry.dart';

class TransactionParser {
  const TransactionParser();

  ParsedEntry parse(String input) {
    final String original = input.trim();
    final String normalized = original
        .toLowerCase()
        .replaceAll('\u00A0', ' ')
        .replaceAll('\n', ' ');

    final String type = _detectType(normalized);
    final _AmountMatch? match = _findAmount(normalized);
    final int amount = match?.amount ?? 0;
    final int? categoryId = _detectCategory(normalized, type);
    final String? note =
        match == null ? _cleanNote(original) : _buildNote(original, match);

    return ParsedEntry(
      amount: amount,
      type: type,
      categoryId: categoryId,
      merchant: null,
      note: note,
    );
  }

  String _detectType(String input) {
    for (final String keyword in incomeKeywords) {
      if (_containsKeyword(input, keyword)) {
        return TransactionType.income;
      }
    }
    return TransactionType.expense;
  }

  int? _detectCategory(String input, String type) {
    for (final CategoryKeywordGroup group in categoryKeywords) {
      if (group.type != type) {
        continue;
      }
      for (final String keyword in group.keywords) {
        if (_containsKeyword(input, keyword)) {
          return group.categoryId;
        }
      }
    }
    return null;
  }

  _AmountMatch? _findAmount(String input) {
    final RegExp numericPattern = RegExp(
      r'(?:rp\.?\s*)?(\d+(?:[.,]\d+)*)\s*(ribu|rbu|rb|juta|jt|k)?',
      caseSensitive: false,
    );

    _AmountMatch? firstPlain;
    for (final RegExpMatch match in numericPattern.allMatches(input)) {
      final String rawNumber = match.group(1) ?? '';
      final String? unit = match.group(2);
      final int parsed = _parseNumeric(rawNumber, unit);
      if (parsed <= 0) {
        continue;
      }
      final _AmountMatch candidate = _AmountMatch(
        start: match.start,
        end: match.end,
        amount: parsed,
      );
      if (unit != null) {
        return candidate;
      }
      firstPlain ??= candidate;
    }

    final _AmountMatch? wordMatch = _findWordAmount(input);
    if (wordMatch != null) {
      return wordMatch;
    }
    return firstPlain;
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
      final bool thousands =
          RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(raw);
      return thousands ? raw.replaceAll(',', '') : raw.replaceAll(',', '.');
    }
    if (hasDot) {
      final bool thousands =
          RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(raw);
      final bool decimal =
          hasUnit && RegExp(r'^\d+\.\d{1,2}$').hasMatch(raw);
      if (decimal) {
        return raw;
      }
      return thousands || !hasUnit ? raw.replaceAll('.', '') : raw;
    }
    return raw;
  }

  _AmountMatch? _findWordAmount(String input) {
    final RegExp tokenPattern = RegExp(r'\S+');
    final List<RegExpMatch> tokens = tokenPattern.allMatches(input).toList();

    for (int index = 0; index < tokens.length; index++) {
      if (!_isNumberWord(_cleanToken(tokens[index].group(0) ?? ''))) {
        continue;
      }

      int current = 0;
      int total = 0;
      bool hasScale = false;
      int lastIndex = index;

      for (int cursor = index; cursor < tokens.length; cursor++) {
        final String token = _cleanToken(tokens[cursor].group(0) ?? '');
        if (!_isNumberWord(token)) {
          break;
        }

        switch (token) {
          case 'satu':
            current += 1;
          case 'dua':
            current += 2;
          case 'tiga':
            current += 3;
          case 'empat':
            current += 4;
          case 'lima':
            current += 5;
          case 'enam':
            current += 6;
          case 'tujuh':
            current += 7;
          case 'delapan':
            current += 8;
          case 'sembilan':
            current += 9;
          case 'sepuluh':
            current += 10;
          case 'sebelas':
            current += 11;
          case 'belas':
            current += 10;
          case 'puluh':
            current = (current == 0 ? 1 : current) * 10;
          case 'ratus':
            current = (current == 0 ? 1 : current) * 100;
          case 'seratus':
            current += 100;
          case 'seribu':
            total += (current == 0 ? 1 : current) * 1000;
            current = 0;
            hasScale = true;
          case 'ribu':
            total += (current == 0 ? 1 : current) * 1000;
            current = 0;
            hasScale = true;
          case 'juta':
            total += (current == 0 ? 1 : current) * 1000000;
            current = 0;
            hasScale = true;
          default:
            break;
        }
        lastIndex = cursor;
      }

      if (hasScale && total + current > 0) {
        return _AmountMatch(
          start: tokens[index].start,
          end: tokens[lastIndex].end,
          amount: total + current,
        );
      }
      index = lastIndex;
    }
    return null;
  }

  bool _isNumberWord(String token) {
    return const <String>{
      'satu',
      'dua',
      'tiga',
      'empat',
      'lima',
      'enam',
      'tujuh',
      'delapan',
      'sembilan',
      'sepuluh',
      'sebelas',
      'belas',
      'puluh',
      'ratus',
      'seratus',
      'seribu',
      'ribu',
      'juta',
    }.contains(token);
  }

  String _cleanToken(String token) {
    return token.replaceAll(RegExp(r'^[^a-zA-Z]+|[^a-zA-Z]+$'), '').toLowerCase();
  }

  String? _buildNote(String original, _AmountMatch match) {
    final String before = original.substring(0, match.start);
    final String after = original.substring(match.end);
    return _cleanNote('$before $after');
  }

  String? _cleanNote(String value) {
    String note = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    note = note
        .replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '')
        .trim();
    note = note.replaceAll(RegExp(r'^rp\.?\s*', caseSensitive: false), '').trim();
    return note.isEmpty ? null : note;
  }

  bool _containsKeyword(String input, String keyword) {
    final String pattern =
        r'(^|[^a-z])' + RegExp.escape(keyword) + r'([^a-z]|$)';
    return RegExp(pattern).hasMatch(input);
  }
}

class _AmountMatch {
  const _AmountMatch({
    required this.start,
    required this.end,
    required this.amount,
  });

  final int start;
  final int end;
  final int amount;
}
