# Spesifikasi API v1: Flutter (Pengembang, Pengawas) ↔ Laravel

Status: **USULAN**, turunan dari `KONTRAK_INTEGRASI.md` (nilai role, tahap, status, slot, penomoran ikut dokumen itu).
Belum ada kode. Hal yang butuh keputusan Disperwaskim ditandai **[KEPUTUSAN]**.

Admin memakai Web Admin (sesi Laravel, route `web.php`), bukan API ini. Aksi Admin (verifikasi berkas, jadwal survei,
persetujuan) harus memanggil **service yang sama** dengan yang dipakai API supaya aturan transisi hanya ada satu.

## 1. Aturan umum

| Hal | Aturan |
|---|---|
| Basis | `https://<host>/api/v1`, JSON UTF-8; unggahan `multipart/form-data` |
| Autentikasi | Token bearer (Laravel Sanctum). **Paket belum ada di `composer.json`**, harus ditambah |
| Zona waktu | Server menyimpan UTC, mengirim ISO 8601 dengan offset (`2026-10-26T09:30:15+07:00`) |
| Paginasi | `?page=1&per_page=20`; respons `{data, meta:{page, per_page, total}}` |
| Penguncian | Objek yang bisa diubah membawa `version`. Ubah dengan `version` lama; bila berbeda → 409 `ERR-015` |
| Idempotensi | Header `Idempotency-Key` (UUID dari Flutter) wajib pada pembuatan dan submit; permintaan ulang mengembalikan hasil pertama |
| Hak akses | Pengembang hanya objek miliknya (`developer_id`). Tim lapangan hanya tugas dan laporan miliknya (`officer_id`). Selebihnya 404, bukan 403, agar ID tidak bisa ditebak **[KEPUTUSAN Q03/Q08]** |
| Batas laju | Login 5/menit per IP+username; API lain 120/menit per token |

Format galat (semua 4xx/5xx):

```json
{ "error": { "code": "ERR-002", "message": "Format tidak sesuai. Slot ini hanya menerima PDF.", "fields": { "file": ["…"] } } }
```

| Kode | HTTP | Arti | Asal |
|---|---|---|---|
| ERR-001 | 422 | Ukuran berkas melebihi batas | sudah ada di `SubmissionFileValidator` |
| ERR-002 | 422 | Format atau jumlah berkas pada slot tidak sesuai | sudah ada |
| ERR-003 | 422 | Berkas tidak terbaca, rusak, atau terkunci | sudah ada |
| ERR-004 | 422 | Site Plan wajib memuat minimal 1 DWG dan 1 PDF | sudah ada |
| ERR-015 | 409 | `version` sudah usang (memuat `current_version`) | disebut di migrasi |
| ERR-013 | 404 | Data tidak ditemukan, atau milik akun lain | baru |
| ERR-030 | 429 | Terlalu banyak permintaan | baru |
| ERR-010 | 422 | Validasi isian gagal (lihat `fields`) | baru |
| ERR-011 | 409 | Aksi tidak diizinkan pada tahap/status ini | baru |
| ERR-012 | 422 | Foto ditolak (tanda tangan tidak sah, bukan JPEG, melebihi batas) | baru |
| ERR-020 | 401 | Kredensial salah atau token tidak berlaku | baru |
| ERR-021 | 423 | Akun terkunci sementara (`locked_until`) | baru |
| ERR-022 | 403 | Akun nonaktif, atau wajib ganti kata sandi | baru |

## 2. Autentikasi (semua role)

| Metode dan jalur | Isi | Keterangan |
|---|---|---|
| `POST /auth/login` | `{username, password, device_name}` | Sukses: `{token, user:{id,name,role,jabatan}, must_change_password}`. Gagal berulang menaikkan `failed_login_attempts` dan mengisi `locked_until` (batas dan durasi **[KEPUTUSAN Q14]**) |
| `POST /auth/logout` | | Mencabut token saat ini |
| `GET /me` | | Profil akun dan, untuk pengembang, `developer_profile` |
| `POST /auth/change-password` | `{current_password, new_password}` | Wajib bila `must_change_password` |

Akun bersifat **tertutup**: tidak ada pendaftaran mandiri; Administrator membuat akun (sesuai nama migrasi akun).
Tombol "Masuk sebagai Pengembang/Tim Perwaskim" di Flutter hanya untuk mode demo lokal dan dihapus saat produksi.

## 3. Pengembang

| Metode dan jalur | Fungsi | Aturan penting |
|---|---|---|
| `GET /developer/profile`, `PUT /developer/profile` | Data PT dan perumahan (`developer_profiles`) | NIB 13 digit unik |
| `GET /submissions` | Pengajuan milik sendiri; filter `stage`, `sub_status`, `q` | Respons memuat `stage`, `sub_status`, `statusTahap` (pemetaan Flutter), jumlah berkas perlu perbaikan |
| `POST /submissions` | Buat draf (`stage=1`, `sub_status=draft`) | `Idempotency-Key` |
| `GET /submissions/{id}` | Detail: data, `files` per slot (versi aktif), `assignment` aktif, `reports` yang boleh dilihat pengembang **[KEPUTUSAN Q09]** | |
| `PATCH /submissions/{id}` | Simpan isian draf dan `current_step` | Hanya saat `draft` (perbaikan lewat penggantian berkas, bukan PATCH); wajib `version`. Kolom: `nama_perumahan`, `alamat_proyek`, `tipe_pengajuan`, `daya_listrik`, `npwp`, `luas_lahan`, `jumlah_unit`, `tipe_perumahan`, `current_step` |
| `POST /submissions/{id}/files` | Unggah satu berkas: `slot_code`, `file` | Memakai `SubmissionFileValidator`; kode slot `S2-01`…`S4-02` (Flutter memetakan dari kunci). Saat revisi, baris lama `is_current=false`, `replaced_at` terisi, `version` naik |
| `DELETE /submissions/{id}/files/{fileId}` | Hapus berkas draf | Hanya saat `draft`; saat revisi digantikan, tidak dihapus |
| `GET /submissions/{id}/files/{fileId}/download` | Unduh berkas | Terautentikasi, disk privat, tanpa URL publik |
| `POST /submissions/{id}/submit` | Kirim | Server memeriksa semua slot wajib (S3-10 opsional), S4-01 memuat DWG+PDF (ERR-004), lalu menerbitkan `SR-<tahun>-<urut>`, `stage=2`, `submitted_at`, `stage_entered_at`. Gagal → ERR-010 dengan daftar slot yang kurang |
| `POST /submissions/{id}/resubmit` | Kirim perbaikan | Hanya saat `perlu_perbaikan`; semua berkas yang diminta harus sudah diganti; `sub_status=perbaikan_terkirim`; jam SLA berjalan lagi |
| `GET /submissions/{id}/timeline` | Riwayat keputusan dan perubahan | Perlu tabel audit baru |

## 4. Pengawas (tim lapangan)

| Metode dan jalur | Fungsi | Aturan penting |
|---|---|---|
| `GET /officer/assignments` | Tugas milik sendiri; filter `status` | Memuat ringkasan pengajuan (nama perumahan, PT, lokasi, `scheduled_date`, `note`). Menggantikan `surveyAktifProvider` |
| `POST /officer/assignments/{id}/accept` | Terima tugas | `diterima`, `accepted_at` |
| `GET /officer/reports` | Daftar laporan sendiri (draf dan final) | |
| `POST /officer/reports` | Buat draf laporan | Boleh tanpa `assignment_id` (laporan mandiri) **[KEPUTUSAN Q08]**; `Idempotency-Key` = id draf Flutter |
| `PUT /officer/reports/{id}` | Simpan isian | Bidang sesuai kontrak (bagian 7): `monitoring_date`, `nama_perumahan`, `lokasi`, `maksud_tujuan`, `temuan[]`, `kesimpulan[]`, `kesepakatan[]`, `rtl[]`, `status_hasil_evaluasi`, `tim_pelaksana[]`, `pihak_ditemui[]`; wajib `version`; hanya saat `draft` |
| `POST /officer/reports/{id}/photos` | Unggah satu foto | `multipart`: `file` (JPEG ≤ 10 MB) dan `meta` (JSON: `latitude`, `longitude`, `accuracy_m`, `captured_at`, `address`, `note`, `source`). Maksimal **10** foto per laporan. Server **memverifikasi tanda tangan JPEG** dan menyimpan berkas apa adanya. Salah → ERR-012 |
| `DELETE /officer/reports/{id}/photos/{photoId}` | Hapus foto | Hanya saat `draft` |
| `POST /officer/reports/{id}/submit` | Final | Body `{latitude, longitude}`. Aturan yang sudah ada di Flutter dibawa ke server: `maksud_tujuan` dan `status_hasil_evaluasi` wajib; bila hasil bukan "sesuai" maka `rtl` minimal 1 butir; tidak ada foto yang perlu diambil ulang. Server menerbitkan `600.2.5/BA-MON/<romawi>/<tahun>/<urut>`, mengisi `submitted_at`, `status=final`, menutup tugas (`selesai`), memberi tahu Admin |
| `GET /officer/reports/{id}/pdf` | PDF resmi | Dibuat server (kontrak bagian 8) |

Kunci tanda tangan foto saat ini **tertanam di aplikasi Flutter**. Server hanya bisa memverifikasi bila memegang kunci yang
sama, sehingga ini mendeteksi foto yang diubah, bukan memalsukan. Bukti foto dengan kekuatan hukum membutuhkan
penandatanganan di server **[KEPUTUSAN]**.

## 5. Notifikasi (semua role)

| Metode dan jalur | Fungsi |
|---|---|
| `GET /notifications` | Milik sendiri, terbaru dulu, filter `unread` |
| `POST /notifications/{id}/read`, `POST /notifications/read-all` | Tandai dibaca |

Versi 1 memakai penarikan berkala (polling) saat aplikasi terbuka; dorongan (FCM) ditunda. Pemicu usulan:

| Peristiwa | Penerima |
|---|---|
| Pengajuan dikirim atau dikirim ulang | Verifikator |
| Admin meminta perbaikan | Pengembang |
| Survei dijadwalkan atau dialihkan | Petugas dan pengembang |
| Laporan BA dikirim | Verifikator |
| Keputusan terbit (`selesai` atau `ditolak`) | Pengembang |

Matriks final **[KEPUTUSAN Q10]**.

## 6. Pekerjaan di Laravel (berurutan)

1. Tambah Sanctum; `routes/api.php`; middleware peran (`administrator`, `verifikator`, `pengembang`, `tim_lapangan`).
2. Model dan relasi untuk tabel baru: `DeveloperProfile`, `Submission`, `SubmissionFile`, `InspectionAssignment`, `InspectionReport`, plus foto.
3. Migrasi tambahan: `inspection_report_photos`; kolom `maksud_tujuan` dan `status_hasil_evaluasi` pada `inspection_reports`; tabel audit; tabel notifikasi baru; atribut `required` pada katalog slot.
4. Service tunggal alur status (`SubmissionWorkflow`) dan penomor (`number_sequences` dengan kunci baris `lockForUpdate`).
5. Policy kepemilikan, `FormRequest`, `Resource` (bentuk JSON stabil).
6. Verifikator foto (tanda tangan), pembuat PDF dan QR.
7. Ubah controller Admin web agar memakai service yang sama; lalu hapus tabel lama.
8. Uji fitur (feature test) per jalur: kepemilikan, transisi terlarang, konflik `version`, idempotensi, validator berkas.

## 7. Pekerjaan di Flutter

1. Klien HTTP (Dio sudah ada) dengan token dan penanganan 401/423. Penyimpanan token aman membutuhkan paket yang sudah kita hapus (`flutter_secure_storage`), jadi harus ditambah lagi.
2. Lapisan pemetaan (role, tahap, kunci slot ↔ kode slot, tipe perumahan) sesuai kontrak.
3. Repository berbasis API menggantikan repository dalam memori; draf lokal tetap ada dan disinkronkan lewat `Idempotency-Key` dan `version`.
4. Login nyata; menghapus pilihan peran dari username.
5. Unggah berkas dan foto dengan antrean ulang; ukuran dwg hingga 50 MB.
6. Mematikan layar Admin setelah Web Admin siap.

## 8. Tahapan pengerjaan yang disarankan

| Fase | Isi | Hasil yang bisa diuji |
|---|---|---|
| A | Autentikasi + `/me` + akun seed | Login nyata dari Flutter untuk 3 role |
| B | Pengajuan dan berkas Pengembang | Pengembang mengirim pengajuan dan Admin web melihatnya di tabel baru |
| C | Tugas dan laporan Pengawas, foto geotag | Pengawas mengirim BA yang tampil di Admin web |
| D | Notifikasi dan alur revisi | Admin minta perbaikan, pengembang kirim ulang |
| E | PDF/QR server, pembersihan tabel lama | Dokumen resmi dan satu skema |

## 9. Status Fase A (autentikasi): sudah dikerjakan

Laravel: Sanctum, `routes/api.php`, `Api\AuthController` (login, logout, `me`, ganti kata sandi), middleware `role` dan
`password.changed`, `AccountSeeder` (satu akun per role), `DeveloperProfile`, 17 feature test. Web Admin kini hanya
untuk `verifikator` dan `administrator`. Flutter (branch `feat/api-fase-a-flutter`): klien HTTP, `flutter_secure_storage`
untuk token, login nyata, layar Ganti Kata Sandi, pemulihan sesi di splash, logout yang mencabut token.

Mode Flutter ditentukan saat build: tanpa `API_BASE_URL` aplikasi tetap mode demo lokal (pintasan demo aktif);
dengan `API_BASE_URL` login memakai server dan pintasan demo dimatikan.

Akun seed (hanya `local`/`testing`; di lingkungan lain wajib mengisi `SEED_DEFAULT_PASSWORD`):

| Username | Role | Kata sandi awal |
|---|---|---|
| `pengembang` | pengembang | `SatuRumah#2026` (wajib diganti saat masuk pertama) |
| `tim_lapangan` | tim_lapangan | sama |
| `verifikator`, `administrator` | Web Admin (ditolak oleh API mobile) | sama |

Menjalankan untuk uji di HP (laptop dan HP satu Wi-Fi):

```bash
# Laravel (butuh PHP 8.2+)
cd Backend-SatuRumah
composer install && cp .env.example .env && php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000   # izinkan port 8000 di firewall Windows

# Flutter (ganti IP-LAN dengan IP laptop, mis. 192.168.1.10)
flutter run --dart-define=API_BASE_URL=http://IP-LAN:8000/api/v1/
```

HTTP biasa hanya diizinkan pada build debug/profile. APK release wajib memakai HTTPS (server sungguhan atau terowongan
seperti Cloudflare Tunnel/ngrok). Batas percobaan masuk dan durasi kunci: `AUTH_MAX_ATTEMPTS` dan `AUTH_LOCK_MINUTES`
di `.env` (usulan 5 kali dan 15 menit, menunggu keputusan Q14).

## 10. Status Fase B (pengajuan dan berkas Pengembang): sudah dikerjakan

Laravel (35 feature test): `GET/PUT developer/profile`; `GET/POST submissions` (`?detail=1` memuat berkas aktif,
`Idempotency-Key` wajib pada POST); `GET/PATCH submissions/{id}`; `POST/DELETE submissions/{id}/files`;
`GET submissions/{id}/files/{fileId}/download`; `POST submissions/{id}/submit` dan `/resubmit`.
Nomor `SR-<tahun>-<urut>` diterbitkan server saat kirim. Berkas disimpan di disk privat dengan nama acak.

Flutter (branch `feat/api-fase-b-flutter`): daftar "Pengajuan" dimuat dari server (tarik untuk memuat ulang);
tombol Kirim di Langkah 5 membuat draf, menyimpan isian, mengunggah tiap berkas, lalu mengirim, dengan indikator
langkah dan percobaan ulang yang aman (kunci idempotensi dan berkas yang sudah ada tidak diunggah ulang). Tanpa
`API_BASE_URL` perilaku prototipe lama tidak berubah.

Belum dikerjakan di Fase B: layar perbaikan berkas (Flutter) dan riwayat/timeline. Keduanya butuh Admin web yang
menulis ke tabel baru (Fase D) agar ada status `perlu_perbaikan` yang nyata. Profil perusahaan tidak punya layar
pengisian: dibuat Administrator bersama akun (seed `AccountSeeder` membuatnya untuk akun contoh).
