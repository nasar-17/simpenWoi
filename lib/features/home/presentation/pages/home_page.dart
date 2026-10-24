import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_text.dart';
import '../widgets/balance_card.dart';
import '../widgets/capture_sheet.dart';
import '../widgets/today_summary_row.dart';
import '../widgets/today_transactions_section.dart';
import '../widgets/uncategorized_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: UiText.settings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          const BalanceCard(),
          const UncategorizedBanner(),
          const SizedBox(height: 16),
          const TodaySummaryRow(),
          const SizedBox(height: 24),
          const TodayTransactionsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCaptureSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
    );
  }

  void _showCaptureSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const CaptureSheet(),
    );
  }
}
