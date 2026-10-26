import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/lexicon_data.dart';

class LexiconRepository {
  LexiconRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  LexiconData? _cache;

  Future<LexiconData> load() async {
    final LexiconData? cached = _cache;
    if (cached != null) {
      return cached;
    }
    try {
      final String raw = await _bundle.loadString(
        'assets/ai/lexicon_id.json',
      );
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic> categoriesJson =
          json['categories'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final Map<String, dynamic> slangJson =
          json['slang'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final Map<String, LexiconCategory> categories =
          <String, LexiconCategory>{};
      for (final MapEntry<String, dynamic> entry in categoriesJson.entries) {
        final Map<String, dynamic> value =
            entry.value as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final List<String> terms =
            (value['terms'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false);
        categories[entry.key.toLowerCase()] = LexiconCategory(
          type: value['type'] as String? ?? 'expense',
          terms: terms,
        );
      }
      final LexiconData data = LexiconData(
        categories: categories,
        slang: slangJson.map(
          (String key, Object? value) =>
              MapEntry<String, String>(key.toLowerCase(), '$value'),
        ),
      );
      _cache = data;
      return data;
    } catch (_) {
      const LexiconData empty = LexiconData.empty();
      _cache = empty;
      return empty;
    }
  }
}
