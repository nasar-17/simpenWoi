import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../capture/native_capture_bridge.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  bool? _listenerEnabled;
  bool _requestingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshListener();
    }
  }

  Future<void> _refreshListener() async {
    try {
      final bool enabled =
          await ref.read(nativeCaptureBridgeProvider).isListenerEnabled();
      if (mounted) {
        setState(() {
          _listenerEnabled = enabled;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listenerEnabled = false;
        });
      }
    }
  }

  Future<void> _openListenerSettings() async {
    try {
      await ref.read(nativeCaptureBridgeProvider).openListenerSettings();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka pengaturan akses notifikasi.'),
          ),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _requestingNotification = true;
    });
    try {
      final PermissionStatus status = await Permission.notification.request();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? 'Izin notifikasi diberikan.'
                : 'Izin notifikasi belum diberikan. Aktifkan dari pengaturan '
                    'aplikasi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingNotification = false;
        });
      }
    }
  }

  Future<void> _simulateCapture() async {
    try {
      await ref.read(nativeCaptureBridgeProvider).simulateCapture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifikasi simulasi dikirim. Ketuk kategori atau ketik '
              'catatan, lalu buka kembali aplikasi untuk impor.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Simulasi hanya tersedia di build debug pada perangkat Android.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool? listenerEnabled = _listenerEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _Section(
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
                      : listenerEnabled
                          ? 'Aktif. simpenWoi dapat membaca notifikasi '
                              'e-wallet.'
                          : 'Belum aktif. Aktifkan agar transaksi tercatat '
                              'otomatis.',
                ),
                trailing: FilledButton.tonal(
                  onPressed: _openListenerSettings,
                  child: Text(listenerEnabled == true ? 'Kelola' : 'Aktifkan'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Izin notifikasi'),
                subtitle: const Text(
                  'Diperlukan agar simpenWoi dapat menampilkan pertanyaan '
                  'kategori.',
                ),
                trailing: _requestingNotification
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _requestNotificationPermission,
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
                  onTap: _simulateCapture,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Agar tetap berjalan',
            children: const <Widget>[
              _InfoTile(
                icon: Icons.battery_saver_outlined,
                title: 'Matikan optimasi baterai',
                subtitle: 'Di Xiaomi/MIUI, Oppo/ColorOS, Vivo/FuntouchOS, dan '
                    'Samsung One UI, izinkan simpenWoi berjalan di latar '
                    'belakang agar notifikasi tidak tertunda.',
              ),
              _InfoTile(
                icon: Icons.phonelink_lock_outlined,
                title: 'Isi notifikasi diproses lokal',
                subtitle: 'Nominal dan merchant diambil di perangkat. Tidak '
                    'ada data yang dikirim keluar.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Aplikasi',
            children: <Widget>[
              _InfoTile(
                icon: Icons.info_outline,
                title: 'Tentang simpenWoi',
                subtitle: 'Pengatur keuangan offline \u2022 versi 1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Privasi',
            children: <Widget>[
              _InfoTile(
                icon: Icons.lock_outline,
                title: 'Data 100% di perangkat',
                subtitle: 'Tidak ada data yang dikirim ke server. Semua '
                    'tersimpan lokal di database aplikasi.',
              ),
              _InfoTile(
                icon: Icons.wifi_off,
                title: 'Tanpa koneksi internet',
                subtitle: 'Aplikasi berjalan penuh tanpa izin internet, akun, '
                    'maupun layanan pihak ketiga.',
              ),
            ],
          ),
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
