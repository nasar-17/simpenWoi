import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/transaction_values.dart';
import '../../core/utils/currency.dart';
import '../transactions/transaction_providers.dart';
import '../transactions/transaction_repository.dart';

enum RecapPeriod { daily, weekly, monthly }

class RecapPage extends ConsumerStatefulWidget {
  const RecapPage({super.key});

  @override
  ConsumerState<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends ConsumerState<RecapPage> {
  RecapPeriod _period = RecapPeriod.daily;
  DateTime _anchor = DateTime.now();
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late Stream<List<TransactionDetail>> _stream;

  @override
  void initState() {
    super.initState();
    _refreshRange();
  }

  void _refreshRange() {
    switch (_period) {
      case RecapPeriod.daily:
        _rangeStart = DateTime(_anchor.year, _anchor.month, _anchor.day);
        _rangeEnd = _rangeStart.add(const Duration(days: 1));
      case RecapPeriod.weekly:
        final DateTime monday =
            _anchor.subtract(Duration(days: _anchor.weekday - 1));
        _rangeStart = DateTime(monday.year, monday.month, monday.day);
        _rangeEnd = _rangeStart.add(const Duration(days: 7));
      case RecapPeriod.monthly:
        _rangeStart = DateTime(_anchor.year, _anchor.month, 1);
        _rangeEnd = DateTime(_anchor.year, _anchor.month + 1, 1);
    }
    _stream = ref
        .read(transactionRepositoryProvider)
        .watchBetween(_rangeStart, _rangeEnd);
  }

  void _setPeriod(RecapPeriod period) {
    if (period == _period) {
      return;
    }
    setState(() {
      _period = period;
      _refreshRange();
    });
  }

  void _shift(int direction) {
    setState(() {
      switch (_period) {
        case RecapPeriod.daily:
          _anchor = _anchor.add(Duration(days: direction));
        case RecapPeriod.weekly:
          _anchor = _anchor.add(Duration(days: direction * 7));
        case RecapPeriod.monthly:
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
      }
      _refreshRange();
    });
  }

  String get _rangeLabel {
    switch (_period) {
      case RecapPeriod.daily:
        return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_rangeStart);
      case RecapPeriod.weekly:
        final DateTime lastDay = _rangeEnd.subtract(const Duration(days: 1));
        return '${DateFormat('d MMM', 'id_ID').format(_rangeStart)} - '
            '${DateFormat('d MMM yyyy', 'id_ID').format(lastDay)}';
      case RecapPeriod.monthly:
        return DateFormat('MMMM yyyy', 'id_ID').format(_rangeStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          SegmentedButton<RecapPeriod>(
            segments: const <ButtonSegment<RecapPeriod>>[
              ButtonSegment<RecapPeriod>(
                value: RecapPeriod.daily,
                label: Text('Harian'),
              ),
              ButtonSegment<RecapPeriod>(
                value: RecapPeriod.weekly,
                label: Text('Mingguan'),
              ),
              ButtonSegment<RecapPeriod>(
                value: RecapPeriod.monthly,
                label: Text('Bulanan'),
              ),
            ],
            selected: <RecapPeriod>{_period},
            onSelectionChanged: (Set<RecapPeriod> selection) =>
                _setPeriod(selection.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  _rangeLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TransactionDetail>>(
            stream: _stream,
            builder: (BuildContext context,
                AsyncSnapshot<List<TransactionDetail>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Gagal memuat data rekap'),
                );
              }
              final List<TransactionDetail> transactions =
                  snapshot.data ?? <TransactionDetail>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildSummaryCards(context, transactions),
                  const SizedBox(height: 16),
                  _buildChartSection(context, transactions),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    List<TransactionDetail> transactions,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
                    'Pengeluaran',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(expense),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    'Pemasukan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(income),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
  }

  Widget _buildChartSection(
    BuildContext context,
    List<TransactionDetail> transactions,
  ) {
    final Map<String, int> byCategory = <String, int>{};
    for (final TransactionDetail detail in transactions) {
      if (detail.transaction.type != TransactionType.expense) {
        continue;
      }
      final String key =
          detail.category?.name ?? 'Belum dikategorikan';
      byCategory[key] = (byCategory[key] ?? 0) + detail.transaction.amount;
    }

    if (byCategory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada pengeluaran di periode ini',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final List<MapEntry<String, int>> entries = byCategory.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    final int total =
        entries.fold<int>(0, (int sum, MapEntry<String, int> e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pengeluaran per kategori',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: <PieChartSectionData>[
                        for (int i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: _colorFor(context, i),
                            radius: 64,
                            title: entries[i].value / total >= 0.05
                                ? '${(entries[i].value / total * 100).round()}%'
                                : '',
                            titleStyle: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      Text(
                        formatRupiah(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...entries.asMap().entries.map(
                  (MapEntry<int, MapEntry<String, int>> entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _colorFor(context, entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(entry.value.key),
                        ),
                        Text(
                          formatRupiah(entry.value.value),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context, int index) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> palette = <Color>[
      scheme.error,
      scheme.primary,
      scheme.tertiary,
      const Color(0xFF0F9D58),
      const Color(0xFF7B1FA2),
      const Color(0xFFEF6C00),
      const Color(0xFF00838F),
      const Color(0xFFAD1457),
    ];
    return palette[index % palette.length];
  }
}
