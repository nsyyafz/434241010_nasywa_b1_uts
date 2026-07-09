# 🎫 E-Ticketing Helpdesk

Aplikasi mobile helpdesk berbasis **Flutter** dan **Supabase** untuk mengelola tiket keluhan/permintaan layanan IT secara real-time, dengan tiga peran pengguna: **User**, **Helpdesk**, dan **Admin**.

Dikembangkan sebagai proyek UAS mata kuliah **Pemrograman Aplikasi Mobile** — Program Studi D4 Teknik Informatika, Fakultas Vokasi, Universitas Airlangga.

---

## ✨ Fitur Utama

- 🔐 Autentikasi berbasis Supabase Auth (Login, Register, Reset Password)
- 🎟️ Manajemen tiket end-to-end: buat, lihat, komentar, hingga selesai
- 👥 Tiga peran pengguna dengan alur kerja berbeda:
  - **User** — membuat tiket, memantau status, berkomunikasi dengan helpdesk
  - **Helpdesk** — menangani tiket yang ditugaskan, update status, balas komentar
  - **Admin** — mengelola seluruh tiket, assign helpdesk, kelola pengguna
- 🔔 Sistem notifikasi antar pengguna (badge unread, tandai dibaca)
- 📊 Dashboard statistik tiket (Open, In Progress, Closed, Rejected)
- 📈 Tracking progres tiket dengan timeline dan persentase penyelesaian
- 🌗 Dark Mode & Light Mode
- 📎 Upload lampiran gambar pada tiket

---

## 🛠️ Tech Stack

| Teknologi | Fungsi |
|---|---|
| Flutter | Framework aplikasi mobile |
| Dart | Bahasa pemrograman |
| Riverpod | State management (caching, dependency injection, auto-rebuild UI) |
| Supabase | Backend-as-a-Service (Auth, Database, REST API) |
| PostgreSQL | Database relasional (dikelola Supabase, diakses via PostgREST) |
| Google Fonts | Font Inter untuk seluruh tipografi |
| Postman | Dokumentasi & testing API |

---

## 📁 Struktur Project

```
lib/
├── main.dart                          # Entry point aplikasi & inisialisasi Supabase
├── splash_screen.dart                 # Splash screen awal
│
├── core/
│   ├── constants/                     # Konstanta global
│   ├── router/                        # (reserved untuk routing, saat ini navigasi manual)
│   ├── theme/
│   │   └── app_theme.dart             # Konfigurasi tema, warna, style global (light/dark)
│   ├── utils/                         # Fungsi bantu umum
│   └── widgets/                       # Komponen reusable (BottomNav, TicketCard, StatGrid, dll)
│
├── data/
│   ├── models/
│   │   └── ticket_model.dart          # Model Ticket & Comment
│   └── repositories/                  # Layer akses data ke Supabase
│       ├── auth_repository.dart
│       ├── comment_repository.dart
│       ├── notification_repository.dart
│       ├── ticket_repository.dart
│       └── user_repository.dart
│
└── presentation/
    ├── providers/                     # State management (Riverpod)
    │   ├── auth_provider.dart
    │   ├── notification_provider.dart
    │   └── ticket_provider.dart
    └── screens/
        ├── admin/                     # Screen khusus role Admin
        ├── auth/                      # Login, Register, Reset Password
        ├── dashboard/                 # Dashboard utama (role-aware)
        ├── notifikasi/                # Daftar notifikasi
        ├── profile/                   # Profil, edit profil, pengaturan
        ├── riwayat/                   # Riwayat tiket
        ├── tiket/                     # Buat, list, detail, tracking tiket
        └── main_screen.dart           # Bottom navigation shell
```

---

## 🏗️ Arsitektur

Aplikasi ini **tidak menggunakan backend server custom** — seluruh backend ditangani oleh Supabase (PostgreSQL + PostgREST + Auth). Alur data mengikuti pola berlapis:

```
UI (Screen)  →  Provider (Riverpod)  →  Repository  →  Supabase Client SDK  →  Supabase (PostgREST + PostgreSQL)
```

- **Screen** hanya menangani tampilan dan interaksi, tidak memanggil Supabase secara langsung.
- **Provider** (Riverpod) meng-cache data, menyediakan state ke berbagai screen tanpa fetch berulang, dan otomatis me-rebuild UI ketika data berubah lewat `ref.watch()` / `ref.invalidate()`.
- **Repository** berisi seluruh logic query (select, insert, update, delete) ke tabel Supabase, dipisah per domain (`ticket_repository.dart`, `auth_repository.dart`, dst).
- **Supabase** menerima request tersebut sebagai REST API (via PostgREST) yang di-generate otomatis dari skema tabel PostgreSQL, dengan keamanan akses data diatur lewat Row Level Security (RLS).

---

## 🚀 Cara Menjalankan

1. Clone repository ini
   ```bash
   git clone https://github.com/nsyyafz/434241010_nasywa_b2_uas.git
   cd 434241010_nasywa_b2_uas
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Sambungkan ke project Supabase kamu sendiri di `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'https://xxxxxxxxxxxx.supabase.co',
     anonKey: 'anon-key-kamu',
   );
   ```

4. Jalankan aplikasi
   ```bash
   flutter run
   ```

---

## 📡 Dokumentasi API

Backend menggunakan Supabase REST API yang dihasilkan otomatis dari skema PostgreSQL.
Dokumentasi lengkap beserta contoh request tersedia di Postman:

🔗 [Postman Collection](https://documenter.getpostman.com/view/55418829/2sBXwpPX7)

---

## 👤 Author

**Nasywa Ashilah Fairuz Zahra**
NIM 434241010 — D4 Teknik Informatika, TI B-2
Fakultas Vokasi, Universitas Airlangga

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan tugas akademik (UAS Pemrograman Aplikasi Mobile) dan tidak dimaksudkan untuk penggunaan produksi.
