import 'package:drift/drift.dart';

@DataClassName('SpendingTarget')
class SpendingTargets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get month => text().withLength(min: 7, max: 7).unique()();
  IntColumn get limitAmount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
