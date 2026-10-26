enum QueryTotalPeriod { today, week, month }

sealed class AssistantAction {
  const AssistantAction();
}

class AddTransactionAction extends AssistantAction {
  const AddTransactionAction({
    required this.amount,
    required this.type,
    required this.walletId,
    this.categoryId,
    this.note,
    this.merchant,
    this.excludeFromTarget = false,
    this.createdAt,
  });

  final int amount;
  final String type;
  final int walletId;
  final int? categoryId;
  final String? note;
  final String? merchant;
  final bool excludeFromTarget;
  final DateTime? createdAt;
}

class CreateCategoryAction extends AssistantAction {
  const CreateCategoryAction({required this.name, required this.type});

  final String name;
  final String type;
}

class SetWalletBalanceAction extends AssistantAction {
  const SetWalletBalanceAction({
    required this.walletId,
    required this.targetBalance,
  });

  final int walletId;
  final int targetBalance;
}

class TransferAction extends AssistantAction {
  const TransferAction({
    required this.amount,
    required this.fromWalletId,
    required this.toWalletId,
  });

  final int amount;
  final int fromWalletId;
  final int toWalletId;
}

class CreateWalletAction extends AssistantAction {
  const CreateWalletAction({required this.name, this.initialBalance = 0});

  final String name;
  final int initialBalance;
}

class SetSpendingTargetAction extends AssistantAction {
  const SetSpendingTargetAction({required this.month, required this.amount});

  final String month;
  final int amount;
}

class QueryTotalAction extends AssistantAction {
  const QueryTotalAction({required this.period, this.categoryId});

  final QueryTotalPeriod period;
  final int? categoryId;
}

class AskClarificationAction extends AssistantAction {
  const AskClarificationAction({
    required this.question,
    this.options = const <String>[],
  });

  final String question;
  final List<String> options;
}
