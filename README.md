# simpenWoi

Aplikasi pengatur keuangan Android yang cepat, mudah, dan sepenuhnya offline.

## Fitur

- Catat transaksi dari teks bebas (mis. `bakso 15rb`) melalui FunctionGemma lokal.
- Input formulir untuk mengisi nominal, jenis, dompet, dan kategori secara langsung.
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
- Saran kategori melalui model lokal, contoh koreksi pengguna, uji inferensi, dan ekspor JSONL.
- FunctionGemma 270M sebagai jalur pemahaman teks dan notifikasi; model diimpor
  dari penyimpanan lalu diaktifkan otomatis setelah impor berhasil.
- Navigasi lima tab: Beranda, Rekap, Input, Target, Pengaturan.

## Prinsip offline-first

- Tidak ada backend, API eksternal, analytics, maupun Firebase.
- Tidak ada izin INTERNET.
- Seluruh data transaksi disimpan lokal di perangkat menggunakan SQLite melalui Drift.
- Isi notifikasi dan input asisten diproses di perangkat dan tidak pernah dikirim keluar.
- Model AI berjalan sepenuhnya di perangkat; file model tidak
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
    utils/                # format rupiah, tanggal, input nominal
    widgets/              # widget kecil lintas fitur
  features/
    assistant/            # input asisten, inferensi, prompt, model on-device
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
  ai/                     # instruksi model lokal
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
      parser/                       # daftar aplikasi yang dipantau dan model data
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

Isi notifikasi dari aplikasi yang dipantau disimpan ke antrean SQLite lokal.
FunctionGemma memahami nominal, arah transaksi, merchant, dan kategorinya dari
isi notifikasi. Tidak ada kamus kata atau aturan merchant sebagai pengganti
inferensi model. Notifikasi yang belum dapat dipahami tetap menunggu pemrosesan.

Layanan notifikasi dapat memulai engine Flutter yang sama tanpa membuka layar.
Engine itu juga dipakai saat aplikasi dibuka: hanya ada satu pemilik database,
sinkronisasi, dan model. Android tetap dapat menunda atau menghentikan proses
karena force-stop, Doze, atau kebijakan baterai vendor; antrean lokal menjadi
sumber pemulihan setelah proses aktif lagi.

Dua notifikasi dari dompet berbeda dapat dipahami bersama oleh model sebagai
transfer internal. Nominal/waktu saja tidak cukup untuk memasangkan transaksi:
model harus mengembalikan transfer yang valid untuk kedua dompet tersebut.
Pemeriksaan pasangan dibatasi untuk menjaga beban inferensi. Pasangan yang
belum jelas tetap dapat dikoreksi secara manual, termasuk aksi **Bukan transfer**.
Buat dompet bernama sesuai bank/e-wallet (misalnya DANA dan SeaBank) sebelum
capture diandalkan; dompet sumber yang tidak tersedia tidak diganti dengan Tunai.

Daftar paket yang dipantau saat ini: GoPay/Gojek, OVO, DANA, ShopeePay,
LinkAja, BCA mobile, Livin' by Mandiri, BRImo, dan SeaBank. Nama paket dapat berubah
antar versi aplikasi; verifikasi di perangkat sebelum mengandalkan fitur ini.

Pada build debug, **Pengaturan > Notifikasi Otomatis** menyediakan tombol
**Kirim notifikasi simulasi** untuk menguji alur tanpa transaksi sungguhan.

Build debug juga memiliki **Pengaturan > Inspektor Notifikasi**. Saat diaktifkan,
inspektor menyimpan maksimal 50 notifikasi terakhir secara lokal beserta hasil
status antrean, sehingga notifikasi yang tidak
tertangkap dapat didiagnosis. Isi notifikasi hanya disimpan selama inspektor
aktif dan dapat dihapus dari layar tersebut.

Kategori dan dompet dapat dikelola dari **Pengaturan > Kelola kategori/dompet**.
Nama dan jenis kategori menjadi konteks model; tidak perlu mengisi kata kunci.
Menghapus kategori
atau dompet yang masih dipakai akan memindahkan transaksi terkait, termasuk
transaksi transfer yang memakai dompet tersebut sebagai asal atau tujuan.

## Asisten dan model AI

FunctionGemma 270M dipanggil untuk memahami input teks dan saran kategori.
Tidak ada fallback ke parser kata kunci atau klasifikasi Naive Bayes. Jika model
belum diimpor, dinonaktifkan, gagal, atau hasilnya belum jelas, aplikasi meminta
pengguna memeriksa model atau melengkapi informasi. **Input > Input formulir**
tetap dapat dipakai untuk pencatatan eksplisit tanpa inferensi.

Untuk menyiapkan model:

1. Baca [dokumentasi FunctionGemma Google](https://ai.google.dev/gemma/docs/functiongemma)
   dan [model card resminya](https://huggingface.co/google/functiongemma-270m-it).
   Ikuti persyaratan akses dan lisensi model yang berlaku.
2. Dapatkan artefak **FunctionGemma 270M `.litertlm` yang kompatibel dengan
   LiteRT-LM**. Mengganti ekstensi file GGUF, TFLite, atau model lain tidak
   menghasilkan model yang kompatibel. Repo ini tidak membundel atau mengunduh model.
3. Buka **Pengaturan > Model AI > Impor model**. Setelah berhasil, model aktif.
4. Buka **Uji AI lokal** untuk menjalankan inferensi atas sepuluh contoh input.
   Halaman ini hanya menampilkan usulan dan waktu proses; tidak menyimpan transaksi
   dan tidak mengklaim persentase akurasi dari hasil yang belum dinilai.
5. Coba input Anda sendiri, periksa nominal, jenis, dompet, dan kategori sebelum
   menyimpan. Koreksi yang diterima dapat dipakai sebagai contoh dalam konteks model.

Kinerja dan dukungan model bergantung perangkat, memori, dan artefak model.
Model dilepas dari memori setelah 3 menit tidak dipakai. Operasi model diserialkan
agar dua input tidak memakai sesi inferensi yang sama bersamaan. Tidak perlu
menambahkan izin INTERNET untuk fitur ini.

## Menjalankan

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Validasi

```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Uji inferensi nyata memerlukan perangkat Android dan file model kompatibel.
Build APK, kualitas pemahaman notifikasi, suara, izin Android, dan ketahanan
background tetap perlu diverifikasi pada perangkat; halaman uji model bukan
pengganti pengujian APK. Budget, OCR struk, dan input suara belum diimplementasikan.
