# simpenWoi

Aplikasi pengatur keuangan Android yang cepat, mudah, dan sepenuhnya offline.

## Fitur

- Catat transaksi cepat dari teks bebas (mis. `bakso 15rb`) dengan parser lokal.
- Asisten Input untuk mencatat, menanyakan total, transfer, dan mengelola
  dompet/kategori dari teks bebas.
- Dompet dengan saldo otomatis, kategori pengeluaran/pemasukan.
- Transfer antar dompet tanpa mengubah total pemasukan/pengeluaran.
- Rekap harian, mingguan, dan bulanan dengan grafik.
- Target tabungan beserta setoran dan target pengeluaran bulanan dengan sisa harian.
- Tangkapan otomatis notifikasi e-wallet dan m-banking.
- Kategorisasi langsung dari notifikasi (tombol kategori + balasan teks).
- Deteksi transfer dari pasangan notifikasi keluar/masuk dan opsi **Bukan transfer**.
- Layar "Perlu dilengkapi" untuk transaksi yang belum berkategori.
- Saran kategori yang belajar dari koreksi lokal, debug golden set, dan ekspor JSONL.
- Asisten on-device opsional dengan FunctionGemma 270M; model diimpor manual
  dan nonaktif secara default.
- Navigasi lima tab: Beranda, Rekap, Input, Target, Pengaturan.

## Prinsip offline-first

- Tidak ada backend, API eksternal, analytics, maupun Firebase.
- Tidak ada izin INTERNET.
- Seluruh data transaksi disimpan lokal di perangkat menggunakan SQLite melalui Drift.
- Isi notifikasi dan input asisten diproses di perangkat dan tidak pernah dikirim keluar.
- Model AI opsional juga berjalan sepenuhnya di perangkat; file model tidak
  disertakan dalam aplikasi dan tidak diunduh otomatis.

## Struktur folder

```
lib/
  main.dart
  app/                    # shell, router, dan tema
  core/
    assistant/            # action, konteks, validasi, eksekusi asisten
    constants/            # nilai domain dan teks lintas fitur
    database/             # skema Drift, migrasi, seed, tables/
    parser/               # parser teks dan nominal
    utils/                # format rupiah, tanggal, input nominal
    widgets/              # widget kecil lintas fitur
  features/
    assistant/            # Input asisten, scorer, prompt, model on-device
    capture/              # jembatan notifikasi native + impor + kategori
    categories/           # kategori dan aturan kategori
    home/                 # beranda, input cepat, edit transaksi
    learning/             # feedback, statistik, golden set
    recap/                # rekap harian, mingguan, bulanan
    savings_goals/        # target tabungan dan setoran
    targets/              # target pengeluaran bulanan
    settings/             # pengaturan aplikasi, notifikasi, dan model AI
    transactions/         # repository, model, dan provider transaksi
    wallets/              # dompet dan saldo
assets/
  ai/                     # lexicon dan prompt asisten
docs/
  CONVENTIONS.md          # struktur dan aturan kontribusi
android/
  app/src/main/kotlin/com/drena/simpen_woi/
    MainActivity.kt                 # pemasangan channel capture
    bridge/CaptureChannelHandler.kt # handler MethodChannel native
    bridge/CaptureEventChannel.kt   # EventChannel perubahan antrean
    capture/
      NotificationCaptureService.kt # NotificationListenerService
      CaptureSimulator.kt           # simulasi debug
      notify/                       # contract, intents, text, notifier, receiver
      parser/                       # parser notifikasi per aplikasi
      prefs/                        # kategori, aturan merchant, dedupe
      queue/                        # antrean SQLite + pemasangan transfer
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
tombol kategori teratas dan opsi **Ketik** untuk catatan. Selama aplikasi
terbuka, perubahan antrean (capture baru, hasil pasangan transfer, atau kategori
dari notifikasi) dikirim ke Flutter melalui EventChannel dan langsung
disinkronkan. Saat aplikasi dibuka kembali, impor tetap dijalankan sebagai
cadangan. Aturan merchant dipakai setelah kategori yang sama dipilih minimal dua
kali.

Notifikasi keluar dan masuk dengan nominal sama dari aplikasi berbeda dalam
10 menit dipasangkan menjadi satu transfer. simpenWoi menampilkan notifikasi
`Transfer Rp10.000: DANA → SeaBank tersimpan` dengan aksi **Bukan transfer**
untuk membatalkan pasangan tersebut.

Daftar paket yang dipantau saat ini: GoPay/Gojek, OVO, DANA, ShopeePay,
LinkAja, BCA mobile, Livin' by Mandiri, BRImo, dan SeaBank. Nama paket dapat berubah
antar versi aplikasi; verifikasi di perangkat sebelum mengandalkan fitur ini.

Pada build debug, **Pengaturan > Notifikasi Otomatis** menyediakan tombol
**Kirim notifikasi simulasi** untuk menguji alur tanpa transaksi sungguhan.

Build debug juga memiliki **Pengaturan > Inspektor Notifikasi**. Saat diaktifkan,
inspektor menyimpan maksimal 50 notifikasi terakhir secara lokal beserta hasil
deteksi parser (ditangkap atau alasan dilewati), sehingga notifikasi yang tidak
tertangkap dapat didiagnosis. Isi notifikasi hanya disimpan selama inspektor
aktif dan dapat dihapus dari layar tersebut.

Kategori dan dompet dapat dikelola dari **Pengaturan > Kelola kategori/dompet**.
Kata kunci kategori dipakai parser sebelum kamus bawaan, dan setiap perubahan
kategori langsung dikirim ulang ke layanan capture native. Menghapus kategori
atau dompet yang masih dipakai akan memindahkan transaksi terkait, termasuk
transaksi transfer yang memakai dompet tersebut sebagai asal atau tujuan.

## Asisten dan model AI

Asisten Input memakai aturan dan scorer lokal terlebih dahulu. Jika hasilnya
belum yakin, aplikasi dapat memakai FunctionGemma 270M yang berjalan di perangkat.
Tanpa model, seluruh fitur asisten tetap berfungsi dengan aturan lokal.

Untuk mengaktifkan model:

1. Unduh file model `.litertlm` yang kompatibel secara terpisah.
2. Buka **Pengaturan > Model AI**.
3. Ketuk **Impor model**, pilih file, lalu aktifkan **Asisten on-device**.
4. Gunakan **Debug golden set** untuk membandingkan prediksi aturan dan model.

Model nonaktif secara default, tidak disertakan dalam repo, dan tidak diunduh
otomatis. Model dibongkar dari memori setelah 3 menit tidak dipakai. Jangan
menambahkan izin INTERNET untuk fitur ini.

## Menjalankan

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Tahap 1-8 selesai: setup, MVP transaksi/rekap/target tabungan, tangkapan
notifikasi, navigasi lima tab, transfer antar dompet, target pengeluaran,
asisten dan pembelajaran kategori, serta ekspor dataset. Model on-device
opsional sudah terpasang di kode, tetapi verifikasi runtime di perangkat belum
dilakukan. Budget, OCR struk, dan input suara belum diimplementasikan.
