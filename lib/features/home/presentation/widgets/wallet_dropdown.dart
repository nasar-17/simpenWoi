import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../wallets/domain/wallet_resolver.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';

class WalletDropdown extends ConsumerWidget {
  const WalletDropdown({
    super.key,
    required this.preferredId,
    required this.onChanged,
    this.isDense = false,
  });

  final int? preferredId;
  final ValueChanged<int> onChanged;
  final bool isDense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Wallet>> walletsAsync = ref.watch(walletsProvider);

    return walletsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (Object error, StackTrace stack) =>
          const Text(UiText.loadWalletsFailed),
      data: (List<Wallet> wallets) {
        if (wallets.isEmpty) {
          return const Text('Dompet belum tersedia');
        }
        final Wallet selected = resolveWallet(
          wallets,
          preferredId: preferredId,
        );
        return DropdownButtonFormField<int>(
          initialValue: selected.id,
          decoration: InputDecoration(labelText: 'Dompet', isDense: isDense),
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
              onChanged(value);
            }
          },
        );
      },
    );
  }
}
