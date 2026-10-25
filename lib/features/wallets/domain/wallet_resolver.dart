import '../../../core/constants/capture_wallet_names.dart';
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
  final String? targetName = captureWalletNames[sourcePackage];
  if (targetName != null) {
    final String normalizedTarget = targetName.trim().toLowerCase();
    for (final Wallet wallet in wallets) {
      if (wallet.name.trim().toLowerCase() == normalizedTarget) {
        return wallet;
      }
    }
  }
  return resolveWallet(wallets);
}

Wallet? resolveTransferWallet(
  List<Wallet> wallets, {
  int? preferredId,
  required int sourceId,
}) {
  if (preferredId != null && preferredId != sourceId) {
    for (final Wallet wallet in wallets) {
      if (wallet.id == preferredId) {
        return wallet;
      }
    }
  }
  for (final Wallet wallet in wallets) {
    if (wallet.id != sourceId) {
      return wallet;
    }
  }
  return null;
}

int totalWalletBalance(Iterable<Wallet> wallets) {
  int total = 0;
  for (final Wallet wallet in wallets) {
    total += wallet.balance;
  }
  return total;
}
