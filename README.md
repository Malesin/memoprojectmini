# Memo — Mobile App (Flutter Fullstack Simple & Clean)

Aplikasi catatan mobile **Memo** yang dibangun secara *fullstack* menggunakan Flutter (Dart) dengan desain modern, minimalis, dan palet warna pastel yang lembut. Aplikasi ini dirancang ramah pemula dengan memprioritaskan kesederhanaan (*Keep It Simple*), performa ringan, dan penyimpanan lokal yang aman.

---

## 📱 Fitur Utama

1. **Pencarian Real-Time & Filter Folder:**
   - Pencarian instan berdasarkan judul atau isi memo melalui *search bar* berbentuk pil.
   - Filter cepat berdasarkan kategori (*Semua*, *Kuliah*, *Pribadi*, dll.).
   - Kemampuan membuat folder/kategori baru secara dinamis.

2. **Kartu Memo Pastel & Interaktif:**
   - Tampilan grid 2 kolom dengan 6 variasi warna pastel (Lavender, Peach, Soft Pink, Mint Green, Soft Yellow, Sky Blue).
   - Indikator tanggal pembuatan dan ikon media (foto/mikrofon).
   - *Tap* untuk membuka mode edit, dan *Long-press* untuk memunculkan pop-up konfirmasi hapus memo.

3. **Multimodal Input (Teks, Foto, dan Suara):**
   - **Teks:** Form catatan luas dengan pemilihan folder berbasis *pill dropdown*.
   - **Foto:** Lampirkan foto dari kamera atau galeri dengan thumbnail, tombol hapus foto, serta fitur pratinjau foto layar penuh (*full-screen preview*).
   - **Voice-to-Text:** Rekam suara langsung dan otomatis ubah menjadi teks di dalam catatan menggunakan `speech_to_text` dengan proteksi *anti-crash*.

4. **Expandable Floating Action Button (Speed Dial):**
   - Tombol `+` di pojok kanan bawah yang membuka 3 opsi cepat:
     - 📝 Tulis Catatan Teks
     - 🖼️ Pilih Foto dari Galeri
     - 🎙️ Langsung Rekam Suara (*Auto-start Voice*)

5. **Navigasi Bawah & Quick Capture:**
   - **Tab Home:** Menampilkan daftar seluruh memo.
   - **Tab Camera (Quick Capture):** Langsung membuka kamera perangkat untuk mengambil foto instan dan meneruskannya ke form memo baru.

6. **Local Database & Offline First:**
   - Data memo dan kategori tersimpan secara persisten di `SharedPreferences`.
   - File foto secara otomatis disalin dari direktori sementara ke penyimpanan dokumen aplikasi permanen (`getApplicationDocumentsDirectory()`) agar foto tidak hilang saat cache dibersihkan oleh OS.

---

## 📂 Struktur Proyek (`lib/`)

Proyek ini dibatasi menjadi 5 file inti yang terstruktur rapi:

```text
lib/
├── main.dart               # Inisialisasi aplikasi, setup tema, dan BottomNavigationBar
├── memo_model.dart         # Model data Memo, SharedPreferences helper, palet warna, & dummy seed data
├── home_screen.dart        # Search bar, filter folder, GridView memo, pop-up dialog hapus, & FAB SpeedDial
├── memo_card.dart          # Komponen kartu memo warna pastel dengan indikator media
└── memo_form_screen.dart   # Form input catatan, pill dropdown, thumbnail foto, & tombol rekam suara
```

---

## 🛠️ Dependencies

* `flutter`: SDK
* `shared_preferences: ^2.3.2` — Penyimpanan lokal JSON data catatan & kategori.
* `image_picker: ^1.1.2` — Akses kamera dan galeri foto perangkat.
* `speech_to_text: ^7.0.0` — Transkripsi suara menjadi teks secara langsung.
* `flutter_speed_dial: ^7.0.0` — Tombol aksi melayang dengan animasi expandable.
* `path_provider: ^2.1.4` & `path: ^1.9.0` — Manajemen direktori lokal dan penyimpanan foto permanen.
* `intl: ^0.19.0` — Format tanggal ringkas.

---

## 🚀 Cara Menjalankan

1. **Clone repository:**
   ```bash
   git clone https://github.com/Malesin/memoprojectmini.git
   cd memoprojectmini
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

4. **Jalankan pengujian (Tests):**
   ```bash
   flutter test
   ```
