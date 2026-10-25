/// Periode rekap yang dapat dipilih pengguna.
enum RecapPeriod { daily, weekly, monthly }

/// Rentang tanggal setengah terbuka `[start, end)` untuk sebuah rekap.
class RecapRange {
  const RecapRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is RecapRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

RecapRange recapRangeFor(RecapPeriod period, DateTime anchor) {
  switch (period) {
    case RecapPeriod.daily:
      final DateTime start = DateTime(anchor.year, anchor.month, anchor.day);
      return RecapRange(start: start, end: start.add(const Duration(days: 1)));
    case RecapPeriod.weekly:
      final DateTime monday = anchor.subtract(
        Duration(days: anchor.weekday - 1),
      );
      final DateTime start = DateTime(monday.year, monday.month, monday.day);
      return RecapRange(start: start, end: start.add(const Duration(days: 7)));
    case RecapPeriod.monthly:
      return RecapRange(
        start: DateTime(anchor.year, anchor.month, 1),
        end: DateTime(anchor.year, anchor.month + 1, 1),
      );
  }
}

DateTime shiftRecapAnchor(RecapPeriod period, DateTime anchor, int direction) {
  switch (period) {
    case RecapPeriod.daily:
      return anchor.add(Duration(days: direction));
    case RecapPeriod.weekly:
      return anchor.add(Duration(days: direction * 7));
    case RecapPeriod.monthly:
      return DateTime(anchor.year, anchor.month + direction, 1);
  }
}
