import 'package:flutter/material.dart';

import '../../../assistant/data/function_gemma_model_status.dart';

class ModelAiStatusCard extends StatelessWidget {
  const ModelAiStatusCard({
    super.key,
    required this.status,
    required this.busy,
    required this.installed,
    required this.enabled,
    required this.onImport,
    required this.onDelete,
    required this.onToggle,
  });

  final FunctionGemmaModelStatus? status;
  final bool busy;
  final bool installed;
  final bool enabled;
  final VoidCallback? onImport;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.smart_toy_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'FunctionGemma 270M',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_subtitle()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Inferensi selesai pada sesi aplikasi ini: '
              '${status?.completedInferences ?? 0}',
            ),
            if (status?.lastInferenceDuration != null)
              Text(
                'Durasi proses AI terakhir: '
                '${(status!.lastInferenceDuration!.inMilliseconds / 1000).toStringAsFixed(1)} detik',
              ),
            const Text(
              'Penghitung bertambah setelah model selesai memproses input; '
              'hasilnya tetap perlu diperiksa. Penghitung kembali nol saat '
              'proses aplikasi dimulai ulang.',
            ),
            if (busy) ...<Widget>[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktifkan AI lokal'),
              subtitle: Text(
                enabled
                    ? 'Memahami teks dan kategori dengan model di perangkat.'
                    : 'Pemahaman teks menunggu model aktif. Input formulir tetap tersedia.',
              ),
              value: enabled,
              onChanged: onToggle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(installed ? 'Ganti model' : 'Impor model'),
                ),
                if (installed)
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final FunctionGemmaModelStatus? value = status;
    if (value == null) {
      return 'Memuat...';
    }
    if (value.error != null && value.error!.isNotEmpty) {
      return 'Gagal memuat status model.';
    }
    if (!value.installed) {
      return 'Belum diimpor — pemahaman teks belum tersedia';
    }
    if (!value.enabled) return 'Terpasang, tetapi belum diaktifkan';
    if (value.loaded) {
      return 'Aktif di memori | ${_formatSize(value.sizeBytes)}';
    }
    return 'Siap digunakan | ${_formatSize(value.sizeBytes)}';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) {
      return '0 MB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ModelAiInfoCard extends StatelessWidget {
  const ModelAiInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Berjalan sepenuhnya di perangkat',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'FunctionGemma diperlukan untuk memahami input teks dan '
              'notifikasi. Impor file FunctionGemma 270M .litertlm yang '
              'kompatibel dari penyimpanan. Tidak ada unduhan otomatis.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Data tetap di perangkat. Model dilepas dari memori setelah '
              '3 menit tidak dipakai. Saat model tidak aktif, notifikasi '
              'tetap disimpan untuk diproses setelah model siap.',
            ),
          ],
        ),
      ),
    );
  }
}
