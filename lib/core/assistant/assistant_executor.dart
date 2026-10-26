import '../../features/categories/data/category_repository.dart';
import '../../features/targets/data/spending_target_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../../features/wallets/data/wallet_repository.dart';
import '../constants/transaction_values.dart';
import '../database/app_database.dart';
import '../utils/currency.dart';
import 'assistant_action.dart';
import 'assistant_context.dart';
import 'assistant_data_repository.dart';
import 'assistant_execution.dart';
import 'assistant_query_repository.dart';
import 'assistant_validator.dart';

class AssistantExecutor {
  const AssistantExecutor({
    required this.database,
    required this.dataRepository,
    required this.queryRepository,
    required this.transactionRepository,
    required this.walletRepository,
    required this.categoryRepository,
    required this.targetRepository,
  });
  final AppDatabase database;
  final AssistantDataRepository dataRepository;
  final AssistantQueryRepository queryRepository;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;
  final SpendingTargetRepository targetRepository;
  Future<AssistantExecution> execute(AssistantAction action) async {
    final AssistantContext context = await dataRepository.loadContext();
    final String? error = validateAssistantAction(action, context);
    if (error != null) {
      throw AssistantExecutionException(error);
    }
    return switch (action) {
      AddTransactionAction() => _addTransaction(action, context),
      CreateCategoryAction() => _createCategory(action),
      SetWalletBalanceAction() => _setBalance(action, context),
      TransferAction() => _transfer(action, context),
      CreateWalletAction() => _createWallet(action),
      SetSpendingTargetAction() => _setTarget(action),
      QueryTotalAction() => _queryTotal(action, context),
      AskClarificationAction() => AssistantExecution(message: action.question),
    };
  }

  Future<AssistantExecution> _addTransaction(
    AddTransactionAction action,
    AssistantContext context,
  ) async {
    final int id = await database.transaction(
      () => transactionRepository.addTransaction(
        amount: action.amount,
        type: action.type,
        walletId: action.walletId,
        categoryId: action.categoryId,
        note: action.note,
        merchant: action.merchant,
        source: TransactionSource.assistant,
        excludeFromTarget: action.excludeFromTarget,
        createdAt: action.createdAt,
      ),
    );
    final String label = action.type == TransactionType.income
        ? 'Pemasukan'
        : 'Pengeluaran';
    return AssistantExecution(
      message: '$label ${formatRupiah(action.amount)} tersimpan.',
      undo: () => transactionRepository.deleteTransaction(id),
    );
  }

  Future<AssistantExecution> _createCategory(
    CreateCategoryAction action,
  ) async {
    final int id = await database.transaction(
      () => categoryRepository.add(name: action.name, type: action.type),
    );
    return AssistantExecution(
      message: 'Kategori "${action.name.trim()}" dibuat.',
      undo: () => categoryRepository.delete(id: id),
    );
  }

  Future<AssistantExecution> _setBalance(
    SetWalletBalanceAction action,
    AssistantContext context,
  ) async {
    final Wallet wallet = context.walletById(action.walletId)!;
    final int delta = action.targetBalance - wallet.balance;
    if (delta == 0) {
      return AssistantExecution(
        message: 'Saldo ${wallet.name} sudah ${formatRupiah(wallet.balance)}.',
      );
    }
    final int id = await database.transaction(
      () => transactionRepository.addTransaction(
        amount: delta,
        type: TransactionType.adjustment,
        walletId: wallet.id,
        note: 'Penyesuaian saldo',
        source: TransactionSource.assistant,
      ),
    );
    return AssistantExecution(
      message:
          'Saldo ${wallet.name} menjadi '
          '${formatRupiah(action.targetBalance)}.',
      undo: () => transactionRepository.deleteTransaction(id),
    );
  }

  Future<AssistantExecution> _transfer(
    TransferAction action,
    AssistantContext context,
  ) async {
    final Wallet from = context.walletById(action.fromWalletId)!;
    final Wallet to = context.walletById(action.toWalletId)!;
    final int id = await database.transaction(
      () => transactionRepository.addTransaction(
        amount: action.amount,
        type: TransactionType.transfer,
        walletId: from.id,
        counterpartWalletId: to.id,
        source: TransactionSource.assistant,
      ),
    );
    return AssistantExecution(
      message:
          'Transfer ${formatRupiah(action.amount)} dari '
          '${from.name} ke ${to.name} tersimpan.',
      undo: () => transactionRepository.deleteTransaction(id),
    );
  }

  Future<AssistantExecution> _createWallet(CreateWalletAction action) async {
    final int id = await database.transaction(
      () => walletRepository.add(
        name: action.name,
        initialBalance: action.initialBalance,
      ),
    );
    return AssistantExecution(
      message: 'Dompet "${action.name.trim()}" dibuat.',
      undo: () => walletRepository.delete(id),
    );
  }

  Future<AssistantExecution> _setTarget(SetSpendingTargetAction action) async {
    final SpendingTarget? previous = await targetRepository.getTarget(
      action.month,
    );
    await database.transaction(
      () => targetRepository.saveTarget(
        month: action.month,
        limitAmount: action.amount,
      ),
    );
    return AssistantExecution(
      message:
          'Target pengeluaran ${action.month} menjadi '
          '${formatRupiah(action.amount)}.',
      undo: () async {
        if (previous == null) {
          await targetRepository.deleteTarget(action.month);
        } else {
          await targetRepository.saveTarget(
            month: action.month,
            limitAmount: previous.limitAmount,
          );
        }
      },
    );
  }

  Future<AssistantExecution> _queryTotal(
    QueryTotalAction action,
    AssistantContext context,
  ) async {
    final int total = await queryRepository.expenseTotal(
      period: action.period,
      categoryId: action.categoryId,
    );
    final Category? category = context.categoryById(action.categoryId);
    final String label = switch (action.period) {
      QueryTotalPeriod.today => 'hari ini',
      QueryTotalPeriod.week => 'minggu ini',
      QueryTotalPeriod.month => 'bulan ini',
    };
    final String categoryLabel = category == null ? '' : ' ${category.name}';
    return AssistantExecution(
      message:
          'Total pengeluaran$categoryLabel $label: '
          '${formatRupiah(total)}.',
    );
  }
}
