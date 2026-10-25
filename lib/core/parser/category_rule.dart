class CategoryRule {
  const CategoryRule({
    required this.id,
    required this.name,
    required this.type,
    this.keywords,
  });

  final int id;
  final String name;
  final String type;
  final String? keywords;
}
