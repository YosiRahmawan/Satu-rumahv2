# Kontrak Integrasi SATU RUMAH: Admin Web (Laravel) ↔ Flutter (Pengembang, Pengawas)

Status: **disinkronkan dengan implementasi Fase A–D** (26 Oktober 2026). Nilai di bawah adalah yang benar-benar
dipakai kode di branch `feat/backend-satu-rumah` dan `feat/alur-pengawas-lapangan`. Bagian yang masih menunggu
Disperwaskim tetap bertanda **[KEPUTUSAN]**; implementasi memakai **asumsi sementara** untuk semuanya (bagian 10),
dan asumsi itu bukan keputusan resmi.

Backend utama: `satu-rumahv2-backend/Backend-SatuRumah`, branch `feat/backend-satu-rumah`. Clone `Backend-SatuRumah`
di luar repo (milik teman) dan folder `backend/` prototipe di repo Flutter **bukan** sumber kebenaran.

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
Status: controller, model, dan tampilan yang memakainya **sudah dihapus** (Fase D) dan tidak ada kode yang menulis ke
tabel ini lagi. **Tabelnya sendiri masih ada di database**; pembuangannya (migrasi) dijadwalkan di Fase E.

**Sudah ditambah:** `inspection_report_photos` (Fase C, bagian 7), `submission_events` (riwayat) dan
`app_notifications` (notifikasi) (Fase D), penanda `required` pada katalog slot (bagian 5).

---

## 2. Role

| Konsep | Flutter (`AppRole`) | Laravel (`users.role`, saat ini) | Nilai yang disepakati |
|---|---|---|---|
| Pengembang | `developer` | (tidak ada di seeder) | `pengembang` |
| Admin (Verifikator dan Administrator digabung) | `admin` | `admin` (sebelumnya `verifikator`/`administrator`, digabung 29 Okt 2026) | `admin` |
| Pengawas / Perwaskim | `perwaskim` | `perwaskim` (seeder) | `tim_lapangan` |

Status: `AccountSeeder` membuat akun `admin`, `pengembang`, `tim_lapangan` (Fase A); login dan
peran berasal dari backend. Flutter memetakan `pengembang→developer`, `tim_lapangan→perwaskim`. Role `admin`
masuk lewat Web Admin (satu role untuk semua pekerjaan admin, **[KEPUTUSAN Q10: keputusan tim, belum dikonfirmasi Disperwaskim]**). `AppRole.admin` di Flutter masih ada untuk layar
Admin prototipe (bagian 9).

---

## 3. Tahap dan status pengajuan

Laravel menyimpan **dua kolom**: `stage` (angka) dan `sub_status` (teks). Flutter punya **satu enum**
`StatusTahapPengajuan` + penanda revisi. Pemetaan yang dipakai kode (tahap 1 dan 6 masih usulan, Q04):

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
| `ditolak` | Ditolak | `ditolak`; tombol "Ajukan Ulang" membuka form baru berisi data lama (berkas diunggah lagi, nomor baru) **[KEPUTUSAN Q04: keputusan tim, belum dikonfirmasi Disperwaskim]** |

Aturan transisi memakai guard yang sudah ada di Flutter (lihat `design.md` bagian 6.2). **Server menjadi penentu
akhir**; Flutter hanya menampilkan dan tidak boleh mengubah `stage` sendiri.

**Status berkas** (`submission_files.status`) ↔ Flutter `verifiedDocs`:

| `submission_files.status` | Flutter `verifiedDocs[key]` |
|---|---|
| `menunggu_telaah` | tidak ada entri |
| `lolos` | `true` (Flutter juga menerima `sesuai`) |
| `perlu_perbaikan` | `false` (dan masuk `dokumenPerluRevisi`) |

Nilai di server adalah `lolos`, bukan `sesuai` (dokumen versi awal keliru). Saat Admin menandai `perlu_perbaikan`,
`decision_type` diisi `revisi`; nilai `tolak` belum dipakai **[KEPUTUSAN Q05]**. Berkas hasil revisi disimpan sebagai baris baru (`version` naik, `is_current` berpindah).

**Status penugasan** (`inspection_assignments.status`): `dijadwalkan` → `diterima` → `selesai`;
cabang `dialihkan` (isi `reassigned_from_id` dan `reassign_reason`; dipakai saat Admin menjadwal ulang atau mengganti
petugas) dan `dibatalkan` (**belum ada tindakan Admin yang menghasilkannya**). Satu penugasan = satu petugas;
tim banyak orang belum didukung **[KEPUTUSAN Q08]**.

---

## 4. Penomoran

| Objek | Format | Pembuat |
|---|---|---|
| Pengajuan | `SR-<tahun>-<urut 4 digit>`, contoh `SR-2026-0001` | **Server**, saat Submit (`submissions.number`) |
| BA Monitoring | `600.2.5/BA-MON/<bulan Romawi>/<tahun>/<urut 3 digit>`, contoh `600.2.5/BA-MON/X/2026/002` | **Server**, saat laporan final |

Status: **sudah dilaksanakan** (`NumberGenerator`, Fase B dan C). Urut BA per bulan mengikuti format Flutter; nomor di
Flutter hanya sementara selama draf, nomor sah diterbitkan server saat Submit/final. Kolom `report_number` (30
karakter) cukup (terpanjang 27).

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

Status selisih:
1. **Wajib/opsional:** selesai. Atribut `required` ada di `config/satu_rumah.php`; S3-10 `false`
   **[KEPUTUSAN Q06/Q07 untuk kewajiban resmi]**.
2. **Ukuran:** server menerima pdf 10 MB dan dwg 50 MB; Flutter menerima dwg/pdf hingga 50 MB untuk site plan
   (`FilePickerUtil.revisionRule`). Cocok.
3. **Tahap pemeriksa:** semua slot S2 dan S3 diperiksa pada tahap 2 (Administrasi), S4 pada tahap 3 (Teknis).
   Ini sudah sama dengan guard Flutter.
4. Hubungan DOC01–DOC16 dengan slot: lihat `design.md` bagian 10. Hanya **jumlahnya** yang cocok (16 = S2 yang 5
   + S3 yang 11); pemetaan per nomor **belum ada sumbernya** dan tidak ditebak **[KEPUTUSAN Q07]**. Slot S4-01
   dan S4-02 adalah dua dokumen teknis tambahan (total 18).

**Site Plan (S4-01):** cukup **satu berkas DWG atau PDF** (keputusan pemilik produk, 27 Okt 2026; sebelumnya
diminta DWG dan PDF sekaligus).

**Sumber resmi daftar dokumen:** *Proses Bisnis Aplikasi SATU RUMAH Kota Tasikmalaya* (docx dari Disperwaskim)
memuat 18 dokumen unggahan: Step 2 (5, administrasi perusahaan), Step 3 (11, administrasi perumahan), Step 4 (2,
teknis). Nama, urutan, dan banyak berkas sama persis dengan tabel di atas. Dokumen itu tidak memberi label DOC01–DOC16.
Ia juga memuat 6 format surat yang bisa diunduh (permohonan, kesanggupan PSU, pernyataan keterbangunan PSU, lampiran
SPTJM, permohonan untuk perubahan, contoh hitung KDB/KLB/KDH) dan 2 format teknis yang hanya dapat dipratinjau.

Berkas disimpan dengan nama acak (`stored_name`) di disk privat, tanpa URL publik; unduhan lewat endpoint terautentikasi.

---

## 6. Data pengajuan dan profil pengembang

| Flutter (`Pengajuan` / form) | Laravel | Catatan |
|---|---|---|
| `id` | `submissions.number` | `submissions.id` angka internal, `number` yang tampil |
| `namaPerumahan` | `submissions.nama_perumahan` | Per pengajuan (satu pengembang bisa mengajukan beberapa perumahan). Nilai awal disalin dari `developer_profiles.nama_perumahan` |
| `namaPt` | `developer_profiles.nama_pt` | |
| `namaDirektur` | `developer_profiles.nama_direktur` | |
| `nib` | `developer_profiles.nib` | 13 digit, unik |
| `alamatProyek` | `submissions.alamat_proyek` | Per pengajuan; nilai awal dari `developer_profiles.alamat_perumahan` |
| `tipePengajuan` (teks bebas, "Pengajuan Site Plan Baru") | `submissions.tipe_pengajuan` (maks 40) | Per pengajuan; Flutter mengirim teks pilihan form. Kosakata final **[KEPUTUSAN]** |
| `npwpPerusahaan` | `submissions.npwp` | |
| `luasLahan` | `submissions.luas_lahan` | |
| `jumlahUnit` | `submissions.jumlah_unit` | |
| `tipePerumahan`: `Subsidi`/`Komersil`/`Campuran` | `submissions.tipe_perumahan`: `subsidi`/`komersil`/`subsidi_komersil` | `Campuran` ↔ `subsidi_komersil` |
| `dayaListrik` | `submissions.daya_listrik` | Opsional |
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
| (tugas) | `assignment_id` | Sejak Fase C laporan menunjuk tugas lewat `assignment_id` atau `submission_number`; tanpa keduanya = laporan mandiri |
| (login) | `officer_id` | dari token |
| `tanggalMonitoring` | `monitoring_date` | |
| `namaPerumahan` | `nama_perumahan` | |
| `lokasiPerumahan` | `lokasi` | |
| `maksudTujuan` | `maksud_tujuan` | Ditambah di Fase C |
| `temuanLapangan` | `temuan` (json, maks 20) | |
| `kesimpulan` | `kesimpulan` (json) | |
| `kesepakatan` | `kesepakatan` (json) | |
| `rencanaTindakLanjut` | `rtl` (json) | |
| `statusHasilEvaluasi` (`sesuaiSiteplan`, `tidakSesuaiSiteplan`, `perluEvaluasiLanjutan`) | `status_hasil_evaluasi` | Ditambah di Fase C; nilai string yang sama |
| `pelaksana` | `tim_pelaksana` (json `[{nama, jabatan}]`, maks 10) | |
| `ditemui` | `pihak_ditemui` (json) | |
| `isDraft` | `status` | `draft` → `final` (dikirim, `submitted_at`). `published_at` diisi Admin lewat tombol "Terbitkan BA" (setelah laporan diterima); `status` tetap `final`. Arti resmi dan penandatangan: **[KEPUTUSAN Q09]** |
| `photos` | `inspection_report_photos` | lihat di bawah |
| (tidak ada) | `submit_latitude`, `submit_longitude` | Flutter kirim koordinat saat submit |
| (tidak ada) | `pdf_path`, `docx_path`, `verification_token` | dihasilkan server (bagian 8) |

**Tabel foto** (`inspection_report_photos`, sudah dibuat di Fase C): `report_id`, `position`, `stored_name`,
`storage_path`, `size_bytes`, `checksum` (sha256, unik per laporan), `latitude`, `longitude`, `accuracy_m`,
`captured_at`, `address`, `note`, `source` (`camera`/`gallery`). Hanya foto yang tanda tangannya sah yang disimpan,
jadi tidak ada kolom `signature_ok`.

Aturan foto:
- Foto sudah **berwatermark di piksel** dan memuat tanda tangan tertanam. Server menyimpan berkas apa adanya
  (jangan kompres ulang, itu merusak tanda tangan) dan menyimpan metadata di kolom.
- **Batas jumlah:** **10** di Laravel (`upload.photo_max_count`) dan Flutter (`kMaxReportPhotos`) (keputusan pemilik produk).
- **Batas ukuran:** 10 MB per foto, sama di kedua sisi.
- Server memverifikasi ulang tanda tangan dan menolak foto yang rusak. Kunci tanda tangan saat ini ada di aplikasi,
  jadi ini hanya mendeteksi perubahan, bukan keamanan penuh **[KEPUTUSAN]** (pindahkan penandatanganan ke server
  bila bukti foto perlu kekuatan hukum).

---

## 8. PDF dan QR

Flutter membuat PDF di perangkat (format resmi Dinas, F4, Times 12). Laravel menyiapkan `pdf_path`, `docx_path`,
dan `verification_token` (untuk QR) tetapi **belum ada pembuatnya (dijadwalkan Fase E)**. Usulan: PDF resmi dibuat **server** dari data
laporan agar sama untuk semua perangkat dan bisa diberi QR verifikasi; PDF di HP dipertahankan hanya sebagai pratinjau.
**[KEPUTUSAN Q09]** siapa yang menandatangani dan kapan sebuah BA dianggap resmi.

---

## 9. Yang harus dihapus atau dimatikan setelah integrasi

- Layar Admin di Flutter (`pengajuan_admin_*`, `AppRole.admin`) setelah Admin web siap **[KEPUTUSAN Q16]**.
- ~~Data dummy di `MonitoringController` Laravel lama~~ — **selesai**, controller dihapus di Fase D.
- Tabel lama (bagian 1): kode sudah tidak memakainya, migrasi pembuangan menunggu Fase E.

---

## 10. Status implementasi dan keputusan Disperwaskim yang masih terbuka

**Sudah ada di kode (Fase A–D):** login dan peran dari backend; pengajuan, 18 slot berkas, nomor `SR-…` dari
server; penugasan dan laporan BA dengan foto geotag (maks 10, tanpa kompresi ulang, tanda tangan diverifikasi);
Web Admin pada tabel baru (nilai berkas, permintaan perbaikan, setujui administrasi, jadwal/alihkan survei, terima
laporan, keputusan akhir); riwayat, notifikasi dalam aplikasi, kirim revisi dari Flutter.

**Sudah ada:** tanda tangan BA oleh Ketua Pengawas dan Admin dengan unggahan visualisasi TTE Suresman (akun wajib ber-NIP), PDF final dari server, dan QR ke `/verifikasi/{token}` (lihat API_SPEC.md bagian 15). PDF dengan visualisasi TTE dianggap sah oleh Disperwaskim; format PDF BA mengikuti contoh resmi Disperwaskim (BA View Medina); letak blok tanda tangan Admin ("Mengetahui, Tim Verifikator") belum ada di contoh dan masih asumsi.

**Perlu konfirmasi:** letak tanda tangan Admin pada format BA resmi. Admin sudah bisa membatalkan penugasan survei (status `dibatalkan`, alasan wajib) dan menerbitkan BA (`published_at`). Tabel lama sudah punya migrasi pembuangan (`2026_10_26_140000`) tetapi baru hilang setelah `migrate` dijalankan;
push notification; layar timeline di Flutter; hari libur nasional pada SLA (SLA hari kerja Senin-Jumat sudah dihitung dan diingatkan oleh `pengajuan:ingatkan-tenggat`; angka diatur di halaman Pengaturan); unggah berkas keputusan oleh Admin;
pemisahan hak admin (bila Disperwaskim meminta dua role).

**Keputusan Disperwaskim yang terbuka.** Kolom kanan adalah asumsi sementara di kode, **bukan keputusan resmi**:

| Rujukan | Pertanyaan | Asumsi sementara di kode |
|---|---|---|
| Q04 | Nomor tahap 1 dan 6; `ditolak` final atau boleh diajukan ulang; arti `selesai` | Tahap 1 draf, 6 selesai; `ditolak` tidak final: pengembang boleh mengajukan ulang sebagai pengajuan baru (data disalin, berkas diunggah lagi) |
| Q05 | Nilai `decision_type`; apakah revisi wajib diperiksa ulang per berkas | `revisi`; berkas pengganti kembali `menunggu_telaah` dan dinilai ulang |
| Q06/Q07 | Slot mana yang wajib; hubungan 18 slot dengan DOC01–DOC16 | Semua wajib kecuali S3-10; pemetaan DOC belum dibuat |
| Q08 | Satu petugas atau tim; pengalihan dan pembatalan tugas | Satu petugas utama dengan anggota tim; pengalihan lewat jadwal ulang; pembatalan oleh Admin dengan alasan |
| Q09 | Penandatangan BA, arti final, siapa membuat PDF resmi | **Jawaban Disperwaskim (29 Okt 2026):** BA ditandatangani dua pihak, ketua pengawas lapangan (= petugas utama pilihan admin saat penjadwalan) lalu tim verifikator (Admin). Tanda tangan memakai **visualisasi TTE dari Suresman** (`suresman.tasikmalayakota.go.id/visualcustom`, didukung BSrE dan Diskominfo): penanda tangan memasukkan NIP di situs itu, mengunduh gambarnya, lalu mengunggahnya di aplikasi. **PDF final dengan visualisasi TTE dianggap sah; PDF tidak perlu ditandatangani ulang lewat BSrE.** BA terbit hanya setelah tanda tangan Ketua (aplikasi Flutter) dan Admin (Web Admin). Usulan tim: status Draf, Dikirim (`final`), Diverifikasi, Diterbitkan (`published_at`); PDF final dibuat server dengan QR. **Contoh format BA resmi sudah diterima (29 Okt 2026).** Belum jelas: letak blok tanda tangan Admin pada format itu |
| Q10 | Matriks hak Administrator vs Verifikator | Digabung menjadi satu role `admin`; semua tindakan tercatat dengan nama pelakunya di Riwayat |
| Q16 | Waktu penghentian layar Admin di Flutter | Dalam mode API, role web tidak bisa masuk lewat aplikasi dan layar Admin tidak terjangkau; kode prototipe masih ada untuk mode lokal |

**Keputusan bahwa persetujuan akhir sah** (setuju/tolak, nomor dan tanggal SK) saat ini dicatat oleh verifikator di
Web Admin. Apakah itu cukup sebagai keputusan resmi, atau perlu pejabat Disperwaskim menyetujui lebih dulu, adalah
keputusan Disperwaskim; data di sistem tidak boleh dianggap usulan administratif sebagai keputusan resmi sebelum itu.
