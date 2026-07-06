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
- 🔔 Sistem notifikasi antar pengguna secara real-time
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
| Supabase | Backend-as-a-Service (Auth, Database, REST API, Realtime) |
| PostgreSQL | Database relasional (dikelola Supabase) |
| Google Fonts | Font Inter untuk seluruh tipografi |
| Postman | Dokumentasi & testing API |

---

## 📁 Struktur Project

```
lib/
├── main.dart                  # Entry point aplikasi & inisialisasi Supabase
├── theme/
│   └── app_theme.dart         # Konfigurasi tema, warna, style global
├── models/
│   └── ticket_model.dart      # Model data tiket & komentar
├── widgets/                   # Komponen reusable (TicketCard, BottomNav, dll)
└── screens/
    ├── admin/                 # Screen khusus role Admin
    ├── helpdesk/               # Screen khusus role Helpdesk
    └── ...                    # Screen umum & role User
```

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
