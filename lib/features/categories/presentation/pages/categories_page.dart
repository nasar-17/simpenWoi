import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/database/app_database.dart';
import '../../../capture/presentation/widgets/category_picker_sheet.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/category_repository.dart';
import '../providers/category_providers.dart';
import '../widgets/category_dialogs.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_tile.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('Gagal memuat kategori: $error')),
        data: (List<Category> data) => _CategoryList(categories: data),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final List<Category> expense = categories
        .where((Category item) => item.type == TransactionType.expense)
        .toList(growable: false);
    final List<Category> income = categories
        .where((Category item) => item.type == TransactionType.income)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        _Section(
          title: 'Pengeluaran',
          type: TransactionType.expense,
          categories: expense,
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Pemasukan',
          type: TransactionType.income,
          categories: income,
        ),
      ],
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.type,
    required this.categories,
  });

  final String title;
  final String type;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              tooltip: 'Tambah $title',
              onPressed: () => _openForm(context, type: type),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Belum ada kategori.'),
          )
        else
          ...categories.map(
            (Category category) => CategoryTile(
              category: category,
              canDelete: !ref
                  .read(categoryRepositoryProvider)
                  .isProtected(category),
              onEdit: () => _openForm(context, category: category),
              onDelete: () => _delete(context, ref, category),
            ),
          ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    String? type,
    Category? category,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) =>
          CategoryFormSheet(category: category, initialType: type),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final CategoryRepository repository = ref.read(categoryRepositoryProvider);
    try {
      final int usage = await repository.countTransactions(category.id);
      if (!context.mounted) {
        return;
      }
      int? moveToId;
      String? targetName;
      if (usage > 0) {
        final List<Category> targets = categories
            .where(
              (Category item) =>
                  item.id != category.id && item.type == category.type,
            )
            .toList(growable: false);
        if (targets.isEmpty) {
          showCategoryMessage(context, 'Tidak ada kategori pengganti.');
          return;
        }
        final int? selected = await showModalBottomSheet<int>(
          context: context,
          useSafeArea: true,
          builder: (BuildContext context) =>
              CategoryPickerSheet(categories: targets),
        );
        if (selected == null || !context.mounted) {
          return;
        }
        moveToId = selected;
        targetName = targets
            .firstWhere((Category item) => item.id == selected)
            .name;
      }
      final bool confirmed = await confirmCategoryDelete(
        context,
        name: category.name,
        usage: usage,
        targetName: targetName,
      );
      if (!confirmed || !context.mounted) {
        return;
      }
      await ref
          .read(categoryServiceProvider)
          .delete(id: category.id, moveToId: moveToId);
      if (context.mounted) {
        showCategoryMessage(context, 'Kategori dihapus.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        showCategoryMessage(context, error.toString());
      }
    }
  }
}
