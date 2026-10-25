import 'amount_match.dart';

/// Membersihkan catatan dari teks nominal dan tanda baca di tepi.
class NoteCleaner {
  const NoteCleaner();

  String? build(String original, AmountMatch match) {
    final String before = original.substring(0, match.start);
    final String after = original.substring(match.end);
    return clean('$before $after');
  }

  String? clean(String value) {
    String note = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    note = note.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
    note = note
        .replaceAll(RegExp(r'^rp\.?\s*', caseSensitive: false), '')
        .trim();
    return note.isEmpty ? null : note;
  }
}
