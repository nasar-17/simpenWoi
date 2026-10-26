part of 'input_patterns.dart';

ProposedAction _balance(
  String walletText,
  String amountText,
  AssistantContext context,
) {
  final int amount = _amount(amountText);
  if (amount < 0) {
    return _clarify('Saldo tujuan belum jelas.');
  }
  final wallet = context.walletByName(walletText);
  if (wallet == null) {
    return _clarify(
      'Dompet "$walletText" tidak ditemukan.',
      options: context.wallets.map((wallet) => wallet.name).toList(),
    );
  }
  return ProposedAction(
    action: SetWalletBalanceAction(walletId: wallet.id, targetBalance: amount),
    confidence: 0.95,
    source: ActionSource.rules,
    summary: 'Ubah saldo ${wallet.name} menjadi ${formatRupiah(amount)}',
  );
}

ProposedAction _transfer(
  String amountText,
  String fromText,
  String toText,
  AssistantContext context,
) {
  final int amount = _amount(amountText);
  if (amount <= 0) {
    return _clarify('Nominal transfer belum jelas.');
  }
  final from = context.walletByName(fromText);
  final to = context.walletByName(toText);
  if (from == null || to == null) {
    return _clarify(
      'Dompet asal atau tujuan tidak ditemukan.',
      options: context.wallets.map((wallet) => wallet.name).toList(),
    );
  }
  if (from.id == to.id) {
    return _clarify('Dompet asal dan tujuan harus berbeda.');
  }
  return ProposedAction(
    action: TransferAction(
      amount: amount,
      fromWalletId: from.id,
      toWalletId: to.id,
    ),
    confidence: 0.95,
    source: ActionSource.rules,
    summary:
        'Transfer ${formatRupiah(amount)} dari '
        '${from.name} ke ${to.name}',
  );
}

ProposedAction _total(
  String? categoryText,
  String periodText,
  AssistantContext context,
) {
  final QueryTotalPeriod period = switch (periodText) {
    'hari ini' => QueryTotalPeriod.today,
    'minggu ini' => QueryTotalPeriod.week,
    _ => QueryTotalPeriod.month,
  };
  final String? name = categoryText?.trim();
  final category = name == null
      ? null
      : context.categoryByName(name, type: TransactionType.expense);
  if (name != null && category == null) {
    return _clarify(
      'Kategori "$name" tidak ditemukan.',
      options: context.categories
          .where((category) => category.type == TransactionType.expense)
          .map((category) => category.name)
          .take(5)
          .toList(),
    );
  }
  final String categoryLabel = category == null ? '' : ' ${category.name}';
  return ProposedAction(
    action: QueryTotalAction(period: period, categoryId: category?.id),
    confidence: 0.95,
    source: ActionSource.rules,
    summary: 'Hitung total pengeluaran$categoryLabel $periodText',
  );
}

ProposedAction _clarify(
  String question, {
  List<String> options = const <String>[],
}) {
  return ProposedAction(
    action: AskClarificationAction(question: question, options: options),
    confidence: 0,
    source: ActionSource.rules,
    summary: question,
    details: options,
  );
}

int _amount(String text) {
  final AmountMatch? match = const AmountParser().find(text);
  return match?.amount ?? -1;
}

String _monthKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}
