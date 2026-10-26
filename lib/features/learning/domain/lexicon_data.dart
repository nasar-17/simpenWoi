class LexiconCategory {
  const LexiconCategory({required this.type, required this.terms});

  final String type;
  final List<String> terms;
}

class LexiconData {
  const LexiconData({
    required this.categories,
    required this.slang,
  });

  const LexiconData.empty()
    : categories = const <String, LexiconCategory>{},
      slang = const <String, String>{};

  final Map<String, LexiconCategory> categories;
  final Map<String, String> slang;
}
