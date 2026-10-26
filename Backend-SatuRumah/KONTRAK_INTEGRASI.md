# Kontrak Integrasi SATU RUMAH: Admin Web (Laravel) ↔ Flutter (Pengembang, Pengawas)

Status: **USULAN untuk disetujui**. Disusun 26 Oktober 2026 dari pembacaan kode, tanpa menjalankan aplikasi.
Dokumen ini menjawab satu hal: **nilai apa yang dipakai bersama** oleh tiga role agar data dari Flutter bisa
masuk ke Laravel tanpa tebak-tebakan. Hal yang butuh keputusan Disperwaskim ditandai **[KEPUTUSAN]**
(rujukan Q-nomor ada di `design.md` bagian 18).

Sumber yang dibandingkan:
- Laravel: `config/satu_rumah.php`, migrasi `2026_10_12_*`, seeder, controller.
- Flutter: `status_tahap_pengajuan.dart`, `pengajuan_form_controller.dart`, `monitoring_model.dart`,
  `status_hasil_evaluasi.dart`, `role_session.dart`.

---

## 1. Keputusan skema (satu sumber kebenaran)

**Dipakai (skema baru, migrasi 12 Okt 2026):**
`users` (+ kolom akun), `developer_profiles`, `submissions`, `submission_files`,
`inspection_assignments`, `inspection_reports`, `settings`, `number_sequences`.

**Dihentikan (skema lama, migrasi 19 Agu 2026):**
`pengajuan`, `dokumen_pengajuan`, `survey_pengajuan`, `monitoring_pengajuan`, `riwayat_pengajuan`, `notifikasi`.
Tabel lama baru boleh dihapus setelah controller Admin dipindah ke tabel baru. Sampai saat itu keduanya
berjalan berdampingan dan **data tidak boleh ditulis ke dua tempat**.

**Perlu ditambah (belum ada di skema):** tabel foto laporan (bagian 7), tabel riwayat/audit,
tabel notifikasi baru, penanda wajib/opsional pada katalog slot (bagian 5).

---

## 2. Role

| Konsep | Flutter (`AppRole`) | Laravel (`users.role`, saat ini) | Nilai yang disepakati |
|---|---|---|---|
| Pengembang | `developer` | (tidak ada di seeder) | `pengembang` |
| Admin / Verifikator | `admin` | `verifikator` (seeder), `admin_dpkp` (default kolom) | `verifikator` |
| Administrator sistem | (tidak ada) | `administrator` (hanya di config) | `administrator` |
| Pengawas / Perwaskim | `perwaskim` | `perwaskim` (seeder) | `tim_lapangan` |

Yang harus diubah: `config/satu_rumah.php` sudah memakai `administrator, verifikator, pengembang, tim_lapangan`.
Seeder (`perwaskim`) dan default kolom (`admin_dpkp`) harus mengikuti config. Di sisi Flutter, API mengirim
nilai Laravel dan Flutter memetakannya: `pengembang→developer`, `verifikator→admin`, `tim_lapangan→perwaskim`.
`AppRole.admin` di Flutter hanya dipakai selama layar Admin prototipe masih ada (bagian 9).

---

## 3. Tahap dan status pengajuan

Laravel menyimpan **dua kolom**: `stage` (angka) dan `sub_status` (teks). Flutter punya **satu enum**
`StatusTahapPengajuan` + penanda revisi. Pemetaan usulan:

| `stage` | Arti | Flutter `statusTahap` |
|---|---|---|
| 1 | Draf (pengembang mengisi) | belum dikirim (tidak ada di enum; draf lokal) |
| 2 | Verifikasi Administrasi | `verifikasiAdministrasi` (`pengajuanBaru` dipakai bila `sub_status = baru`) |
| 3 | Verifikasi Teknis | `verifikasiTeknis` |
| 4 | Survei Lapangan | `surveyLapangan` |
| 5 | Persetujuan | `persetujuan` |
| 6 | Selesai | `selesai` |

Dasar: SLA di `SlaSettings` hanya berlaku untuk tahap 2–5, dan katalog slot menyebut `stage 2 = Administrasi`,
`stage 3 = Teknis`. **[KEPUTUSAN Q04]** nomor tahap 1 dan 6 adalah usulan.

**`perluPerbaikan` bukan tahap.** Di Flutter ia adalah enum, di Laravel ia adalah `sub_status` pada tahap yang sama.
`tahapAsalPerbaikan` Flutter = `stage` saat ini; tenggat revisi = `correction_deadline_at` (default 14 hari, `revision.deadline_days`).

Kosakata `sub_status` yang diusulkan:

| `sub_status` | Arti | Flutter |
|---|---|---|
| `draft` | Belum dikirim | draf lokal |
| `baru` | Baru masuk, belum ditelaah | `pengajuanBaru` |
| `dalam_telaah` | Sedang diperiksa Admin | tahap sesuai `stage` |
| `perlu_perbaikan` | Admin meminta revisi | `perluPerbaikan` + `tahapAsalPerbaikan` |
| `perbaikan_terkirim` | Pengembang sudah kirim ulang, menunggu Admin | `revisionSubmitted = true` |
| `terjadwal` | Survei dijadwalkan (tahap 4) | `surveyLapangan` |
| `menunggu_persetujuan` | Laporan final diterima, menunggu keputusan | `persetujuan` |
| `selesai` | Keputusan terbit (`decision_number`, `completed_at`) | `selesai` |
| `ditolak` | Ditolak | belum ada di Flutter **[KEPUTUSAN Q04: final atau boleh diajukan ulang]** |

Aturan transisi memakai guard yang sudah ada di Flutter (lihat `design.md` bagian 6.2). **Server menjadi penentu
akhir**; Flutter hanya menampilkan dan tidak boleh mengubah `stage` sendiri.

**Status berkas** (`submission_files.status`) ↔ Flutter `verifiedDocs`:

| `submission_files.status` | Flutter `verifiedDocs[key]` |
|---|---|
| `menunggu_telaah` | tidak ada entri |
| `sesuai` | `true` |
| `perlu_perbaikan` | `false` (dan masuk `dokumenPerluRevisi`) |

Nilai `sesuai` dan `perlu_perbaikan` adalah usulan; kolom `decision_type` (maks 10 karakter) belum didefinisikan
**[KEPUTUSAN Q05]**. Berkas hasil revisi disimpan sebagai baris baru (`version` naik, `is_current` berpindah).

**Status penugasan** (`inspection_assignments.status`): `dijadwalkan` → `diterima` → `selesai`;
cabang `dialihkan` (isi `reassigned_from_id` dan `reassign_reason`) dan `dibatalkan`. **[KEPUTUSAN Q08]**

---

## 4. Penomoran

| Objek | Format | Pembuat |
|---|---|---|
| Pengajuan | `SR-<tahun>-<urut 4 digit>`, contoh `SR-2026-0001` | **Server**, saat Submit (`submissions.number`) |
| BA Monitoring | `600.2.5/BA-MON/<bulan Romawi>/<tahun>/<urut 3 digit>`, contoh `600.2.5/BA-MON/X/2026/002` | **Server**, saat laporan final |

Perubahan yang dibutuhkan:
- Laravel saat ini merencanakan `BA-MON/2026/0001` (urut per tahun). Flutter memakai format dinas di atas dengan urut
  **per bulan** (keputusan pemilik produk). Samakan ke format Flutter: kunci `number_sequences` menjadi `BA-MON-<tahun>-<bulan>`.
- Kolom `report_number` sepanjang 30 karakter cukup (nomor terpanjang `…/XII/2026/001` = 27 karakter).
- Nomor di Flutter hanya **sementara** selama draf; nomor sah diterbitkan server saat final.

---

## 5. Katalog 18 slot berkas

Kunci Flutter ↔ kode Laravel. Urutan, nama, dan kardinalitas sudah cocok; yang berbeda hanya kunci.

| Kode Laravel | Kunci Flutter | Nama | Format | Banyak berkas | Wajib |
|---|---|---|---|---|---|
| S2-01 | `ktp` | KTP Elektronik Pemohon | pdf | tidak | ya |
| S2-02 | `nib` | Nomor Induk Berusaha (NIB) | pdf | tidak | ya |
| S2-03 | `npwp_doc` | NPWP Perusahaan | pdf | tidak | ya |
| S2-04 | `asosiasi` | Bukti Keanggotaan Asosiasi | pdf | tidak | ya |
| S2-05 | `legalitas` | Akta Pendirian/Perubahan dan SK Kemenkumham | pdf | tidak | ya |
| S3-01 | `surat_permohonan` | Surat Permohonan Persetujuan | pdf | tidak | ya |
| S3-02 | `info_intensitas_ruang` | Informasi Intensitas Pemanfaatan Ruang / KKPR | pdf | tidak | ya |
| S3-03 | `bukti_kepemilikan_lahan` | Bukti Kepemilikan Lahan / Sertifikat Induk | pdf | tidak | ya |
| S3-04 | `bukti_tpu` | Bukti Penyediaan Lahan TPU | pdf | tidak | ya |
| S3-05 | `rekomendasi_lingkungan` | Rekomendasi Teknis Dinas Terkait | pdf | **ya** | ya |
| S3-06 | `andalalin` | Persetujuan ANDALALIN | pdf | tidak | ya |
| S3-07 | `rekomendasi_air_bersih` | Rekomendasi Air Bersih | pdf | tidak | ya |
| S3-08 | `rekomendasi_listrik` | Rekomendasi Listrik PLN | pdf | tidak | ya |
| S3-09 | `pernyataan_psu` | Surat Pernyataan Kesanggupan Penyerahan PSU | pdf | tidak | ya |
| S3-10 | `penanggung_jawab_teknis` | Data Penanggung Jawab Dokumen Teknis | pdf | tidak | **tidak (opsional di Flutter)** |
| S3-11 | `proposal_pembangunan` | Proposal Rencana Pembangunan | pdf | tidak | ya |
| S4-01 | `site_plan_dwg` + `technicalFiles` | Dokumen Perencanaan dan Perancangan Site Plan | dwg, pdf | **ya** | ya |
| S4-02 | `kajian_teknis` | Dokumen Kajian Teknis | pdf | **ya** | ya |

Selisih yang harus ditutup:
1. **Wajib/opsional** belum ada di katalog Laravel. Tambah atribut `required` per slot; S3-10 ditandai `false`
   mengikuti Flutter **[KEPUTUSAN Q06/Q07]**.
2. **Ukuran:** Laravel memakai pdf 10 MB dan dwg 50 MB; Flutter memakai 10 MB untuk semua. Flutter harus
   menerima dwg hingga 50 MB di slot S4-01.
3. **Tahap pemeriksa:** semua slot S2 dan S3 diperiksa pada tahap 2 (Administrasi), S4 pada tahap 3 (Teknis).
   Ini sudah sama dengan guard Flutter.
4. Penamaan dan susunan DOC01–DOC16 di `design.md` bagian 10 belum sama dengan 18 slot ini **[KEPUTUSAN Q07]**.

Berkas disimpan dengan nama acak (`stored_name`) di disk privat, tanpa URL publik; unduhan lewat endpoint terautentikasi.

---

## 6. Data pengajuan dan profil pengembang

| Flutter (`Pengajuan` / form) | Laravel | Catatan |
|---|---|---|
| `id` | `submissions.number` | `submissions.id` angka internal, `number` yang tampil |
| `namaPerumahan` | `developer_profiles.nama_perumahan` | |
| `namaPt` | `developer_profiles.nama_pt` | |
| `namaDirektur` | `developer_profiles.nama_direktur` | |
| `nib` | `developer_profiles.nib` | 13 digit, unik |
| `alamatProyek` | `developer_profiles.alamat_perumahan` | |
| `tipePengajuan` (teks bebas, "Pengajuan Site Plan Baru") | `developer_profiles.tipe_pengajuan` (maks 30) | samakan kosakata **[KEPUTUSAN]** |
| `npwpPerusahaan` | `submissions.npwp` | |
| `luasLahan` | `submissions.luas_lahan` | |
| `jumlahUnit` | `submissions.jumlah_unit` | |
| `tipePerumahan`: `Subsidi`/`Komersil`/`Campuran` | `submissions.tipe_perumahan`: `subsidi`/`komersil`/`subsidi_komersil` | `Campuran` ↔ `subsidi_komersil` |
| `dayaListrik` | **tidak ada** | tambah kolom bila memang dipakai |
| (tidak ada di Flutter) | `alamat_pt`, `no_hp_direktur`, `email_pt` | tambahkan ke form Langkah 1 atau jadikan opsional |
| `tanggal` | `submitted_at` | |
| `catatanPerbaikan` | `submission_files.review_note` (per berkas) | |
| `nomorSk`, `tanggalSk`, `skPersetujuanPath` | `decision_number`, `decision_date`, `decision_file_path` | |
| `tanggalSurvey`, `catatanSurvey` | `inspection_assignments.scheduled_date`, `note` | |

---

## 7. Laporan BA dan foto geotag

| Flutter (`MonitoringModel`) | Laravel (`inspection_reports`) | Catatan |
|---|---|---|
| `nomorSuratBA` | `report_number` | bagian 4 |
| `pengajuanId` | `submission_id` | |
| (tugas) | `assignment_id` | **Flutter belum menyimpan ID tugas**; saat ini hanya `pengajuanId` |
| (login) | `officer_id` | dari token |
| `tanggalMonitoring` | `monitoring_date` | |
| `namaPerumahan` | `nama_perumahan` | |
| `lokasiPerumahan` | `lokasi` | |
| `maksudTujuan` | **tidak ada** | tambah kolom (BA resmi memuat bagian I) |
| `temuanLapangan` | `temuan` (json, maks 20) | |
| `kesimpulan` | `kesimpulan` (json) | |
| `kesepakatan` | `kesepakatan` (json) | |
| `rencanaTindakLanjut` | `rtl` (json) | |
| `statusHasilEvaluasi` (`sesuaiSiteplan`, `tidakSesuaiSiteplan`, `perluEvaluasiLanjutan`) | **tidak ada** | tambah kolom; nilai disimpan sebagai string yang sama |
| `pelaksana` | `tim_pelaksana` (json `[{nama, jabatan}]`, maks 10) | |
| `ditemui` | `pihak_ditemui` (json) | |
| `isDraft` | `status` | `draft` → `final` (dikirim, `submitted_at`) → `diterbitkan` (`published_at`, Admin) |
| `photos` | **tidak ada tabel** | lihat di bawah |
| (tidak ada) | `submit_latitude`, `submit_longitude` | Flutter kirim koordinat saat submit |
| (tidak ada) | `pdf_path`, `docx_path`, `verification_token` | dihasilkan server (bagian 8) |

**Tabel foto yang perlu ditambah** (`inspection_report_photos`, usulan kolom): `report_id`, `storage_path`,
`stored_name`, `size_bytes`, `checksum`, `latitude`, `longitude`, `accuracy_m`, `captured_at`, `address`, `note`,
`source` (`camera`/`gallery`), `signature_ok` (hasil verifikasi tanda tangan JPEG), `position`.

Aturan foto:
- Foto sudah **berwatermark di piksel** dan memuat tanda tangan tertanam. Server menyimpan berkas apa adanya
  (jangan kompres ulang, itu merusak tanda tangan) dan menyimpan metadata di kolom.
- **Batas jumlah:** Laravel `upload.photo_max_count = 15`, Flutter `kMaxReportPhotos = 10`.
  Disepakati **10** (keputusan pemilik produk); ubah default Laravel menjadi 10.
- **Batas ukuran:** 10 MB per foto, sama di kedua sisi.
- Server memverifikasi ulang tanda tangan dan menolak foto yang rusak. Kunci tanda tangan saat ini ada di aplikasi,
  jadi ini hanya mendeteksi perubahan, bukan keamanan penuh **[KEPUTUSAN]** (pindahkan penandatanganan ke server
  bila bukti foto perlu kekuatan hukum).

---

## 8. PDF dan QR

Flutter membuat PDF di perangkat (format resmi Dinas, F4, Times 12). Laravel menyiapkan `pdf_path`, `docx_path`,
dan `verification_token` (untuk QR) tetapi belum ada pembuatnya. Usulan: PDF resmi dibuat **server** dari data
laporan agar sama untuk semua perangkat dan bisa diberi QR verifikasi; PDF di HP dipertahankan hanya sebagai pratinjau.
**[KEPUTUSAN Q09]** siapa yang menandatangani dan kapan sebuah BA dianggap resmi.

---

## 9. Yang harus dihapus atau dimatikan setelah integrasi

- Layar Admin di Flutter (`pengajuan_admin_*`, `AppRole.admin`) setelah Admin web siap **[KEPUTUSAN Q16]**.
- Data dummy tetap di `MonitoringController` Laravel lama (`tanggal_survey: '22 Mei 2025'`, petugas bawaan).
- Tabel lama (bagian 1).

---

## 10. Daftar keputusan yang menunggu Disperwaskim

| Rujukan | Pertanyaan |
|---|---|
| Q04 | Nomor tahap 1 dan 6; status `ditolak` final atau boleh diajukan ulang; arti `selesai` |
| Q05 | Nilai `decision_type` berkas; apakah revisi wajib diperiksa ulang per berkas |
| Q06/Q07 | Slot mana yang wajib; hubungan 18 slot dengan DOC01–DOC16 |
| Q08 | Satu petugas atau tim; pengalihan dan pembatalan tugas |
| Q09 | Penandatangan BA, arti final, siapa membuat PDF resmi |
| Q16 | Waktu penghentian layar Admin di Flutter |

Setelah butir-butir ini disetujui, langkah berikutnya adalah merancang endpoint API di atas kontrak ini
(login token, daftar tugas, kirim berkas, kirim BA beserta foto).
