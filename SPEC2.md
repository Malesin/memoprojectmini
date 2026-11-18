# SPEC.md — Aplikasi Mobile "Memo" (Flutter Fullstack — Simple & Clean)

## 1. Konteks & Aturan Utama Pengembangan
Bangun aplikasi catatan mobile **Memo** secara *fullstack* menggunakan **Flutter (Dart)** dengan mereplikasi tampilan visual pada gambar prototype (`memo_proto_2.jpeg`).

**Aturan Wajib untuk AI Agent:**
1. **Simple & Beginner-Friendly (KISS):** Proyek ini adalah *mini project* pembelajaran dasar Flutter. **DILARANG** menggunakan *state management* kompleks (seperti BLoC, Riverpod, Provider, GetX) atau *code generation* (`build_runner`). Gunakan **`StatefulWidget` + `setState()`** standar Flutter agar kode mudah dibaca oleh pemula.
2. **Struktur File Ramping:** Batasi kode inti di dalam folder `lib/` menjadi **maksimal 5 file** yang rapi dan terpisah dengan jelas antara logika data dan komponen UI.
3. **Komentar Edukatif:** Berikan komentar singkat berbahasa Indonesia pada bagian-bagian penting (seperti penyimpanan data, *picker* gambar, *voice-to-text*, dan interaksi kartu) agar mudah dipelajari.
4. **Akurasi Visual & Improvisasi Cerdas:** Buat tampilan sehalus dan serapi gambar prototype (`memo_proto_2.jpeg`), serta lengkapi detail teknis yang dibutuhkan (izin perangkat, validasi input kosong, *error handling*, dan notifikasi `SnackBar`) agar aplikasi berjalan mulus tanpa *crash*.

---

## 2. Dependencies (`pubspec.yaml`)
Gunakan *package* berikut yang ringan, stabil, dan tidak memerlukan konfigurasi rumit:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.2   # Penyimpanan lokal JSON (memo & daftar folder)
  image_picker: ^1.1.2         # Ambil foto dari kamera & pilih dari galeri
  speech_to_text: ^7.0.0       # Transkripsi suara langsung menjadi teks
  flutter_speed_dial: ^7.0.0   # Expandable Floating Action Button (+)
  path_provider: ^2.1.4        # Menyimpan salinan foto ke direktori lokal aplikasi
  intl: ^0.19.0                # Format tanggal ringkas (contoh: "15 Nov")
```

---

## 3. Konfigurasi Native Permissions
Pastikan konfigurasi izin perangkat ditambahkan dengan benar agar fitur kamera, galeri, dan mikrofon berfungsi saat di-*build*:

1. **Android (`android/app/src/main/AndroidManifest.xml`):**
   * Tambahkan izin di atas tag `<application>`:
     ```xml
     <uses-permission android:name="android.permission.CAMERA" />
     <uses-permission android:name="android.permission.RECORD_AUDIO" />
     <uses-permission android:name="android.permission.INTERNET" />
     ```
   * Tambahkan tag `<queries>` untuk Android 11+ agar `image_picker` dan `speech_to_text` tidak terblokir:
     ```xml
     <queries>
       <intent>
         <action android:name="android.media.action.IMAGE_CAPTURE" />
       </intent>
       <intent>
         <action android:name="android.speech.RecognitionService" />
       </intent>
     </queries>
     ```
2. **iOS (`ios/Runner/Info.plist`):**
   * Tambahkan `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, dan `NSMicrophoneUsageDescription` beserta `NSSpeechRecognitionUsageDescription`.

---

## 4. Arsitektur Folder (`lib/`)
Gunakan struktur 5 file berikut tanpa sub-folder yang rumit:

```text
lib/
├── main.dart               # Theme setup, inisialisasi app, & BottomNavigationBar (Home & Camera)
├── memo_model.dart         # Model Memo, helper penyimpanan SharedPreferences, & data dummy awal
├── home_screen.dart        # Layar Kiri: Search bar, filter folder, GridView memo, FAB, & Pop-up Hapus
├── memo_card.dart          # Komponen UI kartu memo pastel (judul, preview teks, tanggal, ikon media)
└── memo_form_screen.dart   # Layar Kanan: Form tambah/edit memo, dropdown folder, preview foto, & suara
```

---

## 5. Model Data & Penyimpanan Lokal (`memo_model.dart`)

### A. Atribut Class `Memo`
* `id` (`String`): ID unik berbasis *timestamp* (`DateTime.now().millisecondsSinceEpoch.toString()`).
* `title` (`String`): Judul memo (jika user mengosongkan judul saat menyimpan, otomatis isi dengan `"Tanpa Judul"`).
* `content` (`String`): Isi lengkap catatan teks.
* `folder` (`String`): Nama kategori/folder (default: `"Kuliah"` atau `"Pribadi"`).
* `imagePath` (`String?`): Lokasi path foto permanen di direktori aplikasi (`nullable`).
* `hasVoice` (`bool`): Bernilai `true` jika memo pernah diisi menggunakan fitur rekam suara (untuk memunculkan ikon mikrofon pada kartu).
* `colorIndex` (`int`): Indeks warna pastel kartu (`0` sampai `5`).
* `createdAt` (`DateTime`): Waktu memo dibuat.

### B. Penyimpanan & Data Awal (*Seed Data*)
* Simpan daftar `Memo` dalam bentuk JSON String ke `SharedPreferences` dengan key `'memos_data'`.
* Simpan daftar nama folder dalam bentuk `List<String>` ke `SharedPreferences` dengan key `'folders_data'` (nilai awal: `['Kuliah', 'Pribadi']`).
* **Initial Dummy Data:** Saat aplikasi pertama kali dijalankan dan `'memos_data'` masih `null`, otomatis muat **5 memo contoh** (misalnya: *"Tugas PPW"*, *"Belanja Bulanan"*, *"Ide Aplikasi"*, *"Catatan Rapat"*, *"Jadwal Kuis"*) dengan variasi warna pastel dan status ikon agar tampilan langsung hidup seperti prototype.

---

## 6. Spesifikasi Detail UI & UX (Sesuai Prototype)

### Design System & Palet Warna
* **Background Utama:** Putih bersih (`#FFFFFF`) dengan aksen abu-abu sangat muda (`#F5F6FA`) untuk kolom input/chip tidak aktif.
* **Warna Aktif / Primer:** Biru lembut (`#4A80F0`) untuk chip kategori aktif dan tombol aksi utama.
* **Palet Warna Pastel Kartu (`MemoCard`):**
  * `0`: Lavender / Ungu Muda (`#EAE6FF`)
  * `1`: Peach / Oranye Muda (`#FFE8D6`)
  * `2`: Soft Pink / Merah Muda (`#FCE4EC`)
  * `3`: Mint Green / Hijau Muda (`#E0F2F1`)
  * `4`: Soft Yellow / Kuning Muda (`#FFF9C4`)
  * `5`: Sky Blue / Biru Muda (`#E1F5FE`)

### Layar 1: Navigasi Bawah & `HomeScreen` (Layar Kiri Prototype)
1. **Bottom Navigation Bar (`main.dart`):**
   * Hanya memiliki **2 tab** sesuai prototype:
     * **Tab 0 (`Home`):** Menampilkan `HomeScreen`.
     * **Tab 1 (`Camera` — *Quick Capture*):** Saat ditekan, tidak berpindah tab kosong, melainkan langsung membuka kamera (`ImagePicker().pickImage(source: ImageSource.camera)`). Jika foto berhasil diambil, simpan salinannya ke direktori lokal lalu langsung buka `MemoFormScreen` dengan foto tersebut sudah terpasang.
2. **Search Bar:**
   * Kolom pencarian berbentuk pil (`BorderRadius.circular(24)`) di bagian paling atas dengan ikon kaca pembesar dan *hint* `"Cari memo..."`. Memfilter memo secara *real-time* berdasarkan judul atau isi.
3. **Filter Kategori / Folder:**
   * Deretan horizontal `ChoiceChip` di bawah *search bar*:
     * Chip **`Semua`** (aktif secara default dengan warna biru `#4A80F0` & teks putih).
     * Chip folder dari database (`Kuliah`, `Pribadi`, dll.).
     * Tombol chip **`+`** di ujung kanan untuk menambah nama folder baru melalui `AlertDialog` sederhana.
4. **Grid Kartu Memo (`GridView.builder` 2 Kolom):**
   * Gunakan `crossAxisCount: 2`, `crossAxisSpacing: 12`, `mainAxisSpacing: 12`, dan `childAspectRatio: 0.95`.
   * **Desain `MemoCard`:**
     * Sudut membulat `BorderRadius.circular(16)` dengan padding `14`.
     * **Judul:** Teks tebal (*bold*, `fontSize: 15`, `maxLines: 1`, `overflow: TextOverflow.ellipsis`).
     * **Cuplikan Isi:** Teks isi (`fontSize: 13`, warna abu-abu gelap `#4A4A4A`, `maxLines: 2`, `overflow: TextOverflow.ellipsis`).
     * **Footer Kartu (Bawah):** `Row` dengan tanggal di kiri (`DateFormat('dd MMM').format(memo.createdAt)`, misal `"15 Nov"`, `fontSize: 11`) dan ikon indikator kecil (`size: 14`) di kanan (ikon kamera/gambar jika `imagePath != null`, dan ikon mikrofon jika `hasVoice == true`).
   * **Interaksi Kartu:**
     * **Tap (Klik Sekali):** Buka `MemoFormScreen` membawa objek `memo` tersebut untuk mode baca & edit.
     * **Long-Press (Tahan):** Munculkan pop-up `AlertDialog` persis seperti di prototype dengan judul **`"Hapus Memo?"`** dan 2 tombol teks di kanan bawah: **`"Batal"`** dan **`"Hapus"`** (warna merah). Jika dihapus, hapus juga file foto lokalnya (jika ada) dan tampilkan `SnackBar("Memo dihapus")`.
5. **Expandable Floating Action Button (`SpeedDial`):**
   * Tombol bulat di pojok kanan bawah (`backgroundColor: Color(0xFF455A64)`) dengan ikon `+` putih.
   * Saat ditekan, memunculkan 3 tombol bulat kecil berwarna putih ke atas sesuai prototype:
     1. **Ikon Huruf `A` / Teks:** Buka `MemoFormScreen` kosong.
     2. **Ikon Galeri:** Buka galeri (`ImageSource.gallery`), lalu teruskan gambar ke `MemoFormScreen`.
     3. **Ikon Mikrofon:** Buka `MemoFormScreen` dengan parameter `autoStartVoice: true` agar langsung merekam suara.

### Layar 2: Form & Detail Memo (`MemoFormScreen` — Layar Kanan Prototype)
1. **Top AppBar:**
   * Tombol kembali (`Icons.arrow_back_ios_new`) di kiri.
   * Judul halaman: `"Tambah Memo"` (mode baru) atau `"Edit Memo"` (mode edit).
   * Tombol teks **`Simpan`** (warna biru `#4A80F0`, tebal) di kanan atas.
2. **Area Input:**
   * **Judul:** `TextField` tanpa border kotak, hanya garis bawah tipis (`UnderlineInputBorder`), *hint* `"Judul Memo"`, ukuran font besar (`18`, *semi-bold*).
   * **Dropdown Folder:** Tombol dropdown berbentuk pil abu-abu terang (`#F0F2F5`, `BorderRadius.circular(20)`) di bawah judul (contoh: `Kuliah ▾`) untuk memilih atau memindahkan folder memo.
   * **Isi Catatan:** `TextField` multi-baris (`maxLines: null`, `expands: true`) yang luas dengan *hint* `"Tulis catatanmu di sini..."`.
3. **Preview Foto Lampiran:**
   * Jika `imagePath != null`, tampilkan kotak *thumbnail* foto persegi (`width: 90, height: 90`) dengan `BorderRadius.circular(12)` di bagian bawah area teks.
   * Tambahkan tombol lingkaran kecil ikon `X` di pojok kanan atas *thumbnail* untuk menghapus lampiran foto, serta fitur *tap* pada foto untuk melihatnya dalam ukuran penuh (*full-screen dialog*).
4. **2 Tombol Aksi di Bagian Bawah (`SafeArea`):**
   * Dua tombol persegi panjang sejajar (`Expanded` dengan jarak `12`):
     * **Tombol Kiri (`Tambah Foto`):** Berisi ikon kamera + teks `"Tambah Foto"`. Saat ditekan, tampilkan `showModalBottomSheet` sederhana dengan 2 pilihan: *"Ambil dari Kamera"* dan *"Pilih dari Galeri"*.
     * **Tombol Kanan (`Rekam Suara`):** Berisi ikon mikrofon + teks `"Rekam Suara"` (berubah menjadi `"Mendengarkan..."` dengan warna aksen merah lembut saat mikrofon aktif). Hasil transkripsi suara langsung ditambahkan (*append*) ke dalam kolom teks isi memo dan mengubah `hasVoice = true`.

---

## 7. Improvisasi Teknis Wajib (Anti-Bug)
* **Salin File Gambar Permanen:** Setiap kali gambar diambil dari `image_picker` (baik kamera maupun galeri), salin file dari direktori *cache* sementara ke `getApplicationDocumentsDirectory()` agar gambar tidak hilang saat aplikasi ditutup/di-restart.
* **Fallback Mikrofon Emulator:** Jika perangkat/emulator tidak mendukung `speech_to_text` atau izin mikrofon ditolak, tangkap *error*-nya dengan aman (*try-catch*) dan tampilkan `SnackBar("Fitur suara tidak tersedia di perangkat ini")` tanpa membuat aplikasi *crash*.
* **Validasi Simpan:** Jika user menekan tombol `Simpan` saat judul dan isi sama-sama kosong serta tidak ada foto, tampilkan `SnackBar("Catatan tidak boleh kosong")` dan batalkan penyimpanan.
