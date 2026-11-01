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

## Cold-start model identity repair

The pinned FlutterGemma 1.11.3 SDK automatically activates a file model when
`installModel(...).fromFile(path).install()` completes. Its mobile model manager
persists this identity, but its cold-start restore reads the SDK Documents
location rather than the external FileSource path. simpenWoi owns its model in
ApplicationSupport/ai_models, so an installed file could otherwise appear ready
while `getActiveModel()` fails after restarting the process.

`FunctionGemmaModelManager._loadModel()` now idempotently re-registers the owned
file before each native load. SDK registration activates the correct FileSource
and uses its existing installation metadata; it does not copy or download model
weights. The app keeps inference, import and unload on the same serialized queue.

This fix was checked against exact upstream source at release commit
`56be5a04dd906a4f4363b80aa5137abe243e8a0b`:

- `packages/flutter_gemma/lib/core/api/inference_installation_builder.dart`:
  `.install()` calls `manager.setActiveModel(spec)` even for an installed file.
- `packages/flutter_gemma/lib/core/model_management/managers/mobile_model_manager.dart`:
  `_restoreActiveInferenceModel()` calls `fileSystemService.getTargetPath(filename)`.
- `packages/flutter_gemma/lib/core/infrastructure/platform_file_system_service.dart`:
  Android `getTargetPath()` resolves the Documents directory.
- `packages/flutter_gemma/lib/core/handlers/file_source_handler.dart`:
  FileSource installation registers the existing file and external path without copying.

A real cold-start inference still requires importing compatible FunctionGemma
weights on an Android device; static source verification and mocked routing tests
do not establish model accuracy or prove that hardware run.
