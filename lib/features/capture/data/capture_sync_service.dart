import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import 'capture_context_pusher.dart';
import 'capture_importer.dart';
import 'merchant_rule_repository.dart';

/// Orkestrator sinkronisasi capture dari notifikasi.
class CaptureSyncService {
  CaptureSyncService({
    required this.transactionRepository,
    required this.merchantRuleRepository,
    required this.contextPusher,
    required this.importer,
  });

  final TransactionRepository transactionRepository;
  final MerchantRuleRepository merchantRuleRepository;
  final CaptureContextPusher contextPusher;
  final CaptureImporter importer;

  bool _syncing = false;
  bool _syncPending = false;

  Future<void> refreshNativeContext() {
    return contextPusher.pushLocalContext();
  }

  Future<void> sync() async {
    if (_syncing) {
      _syncPending = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncPending = false;
        await contextPusher.pushLocalContext();
        await importer.importPending();
        await importer.syncDirtyCaptures();
      } while (_syncPending);
    } finally {
      _syncing = false;
    }
  }

  Future<void> categorizeTransaction(
    TransactionRecord record,
    int categoryId,
  ) async {
    final bool rulesChanged = await transactionRepository.updateTransaction(
      id: record.id,
      amount: record.amount,
      type: record.type,
      walletId: record.walletId,
      counterpartWalletId: record.counterpartWalletId,
      categoryId: categoryId,
      note: record.note,
      merchant: record.merchant,
      excludeFromTarget: record.excludeFromTarget,
    );
    final int? nativeCaptureId = record.nativeCaptureId;
    if (nativeCaptureId != null) {
      await importer.syncEditedCapture(
        nativeCaptureId: nativeCaptureId,
        categoryId: categoryId,
        note: record.note,
      );
    }
    if (rulesChanged) {
      await refreshNativeContext();
    }
  }

  Future<void> syncEditedCapture({
    required int nativeCaptureId,
    required int? categoryId,
    required String? note,
  }) {
    return importer.syncEditedCapture(
      nativeCaptureId: nativeCaptureId,
      categoryId: categoryId,
      note: note,
    );
  }

  Future<void> recordMerchantUsage(String? merchant, int categoryId) async {
    final String? trimmed = merchant?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    await merchantRuleRepository.recordUsage(trimmed, categoryId);
    await contextPusher.pushLocalContext();
  }
}
