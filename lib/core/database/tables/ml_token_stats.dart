import 'package:drift/drift.dart';

import 'categories.dart';

@TableIndex(
  name: 'idx_ml_token_stats_token_category',
  columns: <Symbol>{#token, #categoryId},
  unique: true,
)
@DataClassName('MlTokenStat')
class MlTokenStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get token => text()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
