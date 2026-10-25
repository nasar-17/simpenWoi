import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../providers/wallet_providers.dart';
import '../widgets/wallet_dialogs.dart';
import '../widgets/wallet_form_sheet.dart';
import '../widgets/wallet_picker_sheet.dart';

class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Wallet>> wallets = ref.watch(walletsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tambah dompet',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('Gagal memuat dompet: $error')),
        data: (List<Wallet> data) => _WalletList(wallets: data),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Wallet? wallet}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => WalletFormSheet(wallet: wallet),
    );
  }
}

class _WalletList extends ConsumerWidget {
  const _WalletList({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (wallets.isEmpty) {
      return const Center(child: Text('Belum ada dompet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: wallets.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final Wallet wallet = wallets[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.account_balance_wallet),
            ),
            title: Row(
              children: <Widget>[
                Flexible(child: Text(wallet.name)),
                if (wallet.isDefault) ...<Widget>[
                  const SizedBox(width: 8),
                  const Chip(label: Text('Utama')),
                ],
              ],
            ),
            subtitle: Text(formatRupiah(wallet.balance)),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) {
                if (action == 'edit') {
                  _openForm(context, wallet: wallet);
                } else if (action == 'default') {
                  _setDefault(context, ref, wallet);
                } else if (action == 'delete') {
                  _delete(context, ref, wallet);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Ubah')),
                if (!wallet.isDefault)
                  const PopupMenuItem<String>(
                    value: 'default',
                    child: Text('Jadikan utama'),
                  ),
                if (wallets.length > 1)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, {Wallet? wallet}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => WalletFormSheet(wallet: wallet),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    try {
      await ref.read(walletServiceProvider).setDefault(wallet.id);
    } on Object catch (error) {
      if (context.mounted) {
        showWalletMessage(context, error.toString());
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    try {
      final int usage = await ref
          .read(walletRepositoryProvider)
          .countTransactions(wallet.id);
      if (!context.mounted) {
        return;
      }
      int? moveToId;
      String? targetName;
      if (usage > 0) {
        final List<Wallet> targets = wallets
            .where((Wallet item) => item.id != wallet.id)
            .toList(growable: false);
        if (targets.isEmpty) {
          showWalletMessage(context, 'Tidak ada dompet pengganti.');
          return;
        }
        final int? selected = await showModalBottomSheet<int>(
          context: context,
          useSafeArea: true,
          builder: (BuildContext context) =>
              WalletPickerSheet(wallets: targets),
        );
        if (selected == null || !context.mounted) {
          return;
        }
        moveToId = selected;
        targetName = targets
            .firstWhere((Wallet item) => item.id == selected)
            .name;
      }
      final bool confirmed = await confirmWalletDelete(
        context,
        name: wallet.name,
        usage: usage,
        targetName: targetName,
      );
      if (!confirmed || !context.mounted) {
        return;
      }
      await ref
          .read(walletServiceProvider)
          .delete(wallet.id, moveToId: moveToId);
      if (context.mounted) {
        showWalletMessage(context, 'Dompet dihapus.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        showWalletMessage(context, error.toString());
      }
    }
  }
}
