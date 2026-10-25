import '../../../core/constants/transaction_values.dart';
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

  Future<void> refreshNativeContext() {
    return contextPusher.pushLocalContext();
  }

  Future<void> sync() async {
    if (_syncing) {
      return;
    }
    _syncing = true;
    try {
      await contextPusher.pushLocalContext();
      await importer.importPending();
      await importer.syncDirtyCaptures();
    } finally {
      _syncing = false;
    }
  }

  Future<void> categorizeTransaction(
    TransactionRecord record,
    int categoryId,
  ) async {
    await transactionRepository.updateTransaction(
      id: record.id,
      amount: record.amount,
      type: record.type,
      walletId: record.walletId,
      categoryId: categoryId,
      note: record.note,
      merchant: record.merchant,
    );
    if (record.type == TransactionType.expense) {
      await recordMerchantUsage(record.merchant, categoryId);
    }
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
