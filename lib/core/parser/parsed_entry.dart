class ParsedEntry {
  const ParsedEntry({
    required this.amount,
    required this.type,
    this.categoryId,
    this.merchant,
    this.note,
  });

  final int amount;
  final String type;
  final int? categoryId;
  final String? merchant;
  final String? note;
}
