class TextNormalizer {
  const TextNormalizer({this.slang = const <String, String>{}});

  final Map<String, String> slang;

  static const Set<String> _stopwords = <String>{
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'untuk',
    'dengan',
    'buat',
    'bayar',
    'beli',
    'aku',
    'saya',
    'gue',
    'gw',
    'lo',
    'kamu',
    'dia',
    'ini',
    'itu',
    'aja',
    'sih',
    'dong',
    'ya',
    'yg',
    'dgn',
    'utk',
    'nya',
    'the',
    'rp',
    'ribu',
    'rb',
    'juta',
    'jt',
  };

  List<String> tokenize(String text) {
    final String cleaned = text
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), ' ');
    final List<String> result = <String>[];
    for (final String raw in cleaned.split(RegExp('\\s+'))) {
      if (raw.isEmpty) {
        continue;
      }
      final String? replacement = slang[raw];
      final Iterable<String> parts = replacement == null
          ? <String>[raw]
          : replacement.split(RegExp('\\s+'));
      for (final String part in parts) {
        if (part.length > 1 && !_stopwords.contains(part)) {
          result.add(part);
        }
      }
    }
    return result;
  }

  String normalize(String text) => tokenize(text).join(' ');
}
