# simpenWoi

Aplikasi pengatur keuangan Android yang cepat, mudah, dan sepenuhnya offline.

## Fitur

- Catat transaksi cepat dari teks bebas (mis. `bakso 15rb`) dengan parser lokal.
- Dompet dengan saldo otomatis, kategori pengeluaran/pemasukan.
- Rekap harian, mingguan, dan bulanan dengan grafik.
- Target tabungan beserta setoran.
- Tangkapan otomatis notifikasi e-wallet dan m-banking.
- Kategorisasi langsung dari notifikasi (tombol kategori + balasan teks).
- Layar "Perlu dilengkapi" untuk transaksi yang belum berkategori.

## Prinsip offline-first

- Tidak ada backend, API eksternal, analytics, maupun Firebase.
- Tidak ada izin INTERNET.
- Seluruh data transaksi disimpan lokal di perangkat menggunakan SQLite melalui Drift.
- Isi notifikasi diproses di perangkat dan tidak pernah dikirim keluar.

## Struktur folder

```
lib/
  main.dart
  app/            # router, shell, dan tema
  core/
    database/     # skema Drift + migrasi
    parser/       # parser teks dan nominal
    utils/        # format rupiah dan input nominal
  features/
    transactions/ # repository dan provider transaksi
    wallets/
    savings_goals/
    recap/
    capture/      # jembatan notifikasi native + impor + layar kategori
    home/
    settings/
android/
  app/src/main/kotlin/com/drena/simpen_woi/
    MainActivity.kt                 # MethodChannel simpenwoi/capture
    NotificationCaptureService.kt   # NotificationListenerService
    CaptureQueue.kt                 # antrean SQLite pending_captures
    CaptureParser.kt                # parser notifikasi per aplikasi
    CaptureNotifier.kt              # notifikasi pertanyaan/kategori
    CaptureActionReceiver.kt        # aksi kategori, balasan, ubah
    CapturePreferences.kt           # kategori, aturan merchant, dedupe
    SupportedApps.kt                # daftar paket yang dipantau
    CaptureSimulator.kt             # simulasi debug
```

## Notifikasi otomatis

1. Buka **Pengaturan > Notifikasi Otomatis**.
2. Ketuk **Aktifkan** pada Akses notifikasi, lalu izinkan simpenWoi di daftar
   akses notifikasi sistem.
3. Ketuk **Izinkan** pada Izin notifikasi (Android 13+).
4. Nonaktifkan optimasi baterai untuk simpenWoi (terutama Xiaomi/MIUI,
   Oppo/ColorOS, Vivo/FuntouchOS, Samsung One UI).

Notifikasi transaksi keluar dari aplikasi yang dipantau akan dicatat ke antrean
lokal. simpenWoi menampilkan notifikasi `Rp25.000 di Warung Bu Tini` dengan
tombol kategori teratas dan opsi **Ketik** untuk catatan. Saat aplikasi dibuka
kembali, antrean diimpor menjadi transaksi. Aturan merchant dipakai setelah
kategori yang sama dipilih minimal dua kali.

Daftar paket yang dipantau saat ini: GoPay/Gojek, OVO, DANA, ShopeePay,
LinkAja, BCA mobile, Livin' by Mandiri, dan BRImo. Nama paket dapat berubah
antar versi aplikasi; verifikasi di perangkat sebelum mengandalkan fitur ini.

Pada build debug, **Pengaturan > Notifikasi Otomatis** menyediakan tombol
**Kirim notifikasi simulasi** untuk menguji alur tanpa transaksi sungguhan.

## Menjalankan

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Tahap 1 (setup), tahap 2 (MVP transaksi, rekap, target tabungan), dan tahap 3
(tangkapan notifikasi + kategorisasi inline) selesai. Budget, OCR struk, dan
input suara belum diimplementasikan.
