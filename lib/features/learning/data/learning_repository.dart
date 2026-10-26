import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/learning_stats.dart';

class LearningRepository {
  LearningRepository(this._database);

  final AppDatabase _database;

  Future<int> record({
    required String inputText,
    required String actionJson,
    required String outcome,
  }) {
    return _database
        .into(_database.learningLog)
        .insert(
          LearningLogCompanion.insert(
            inputText: inputText,
            actionJson: actionJson,
            outcome: outcome,
          ),
        );
  }

  Future<LearningStats> stats({DateTime? now}) async {
    final DateTime anchor = now ?? DateTime.now();
    final DateTime since = anchor.subtract(const Duration(days: 7));
    final QueryRow words = await _database
        .customSelect(
          'SELECT COUNT(DISTINCT token) AS total FROM ml_token_stats',
        )
        .getSingle();
    final QueryRow corrections = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM learning_log '
          'WHERE outcome = ? AND created_at >= ?',
          variables: <Variable<Object>>[
            Variable.withString('corrected'),
            Variable.withDateTime(since),
          ],
        )
        .getSingle();
    final QueryRow guesses = await _database
        .customSelect(
          'SELECT COUNT(*) AS total, '
          'COALESCE(SUM(CASE WHEN outcome = ? THEN 1 ELSE 0 END), 0) AS correct '
          'FROM learning_log '
          'WHERE outcome IN (?, ?) AND created_at >= ?',
          variables: <Variable<Object>>[
            Variable.withString('accepted'),
            Variable.withString('accepted'),
            Variable.withString('corrected'),
            Variable.withDateTime(since),
          ],
        )
        .getSingle();
    return LearningStats(
      words: words.read<int>('total'),
      corrections7d: corrections.read<int>('total'),
      guesses7d: guesses.read<int>('total'),
      correctFirstGuess7d: guesses.read<int>('correct'),
    );
  }

  Future<void> resetStats() {
    return _database.delete(_database.mlTokenStats).go();
  }

  Future<void> clearLog() {
    return _database.delete(_database.learningLog).go();
  }

  Future<List<LearningLogEntry>> recentExamples({int limit = 3}) {
    return (_database.select(_database.learningLog)
          ..where(
            (table) => table.outcome.isIn(<String>['accepted', 'corrected']),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<List<LearningLogEntry>> allEntries() {
    return (_database.select(
      _database.learningLog,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
  }
}
