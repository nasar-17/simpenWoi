import 'package:flutter/material.dart';

Future<bool> confirmWalletDelete(
  BuildContext context, {
  required String name,
  required int usage,
  String? targetName,
}) async {
  final String message = usage > 0
      ? '$usage transaksi akan dipindahkan ke ${targetName ?? 'dompet lain'}.'
      : 'Dompet ini tidak dipakai transaksi.';
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text('Hapus $name?'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showWalletMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
