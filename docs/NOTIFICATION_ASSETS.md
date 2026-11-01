# Notifikasi dan aset Android

Kanal `capture_ai_v2` menggantikan kanal `capture` yang dibuat senyap pada versi
sebelumnya. Android menyimpan tingkat kepentingan dan suara saat kanal pertama
kali dibuat; mengubah kode kanal lama tidak memperbarui instalasi yang sudah ada.
Kanal baru memakai `IMPORTANCE_HIGH`, getaran pendek, dan `simpenwoi_chime.wav`.
Kode tidak menghapus/membuat ulang kanal setelah pengguna menyesuaikannya dan
tidak meminta akses untuk melewati DND. Suara tetap mengikuti volume notifikasi,
mode senyap/DND, izin notifikasi, dan pengaturan kanal Android.

Suara asli terdiri dari tiga nada pendek C5–G5–C6, berdurasi 0,72 detik. Suara
ini disintesis tanpa sampel pihak ketiga dan tersedia dengan dedikasi CC0.
Jalankan `python3 tool/generate_notification_chime.py` untuk menghasilkan kembali
WAV mono PCM16 24 kHz yang identik. URI memakai nama resource agar stabil ketika
ID resource berubah pada build berikutnya.

Notifikasi antrean mentah dibuat senyap selama menunggu AI. Setelah transaksi
tervalidasi dan commit database selesai, notifikasi tersimpan berbunyi sekali. Pembaruan pada ID yang sama
memakai `setOnlyAlertOnce(true)`; ringkasan grup dibuat senyap agar tidak berbunyi
dua kali. `ic_notification_simpenwoi.xml` adalah mask putih berbentuk dompet,
sesuai format small icon Android, terpisah dari logo launcher berwarna.

## Logo launcher

Pada snapshot sumber yang diperiksa (root branch `main`, `feat/ai-assistant`,
`refactor/clean-code`, dan `fix/realtime-recap`), tidak ada berkas logo di root.
Ikon launcher bawaan dari repo tetap dipertahankan, tanpa mengganti dengan logo
rekaan. Setelah logo tersedia, instal PNG/WebP/JPEG resolusi minimal 432 px:

```sh
python3 tool/install_launcher_logo.py logo.png --background '#F7F5EF'
```

Skrip memerlukan Pillow. Untuk SVG, ekspor PNG transparan terlebih dahulu. Skrip
menghasilkan lima kepadatan ikon legacy dan ikon adaptive Android 8+ dengan
artwork di dalam safe zone 66/108 dp. Berkas sumber logo tidak diubah.

## Pemeriksaan perangkat

1. Impor dan aktifkan model kompatibel, izinkan notifikasi di Android13+,
   lalu kirim dua notifikasi simulasi terpisah.
2. Pastikan masing-masing berbunyi satu kali dan membuka simpenWoi saat diketuk.
3. Pastikan perubahan kategori pada ID yang sama tidak membunyikan ulang suara.
4. Pastikan ringkasan grup tidak menghasilkan bunyi tambahan.
5. Matikan suara kanal di pengaturan Android; pembukaan ulang aplikasi harus
   mempertahankan pilihan tersebut. Ulangi dengan mode DND/senyap.

Pemeriksaan format aset dan konfigurasi statis dapat berjalan tanpa perangkat;
perilaku suara, heads-up, dan DND harus diverifikasi pada perangkat/emulator.
