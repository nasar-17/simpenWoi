import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import 'settings_info_tile.dart';
import 'settings_section.dart';

class SettingsInfoSections extends StatelessWidget {
  const SettingsInfoSections({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSection(
          title: 'Agar tetap berjalan',
          children: <Widget>[
            SettingsInfoTile(
              icon: Icons.battery_saver_outlined,
              title: 'Matikan optimasi baterai',
              subtitle:
                  'Di Xiaomi/MIUI, Oppo/ColorOS, Vivo/FuntouchOS, dan '
                  'Samsung One UI, izinkan simpenWoi berjalan di latar '
                  'belakang agar notifikasi tidak tertunda.',
            ),
            SettingsInfoTile(
              icon: Icons.phonelink_lock_outlined,
              title: 'Isi notifikasi diproses lokal',
              subtitle:
                  'Nominal dan merchant diambil di perangkat. Tidak '
                  'ada data yang dikirim keluar.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SettingsSection(
          title: 'Aplikasi',
          children: <Widget>[
            SettingsInfoTile(
              icon: Icons.info_outline,
              title: 'Tentang simpenWoi',
              subtitle:
                  'Pengatur keuangan offline \u2022 versi '
                  '${AppConstants.appVersion}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SettingsSection(
          title: 'Privasi',
          children: <Widget>[
            SettingsInfoTile(
              icon: Icons.lock_outline,
              title: 'Data 100% di perangkat',
              subtitle:
                  'Tidak ada data yang dikirim ke server. Semua '
                  'tersimpan lokal di database aplikasi.',
            ),
            SettingsInfoTile(
              icon: Icons.wifi_off,
              title: 'Tanpa koneksi internet',
              subtitle:
                  'Aplikasi berjalan penuh tanpa izin internet, akun, '
                  'maupun layanan pihak ketiga.',
            ),
          ],
        ),
      ],
    );
  }
}
