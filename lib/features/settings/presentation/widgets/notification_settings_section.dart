import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'settings_section.dart';

class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({
    super.key,
    required this.listenerEnabled,
    required this.requestingNotification,
    required this.onOpenListenerSettings,
    required this.onRequestNotificationPermission,
    required this.onSimulateCapture,
  });

  final bool? listenerEnabled;
  final bool requestingNotification;
  final VoidCallback onOpenListenerSettings;
  final VoidCallback onRequestNotificationPermission;
  final VoidCallback onSimulateCapture;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      title: 'Notifikasi Otomatis',
      children: <Widget>[
        ListTile(
          leading: Icon(
            listenerEnabled == true
                ? Icons.check_circle
                : Icons.notifications_off_outlined,
            color: listenerEnabled == true ? scheme.primary : scheme.error,
          ),
          title: const Text('Akses notifikasi'),
          subtitle: Text(
            listenerEnabled == null
                ? 'Memeriksa status...'
                : listenerEnabled!
                ? 'Aktif. simpenWoi dapat membaca notifikasi e-wallet.'
                : 'Belum aktif. Aktifkan agar transaksi tercatat '
                      'otomatis.',
          ),
          trailing: FilledButton.tonal(
            onPressed: onOpenListenerSettings,
            child: Text(listenerEnabled == true ? 'Kelola' : 'Aktifkan'),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Izin notifikasi'),
          subtitle: const Text(
            'Diperlukan agar simpenWoi dapat menampilkan pertanyaan kategori.',
          ),
          trailing: requestingNotification
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: onRequestNotificationPermission,
                  child: const Text('Izinkan'),
                ),
        ),
        if (kDebugMode) ...<Widget>[
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Kirim notifikasi simulasi'),
            subtitle: const Text(
              'Uji alur tanpa transaksi sungguhan (khusus debug).',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onSimulateCapture,
          ),
        ],
      ],
    );
  }
}
