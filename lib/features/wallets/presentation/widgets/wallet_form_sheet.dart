import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../providers/wallet_providers.dart';

class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.wallet});

  final Wallet? wallet;

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  bool _saving = false;

  bool get _isEdit => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name);
    _balanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Nama dompet wajib diisi.');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final Wallet? wallet = widget.wallet;
      if (wallet == null) {
        await ref
            .read(walletServiceProvider)
            .add(
              name: name,
              initialBalance: parseCurrencyInput(_balanceController.text),
            );
      } else {
        await ref.read(walletServiceProvider).update(id: wallet.id, name: name);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        _showMessage(error.toString());
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Wallet? wallet = widget.wallet;
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
              _isEdit ? 'Ubah dompet' : 'Tambah dompet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama dompet'),
            ),
            const SizedBox(height: 12),
            if (_isEdit)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Saldo saat ini'),
                trailing: Text(formatRupiah(wallet?.balance ?? 0)),
              )
            else
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: const <TextInputFormatter>[
                  CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(labelText: 'Saldo awal (Rp)'),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text(UiText.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text(UiText.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
