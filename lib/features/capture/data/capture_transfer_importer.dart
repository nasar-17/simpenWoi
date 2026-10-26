import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/domain/wallet_resolver.dart';
import '../domain/capture_direction.dart';
import 'native_capture_models.dart';

class CaptureTransferImporter {
  const CaptureTransferImporter({required this.transactionRepository});

  final TransactionRepository transactionRepository;

  Future<void> importTransfer(
    NativeCapture capture,
    List<Wallet> wallets,
  ) async {
    final TransactionRecord? existing = await transactionRepository
        .getByNativeCaptureId(capture.id);
    if (existing != null) {
      return;
    }
    final int? pairId = capture.pairId;
    if (pairId != null) {
      final TransactionRecord? previous = await transactionRepository
          .getByNativeCaptureId(pairId);
      if (previous != null) {
        await transactionRepository.deleteTransaction(previous.id);
      }
    }
    final String sourcePackage =
        capture.transferSourcePackage ?? capture.sourcePackage;
    final String destinationPackage = capture.transferDestinationPackage ?? '';
    final Wallet source = resolveWalletForPackage(wallets, sourcePackage);
    Wallet? destination = destinationPackage.isEmpty
        ? null
        : resolveWalletForPackage(wallets, destinationPackage);
    if (destination == null || destination.id == source.id) {
      destination = resolveTransferWallet(wallets, sourceId: source.id);
    }
    if (destination == null) {
      final bool incoming = capture.direction == CaptureDirection.incoming;
      await transactionRepository.addTransaction(
        amount: capture.amount,
        type: incoming ? TransactionType.income : TransactionType.expense,
        walletId: source.id,
        note: capture.note,
        source: TransactionSource.notification,
        createdAt: capture.postedAt,
        nativeCaptureId: capture.id,
      );
      return;
    }
    await transactionRepository.addTransaction(
      amount: capture.amount,
      type: TransactionType.transfer,
      walletId: source.id,
      counterpartWalletId: destination.id,
      note: capture.note,
      source: TransactionSource.notification,
      createdAt: capture.postedAt,
      nativeCaptureId: capture.id,
    );
  }
}
