# feat/ailocalfull

Perubahan telah didorong ke branch baru, berdasarkan feat/ai-assistant.

- Input teks, notifikasi, saran kategori, dan deteksi transfer memakai
  FunctionGemma lokal; kamus prediksi, parser kalimat, dan Naive Bayes dihapus.
- Satu engine melayani UI dan notifikasi background; antrean SQLite menjadi
  sumber pemulihan. Formulir transaksi eksplisit tetap tersedia tanpa model.
- Lifecycle model diserialkan, impor divalidasi dan dapat dipulihkan jika gagal,
  aktivasi private FileSource diperbaiki saat cold start, dan jumlah/durasi
  inferensi ditampilkan tanpa menyimpan isi input ke log.
- Kanal notifikasi bersuara memakai chime asli simpenWoi dan ikon putih Android.
- Logo sumber tidak ditemukan di root empat branch yang tersedia. Ikon launcher
  asli dipertahankan; alat pemasangan logo adaptive disediakan.

## Bukti pengujian

Commit kode3a07c9d: **54tes lulus, analyzer tanpa isu, APK ARM64 berhasil**.
APK debug juga lulus startup serta pemulihan antrean pada emulator Android35:
notifikasi mentah bertahan setelah force-stop dan tidak membuat transaksi tanpa model.

[Unduh APK](https://github.com/nasar-17/simpenWoi/actions/runs/41362256200/artifacts/13105797516)
— [CI](https://github.com/nasar-17/simpenWoi/actions/runs/41362256200)
— [Laporan lengkap](docs/BUILD_TEST_REPORT.md).

APK pengujian memakai kunci debug runner. File model .litertlm harus diimpor
secara terpisah. Inferensi bobot asli dan suara pada speaker perangkat belum
diverifikasi; hasil emulator tidak mengklaim kualitas kategori model.
