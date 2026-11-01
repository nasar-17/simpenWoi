part of 'capture_importer.dart';

extension CaptureDirtySync on CaptureImporter {
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
