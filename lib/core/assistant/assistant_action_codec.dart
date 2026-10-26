import 'assistant_action.dart';

Map<String, Object?> actionToJson(AssistantAction action) {
  return switch (action) {
    AddTransactionAction() => <String, Object?>{
      'type': 'add_transaction',
      'amount': action.amount,
      'transaction_type': action.type,
      'wallet_id': action.walletId,
      'category_id': action.categoryId,
      'note': action.note,
      'merchant': action.merchant,
      'exclude_from_target': action.excludeFromTarget,
      'created_at': action.createdAt?.toIso8601String(),
    },
    CreateCategoryAction() => <String, Object?>{
      'type': 'create_category',
      'name': action.name,
      'category_type': action.type,
    },
    SetWalletBalanceAction() => <String, Object?>{
      'type': 'set_wallet_balance',
      'wallet_id': action.walletId,
      'target_balance': action.targetBalance,
    },
    TransferAction() => <String, Object?>{
      'type': 'transfer',
      'amount': action.amount,
      'from_wallet_id': action.fromWalletId,
      'to_wallet_id': action.toWalletId,
    },
    CreateWalletAction() => <String, Object?>{
      'type': 'create_wallet',
      'name': action.name,
      'initial_balance': action.initialBalance,
    },
    SetSpendingTargetAction() => <String, Object?>{
      'type': 'set_spending_target',
      'month': action.month,
      'amount': action.amount,
    },
    QueryTotalAction() => <String, Object?>{
      'type': 'query_total',
      'period': action.period.name,
      'category_id': action.categoryId,
    },
    AskClarificationAction() => <String, Object?>{
      'type': 'ask_clarification',
      'question': action.question,
      'options': action.options,
    },
  };
}

AssistantAction? actionFromJson(Map<String, Object?> json) {
  final String? type = json['type'] as String?;
  return switch (type) {
    'add_transaction' => AddTransactionAction(
      amount: _int(json['amount']) ?? 0,
      type: json['transaction_type'] as String? ?? '',
      walletId: _int(json['wallet_id']) ?? 0,
      categoryId: _int(json['category_id']),
      note: json['note'] as String?,
      merchant: json['merchant'] as String?,
      excludeFromTarget: json['exclude_from_target'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    ),
    'create_category' => CreateCategoryAction(
      name: json['name'] as String? ?? '',
      type: json['category_type'] as String? ?? '',
    ),
    'set_wallet_balance' => SetWalletBalanceAction(
      walletId: _int(json['wallet_id']) ?? 0,
      targetBalance: _int(json['target_balance']) ?? 0,
    ),
    'transfer' => TransferAction(
      amount: _int(json['amount']) ?? 0,
      fromWalletId: _int(json['from_wallet_id']) ?? 0,
      toWalletId: _int(json['to_wallet_id']) ?? 0,
    ),
    'create_wallet' => CreateWalletAction(
      name: json['name'] as String? ?? '',
      initialBalance: _int(json['initial_balance']) ?? 0,
    ),
    'set_spending_target' => SetSpendingTargetAction(
      month: json['month'] as String? ?? '',
      amount: _int(json['amount']) ?? 0,
    ),
    'query_total' => QueryTotalAction(
      period: _period(json['period'] as String?),
      categoryId: _int(json['category_id']),
    ),
    'ask_clarification' => AskClarificationAction(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<Object?>? ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
    ),
    _ => null,
  };
}

int? _int(Object? value) {
  return value is num ? value.toInt() : int.tryParse('$value');
}

QueryTotalPeriod _period(String? value) {
  for (final QueryTotalPeriod period in QueryTotalPeriod.values) {
    if (period.name == value) {
      return period;
    }
  }
  return QueryTotalPeriod.month;
}
