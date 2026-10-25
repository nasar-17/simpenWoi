# Konvensi Kode
## Prinsip
- Refactor bersifat memindahkan/memecah kode; jangan mengubah perilaku yang tidak diminta.
- Perubahan perilaku dan skema database harus disengaja, didokumentasikan, dan memakai migrasi aditif.
- Tidak menambah dependency tanpa kebutuhan yang jelas.
- Perbaikan bug di luar refactor dicatat, bukan dicampur diam-diam.
## Struktur Dart
```
lib/
  app/                  # shell, router, theme, root app
  core/
    constants/          # nilai domain dan teks lintas fitur
    database/           # AppDatabase, migrasi, seed, tables/
    parser/             # parser teks; satu tanggung jawab per file
    utils/              # format mata uang, tanggal, input
    widgets/            # widget kecil lintas fitur
  features/<fitur>/
    data/               # repository, model data, bridge
    domain/             # fungsi/aturan bisnis murni
    presentation/
      pages/            # layar
      providers/        # Riverpod provider
      widgets/          # widget khusus fitur
```
- Nama file `snake_case`; kelas `PascalCase`; widget privat berawalan `_`.
- Satu file maksimal 200 baris fisik. Pecah berdasarkan tanggung jawab.
- Provider di `presentation/providers`; repository di `data`; logika murni di `domain`.
- Jangan membuat barrel file baru kecuali sudah ada pola sejenis.
## Gaya Dart
- Ikuti `analysis_options.yaml`: `prefer_const_constructors`, `prefer_const_declarations`,
  `prefer_final_locals`, `always_declare_return_types`, `avoid_print`,
  `require_trailing_commas`, `directives_ordering`, `unawaited_futures`.
- Tulis tipe eksplisit pada field, parameter, dan variabel lokal yang diminta lint.
- Gunakan `const` untuk widget/nilai yang benar-benar konstan.
- Import `package:` lebih dulu, lalu relatif; urutkan sesuai `directives_ordering`.
- Gunakan `unawaited(...)` hanya untuk future yang sengaja tidak ditunggu.
- Setelah mengubah kode: `dart format .` lalu `flutter analyze`.
## Database
- Nama database, tabel, kolom, dan nilai domain adalah kontrak; jangan diubah saat refactor.
- Migrasi bersifat aditif. Perubahan skema harus menaikkan `schemaVersion`.
- Transfer disimpan sebagai satu baris `type = transfer` dengan `counterpart_wallet_id`; jangan membuat dua baris transaksi.
- Index transaksi: `created_at`, `wallet_id`, `category_id`, `is_categorized`.
- Setelah mengubah tabel: `dart run build_runner build --delete-conflicting-outputs`.
## Kotlin/Android
```
com.drena.simpen_woi/
  MainActivity.kt
  bridge/               # MethodChannel
  capture/
    NotificationCaptureService.kt
    CaptureSimulator.kt
    notify/             # contract, intents, text, notifier, receiver
    parser/             # parser per aplikasi + orchestrator
    prefs/              # SharedPreferences
    queue/              # SQLite queue, model, mapper, executor
```
- Nama paket kelas di manifest harus mengikuti lokasi file.
- Konstanta channel, action, extra, ID notifikasi, dan teks notifikasi disimpan di file kontrak/teks.
- Operasi database/notifikasi tidak di main thread; gunakan `CaptureExecutor`.
- Antrean capture memakai singleton `CaptureQueue.getInstance(context)`.
- Pemasangan dan pembatalan transfer ada di `CaptureTransferStore`; jangan menaruh aturan pasangan di service atau receiver.
- Pertahankan nama paket simulator dan nama tabel/kolom antrean.
