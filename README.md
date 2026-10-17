# StraFit — Flutter starter

Starter modular aplikasi pelacak aktivitas dengan inspirasi UI fitness seperti Strava.
Warna aksen tetap oranye khas StraFit.

## Menjalankan

1. Ekstrak ZIP.
2. Buka folder hasil ekstrak di VS Code.
3. Pastikan Flutter SDK terpasang.
4. Jalankan terminal pada folder yang memiliki `pubspec.yaml`.
5. Jalankan:

   ```bash
   flutter pub get
   flutter analyze
   flutter run -d chrome
   ```

Untuk Windows Desktop, gunakan `flutter run -d windows` jika dukungan desktop Windows sudah diaktifkan.

## Struktur

- `lib/main.dart`: entry point dan tema
- `lib/app/app_state.dart`: state lokal aktivitas dan profil
- `lib/models/activity.dart`: model aktivitas
- `lib/pages/`: Login, Home, Explore, Record, Progress, Profile, navigasi, detail aktivitas
- `lib/widgets/`: kartu statistik, item aktivitas, empty state, heading

## Catatan

- Login/register masih demo lokal; belum memverifikasi akun dan belum tersambung ke API.
- Aktivitas disimpan di memori selama aplikasi berjalan; data akan kembali ke data awal saat aplikasi dimulai ulang.
- Jarak aktivitas diisi manual ketika menekan Selesai. GPS belum diaktifkan.
