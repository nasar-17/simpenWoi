import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/data/wallet_repository.dart';
import '../../wallets/domain/wallet_resolver.dart';
import '../domain/capture_category_classifier.dart';
import '../domain/capture_category_resolver.dart';
import '../domain/capture_direction.dart';
import 'capture_context_pusher.dart';
import 'capture_ai_processor.dart';
import 'capture_learning_recorder.dart';
import 'capture_transfer_importer.dart';
import 'native_capture_bridge.dart';
import 'native_capture_models.dart';

/// Mengimpor capture pending dan menyinkronkan perubahan kategori terlambat.
class CaptureImporter {
  CaptureImporter({
    required this.bridge,
    required this.transactionRepository,
    required this.walletRepository,
    required this.contextPusher,
    required this.classifier,
    required this.learningRecorder,
    required this.transferImporter,
    required this.aiProcessor,
  });

  final NativeCaptureBridge bridge;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final CaptureContextPusher contextPusher;
  final CaptureCategoryClassifier classifier;
  final CaptureLearningRecorder learningRecorder;
  final CaptureTransferImporter transferImporter;
  final CaptureAiProcessor aiProcessor;

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

    await aiProcessor.resolvePending(
      captures: captures, wallets: wallets, categories: categories,
    );
    bool rulesChanged = false;
    // Re-read because AI resolution may have changed queue status or fields.
    for (final NativeCapture capture in await bridge.getPendingCaptures()) {
      if (capture.direction == 'raw') continue;
      if (capture.amount <= 0) {
        await bridge.markImported(<int>[capture.id]);
        continue;
      }

      if (capture.isTransfer) {
        await transferImporter.importTransfer(capture, wallets);
        await bridge.markImported(<int>[capture.id]);
        continue;
      }

      final TransactionRecord? existing = await transactionRepository
          .getByNativeCaptureId(capture.id);
      if (existing != null && existing.type != TransactionType.transfer) {
        await bridge.markImported(<int>[capture.id]);
        continue;
      }
      final bool incoming = capture.direction == CaptureDirection.incoming;
      final String type = incoming
          ? TransactionType.income
          : TransactionType.expense;
      final int? categoryId = await resolveCaptureCategory(
        capture,
        categories,
        classifier,
      );
      await transactionRepository.database.transaction(() async {
        if (existing != null) {
          await transactionRepository.deleteTransaction(existing.id);
        }
        await transactionRepository.addTransaction(
        amount: capture.amount,
        type: type,
        walletId: resolveWalletForPackage(wallets, capture.sourcePackage).id,
        categoryId: categoryId,
        note: capture.note,
        merchant: capture.merchant,
        source: TransactionSource.notification,
        createdAt: capture.postedAt,
        nativeCaptureId: capture.id,
        );
      });

      if (!incoming && categoryId != null && capture.categoryId != null) {
        final String? merchant = capture.merchant?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          rulesChanged = true;
        }
      }

      await bridge.markImported(<int>[capture.id]);
    }

    if (rulesChanged) {
      await contextPusher.pushLocalContext();
    }
  }

  Future<void> syncEditedCapture({
    required int nativeCaptureId,
    required int? categoryId,
    required String? note,
  }) {
    return bridge.syncCapture(
      id: nativeCaptureId,
      categoryId: categoryId,
      note: note,
    );
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

      final int? categoryId = await resolveDirtyCaptureCategory(
        dirty,
        record,
        categories,
        classifier,
      );
      final String? note = dirty.note;
      if (categoryId != record.categoryId || note != record.note) {
        final bool ruleChanged = await transactionRepository.updateTransaction(
          id: record.id,
          amount: record.amount,
          type: record.type,
          walletId: record.walletId,
          counterpartWalletId: record.counterpartWalletId,
          categoryId: categoryId,
          note: note,
          merchant: record.merchant,
          excludeFromTarget: record.excludeFromTarget,
        );
        rulesChanged = rulesChanged || ruleChanged;
        if (categoryId != null) {
          await learningRecorder.record(
            inputText: note ?? record.note ?? record.merchant ?? '',
            merchant: record.merchant,
            oldCategoryId: record.categoryId,
            newCategoryId: categoryId,
          );
        }
      }

      await bridge.markSynced(<int>[dirty.id]);
    }

    if (rulesChanged) {
      await contextPusher.pushLocalContext();
    }
  }
}
