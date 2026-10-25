import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../categories/domain/category_selection.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/domain/wallet_resolver.dart';

Future<String?> saveInputTransaction({
  required TransactionRepository repository,
  required List<Wallet> wallets,
  required List<Category> categories,
  required int amount,
  required String type,
  required int? walletId,
  required int? counterpartWalletId,
  required int? categoryId,
  required String note,
  required bool excludeFromTarget,
}) async {
  if (wallets.isEmpty) {
    return 'Dompet belum tersedia.';
  }
  final Wallet wallet = resolveWallet(wallets, preferredId: walletId);
  final int? normalizedCategory = validCategoryId(categoryId, type, categories);
  final int? counterpart = type == TransactionType.transfer
      ? counterpartWalletId
      : null;
  if (type == TransactionType.transfer &&
      (counterpart == null || counterpart == wallet.id)) {
    return 'Pilih dompet tujuan yang berbeda.';
  }
  try {
    await repository.addTransaction(
      amount: amount,
      type: type,
      walletId: wallet.id,
      counterpartWalletId: counterpart,
      categoryId: normalizedCategory,
      note: note.isEmpty ? null : note,
      excludeFromTarget: type == TransactionType.expense && excludeFromTarget,
    );
    return null;
  } catch (_) {
    return 'Gagal menyimpan transaksi.';
  }
}
