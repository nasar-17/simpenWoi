import 'package:flutter/material.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/database/app_database.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String? keywords = category.keywords?.trim();
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          category.type == TransactionType.income
              ? Icons.trending_up
              : Icons.trending_down,
        ),
      ),
      title: Text(category.name),
      subtitle: keywords == null || keywords.isEmpty
          ? null
          : Text('Kata kunci: $keywords'),
      trailing: PopupMenuButton<String>(
        onSelected: (String action) {
          if (action == 'edit') {
            onEdit();
          } else if (action == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'edit', child: Text('Ubah')),
          if (canDelete)
            const PopupMenuItem<String>(value: 'delete', child: Text('Hapus')),
        ],
      ),
    );
  }
}
