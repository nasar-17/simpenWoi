/// Nama channel dan method yang dipakai jembatan capture.
abstract final class CaptureChannel {
  static const String name = 'simpenwoi/capture';

  static const String getPendingCaptures = 'getPendingCaptures';
  static const String getDirtyCaptures = 'getDirtyCaptures';
  static const String markImported = 'markImported';
  static const String markSynced = 'markSynced';
  static const String pushCategories = 'pushCategories';
  static const String pushMerchantRules = 'pushMerchantRules';
  static const String isListenerEnabled = 'isListenerEnabled';
  static const String openListenerSettings = 'openListenerSettings';
  static const String simulateCapture = 'simulateCapture';

  static const String ids = 'ids';
  static const String categories = 'categories';
  static const String topCategories = 'top_categories';
  static const String rules = 'rules';
  static const String amount = 'amount';
  static const String merchant = 'merchant';
}

/// Kunci payload capture dari sisi native.
abstract final class CaptureKeys {
  static const String id = 'id';
  static const String name = 'name';
  static const String amount = 'amount';
  static const String merchant = 'merchant';
  static const String sourcePackage = 'source_package';
  static const String postedAt = 'posted_at';
  static const String categoryId = 'category_id';
  static const String categoryName = 'category_name';
  static const String note = 'note';
}

abstract final class CaptureConstants {
  static const int topCategoryLimit = 2;
  static const int merchantRuleThreshold = 2;
  static const int defaultSimulationAmount = 25000;
  static const String defaultSimulationMerchant = 'Warung Bu Tini';
}
