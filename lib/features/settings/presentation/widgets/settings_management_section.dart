import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'learning_settings_section.dart';

class SettingsManagementSection extends StatelessWidget {
  const SettingsManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Kelola kategori'),
            subtitle: const Text('Tambah, ubah, atau hapus kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/categories'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola dompet'),
            subtitle: const Text('Atur dompet dan dompet utama'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/wallets'),
          ),
          const Divider(height: 1),
          const LearningSettingsSection(),
        ],
      ),
    );
  }
}
