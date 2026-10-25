import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../capture_constants.dart';
import 'merchant_rule_repository.dart';
import 'native_capture_bridge.dart';

/// Mendorong kategori, kategori teratas, dan aturan merchant ke native.
class CaptureContextPusher {
  CaptureContextPusher({
    required this.bridge,
    required this.transactionRepository,
    required this.merchantRuleRepository,
  });

  final NativeCaptureBridge bridge;
  final TransactionRepository transactionRepository;
  final MerchantRuleRepository merchantRuleRepository;

  Future<void> pushLocalContext() async {
    final List<Category> categories = await transactionRepository
        .getCategories();
    final List<Category> expenseCategories = categories
        .where((Category category) => category.type == TransactionType.expense)
        .toList();
    final List<Category> incomeCategories = categories
        .where((Category category) => category.type == TransactionType.income)
        .toList();
    final List<Category> topCategories = await _topCategories(
      expenseCategories,
      TransactionType.expense,
    );
    final List<Category> topIncomeCategories = await _topCategories(
      incomeCategories,
      TransactionType.income,
    );
    final List<MerchantRule> rules = await merchantRuleRepository.getAll();
    final Map<int, String> categoryNames = <int, String>{
      for (final Category category in categories) category.id: category.name,
    };

    await bridge.pushCategories(
      categories: expenseCategories.map(_categoryPayload).toList(),
      topCategories: topCategories.map(_categoryPayload).toList(),
      incomeCategories: incomeCategories.map(_categoryPayload).toList(),
      topIncomeCategories: topIncomeCategories.map(_categoryPayload).toList(),
    );
    await bridge.pushMerchantRules(
      rules
          .where(
            (MerchantRule rule) =>
                rule.useCount >= CaptureConstants.merchantRuleThreshold &&
                categoryNames.containsKey(rule.categoryId),
          )
          .map(
            (MerchantRule rule) => <String, Object?>{
              CaptureKeys.merchant: rule.merchant,
              CaptureKeys.categoryId: rule.categoryId,
              CaptureKeys.categoryName: categoryNames[rule.categoryId] ?? '',
            },
          )
          .toList(),
    );
  }

  Future<List<Category>> _topCategories(
    List<Category> source,
    String type,
  ) async {
    if (source.isEmpty) {
      return <Category>[];
    }

    final List<int> topIds = await transactionRepository.topCategoryIds(
      type,
      limit: CaptureConstants.topCategoryLimit,
    );
    final List<Category> result = <Category>[
      for (final int id in topIds)
        ...source.where((Category category) => category.id == id),
    ];
    for (final Category category in source) {
      if (result.length >= CaptureConstants.topCategoryLimit) {
        break;
      }
      if (result.any((Category item) => item.id == category.id)) {
        continue;
      }
      result.add(category);
    }
    return result.take(CaptureConstants.topCategoryLimit).toList();
  }

  Map<String, Object?> _categoryPayload(Category category) {
    return <String, Object?>{
      CaptureKeys.id: category.id,
      CaptureKeys.name: category.name,
    };
  }
}
