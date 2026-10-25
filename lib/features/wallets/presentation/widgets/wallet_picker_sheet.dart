import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';

class WalletPickerSheet extends StatelessWidget {
  const WalletPickerSheet({super.key, required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text('Pilih dompet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...wallets.map(
            (Wallet wallet) => ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(wallet.name),
              subtitle: Text(formatRupiah(wallet.balance)),
              onTap: () => Navigator.of(context).pop(wallet.id),
            ),
          ),
        ],
      ),
    );
  }
}
