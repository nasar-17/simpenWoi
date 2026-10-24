import 'package:drift/drift.dart';

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
