import '../../../core/database/app_database.dart';

/// Transaksi beserta dompet dan kategori yang terhubung.
class TransactionDetail {
  const TransactionDetail({
    required this.transaction,
    required this.wallet,
    this.counterpartWallet,
    this.category,
  });

  final TransactionRecord transaction;
  final Wallet wallet;
  final Wallet? counterpartWallet;
  final Category? category;
}
