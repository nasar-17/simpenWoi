import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/assistant/assistant_action.dart';
import '../../../core/assistant/assistant_action_codec.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/assistant_validator.dart';
import '../../../core/assistant/proposed_action.dart';
import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency.dart';

class FunctionGemmaActionMapper {
  const FunctionGemmaActionMapper();

  ProposedAction? map(FunctionCallResponse call, AssistantContext context) {
    final Map<String, Object?> json = <String, Object?>{
      ...call.args,
      'type': call.name,
    };
    final AssistantAction? action = actionFromJson(json);
    if (action == null || validateAssistantAction(action, context) != null) {
      return null;
    }
    return _proposal(action, context);
  }

  ProposedAction _proposal(AssistantAction action, AssistantContext context) {
    return switch (action) {
      AddTransactionAction() => _add(action, context),
      CreateCategoryAction() => _createCategory(action),
      SetWalletBalanceAction() => _setBalance(action, context),
      TransferAction() => _transfer(action, context),
      CreateWalletAction() => _createWallet(action),
      SetSpendingTargetAction() => _setTarget(action),
      QueryTotalAction() => _queryTotal(action, context),
      AskClarificationAction() => _clarify(action),
    };
  }

  ProposedAction _add(AddTransactionAction action, AssistantContext context) {
    final Category? category = context.categoryById(action.categoryId);
    final Wallet? wallet = context.walletById(action.walletId);
    final String typeLabel = action.type == TransactionType.income
        ? 'Tambah pemasukan'
        : 'Tambah pengeluaran';
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary:
          '$typeLabel ${formatRupiah(action.amount)} \u2014 '
          '${category?.name ?? 'kategori belum dipilih'}',
      details: <String>[if (wallet != null) wallet.name],
    );
  }

  ProposedAction _createCategory(CreateCategoryAction action) {
    final String typeLabel = action.type == TransactionType.income
        ? 'pemasukan'
        : 'pengeluaran';
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary: 'Buat kategori "${action.name.trim()}" ($typeLabel)',
    );
  }

  ProposedAction _setBalance(
    SetWalletBalanceAction action,
    AssistantContext context,
  ) {
    final Wallet? wallet = context.walletById(action.walletId);
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary:
          'Ubah saldo ${wallet?.name ?? 'dompet'} menjadi '
          '${formatRupiah(action.targetBalance)}',
    );
  }

  ProposedAction _transfer(TransferAction action, AssistantContext context) {
    final Wallet? from = context.walletById(action.fromWalletId);
    final Wallet? to = context.walletById(action.toWalletId);
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary:
          'Transfer ${formatRupiah(action.amount)} dari '
          '${from?.name ?? 'dompet'} ke ${to?.name ?? 'dompet'}',
    );
  }

  ProposedAction _createWallet(CreateWalletAction action) {
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary: 'Buat dompet "${action.name.trim()}"',
    );
  }

  ProposedAction _setTarget(SetSpendingTargetAction action) {
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary:
          'Target pengeluaran ${action.month} '
          '${formatRupiah(action.amount)}',
    );
  }

  ProposedAction _queryTotal(
    QueryTotalAction action,
    AssistantContext context,
  ) {
    final Category? category = context.categoryById(action.categoryId);
    final String period = switch (action.period) {
      QueryTotalPeriod.today => 'hari ini',
      QueryTotalPeriod.week => 'minggu ini',
      QueryTotalPeriod.month => 'bulan ini',
    };
    return ProposedAction(
      action: action,
      confidence: 0.8,
      source: ActionSource.ai,
      summary:
          'Total pengeluaran${category == null ? '' : ' ${category.name}'} '
          '$period',
    );
  }

  ProposedAction _clarify(AskClarificationAction action) {
    return ProposedAction(
      action: action,
      confidence: 0.5,
      source: ActionSource.ai,
      summary: action.question,
      details: action.options,
    );
  }
}
