# Smart Traffic Vision

# 🚦 Smart Traffic Vision

**Smart Traffic Vision** adalah aplikasi monitoring dan analisis lalu lintas cerdas berbasis Flutter. Aplikasi ini dirancang untuk memvisualisasikan data volume kendaraan dari berbagai titik CCTV secara real-time, memberikan rincian statistik (Harian, Mingguan, Bulanan), serta manajemen akun pengguna yang aman.

## 🚀 Fitur Utama

*   **Dashboard Statistik & Analitik**:
    *   Visualisasi grafik batang (Bar Chart) menggunakan `fl_chart`.
    *   Filter periode data: **Harian**, **Mingguan** (rentang tanggal), dan **Bulanan** (Jan-Des).
    *   Mode tampilan **Global** (semua CCTV) atau **Per CCTV**.
*   **Sistem Peringkat**: Menampilkan daftar CCTV dengan volume kendaraan tertinggi berdasarkan periode yang dipilih.
*   **Rincian Data Teks**: Kartu informasi detail yang menampilkan angka pasti dan total akumulasi kendaraan.
*   **Autentikasi Firebase**:
    *   Login menggunakan **Email & Password**.
    *   Login menggunakan **Google Sign-In** (Multiplatform: Android & Web).
*   **Manajemen Profil**:
    *   Update nama dan email pengguna.
    *   Unggah foto profil ke **Firebase Storage**.
*   **Responsive UI**: Tampilan gelap (Dark Mode) yang modern dan nyaman, optimal untuk Web maupun perangkat Mobile.

## 🛠️ Teknologi yang Digunakan

*   **Framework**: [Flutter](https://flutter.dev/) (Channel Stable)
*   **Database**: [Firebase Realtime Database](https://firebase.google.com/docs/database)
*   **Authentication**: Firebase Auth (Email & Google Provider)
*   **Storage**: Firebase Storage (untuk foto profil)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
*   **Icons**: FontAwesome & Material Icons
*   **Launcher Icons**: [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)

## 📦 Struktur Folder Penting

```text
lib/
├── data/       # Sumber data lokal & konfigurasi CCTV
├── models/     # Model data (CCTV, User, dll)
├── screens/    # Halaman UI (Analytics, Login, Profile, dll)
├── services/   # Logika Firebase & Auth (AuthService, TrafficService)
├── widgets/    # Komponen UI yang dapat digunakan kembali
assets/
└── images/     # Logo aplikasi dan aset gambar
