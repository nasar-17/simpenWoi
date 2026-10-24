import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/parser/transaction_parser.dart';
import '../../core/transaction_values.dart';
import '../transactions/transaction_providers.dart';
import '../transactions/transaction_repository.dart';
import '../wallets/wallet_providers.dart';
import 'merchant_rule_repository.dart';
import 'native_capture_bridge.dart';

class CaptureSyncService {
  CaptureSyncService(this._ref);

  final Ref _ref;

  static const TransactionParser _parser = TransactionParser();

  bool _syncing = false;

  Future<void> sync() async {
    if (_syncing) {
      return;
    }
    _syncing = true;
    try {
      await pushLocalContext();
      await _importPending();
    } finally {
      _syncing = false;
    }
  }

  Future<void> pushLocalContext() async {
    final NativeCaptureBridge bridge = _ref.read(nativeCaptureBridgeProvider);
    final List<Category> categories =
        await _ref.read(transactionRepositoryProvider).getCategories();
    final List<Category> expenseCategories = categories
        .where((Category category) => category.type == TransactionType.expense)
        .toList();
    final List<Category> topCategories =
        await _topExpenseCategories(expenseCategories);
    final List<MerchantRule> rules =
        await _ref.read(merchantRuleRepositoryProvider).getAll();
    final Map<int, String> categoryNames = <int, String>{
      for (final Category category in categories) category.id: category.name,
    };

    await bridge.pushCategories(
      categories: expenseCategories.map(_categoryPayload).toList(),
      topCategories: topCategories.map(_categoryPayload).toList(),
    );
    await bridge.pushMerchantRules(
      rules
          .where((MerchantRule rule) => rule.useCount >= 2)
          .map(
            (MerchantRule rule) => <String, Object?>{
              'merchant': rule.merchant,
              'category_id': rule.categoryId,
              'category_name': categoryNames[rule.categoryId] ?? '',
            },
          )
          .toList(),
    );
  }

  Future<List<Category>> _topExpenseCategories(
    List<Category> expenseCategories,
  ) async {
    if (expenseCategories.isEmpty) {
      return <Category>[];
    }

    final List<QueryRow> rows =
        await _ref.read(databaseProvider).customSelect(
      'SELECT category_id, COUNT(*) AS usage_count '
      'FROM transactions '
      'WHERE category_id IS NOT NULL '
      'GROUP BY category_id '
      'ORDER BY usage_count DESC, category_id ASC '
      'LIMIT 2',
    ).get();
    final List<int> topIds = rows
        .map((QueryRow row) => row.read<int>('category_id'))
        .toList();

    final List<Category> result = <Category>[
      for (final int id in topIds)
        ...expenseCategories.where((Category category) => category.id == id),
    ];
    for (final Category category in expenseCategories) {
      if (result.length >= 2) {
        break;
      }
      if (result.any((Category item) => item.id == category.id)) {
        continue;
      }
      result.add(category);
    }
    return result.take(2).toList();
  }

  Map<String, Object?> _categoryPayload(Category category) {
    return <String, Object?>{'id': category.id, 'name': category.name};
  }

  Future<void> _importPending() async {
    final NativeCaptureBridge bridge = _ref.read(nativeCaptureBridgeProvider);
    final List<NativeCapture> captures = await bridge.getPendingCaptures();
    if (captures.isEmpty) {
      return;
    }

    final List<Wallet> wallets =
        await _ref.read(walletRepositoryProvider).getAll();
    if (wallets.isEmpty) {
      return;
    }
    final List<Category> categories =
        await _ref.read(transactionRepositoryProvider).getCategories();
    final TransactionRepository repository =
        _ref.read(transactionRepositoryProvider);

    bool rulesChanged = false;
    for (final NativeCapture capture in captures) {
      if (capture.amount <= 0) {
        await bridge.markImported(<int>[capture.id]);
        continue;
      }

      final int? categoryId = _resolveCategory(capture, categories);
      await repository.addTransaction(
        amount: capture.amount,
        type: TransactionType.expense,
        walletId: _resolveWallet(wallets, capture.sourcePackage).id,
        categoryId: categoryId,
        note: capture.note,
        merchant: capture.merchant,
        source: TransactionSource.notification,
        createdAt: capture.postedAt,
      );

      if (categoryId != null && capture.categoryId != null) {
        final String? merchant = capture.merchant?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          await _ref
              .read(merchantRuleRepositoryProvider)
              .recordUsage(merchant, categoryId);
          rulesChanged = true;
        }
      }

      await bridge.markImported(<int>[capture.id]);
    }

    if (rulesChanged) {
      await pushLocalContext();
    }
  }

  int? _resolveCategory(NativeCapture capture, List<Category> categories) {
    final int? queuedCategoryId = capture.categoryId;
    if (queuedCategoryId != null &&
        categories.any(
          (Category category) =>
              category.id == queuedCategoryId &&
              category.type == TransactionType.expense,
        )) {
      return queuedCategoryId;
    }

    final String? note = capture.note?.trim();
    if (note == null || note.isEmpty) {
      return null;
    }
    final int? parsedCategoryId = _parser.parse(note).categoryId;
    if (parsedCategoryId == null) {
      return null;
    }
    final bool valid = categories.any(
      (Category category) =>
          category.id == parsedCategoryId &&
          category.type == TransactionType.expense,
    );
    return valid ? parsedCategoryId : null;
  }

  Wallet _resolveWallet(List<Wallet> wallets, String sourcePackage) {
    final String normalizedPackage =
        sourcePackage.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final Wallet wallet in wallets) {
      final String normalizedName =
          wallet.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalizedName.isNotEmpty &&
          normalizedPackage.contains(normalizedName)) {
        return wallet;
      }
    }
    for (final Wallet wallet in wallets) {
      if (wallet.isDefault) {
        return wallet;
      }
    }
    return wallets.first;
  }

  Future<void> categorizeTransaction(
    TransactionRecord record,
    int categoryId,
  ) async {
    await _ref.read(transactionRepositoryProvider).updateTransaction(
          id: record.id,
          amount: record.amount,
          type: record.type,
          walletId: record.walletId,
          categoryId: categoryId,
          note: record.note,
          merchant: record.merchant,
        );
    await recordMerchantUsage(record.merchant, categoryId);
  }

  Future<void> recordMerchantUsage(String? merchant, int categoryId) async {
    final String? trimmed = merchant?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    await _ref
        .read(merchantRuleRepositoryProvider)
        .recordUsage(trimmed, categoryId);
    await pushLocalContext();
  }
}

final Provider<CaptureSyncService> captureSyncServiceProvider =
    Provider<CaptureSyncService>((ref) => CaptureSyncService(ref));
