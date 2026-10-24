import '../../../core/database/app_database.dart';

/// Memilih dompet berdasarkan pilihan pengguna atau dompet default.
Wallet resolveWallet(List<Wallet> wallets, {int? preferredId}) {
  if (preferredId != null) {
    for (final Wallet wallet in wallets) {
      if (wallet.id == preferredId) {
        return wallet;
      }
    }
  }
  for (final Wallet wallet in wallets) {
    if (wallet.isDefault) {
      return wallet;
    }
  }
  return wallets.first;
}

/// Memilih dompet dari nama paket sumber notifikasi.
Wallet resolveWalletForPackage(List<Wallet> wallets, String sourcePackage) {
  final String normalizedPackage = sourcePackage.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]'),
    '',
  );
  for (final Wallet wallet in wallets) {
    final String normalizedName = wallet.name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (normalizedName.isNotEmpty &&
        normalizedPackage.contains(normalizedName)) {
      return wallet;
    }
  }
  return resolveWallet(wallets);
}

int totalWalletBalance(Iterable<Wallet> wallets) {
  int total = 0;
  for (final Wallet wallet in wallets) {
    total += wallet.balance;
  }
  return total;
}
