import 'package:drift/drift.dart';

import 'categories.dart';

@DataClassName('MerchantRule')
class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchant => text().withLength(min: 1, max: 100).unique()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
}
