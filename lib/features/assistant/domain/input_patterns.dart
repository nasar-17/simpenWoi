import '../../../core/assistant/assistant_action.dart';
import '../../../core/assistant/assistant_context.dart';
import '../../../core/assistant/proposed_action.dart';
import '../../../core/constants/transaction_values.dart';
import '../../../core/parser/amount_match.dart';
import '../../../core/parser/amount_parser.dart';
import '../../../core/utils/currency.dart';

part 'input_pattern_handlers.dart';

ProposedAction? matchFixedPattern(
  String input,
  AssistantContext context, {
  DateTime? now,
}) {
  final String text = input
      .toLowerCase()
      .replaceAll(RegExp('\\s+'), ' ')
      .trim();
  final DateTime anchor = now ?? DateTime.now();

  final Match? balance = RegExp(
    r'^saldo\s+(.+?)\s+jadi\s+(.+)$',
  ).firstMatch(text);
  if (balance != null) {
    return _balance(balance[1]!, balance[2]!, context);
  }
  final Match? defaultBalance = RegExp(
    r'^saldo\s+jadi\s+(.+)$',
  ).firstMatch(text);
  if (defaultBalance != null && context.wallets.isNotEmpty) {
    return _balance(context.defaultWallet.name, defaultBalance[1]!, context);
  }

  final Match? transfer = RegExp(
    r'^(?:pindah|transfer)\s+(.+?)\s+dari\s+(.+?)\s+ke\s+(.+)$',
  ).firstMatch(text);
  if (transfer != null) {
    return _transfer(transfer[1]!, transfer[2]!, transfer[3]!, context);
  }

  final Match? target = RegExp(
    r'^target pengeluaran(?:\s+bulan ini)?\s+(.+)$',
  ).firstMatch(text);
  if (target != null) {
    final int amount = _amount(target[1]!);
    if (amount <= 0) {
      return _clarify('Nominal target pengeluaran belum jelas.');
    }
    return ProposedAction(
      action: SetSpendingTargetAction(month: _monthKey(anchor), amount: amount),
      confidence: 0.95,
      source: ActionSource.rules,
      summary: 'Atur target pengeluaran bulan ini ke ${formatRupiah(amount)}',
    );
  }

  final Match? wallet = RegExp(r'^buat dompet\s+(.+)$').firstMatch(text);
  if (wallet != null) {
    final String name = wallet[1]!.trim();
    if (name.isEmpty) {
      return _clarify('Nama dompet baru belum jelas.');
    }
    return ProposedAction(
      action: CreateWalletAction(name: name),
      confidence: 0.9,
      source: ActionSource.rules,
      summary: 'Buat dompet "$name"',
    );
  }

  final Match? category = RegExp(r'^buat kategori\s+(.+)$').firstMatch(text);
  if (category != null) {
    final String name = category[1]!.trim();
    final existing = context.similarCategory(
      name,
      type: TransactionType.expense,
    );
    if (existing != null) {
      return _clarify(
        'Kategori mirip sudah ada: ${existing.name}. Gunakan yang ada?',
        options: <String>[existing.name],
      );
    }
    return ProposedAction(
      action: CreateCategoryAction(name: name, type: TransactionType.expense),
      confidence: 0.85,
      source: ActionSource.rules,
      summary: 'Buat kategori "$name"',
    );
  }

  final Match? total = RegExp(
    r'^total(?:\s+(.+?))?\s+(hari ini|minggu ini|bulan ini)$',
  ).firstMatch(text);
  if (total != null) {
    return _total(total[1], total[2]!, context);
  }
  return null;
}
