import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({super.key, required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text('Pilih kategori', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...categories.map(
            (Category category) => ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(category.name),
              onTap: () => Navigator.of(context).pop(category.id),
            ),
          ),
        ],
      ),
    );
  }
}
