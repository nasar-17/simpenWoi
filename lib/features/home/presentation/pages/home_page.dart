import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../widgets/balance_card.dart';
import '../widgets/today_summary_row.dart';
import '../widgets/today_transactions_section.dart';
import '../widgets/uncategorized_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
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
    );
  }
}
