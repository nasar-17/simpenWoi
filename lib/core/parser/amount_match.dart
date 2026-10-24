/// Posisi dan nilai nominal yang ditemukan di teks transaksi.
class AmountMatch {
  const AmountMatch({
    required this.start,
    required this.end,
    required this.amount,
  });

  final int start;
  final int end;
  final int amount;
}
