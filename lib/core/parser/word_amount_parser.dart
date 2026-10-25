import 'amount_match.dart';

/// Mencari nominal yang ditulis dengan kata, misalnya `dua puluh lima ribu`.
class WordAmountParser {
  const WordAmountParser();

  static const Set<String> _numberWords = <String>{
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
  };

  AmountMatch? find(String input) {
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
        return AmountMatch(
          start: tokens[index].start,
          end: tokens[lastIndex].end,
          amount: total + current,
        );
      }
      index = lastIndex;
    }
    return null;
  }

  bool _isNumberWord(String token) => _numberWords.contains(token);

  String _cleanToken(String token) {
    return token
        .replaceAll(RegExp(r'^[^a-zA-Z]+|[^a-zA-Z]+$'), '')
        .toLowerCase();
  }
}
