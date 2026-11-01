# Validasi branch feat/ailocalfull

## Hasil yang benar-benar dijalankan di workspace

- `python3 tools/check_local_assets.py`: lulus. Seluruh XML resource dan manifest
  dapat diurai, lima ikon launcher PNG memiliki ukuran density yang benar, dan
  bunyi notifikasi valid PCM mono 16-bit/24 kHz sepanjang 0,72 detik tanpa clipping.
- `python3 -m py_compile tools/android_startup_smoke.py`: lulus.
- YAML workflow dapat diurai dengan PyYAML.
- Lima ikon launcher lama dipulihkan identik dari branch `feat/ai-assistant`.

Flutter, Dart, Android SDK, ADB, emulator, dan file bobot FunctionGemma tidak
tersedia di workspace. Unduhan dari shell gagal karena proxy tidak dapat
terhubung. Karena itu, analisis Dart, pengujian Flutter, build APK, instalasi
emulator, dan inferensi model **belum dinyatakan lulus** berdasarkan workspace.

## Pipeline yang disiapkan

`.github/workflows/android.yml` berjalan pada push ke `feat/ailocalfull`, pull
request, atau dispatch manual. Pipeline merekam SDK yang dipakai, memvalidasi
asset, menjalankan formatter, analyzer (error/warning fatal; info nonfatal), dan
unit test. Setelah check lulus, pipeline membangun APK release ARM64 untuk uji
perangkat dan APK debug x86_64 untuk tes startup di emulator Android 35.
Screenshot serta log startup diunggah sebagai artifact, termasuk saat tes gagal.

APK release saat ini memakai kunci debug sesuai konfigurasi build repo; artifact
tersebut untuk pengujian dan bukan build penandatanganan Play Store. Model tidak
dimasukkan ke APK dan tidak diunduh pipeline.

Status final pipeline harus dibaca dari run GitHub Actions untuk commit terkait.
Keberadaan workflow atau test dengan model palsu tidak membuktikan inferensi
FunctionGemma berjalan dengan bobot asli pada perangkat.

## Pengujian perangkat dengan model asli

Gunakan perangkat ARM64 yang mendukung runtime LiteRT-LM dan file FunctionGemma
270M `.litertlm` yang kompatibel. Setelah impor, verifikasi status model aktif,
pencatatan teks bebas, kategori, pemasukan, transfer, dan penanganan input
ambigu. Uji notifikasi transaksi nyata, pesan promosi/OTP yang harus dilewati,
dua transaksi sah bernominal sama, antrean saat model tidak siap, dan hasil
setelah aplikasi dibuka kembali. Pastikan koreksi manual tetap dihormati.

Uji suara pada instalasi baru dan pembaruan dari kanal lama yang senyap. Kanal
baru harus bersuara bila izin notifikasi, volume, dan pengaturan kanal Android
mengizinkan; DND/senyap yang dipilih pengguna tetap berlaku. Dengarkan chime di
perangkat untuk menilai kenyamanan; validasi PCM tidak menguji speaker nyata.
