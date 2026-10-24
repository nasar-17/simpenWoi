import 'transaction_values.dart';

/// Kategori bawaan yang di-seed saat database pertama kali dibuat.
class SeedCategory {
  const SeedCategory(this.id, this.name, this.type);

  final int id;
  final String name;
  final String type;
}

/// ID kategori bawaan yang dipakai parser dan aturan merchant.
abstract final class CategoryIds {
  static const int makan = 1;
  static const int transport = 2;
  static const int belanja = 3;
  static const int tagihan = 4;
  static const int hiburan = 5;
  static const int kesehatan = 6;
  static const int lainnyaExpense = 7;
  static const int gaji = 8;
  static const int lainnyaIncome = 9;
}

const List<SeedCategory> seedCategories = <SeedCategory>[
  SeedCategory(CategoryIds.makan, 'Makan', TransactionType.expense),
  SeedCategory(CategoryIds.transport, 'Transport', TransactionType.expense),
  SeedCategory(CategoryIds.belanja, 'Belanja', TransactionType.expense),
  SeedCategory(CategoryIds.tagihan, 'Tagihan', TransactionType.expense),
  SeedCategory(CategoryIds.hiburan, 'Hiburan', TransactionType.expense),
  SeedCategory(CategoryIds.kesehatan, 'Kesehatan', TransactionType.expense),
  SeedCategory(CategoryIds.lainnyaExpense, 'Lainnya', TransactionType.expense),
  SeedCategory(CategoryIds.gaji, 'Gaji', TransactionType.income),
  SeedCategory(CategoryIds.lainnyaIncome, 'Lainnya', TransactionType.income),
];
