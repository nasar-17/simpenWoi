import 'package:drift/drift.dart';

import '../../../core/constants/category_catalog.dart';
import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';

/// Akses data kategori pengguna dan pemindahan transaksi saat hapus.
class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  Stream<List<Category>> watchAll() {
    return _database.select(_database.categories).watch().map(_sorted);
  }

  Future<List<Category>> getAll() async {
    return _sorted(await _database.select(_database.categories).get());
  }

  Future<Category?> getById(int id) {
    return (_database.select(
      _database.categories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> add({
    required String name,
    required String type,
    String? keywords,
  }) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama kategori wajib diisi.');
    }
    if (type != TransactionType.expense && type != TransactionType.income) {
      throw ArgumentError.value(type, 'type', 'Jenis kategori tidak valid.');
    }
    return _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: trimmedName,
            type: Value<String>(type),
            keywords: Value<String?>(_normalizeKeywords(keywords)),
          ),
        );
  }

  Future<void> update({
    required int id,
    required String name,
    String? keywords,
  }) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama kategori wajib diisi.');
    }
    await (_database.update(
      _database.categories,
    )..where((table) => table.id.equals(id))).write(
      CategoriesCompanion(
        name: Value<String>(trimmedName),
        keywords: Value<String?>(_normalizeKeywords(keywords)),
      ),
    );
  }

  Future<int> countTransactions(int id) {
    return _countTransactions(id);
  }

  Future<Category?> fallbackFor(String type) {
    final int id = type == TransactionType.income
        ? CategoryIds.lainnyaIncome
        : CategoryIds.lainnyaExpense;
    return getById(id);
  }

  bool isProtected(Category category) {
    return category.id == CategoryIds.lainnyaExpense ||
        category.id == CategoryIds.lainnyaIncome;
  }

  Future<void> delete({required int id, int? moveToId}) {
    return _database.transaction(() async {
      final Category? category = await getById(id);
      if (category == null) {
        return;
      }
      if (isProtected(category)) {
        throw StateError('Kategori Lainnya tidak boleh dihapus.');
      }
      final int usage = await _countTransactions(id);
      if (usage > 0 && moveToId == null) {
        throw StateError('Kategori masih dipakai transaksi.');
      }
      if (moveToId != null) {
        if (moveToId == id) {
          throw StateError('Kategori tujuan tidak valid.');
        }
        final Category? target = await getById(moveToId);
        if (target == null || target.type != category.type) {
          throw StateError('Kategori tujuan tidak valid.');
        }
        await (_database.update(
          _database.transactions,
        )..where((table) => table.categoryId.equals(id))).write(
          TransactionsCompanion(
            categoryId: Value<int>(moveToId),
            isCategorized: const Value<bool>(true),
          ),
        );
        await (_database.update(_database.merchantRules)
              ..where((table) => table.categoryId.equals(id)))
            .write(MerchantRulesCompanion(categoryId: Value<int>(moveToId)));
      } else {
        await (_database.delete(
          _database.merchantRules,
        )..where((table) => table.categoryId.equals(id))).go();
      }
      await (_database.delete(
        _database.categories,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<int> _countTransactions(int id) async {
    final QueryRow row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM transactions WHERE category_id = ?',
          variables: <Variable<Object>>[Variable.withInt(id)],
        )
        .getSingle();
    return row.read<int>('total');
  }

  List<Category> _sorted(List<Category> categories) {
    categories.sort((Category a, Category b) => a.id.compareTo(b.id));
    return categories;
  }

  String? _normalizeKeywords(String? raw) {
    final String? trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
