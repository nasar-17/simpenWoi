/// Token statistics are historical feedback only, never an inference engine.
class TextNormalizer {
  const TextNormalizer();

  List<String> tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((String token) => token.isNotEmpty)
      .toList(growable: false);
}
