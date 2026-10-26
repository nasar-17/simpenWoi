part of 'input_engine.dart';

Wallet? walletFromText(String text, AssistantContext context) {
  final String normalized = text.toLowerCase();
  Wallet? found;
  for (final Wallet wallet in context.wallets) {
    final String name = wallet.name.toLowerCase().trim();
    if (name.isNotEmpty && normalized.contains(name)) {
      if (found == null || name.length > found.name.length) {
        found = wallet;
      }
    }
  }
  return found;
}

List<String> splitItems(String input) {
  return input
      .split(RegExp(r'\s+(?:sama|dan)\s+|\s*\+\s*|,\s+'))
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

bool isCancellation(String input) {
  return RegExp(
    r'\b(gak jadi|tidak jadi|batal|kembalian|refund)\b',
    caseSensitive: false,
  ).hasMatch(input);
}

String? mainNoun(String text) {
  final List<String> words = text
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9 ]'), ' ')
      .split(RegExp('\\s+'))
      .where((String word) => word.length > 2)
      .toList(growable: false);
  if (words.isEmpty) {
    return null;
  }
  words.sort((String a, String b) => b.length.compareTo(a.length));
  return words.first;
}
