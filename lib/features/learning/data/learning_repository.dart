import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/learning_stats.dart';
import '../domain/text_normalizer.dart';
import 'lexicon_repository.dart';

class LearningRepository {
  LearningRepository(this._database, this._lexiconRepository);

  final AppDatabase _database;
  final LexiconRepository _lexiconRepository;

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

  Future<void> applyFeedback({
    required String inputText,
    required String outcome,
    int? oldCategoryId,
    int? newCategoryId,
    String? merchant,
  }) async {
    final normalizer = TextNormalizer(
      slang: (await _lexiconRepository.load()).slang,
    );
    final Set<String> tokens = normalizer.tokenize(inputText).toSet();
    final Set<String> merchantTokens = normalizer
        .tokenize(merchant ?? '')
        .toSet();
    await _database.transaction(() async {
      if (outcome == 'accepted' && newCategoryId != null) {
        for (final String token in tokens) {
          await _adjustToken(token, newCategoryId, 1);
        }
      } else if (outcome == 'corrected') {
        if (oldCategoryId != null) {
          for (final String token in tokens) {
            await _adjustToken(token, oldCategoryId, -1);
          }
        }
        if (newCategoryId != null) {
          for (final String token in tokens) {
            await _adjustToken(token, newCategoryId, 3);
          }
        }
      } else if (outcome == 'rejected' && oldCategoryId != null) {
        for (final String token in tokens) {
          await _adjustToken(token, oldCategoryId, -1);
        }
      }
      if (newCategoryId != null) {
        for (final String token in merchantTokens) {
          await _adjustToken(token, newCategoryId, 2);
        }
      }
    });
  }

  Future<List<MlTokenStat>> tokenStats() {
    return (_database.select(_database.mlTokenStats)
          ..where((table) => table.count.isBiggerThanValue(0)))
        .get();
  }

  Future<LearningStats> stats({DateTime? now}) async {
    final DateTime anchor = now ?? DateTime.now();
    final DateTime since = anchor.subtract(const Duration(days: 7));
    final QueryRow words = await _database
        .customSelect(
          'SELECT COUNT(DISTINCT token) AS total FROM ml_token_stats '
          'WHERE count > 0',
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

  Future<void> _adjustToken(String token, int categoryId, int delta) async {
    if (delta == 0) {
      return;
    }
    final MlTokenStat? existing =
        await (_database.select(_database.mlTokenStats)..where(
              (table) =>
                  table.token.equals(token) &
                  table.categoryId.equals(categoryId),
            ))
            .getSingleOrNull();
    final DateTime now = DateTime.now();
    if (existing == null) {
      if (delta <= 0) {
        return;
      }
      await _database
          .into(_database.mlTokenStats)
          .insert(
            MlTokenStatsCompanion.insert(
              token: token,
              categoryId: categoryId,
              count: Value<int>(delta),
              updatedAt: Value<DateTime>(now),
            ),
          );
      return;
    }
    final int next = existing.count + delta;
    if (next <= 0) {
      await (_database.delete(_database.mlTokenStats)..where(
            (table) =>
                table.token.equals(token) &
                table.categoryId.equals(categoryId),
          ))
          .go();
      return;
    }
    await (_database.update(_database.mlTokenStats)..where(
          (table) =>
              table.token.equals(token) & table.categoryId.equals(categoryId),
        ))
        .write(
          MlTokenStatsCompanion(
            count: Value<int>(next),
            updatedAt: Value<DateTime>(now),
          ),
        );
  }
}
