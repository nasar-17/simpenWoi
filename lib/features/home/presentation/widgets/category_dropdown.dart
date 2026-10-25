import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({
    super.key,
    required this.type,
    required this.initialValue,
    required this.onChanged,
  });

  final String type;
  final int? initialValue;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Category>> categoriesAsync = ref.watch(
      categoriesProvider,
    );

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (Object error, StackTrace stack) =>
          const Text(UiText.loadCategoriesFailed),
      data: (List<Category> categories) {
        final List<Category> filtered = categories
            .where((Category category) => category.type == type)
            .toList();
        final int? selectedId =
            filtered.any((Category category) => category.id == initialValue)
            ? initialValue
            : null;
        if (selectedId != initialValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              onChanged(selectedId);
            }
          });
        }
        return DropdownButtonFormField<int?>(
          key: ValueKey<int?>(selectedId),
          initialValue: selectedId,
          decoration: const InputDecoration(labelText: 'Kategori'),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(UiText.uncategorized),
            ),
            ...filtered.map(
              (Category category) => DropdownMenuItem<int?>(
                value: category.id,
                child: Text(category.name),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
