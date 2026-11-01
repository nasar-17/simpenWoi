# Branch feat/ailocalfull

Input teks, pemahaman notifikasi, kategori, dan deteksi transfer menggunakan
FunctionGemma lokal. Parser kata, lexicon, Naive Bayes, dan pairing nominal
otomatis dihapus dari jalur aplikasi. Formulir eksplisit tetap tersedia.

Model .litertlm diimpor melalui penyimpanan Android; pemuatan native divalidasi
sebelum diaktifkan. Lifecycle model diserialkan dan dilepas setelah idle3menit.
Engine yang sama melayani notifikasi background dan UI. Antrean lokal tetap
menjadi sumber pemulihan jika Android menghentikan proses.

Kanal baru memakai chime asli simpenWoi dan ikon notifikasi putih. Logo sumber
belum ditemukan di root empat branch yang tersedia; launcher asli dipertahankan.

Validasi CI pada commit88e0b4b:54tes lulus, analyzer tanpa isu. Build APK dan
uji emulator masih dipantau setelah perbaikan aktivasi model saat cold start.
Lihat docs/BUILD_TEST_REPORT.md untuk bukti dan batas pengujian.

Bobot FunctionGemma tidak tersedia dalam repo. Inferensi nyata dan kualitas
kategori dengan bobot asli serta suara pada perangkat belum diklaim teruji.
