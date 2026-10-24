import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _Section(title: 'Aplikasi', children: <Widget>[
            _InfoTile(
              icon: Icons.info_outline,
              title: 'Tentang simpenWoi',
              subtitle: 'Pengatur keuangan offline \u2022 versi 1.0.0',
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Privasi', children: <Widget>[
            _InfoTile(
              icon: Icons.lock_outline,
              title: 'Data 100% di perangkat',
              subtitle:
                  'Tidak ada data yang dikirim ke server. Semua tersimpan '
                  'lokal di database aplikasi.',
            ),
            _InfoTile(
              icon: Icons.wifi_off,
              title: 'Tanpa koneksi internet',
              subtitle:
                  'Aplikasi berjalan penuh tanpa izin internet, akun, '
                  'maupun layanan pihak ketiga.',
            ),
          ]),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'simpenWoi',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
