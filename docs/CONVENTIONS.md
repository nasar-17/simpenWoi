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
    assistant/          # action, konteks, validasi, eksekusi asisten
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
## Asisten dan pembelajaran
- `AiProvider` dipanggil `InputEngine` hanya saat aturan lokal tidak yakin.
  `isAvailable` sinkron, `propose` async, dan `null` berarti fallback ke aturan.
- Validasi setiap `AssistantAction` dengan `validateAssistantAction` sebelum
  dieksekusi; jangan mengeksekusi function call mentah dari model.
- Prompt, tools, dan akses `FlutterGemma` hanya di `features/assistant/data`.
  Widget tidak boleh memanggil model secara langsung.
- File model `.litertlm` tidak disimpan di repo; impor lewat Pengaturan > Model AI.
  Model default nonaktif dan tidak boleh menambah izin INTERNET.
- Inisialisasi, impor, hapus, dan unload model hanya lewat
  `FunctionGemmaModelManager`; UI hanya menampilkan status dan aksi pengguna.
- Jangan mencatat isi input atau notifikasi ke log. Inferensi dan data pengguna
  tetap di perangkat.
- Feedback kategori dicatat lewat `LearningRepository.applyFeedback`; UI tidak
  menulis `learning_log` secara langsung.
- Perubahan prompt/tool harus selaras dengan `assets/ai/skill_keuangan.md` dan
  diuji lewat golden set. Jangan mengubah skema database untuk fitur model.

## Database
- Nama database, tabel, kolom, dan nilai domain adalah kontrak; jangan diubah saat refactor.
- Migrasi bersifat aditif. Perubahan skema harus menaikkan `schemaVersion`.
- Transfer disimpan sebagai satu baris `type = transfer` dengan `counterpart_wallet_id`; jangan membuat dua baris transaksi.
- Index transaksi: `created_at`, `wallet_id`, `category_id`, `is_categorized`.
- Setelah mengubah tabel: `dart run build_runner build --delete-conflicting-outputs`.
- Query `customSelect(...).watch()` wajib menyertakan `readsFrom` untuk semua tabel
  yang dibaca; tanpa itu Drift tidak memicu stream saat data berubah.
- Provider data periode memakai `StreamProvider.autoDispose.family` agar query lama
  dilepas saat periode berubah. Jangan membuat stream baru di dalam `build()`.
- Agregat rekap memakai `SUM`/`GROUP BY` di SQL; jangan memuat semua transaksi ke Dart.
## Kotlin/Android
```
com.drena.simpen_woi/
  MainActivity.kt
  bridge/               # MethodChannel + EventChannel
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
- Service dan receiver mengirim event antrean ringan melalui
  `CaptureEventChannel` setelah antrean berubah. Kirim di main looper, jangan
  sertakan isi notifikasi, dan aman bila sink Flutter tidak aktif.
- Flutter mendengarkan `simpenwoi/capture_events` lalu memanggil
  `CaptureSyncService.sync()` yang sama dengan jalur start/resume. Jangan
  menambah jalur impor terpisah; guard `sync()` mencegah impor bersamaan.
- Pertahankan nama paket simulator dan nama tabel/kolom antrean.
