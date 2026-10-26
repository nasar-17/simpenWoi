import 'package:drift/drift.dart';

import '../constants/transaction_values.dart';
import '../database/app_database.dart';
import 'assistant_action.dart';

class AssistantQueryRepository {
  AssistantQueryRepository(this._database);

  final AppDatabase _database;

  Future<int> expenseTotal({
    required QueryTotalPeriod period,
    int? categoryId,
    DateTime? now,
  }) async {
    final DateTime anchor = now ?? DateTime.now();
    final DateTime start = switch (period) {
      QueryTotalPeriod.today => DateTime(anchor.year, anchor.month, anchor.day),
      QueryTotalPeriod.week => _startOfWeek(anchor),
      QueryTotalPeriod.month => DateTime(anchor.year, anchor.month, 1),
    };
    final DateTime end = switch (period) {
      QueryTotalPeriod.today => start.add(const Duration(days: 1)),
      QueryTotalPeriod.week => start.add(const Duration(days: 7)),
      QueryTotalPeriod.month => DateTime(anchor.year, anchor.month + 1, 1),
    };
    final List<Variable<Object>> variables = <Variable<Object>>[
      Variable.withString(TransactionType.expense),
      Variable.withDateTime(start),
      Variable.withDateTime(end),
    ];
    String categoryFilter = '';
    if (categoryId != null) {
      categoryFilter = 'AND category_id = ? ';
      variables.add(Variable.withInt(categoryId));
    }
    final QueryRow row = await _database
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
          'WHERE type = ? AND created_at >= ? AND created_at < ? '
          '$categoryFilter',
          variables: variables,
        )
        .getSingle();
    return row.read<int>('total');
  }

  DateTime _startOfWeek(DateTime anchor) {
    final DateTime monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
