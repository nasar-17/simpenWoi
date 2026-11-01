import '../../../core/constants/capture_wallet_names.dart';
import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import 'native_capture_models.dart';

/// Reads only explicit source/destination mappings saved by older app versions.
/// No wallet is guessed if the source app no longer has a matching wallet.
({Wallet source, Wallet destination}) resolveCapturedTransferWallets(
  NativeCapture capture,
  List<Wallet> wallets,
) {
  Wallet? findWallet(String? package) {
    if (package != null && package.startsWith('wallet:')) {
      final int? id = int.tryParse(package.substring('wallet:'.length));
      for (final Wallet wallet in wallets) {
        if (wallet.id == id) return wallet;
      }
      return null;
    }
    final String? name = captureWalletNames[package];
    if (name == null) return null;
    for (final Wallet wallet in wallets) {
      if (wallet.name.trim().toLowerCase() == name.toLowerCase()) {
        return wallet;
      }
    }
    return null;
  }

  final Wallet? source = findWallet(
    capture.transferSourcePackage ?? capture.sourcePackage,
  );
  final Wallet? destination = findWallet(capture.transferDestinationPackage);
  if (source == null || destination == null || source.id == destination.id) {
    throw StateError(
      'Dompet transfer tidak dapat ditentukan. Periksa dompet asal dan tujuan.',
    );
  }
  return (source: source, destination: destination);
}

class CaptureTransferImporter {
  const CaptureTransferImporter({required this.transactionRepository});

  final TransactionRepository transactionRepository;

  Future<void> importTransfer(
    NativeCapture capture,
    List<Wallet> wallets,
  ) {
    return transactionRepository.database.transaction(() async {
      final TransactionRecord? existing = await transactionRepository
          .getByNativeCaptureId(capture.id);
      if (existing?.type == TransactionType.transfer) return;
      // Resolve before deleting anything. A missing destination must never
      // remove the original expense or select an unrelated default wallet.
      final ({Wallet source, Wallet destination}) resolved =
          resolveCapturedTransferWallets(capture, wallets);
      if (existing != null) {
        await transactionRepository.deleteTransaction(existing.id);
      }
      final int? pairId = capture.pairId;
      if (pairId != null && pairId != capture.id) {
        final TransactionRecord? previous = await transactionRepository
            .getByNativeCaptureId(pairId);
        if (previous != null) {
          await transactionRepository.deleteTransaction(previous.id);
        }
      }
      await transactionRepository.addTransaction(
        amount: capture.amount,
        type: TransactionType.transfer,
        walletId: resolved.source.id,
        counterpartWalletId: resolved.destination.id,
        note: capture.note,
        source: TransactionSource.notification,
        createdAt: capture.postedAt,
        nativeCaptureId: capture.id,
      );
    });
  }
}
