import 'package:drift/drift.dart';

@DataClassName('LearningLogEntry')
class LearningLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get inputText => text()();
  TextColumn get actionJson => text()();
  TextColumn get outcome => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
