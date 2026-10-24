import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/data/wallet_repository.dart';
import '../../wallets/domain/wallet_resolver.dart';
import '../domain/capture_category_resolver.dart';
import 'capture_context_pusher.dart';
import 'merchant_rule_repository.dart';
import 'native_capture_bridge.dart';
import 'native_capture_models.dart';

/// Mengimpor capture pending dan menyinkronkan perubahan kategori terlambat.
class CaptureImporter {
  CaptureImporter({
    required this.bridge,
    required this.transactionRepository,
    required this.walletRepository,
    required this.merchantRuleRepository,
    required this.contextPusher,
  });

  final NativeCaptureBridge bridge;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final MerchantRuleRepository merchantRuleRepository;
  final CaptureContextPusher contextPusher;

  Future<void> importPending() async {
    final List<NativeCapture> captures = await bridge.getPendingCaptures();
    if (captures.isEmpty) {
      return;
    }

    final List<Wallet> wallets = await walletRepository.getAll();
    if (wallets.isEmpty) {
      return;
    }
    final List<Category> categories = await transactionRepository
        .getCategories();

    bool rulesChanged = false;
    for (final NativeCapture capture in captures) {
      if (capture.amount <= 0) {
        await bridge.markImported(<int>[capture.id]);
        continue;
      }

      final int? categoryId = resolveCaptureCategory(capture, categories);
      await transactionRepository.addTransaction(
        amount: capture.amount,
        type: TransactionType.expense,
        walletId: resolveWalletForPackage(wallets, capture.sourcePackage).id,
        categoryId: categoryId,
        note: capture.note,
        merchant: capture.merchant,
        source: TransactionSource.notification,
        createdAt: capture.postedAt,
        nativeCaptureId: capture.id,
      );

      if (categoryId != null && capture.categoryId != null) {
        final String? merchant = capture.merchant?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          await merchantRuleRepository.recordUsage(merchant, categoryId);
          rulesChanged = true;
        }
      }

      await bridge.markImported(<int>[capture.id]);
    }

    if (rulesChanged) {
      await contextPusher.pushLocalContext();
    }
  }

  Future<void> syncDirtyCaptures() async {
    final List<DirtyNativeCapture> dirtyCaptures = await bridge
        .getDirtyCaptures();
    if (dirtyCaptures.isEmpty) {
      return;
    }

    final List<Category> categories = await transactionRepository
        .getCategories();
    bool rulesChanged = false;

    for (final DirtyNativeCapture dirty in dirtyCaptures) {
      final TransactionRecord? record = await transactionRepository
          .getByNativeCaptureId(dirty.id);
      if (record == null) {
        await bridge.markSynced(<int>[dirty.id]);
        continue;
      }

      final int? categoryId = resolveDirtyCaptureCategory(
        dirty,
        record,
        categories,
      );
      final String? note = dirty.note;
      if (categoryId != record.categoryId || note != record.note) {
        await transactionRepository.updateTransaction(
          id: record.id,
          amount: record.amount,
          type: record.type,
          walletId: record.walletId,
          categoryId: categoryId,
          note: note,
          merchant: record.merchant,
        );

        final String? merchant = record.merchant?.trim();
        if (categoryId != null &&
            categoryId != record.categoryId &&
            merchant != null &&
            merchant.isNotEmpty) {
          await merchantRuleRepository.recordUsage(merchant, categoryId);
          rulesChanged = true;
        }
      }

      await bridge.markSynced(<int>[dirty.id]);
    }

    if (rulesChanged) {
      await contextPusher.pushLocalContext();
    }
  }
}
