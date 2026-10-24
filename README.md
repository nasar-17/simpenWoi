# simpenWoi

Aplikasi pengatur keuangan Android yang cepat, mudah, dan sepenuhnya offline.

## Prinsip offline-first

- Tidak ada backend, API eksternal, analytics, maupun Firebase.
- Tidak ada izin INTERNET.
- Seluruh data transaksi disimpan lokal di perangkat menggunakan SQLite melalui Drift.

## Struktur folder

```
lib/
  main.dart
  app/            # router dan tema
  core/
    database/     # skema Drift
    parser/       # parser teks dan nominal (placeholder)
    utils/        # utilitas umum (placeholder)
  features/
    transactions/
    wallets/
    savings_goals/
    budget/
    recap/
    capture/      # input teks, notifikasi, struk, suara (nanti)
    settings/
android/
  app/src/main/kotlin/com/drena/simpen_woi/
    NotificationCaptureService.kt   # kerangka NotificationListenerService (TODO)
```

## Menjalankan

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Tahap 1: setup project. Fitur transaksi, dompet, target tabungan, budget, rekap,
dan capture belum diimplementasikan.
