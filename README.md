# StraFit — Flutter starter

Starter modular aplikasi pelacak aktivitas dengan inspirasi UI fitness seperti Strava.
Warna aksen tetap oranye khas StraFit.

## Nama Kelompok

- Farid Ulil Yaqin (24051214176)
- Pradnyaparamita Annisa Handoko (24051214200)
- Muhammad Raditnya Arya Putra (24051214206)
- Zakky Zain Alfi Syahri (24051214209)

## Menjalankan

1. Ekstrak ZIP.
2. Buka folder hasil ekstrak di VS Code.
3. Pastikan Flutter SDK terpasang.
4. Jalankan terminal pada folder yang memiliki `pubspec.yaml`.
5. Jalankan:

   ```bash
   flutter pub get
   flutter analyze
   flutter run
   flutter run -d chrome
   ```

Untuk chrome, gunakan `flutter run -d chrome` jika dukungan chrome sudah diaktifkan.
Untuk Windows Desktop, gunakan `flutter run -d windows` jika dukungan desktop Windows sudah diaktifkan.
Untuk emulator, gunakan `flutter run` jika dukungan emulator seperti android studio sudah diaktifkan.

## Struktur

- `lib/main.dart`: entry point dan tema
- `lib/app/app_state.dart`: state lokal aktivitas dan profil
- `lib/models/activity.dart`: model aktivitas
- `lib/pages/`: Login, Home, Explore, Record, Progress, Profile, navigasi, detail aktivitas
- `lib/widgets/`: kartu statistik, item aktivitas, empty state, heading
