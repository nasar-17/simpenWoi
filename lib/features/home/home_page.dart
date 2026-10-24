import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/parser/parsed_entry.dart';
import '../../core/parser/transaction_parser.dart';
import '../../core/transaction_values.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../wallets/wallet_providers.dart';
import '../transactions/transaction_providers.dart';
import '../transactions/transaction_repository.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<int> _hiddenIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Wallet>> walletsAsync = ref.watch(walletsProvider);
    final AsyncValue<List<TransactionDetail>> todayAsync =
        ref.watch(todayTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('simpenWoi'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          _buildBalanceCard(context, walletsAsync),
          const SizedBox(height: 16),
          _buildSummaryRow(context, todayAsync),
          const SizedBox(height: 24),
          _buildTodaySection(context, todayAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCaptureSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AsyncValue<List<Wallet>> walletsAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Saldo total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            walletsAsync.when(
              loading: () => const SizedBox(
                height: 36,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stack) =>
                  Text('Gagal memuat saldo'),
              data: (List<Wallet> wallets) {
                int total = 0;
                for (final Wallet wallet in wallets) {
                  total += wallet.balance;
                }
                return Text(
                  formatRupiah(total),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    AsyncValue<List<TransactionDetail>> todayAsync,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return todayAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) =>
          const Text('Gagal memuat ringkasan'),
      data: (List<TransactionDetail> transactions) {
        int expense = 0;
        int income = 0;
        for (final TransactionDetail detail in transactions) {
          if (detail.transaction.type == TransactionType.expense) {
            expense += detail.transaction.amount;
          } else {
            income += detail.transaction.amount;
          }
        }
        return Row(
          children: <Widget>[
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Pengeluaran hari ini',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(expense),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Pemasukan hari ini',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(income),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaySection(
    BuildContext context,
    AsyncValue<List<TransactionDetail>> todayAsync,
  ) {
    return todayAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) =>
          const Text('Gagal memuat transaksi'),
      data: (List<TransactionDetail> transactions) {
        final List<TransactionDetail> visible = transactions
            .where((TransactionDetail detail) =>
                !_hiddenIds.contains(detail.transaction.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Transaksi hari ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi hari ini.\nTekan Catat untuk menambah.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              )
            else
              ...visible.map(
                (TransactionDetail detail) =>
                    _buildTransactionTile(context, detail),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    TransactionDetail detail,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isExpense =
        detail.transaction.type == TransactionType.expense;
    final Color amountColor = isExpense ? scheme.error : scheme.primary;

    return Dismissible(
      key: ValueKey<int>(detail.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (DismissDirection direction) =>
          _deleteTransaction(context, detail),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            detail.category?.name ?? 'Tanpa kategori',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  '${detail.wallet.name} \u2022 ${_formatTime(detail.transaction.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (!detail.transaction.isCategorized)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Belum dikategorikan',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          trailing: Text(
            '${isExpense ? '-' : '+'}${formatRupiah(detail.transaction.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
          ),
          onTap: () => _showEditorSheet(context, detail),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showCaptureSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const CaptureSheet(),
    );
  }

  void _showEditorSheet(BuildContext context, TransactionDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => TransactionEditorSheet(
        transaction: detail.transaction,
      ),
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionDetail detail,
  ) async {
    final TransactionRecord record = detail.transaction;
    final TransactionRepository repository =
        ref.read(transactionRepositoryProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _hiddenIds.add(record.id);
    });

    final TransactionRecord? deleted =
        await repository.deleteTransaction(record.id);
    if (deleted == null) {
      if (mounted) {
        setState(() {
          _hiddenIds.remove(record.id);
        });
      }
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            repository.addTransaction(
              amount: record.amount,
              type: record.type,
              walletId: record.walletId,
              categoryId: record.categoryId,
              note: record.note,
              merchant: record.merchant,
              source: record.source,
              createdAt: record.createdAt,
            );
            if (mounted) {
              setState(() {
                _hiddenIds.remove(record.id);
              });
            }
          },
        ),
      ),
    );
  }
}

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  static const TransactionParser _parser = TransactionParser();

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  ParsedEntry _parsed = const ParsedEntry(
    amount: 0,
    type: TransactionType.expense,
  );
  String _type = TransactionType.expense;
  int? _categoryId;
  int? _walletId;

  @override
  void dispose() {
    _inputController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Wallet>> walletsAsync = ref.watch(walletsProvider);
    final AsyncValue<List<Category>> categoriesAsync =
        ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Catat cepat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tulis transaksi',
                hintText: 'Misalnya: bakso 15rb',
              ),
              onChanged: _onInputChanged,
            ),
            if (_parsed.amount > 0) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          CurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nominal (Rp)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: TransactionType.expense,
                            label: Text('Pengeluaran'),
                            icon: Icon(Icons.trending_down),
                          ),
                          ButtonSegment<String>(
                            value: TransactionType.income,
                            label: Text('Pemasukan'),
                            icon: Icon(Icons.trending_up),
                          ),
                        ],
                        selected: <String>{_type},
                        onSelectionChanged: (Set<String> selection) {
                          final String newType = selection.first;
                          setState(() {
                            _type = newType;
                            if (_categoryId != null) {
                              final bool stillValid = categoriesAsync.value
                                      ?.any((Category category) =>
                                          category.id == _categoryId &&
                                          category.type == newType) ??
                                  false;
                              if (!stillValid) {
                                _categoryId = null;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (Object error, StackTrace stack) =>
                            const Text('Gagal memuat kategori'),
                        data: (List<Category> categories) {
                          final List<Category> filtered = categories
                              .where((Category category) =>
                                  category.type == _type)
                              .toList();
                          return DropdownButtonFormField<int?>(
                            initialValue: _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                            ),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Belum dikategorikan'),
                              ),
                              ...filtered.map(
                                (Category category) =>
                                    DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              ),
                            ],
                            onChanged: (int? value) {
                              setState(() {
                                _categoryId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: walletsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (Object error, StackTrace stack) =>
                        const Text('Gagal memuat dompet'),
                    data: (List<Wallet> wallets) {
                      if (wallets.isEmpty) {
                        return const Text('Dompet belum tersedia');
                      }
                      final Wallet selected = _resolveWallet(wallets);
                      return DropdownButtonFormField<int>(
                        initialValue: selected.id,
                        decoration: const InputDecoration(
                          labelText: 'Dompet',
                          isDense: true,
                        ),
                        items: wallets
                            .map(
                              (Wallet wallet) => DropdownMenuItem<int>(
                                value: wallet.id,
                                child: Text(wallet.name),
                              ),
                            )
                            .toList(),
                        onChanged: (int? value) {
                          setState(() {
                            _walletId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _parsed.amount > 0 ? _save : null,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onInputChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _parsed = const ParsedEntry(
          amount: 0,
          type: TransactionType.expense,
        );
        _categoryId = null;
        _amountController.clear();
        _noteController.clear();
      });
      return;
    }

    final ParsedEntry parsed = _parser.parse(value);
    setState(() {
      _parsed = parsed;
      _type = parsed.type;
      if (parsed.amount > 0) {
        _amountController.text = formatRupiah(parsed.amount);
      }
      _noteController.text = parsed.note ?? '';
      _categoryId = parsed.categoryId;
    });
  }

  Wallet _resolveWallet(List<Wallet> wallets) {
    if (_walletId != null) {
      for (final Wallet wallet in wallets) {
        if (wallet.id == _walletId) {
          return wallet;
        }
      }
    }
    for (final Wallet wallet in wallets) {
      if (wallet.isDefault) {
        return wallet;
      }
    }
    return wallets.first;
  }

  Future<void> _save() async {
    final int amount = parseCurrencyInput(_amountController.text);
    final List<Wallet> wallets = ref.read(walletsProvider).value ?? <Wallet>[];
    final Wallet wallet = _resolveWallet(wallets);
    final String note = _noteController.text.trim();

    await ref.read(transactionRepositoryProvider).addTransaction(
          amount: amount,
          type: _type,
          walletId: wallet.id,
          categoryId: _categoryId,
          note: note.isEmpty ? null : note,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, required this.transaction});

  final TransactionRecord transaction;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _merchantController;
  late String _type;
  int? _categoryId;
  late int _walletId;

  @override
  void initState() {
    super.initState();
    final TransactionRecord record = widget.transaction;
    _amountController = TextEditingController(
      text: formatRupiah(record.amount),
    );
    _noteController = TextEditingController(text: record.note ?? '');
    _merchantController = TextEditingController(text: record.merchant ?? '');
    _type = record.type;
    _categoryId = record.categoryId;
    _walletId = record.walletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Wallet>> walletsAsync = ref.watch(walletsProvider);
    final AsyncValue<List<Category>> categoriesAsync =
        ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Edit transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment<String>(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.trending_up),
                ),
              ],
              selected: <String>{_type},
              onSelectionChanged: (Set<String> selection) {
                final String newType = selection.first;
                setState(() {
                  _type = newType;
                  if (_categoryId != null) {
                    final bool stillValid = categoriesAsync.value?.any(
                            (Category category) =>
                                category.id == _categoryId &&
                                category.type == newType) ??
                        false;
                    if (!stillValid) {
                      _categoryId = null;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (Object error, StackTrace stack) =>
                  const Text('Gagal memuat kategori'),
              data: (List<Category> categories) {
                final List<Category> filtered = categories
                    .where((Category category) => category.type == _type)
                    .toList();
                return DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Belum dikategorikan'),
                    ),
                    ...filtered.map(
                      (Category category) => DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (int? value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            walletsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (Object error, StackTrace stack) =>
                  const Text('Gagal memuat dompet'),
              data: (List<Wallet> wallets) {
                return DropdownButtonFormField<int>(
                  initialValue: _walletId,
                  decoration: const InputDecoration(
                    labelText: 'Dompet',
                  ),
                  items: wallets
                      .map(
                        (Wallet wallet) => DropdownMenuItem<int>(
                          value: wallet.id,
                          child: Text(wallet.name),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _walletId = value;
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final int amount = parseCurrencyInput(_amountController.text);
    if (amount <= 0) {
      return;
    }
    final String note = _noteController.text.trim();
    final String merchant = _merchantController.text.trim();

    await ref.read(transactionRepositoryProvider).updateTransaction(
          id: widget.transaction.id,
          amount: amount,
          type: _type,
          walletId: _walletId,
          categoryId: _categoryId,
          note: note.isEmpty ? null : note,
          merchant: merchant.isEmpty ? null : merchant,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
