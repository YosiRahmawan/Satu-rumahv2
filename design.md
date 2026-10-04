# SATU RUMAH V2 — Product & UX Source of Truth

Versi: 1.1 · Tanggal: 3 Oktober 2026 · Lingkup perubahan: dokumentasi saja.

Dokumen ini menjadi acuan keputusan produk, UX, pembagian platform, serta visual SATU RUMAH V2. Dokumen ini tidak menetapkan prosedur pemerintah atau mengesahkan perilaku prototype sebagai aturan produksi. Bagian yang belum diputuskan ditandai **OPEN QUESTION**.

## Cara membaca dan sumber

| Label | Makna |
|---|---|
| **CONFIRMED** | Keputusan eksplisit pengguna atau konteks proyek yang diberikan. Untuk visual, nilai berasal dari master yang diminta pengguna sebagai acuan. |
| **EXISTING IMPLEMENTATION** | Perilaku kode/temuan audit prototype; bukan persetujuan requirement produksi. |
| **DOCUMENTED CONTEXT** | Konteks atau lingkup yang disebut README; bukan bukti fitur sudah berjalan atau aturan produksi telah disahkan. |
| **ASSUMPTION** | Asumsi kerja dokumentasi, bukan aturan sistem; belum terkonfirmasi tetap ditandai OPEN QUESTION. |
| **PROPOSAL** | Rekomendasi untuk ditinjau; belum menjadi keputusan. Bagian yang memerlukan keputusan tetap OPEN QUESTION. |
| **OPEN QUESTION** | Informasi atau keputusan belum tersedia; tidak boleh diterjemahkan menjadi izin, validasi, atau transisi baru. |

Urutan acuan: keputusan eksplisit pengguna terbaru → keputusan CONFIRMED dalam dokumen ini → master visual untuk aspek visual → README dan source sebagai bukti implementasi. Master visual tidak menjadi dasar kewenangan hukum, SLA, atau status bisnis. Perubahan keputusan berikutnya harus memperbarui bagian terkait, daftar keputusan, dan change log.

| ID sumber | Acuan lokal / asal | Pemakaian |
|---|---|---|
| S01 | Permintaan pengguna pada 3 Oktober 2026 | Platform per role, 19 bagian dokumentasi, larangan perubahan source code |
| S02 | Audit repository yang disertakan pengguna | Baseline alur, konflik, dan kesenjangan prototype; pemeriksaan statis, tanpa eksekusi aplikasi/test |
| S03 | `Design.md` yang tersedia pada awal penyusunan; isi asli dipertahankan di Lampiran A | DESIGN SYSTEM & PROMPT MASTER SPECIFICATION; sumber token visual |
| S04 | [README.md](README.md) | Konteks produk, fitur, stack, tiga role, dummy data |
| S05 | [app_router.dart](lib/core/router/app_router.dart), [route_policy.dart](lib/core/router/route_policy.dart) | Route Flutter dan batas akses halaman prototype |
| S06 | [pengajuan_form_controller.dart](lib/features/pengajuan/presentation/providers/pengajuan_form_controller.dart) | Tahapan form, key dokumen, submit lokal |
| S07 | [status_tahap_pengajuan.dart](lib/features/pengajuan/data/models/status_tahap_pengajuan.dart), [pengajuan_verifikasi_controller.dart](lib/features/pengajuan/presentation/providers/pengajuan_verifikasi_controller.dart) | Enum, guard, revisi, persetujuan Flutter |
| S08 | [jadwalkan_survey_modal.dart](lib/features/pengajuan/presentation/widgets/jadwalkan_survey_modal.dart) | Form jadwal dan pilihan petugas yang belum diteruskan |
| S09 | [monitoring_form_provider.dart](lib/features/monitoring/presentation/providers/monitoring_form_provider.dart), [laporan_preview_screen.dart](lib/features/monitoring/presentation/screens/laporan_preview_screen.dart), [ba_pdf_generator.dart](lib/features/monitoring/utils/ba_pdf_generator.dart) | Laporan, finalisasi lokal, preview dan PDF; dibaca dalam audit S02 |
| S10 | [PengajuanController.php](backend/app/Http/Controllers/Api/PengajuanController.php), [api.php](backend/routes/api.php), [Pengajuan.php](backend/app/Models/Pengajuan.php) | Potongan kontrak API dan alur backend |
| S11 | [DatabaseSeeder.php](backend/database/seeders/DatabaseSeeder.php), [satu_rumah.sql](backend/database/satu_rumah.sql) | Katalog dummy dan perbedaan struktur data dalam audit |
| S12 | [app_colors.dart](lib/core/theme/app_colors.dart), [app_text_styles.dart](lib/core/theme/app_text_styles.dart), [app_theme.dart](lib/core/theme/app_theme.dart) | Tema Flutter yang berbeda dari master visual |

Koreksi terhadap audit terdahulu: audit S02 menyatakan `design.md` tidak ditemukan. Pada pembacaan 3 Oktober 2026, `Design.md` tersedia sebagai file lokal belum dilacak Git dan berisi master visual. Dokumen tersebut dikembangkan menjadi file ini; namanya dinormalisasi menjadi `design.md`. Tidak dibuat dua file yang hanya berbeda kapitalisasi.

## 1. Product context

**DOCUMENTED CONTEXT S04:** SATU RUMAH V2 merupakan sistem layanan publik untuk pengajuan dan penyerahan Prasarana, Sarana, dan Utilitas Umum (PSU) perumahan Kota Tasikmalaya, dikembangkan bersama Diskominfo dan Disperwaskim. Tujuan produk: membantu pengembang mengajukan dan memperbaiki berkas, Admin mengelola verifikasi dan proses persetujuan, serta Tim Lapangan mencatat hasil survey dan menyiapkan Berita Acara.

| Area | Keputusan / kondisi |
|---|---|
| Mobile | **CONFIRMED S01:** Flutter mobile untuk Pengembang dan Tim Lapangan. **DOCUMENTED CONTEXT S04:** Flutter 3.x / Dart, Riverpod 2.x, GoRouter; penetapan versi produksi **OPEN QUESTION Q16** |
| Web Admin dan backend | **CONFIRMED S01:** Laravel Web Admin untuk Admin. **DOCUMENTED CONTEXT S04:** Laravel 11 / PHP 8.3; versi backend belum dapat diverifikasi dari checkout dan penetapan versi produksi **OPEN QUESTION Q16** |
| PDF dan berbagi | **EXISTING IMPLEMENTATION S02:** dependency `pdf`, `printing`, `share_plus`; kesiapan lampiran PDF produksi **OPEN QUESTION Q09/Q16** |
| Data | **DOCUMENTED CONTEXT S04 / EXISTING IMPLEMENTATION S02:** prototype lokal/dummy; README menyebut target integrasi Laravel API, dengan kontrak produksi **OPEN QUESTION Q16** |
| Kesiapan backend | **EXISTING IMPLEMENTATION:** potongan controller, model, middleware, migration, seeder; audit belum menemukan `composer.json`, `artisan`, bootstrap aplikasi, atau UI Web Admin |
| Batas layanan | **OPEN QUESTION Q01:** hubungan pengajuan PSU, persetujuan site plan, dan istilah perizinan dalam prototype |
| Nama panjang produk/instansi | **OPEN QUESTION Q02:** README dan master memakai kepanjangan SATU RUMAH serta nama dinas yang berbeda; gunakan nama SATU RUMAH V2 dan Disperwaskim sampai redaksi resmi dipastikan |

Tidak ada dasar untuk menjanjikan waktu layanan, menganggap persetujuan aplikasi sebagai pengesahan hukum, atau menetapkan dokumen wajib hanya dari nama field prototype.

## 2. User roles

| Role | Tujuan pengguna — DOCUMENTED CONTEXT S04 | Informasi yang berkaitan dengan tugas | Batas yang belum diputuskan |
|---|---|---|---|
| Pengembang | Mengajukan PSU, mengunggah dokumen, melacak status, menanggapi revisi | Data perumahan, berkas pengajuan, status dan catatan revisi | **OPEN QUESTION Q03/Q06:** cakupan organisasi/akun, akses BA/SK, field wajib |
| Admin Disperwaskim | Memverifikasi, menyetujui/meminta revisi/menolak, menjadwalkan survey, menugaskan petugas, mengelola workflow | Antrean pengajuan, dokumen, hasil survey, alasan keputusan | **OPEN QUESTION Q03/Q04/Q09:** batas tiap tindakan, pengesahan final, pembagian kewenangan internal |
| Tim Perwaskim Lapangan | Melaksanakan survey, mencatat temuan, mengambil foto bukti, menyiapkan BA | Penugasan, lokasi/perumahan, temuan, foto, bahan BA | **OPEN QUESTION Q03/Q08/Q09:** cakupan tugas, laporan mandiri, penandatanganan/finalisasi |

Menyetujui tahap administratif tidak otomatis berarti berwenang menandatangani BA atau menerbitkan SK. Dokumen ini tidak menambahkan role pejabat atau role pengelola pengguna baru.

## 3. Platform per role

| Role | Platform produksi — CONFIRMED S01 | Keadaan prototype — EXISTING IMPLEMENTATION |
|---|---|---|
| Pengembang | Flutter mobile | Area Pengembang pada Flutter |
| Admin Disperwaskim | Laravel Web Admin | Area Admin masih berada pada Flutter; Web Admin belum tersedia dalam audit |
| Tim Perwaskim Lapangan | Flutter mobile | Area Monitoring/Lapangan pada Flutter |

Keputusan ini menggantikan teks master lama yang memasukkan Tim Pengawas Perwaskim ke Web Desktop. Acuan desktop pada master berlaku untuk Admin; adaptasi layar Tim Lapangan mobile masih **OPEN QUESTION Q13**. Keberadaan route Admin Flutter tidak menjadikannya target produksi. Jadwal migrasi dan penghentian area Admin prototype masih **OPEN QUESTION Q16**.

## 4. Role-permission matrix

**C = cakupan tanggung jawab yang disebut README (DOCUMENTED CONTEXT S04), bukan izin produksi yang telah disahkan. OQ = OPEN QUESTION; bukan izin dan bukan penolakan akses.** Setiap cakupan objek, kepemilikan, organisasi, serta kondisi tahap perlu keputusan Q03. Tidak ada izin lintas role yang disimpulkan dari tabel ini. Platform per role saja yang telah dikonfirmasi secara eksplisit pada bagian 3.

| Tindakan | Pengembang mobile | Admin web | Tim Lapangan mobile | Batas / keputusan tertunda |
|---|---|---|---|---|
| Membuat pengajuan PSU | C | OQ | OQ | Pembuatan atas nama pihak lain: Q03 |
| Mengunggah dokumen pengajuan | C | OQ | OQ | Jenis, tahap edit, kepemilikan: Q03/Q06 |
| Memantau pengajuan | C | C untuk workflow | OQ | Akses lintas akun dan detail lampiran: Q03 |
| Memverifikasi dokumen | OQ | C | OQ | Per dokumen/tahap dan verifikasi ulang: Q05 |
| Meminta revisi | OQ | C | OQ | Tahap yang mendukung revisi: Q05 |
| Mengirim perbaikan | C | OQ | OQ | Dokumen/field yang dapat diubah: Q05 |
| Menyetujui atau menolak | OQ | C | OQ | Guard, finalitas penolakan, delegasi: Q04 |
| Menjadwalkan dan menugaskan survey | OQ | C | OQ | Satu petugas/tim, ubah jadwal: Q08 |
| Melakukan survey, mencatat temuan/foto | OQ | OQ | C | Hanya tugas sendiri atau tugas tim: Q03/Q08 |
| Menyiapkan BA | OQ | OQ | C | Jenis BA, template, tahapan final: Q09 |
| Memeriksa/menandatangani/mengesahkan BA | OQ | OQ | OQ | Q09 |
| Mengunggah/menerbitkan/mengesahkan SK | OQ | OQ | OQ | Q09 |
| Melihat, mencetak, mengunduh, membagikan BA/SK | OQ | OQ | OQ | Fitur PDF tersedia; izin per berkas/role: Q03/Q09 |
| Membuka kembali pengajuan selesai; menghapus data | OQ | OQ | OQ | Q04/Q15 |

**EXISTING IMPLEMENTATION:** pembatasan route Flutter tersedia, tetapi Pengajuan Saya memakai daftar lokal bersama; audit endpoint detail belum menemukan pemeriksaan kepemilikan dalam metode tersebut. Kebijakan akses data produksi tetap **OPEN QUESTION Q03**, bukan mengikuti data dummy.

## 5. End-to-end business workflow

**DOCUMENTED CONTEXT S04 pada tingkat aktivitas:** pengembang mengajukan → Admin memverifikasi dan mengelola tindak lanjut → Admin menjadwalkan/menugaskan survey → Tim Lapangan melakukan survey dan menyiapkan BA → proses persetujuan dikelola Admin. Urutan resmi, pengulangan, prasyarat, dan bukti selesai tetap **OPEN QUESTION Q04/Q05/Q08/Q09**.

Peta berikut adalah **EXISTING IMPLEMENTATION Flutter S02/S06/S07**, bukan SOP produksi:

```text
Login → Beranda sesuai role
Pengembang: data perumahan → dokumen perusahaan → administrasi perumahan
            → dokumen teknis → review/pernyataan → kirim
Admin: verifikasi administrasi → verifikasi teknis → jadwalkan survey
Tim Lapangan: survey → temuan/evaluasi/tindak lanjut → foto/pihak terkait
              → preview BA → submit laporan
Admin: pemeriksaan hasil survey → persetujuan → selesai
Cabang revisi: permintaan perbaikan → pengembang mengirim ulang → tahap asal
```

| Fitur / tujuan | Role dan tindakan pengguna | Respons sistem yang ditemukan | Izin, validasi, transisi produksi |
|---|---|---|---|
| Masuk dan mencapai ruang kerja | Semua role: login | Role dipilih berdasarkan username; session memori; redirect route | **OPEN QUESTION Q03/Q14:** autentikasi, penerbitan akun dan session |
| Mengirim permohonan | Pengembang: isi 5 langkah, pilih berkas, review, kirim | Menyimpan data lokal dan masuk verifikasi administrasi | Bagian 4, 6, 10; field wajib dan pernyataan: **OPEN QUESTION Q06** |
| Menilai kelengkapan/kesesuaian | Admin: buka detail/dokumen, tandai hasil, setujui/minta revisi | Status verifikasi per dokumen dan guard Flutter | Bagian 6–7; **OPEN QUESTION Q04/Q05** |
| Mengatur pelaksanaan survey | Admin: pilih tanggal, petugas, catatan | Tanggal/catatan disimpan; identitas pilihan petugas belum diteruskan | Bagian 8; **OPEN QUESTION Q08** |
| Mencatat kondisi lapangan | Tim Lapangan: isi laporan, temuan, foto, evaluasi | Laporan lokal, draft/final, referensi BA | Bagian 9; **OPEN QUESTION Q08/Q09/Q11** |
| Menyelesaikan proses | Admin pada prototype: evaluasi BA dan referensi SK, approve | Guard berbeda dari backend | **OPEN QUESTION Q04/Q09:** pelaku pengesahan dan kriteria selesai |

Struktur layar tercantum pada bagian 13, keadaan antarmuka pada bagian 14, dan komponen pada bagian 15. Aturan visual dibaca setelah cakupan fitur dan ketidakpastiannya.

## 6. Status transition model

### 6.1 Kamus status prototype

Seluruh baris berikut berlabel **EXISTING IMPLEMENTATION S07**. Nama API produksi dan status resmi masih **OPEN QUESTION Q04**.

| Nilai enum | Label UI saat ini | Catatan |
|---|---|---|
| `pengajuanBaru` | Pengajuan Baru | Ada di enum; submit normal melewatinya |
| `verifikasiAdministrasi` | Verifikasi Administrasi | Status setelah submit normal |
| `verifikasiTeknis` | Verifikasi Teknis | Kelanjutan verifikasi administrasi |
| `surveyLapangan` | Survey Lapangan | Dicapai melalui penjadwalan pada Flutter |
| `persetujuan` | Persetujuan | Dicapai setelah guard survey lolos |
| `selesai` | Selesai | Akhir alur normal prototype |
| `perluPerbaikan` | Perlu Perbaikan | Cabang revisi; tahap asal disimpan |

### 6.2 Transisi dan guard yang ditemukan

| Dari → ke | Pemicu prototype | Guard / perilaku Flutter | Keputusan produksi |
|---|---|---|---|
| Form → `verifikasiAdministrasi` | Pengembang kirim | Validasi form lokal dan pernyataan | **OPEN QUESTION Q04/Q06:** status awal dan syarat pengajuan |
| `pengajuanBaru` → `verifikasiAdministrasi` | Admin approve | Tersedia dalam controller | **OPEN QUESTION Q04:** apakah tahap baru diperlukan |
| `verifikasiAdministrasi` → `verifikasiTeknis` | Admin approve | Dokumen administratif wajib tersedia/terverifikasi; revisi terkirim dapat melewati verifikasi ulang per dokumen | **OPEN QUESTION Q05:** pengecualian revisi belum disahkan |
| `verifikasiTeknis` → `surveyLapangan` | Admin jadwalkan | Dokumen teknis terverifikasi; approval biasa diblokir dan diarahkan ke jadwal | **OPEN QUESTION Q04/Q08:** guard teknis dan penugasan |
| `surveyLapangan` → `persetujuan` | Admin approve | Laporan final, referensi BA, evaluasi sesuai | **OPEN QUESTION Q04/Q09:** bukti sah dan hasil evaluasi yang dapat dilanjutkan |
| `persetujuan` → `selesai` | Admin approve | Referensi SK tersedia | **OPEN QUESTION Q04/Q09:** apakah referensi file cukup dan siapa berwenang |
| Tahap proses → `perluPerbaikan` | Admin minta revisi | Catatan, dokumen revisi, tahap asal disimpan | **OPEN QUESTION Q05:** daftar tahap yang boleh meminta revisi |
| `perluPerbaikan` → tahap asal | Pengembang kirim revisi | `revisionSubmitted = true`; edit dikunci sambil menunggu Admin | **OPEN QUESTION Q05:** status, penguncian, dan pemeriksaan ulang |
| `selesai` → tidak ada transisi | Tidak tersedia | Approval lanjutan diblokir | **OPEN QUESTION Q04:** pembukaan kembali/pembatalan |
| Penolakan | Disebut dalam lingkup fitur | Tidak ada enum terminal `ditolak` | **OPEN QUESTION Q04:** final atau dapat diajukan ulang; tidak menambahkan transisi |

### 6.3 Konflik yang menghalangi kontrak produksi

**EXISTING IMPLEMENTATION:** `approveTahap()` backend membaca `$pengajuan` sebelum inisialisasi. Backend belum menyamai guard BA/evaluasi/SK Flutter dan memiliki jalur teknis yang berbeda. Nilai evaluasi perlu evaluasi lanjutan belum diperlakukan konsisten. Kondisi `revisionSubmitted`, hasil verifikasi dokumen, status laporan draft/final, dan keberadaan berkas adalah data berbeda; tidak boleh dianggap satu status yang setara.

**OPEN QUESTION Q04/Q05/Q09/Q16:** satu tabel transisi resmi beserta aktor, prasyarat, hasil, alasan blokir, dan efek notifikasi perlu disepakati sebelum integrasi. Rasio progress tetap dalam enum prototype bukan ukuran waktu/SLA atau persentase layanan yang terkonfirmasi.

## 7. Revision flow

**DOCUMENTED CONTEXT S04:** Admin meminta revisi; Pengembang menanggapi. Kewenangan produksi mengikuti **OPEN QUESTION Q03/Q05**. **EXISTING IMPLEMENTATION S02/S07:**

```text
Admin buka pengajuan → pilih dokumen/catatan perbaikan → kirim permintaan
→ perluPerbaikan + tahap asal
Pengembang buka catatan → pilih pengganti dokumen yang diminta → kirim revisi
→ kembali ke tahap asal + revisionSubmitted=true
→ menunggu tindakan Admin; perubahan dokumen dikunci oleh prototype
```

| Aspek | Spesifikasi yang tersedia | Keputusan tertunda |
|---|---|---|
| Informasi | Catatan, dokumen yang diminta, tahap asal, indikator revisi terkirim | **OPEN QUESTION Q05:** alasan per berkas vs keseluruhan, versi lama/baru, riwayat putaran |
| Tindakan pengguna | Admin meminta; Pengembang mengganti dan mengirim | **OPEN QUESTION Q05:** edit data non-dokumen, tarik kembali kiriman |
| Tindakan sistem | Mengubah metadata revisi dan status lokal | **OPEN QUESTION Q05/Q16:** kontrak API, versi, konflik perubahan |
| Izin | Tanggung jawab role sesuai bagian 4 | **OPEN QUESTION Q03/Q05:** akses versi dokumen, batas edit |
| Validasi | Pemeriksaan lokal berkas pengganti menurut audit | **OPEN QUESTION Q05/Q06:** wajib verifikasi ulang, syarat kirim, tenggat/putaran |
| Survey ulang | Belum memiliki kebijakan yang terkonfirmasi | **OPEN QUESTION Q05/Q08:** revisi dokumen saja atau pemeriksaan lapangan lagi |
| Struktur layar | Detail pengajuan → catatan revisi → slot terkait → aksi kirim; komponen status dan upload | Perbandingan versi dan susunan Web Admin: **OPEN QUESTION Q05/Q13** |
| UI states | Menunggu perbaikan dan menunggu keputusan tersedia sebagai perilaku lokal | Kegagalan kirim, data usang, retry produksi: **OPEN QUESTION Q11/Q16**, lihat bagian 14 |

Persetujuan langsung atas revisi administrasi pada Flutter dicatat sebagai konflik, bukan aturan yang direkomendasikan.

## 8. Survey assignment flow

**DOCUMENTED CONTEXT S04:** Admin menjadwalkan survey dan menugaskan Tim Lapangan. **CONFIRMED S01:** platform Admin adalah Web Admin dan Tim Lapangan adalah Flutter mobile. Jumlah anggota tim, ketua, penerimaan tugas, dan penggantian petugas masih **OPEN QUESTION Q08**.

**EXISTING IMPLEMENTATION S08:** detail pengajuan → modal jadwal → pilih tanggal/petugas/catatan → simpan. `_selectedPerwaskimId` tidak disertakan dalam callback simpan; daftar tugas aktif belum memfilter identitas petugas menurut audit.

| Aspek | Informasi / perilaku yang tersedia | OPEN QUESTION |
|---|---|---|
| Hubungan data | Pengajuan, tanggal survey, pilihan petugas, catatan | Q08: satu pengajuan dapat memiliki berapa penugasan/survey? |
| Aktor | Admin mengatur; Tim Lapangan melaksanakan | Q03/Q08: visibilitas tugas antaranggota/tim, hak ubah jadwal |
| Aksi dan sistem | UI memilih petugas, tetapi penyimpanan penugasan belum utuh | Q08/Q16: identitas petugas/tim, pengiriman, pembaruan, dan pembatalan |
| Validasi | Guard teknis Flutter sebelum penjadwalan | Q08: tanggal/jam, bentrok, ketersediaan, kelengkapan instruksi |
| Transisi | Penjadwalan membawa pengajuan ke survey pada Flutter | Q04/Q08: status penugasan terpisah dari status pengajuan? |
| Laporan mandiri | Tombol Tambah Laporan Baru tersedia; pengaitan mencoba ID atau nama | Q08: apakah laporan tanpa tugas diizinkan, dan apa relasi resminya? |
| Struktur layar | Admin: detail dan form jadwal; Lapangan: daftar tugas → mulai survey → form laporan | Q13: susunan form Web Admin dan detail tugas mobile |
| UI states | Form pilih petugas belum membuktikan tugas tersimpan | Q08/Q11: tidak ada petugas, gagal simpan, jadwal berubah, tugas tidak lagi tersedia |

**OPEN QUESTION Q08/Q16:** keberhasilan penjadwalan produksi harus didefinisikan bersama kontrak penyimpanan dan notifikasi; label tombol “Jadwalkan & Kirim Notifikasi” bukan bukti pengiriman berhasil.

## 9. BA/SK flow

**DOCUMENTED CONTEXT S04:** Tim Lapangan menangani Berita Acara; kemampuan PDF/cetak/berbagi disebut sebagai lingkup fitur. **OPEN QUESTION Q09:** penyiapan dokumen, finalisasi laporan, penandatanganan, dan penerbitan resmi belum dapat disamakan atau ditetapkan kewenangannya dari README.

| Tahap / artefak | EXISTING IMPLEMENTATION S02/S07/S09 | Aturan produksi |
|---|---|---|
| Bahan laporan | Informasi umum, temuan, evaluasi, tindak lanjut, foto, pihak terkait | **OPEN QUESTION Q09:** field wajib dan template resmi |
| Evaluasi | Sesuai, tidak sesuai, perlu evaluasi lanjutan; dua nilai terakhir mewajibkan tindak lanjut dalam kode | **OPEN QUESTION Q04/Q09:** terminologi dan pengaruh terhadap keputusan |
| Preview BA | Preview draft dan laporan tersedia | **OPEN QUESTION Q09:** jenis BA survey vs BA penyerahan, penomoran, redaksi |
| Submit/final laporan | Membentuk string nama PDF sebagai referensi BA | **OPEN QUESTION Q09/Q16:** arti final, penyimpanan berkas nyata, versi |
| BA untuk persetujuan | Flutter memeriksa laporan final, referensi BA, dan evaluasi sesuai | **OPEN QUESTION Q04/Q09:** pemeriksa, penandatangan, pengesahan |
| SK | Referensi SK menjadi guard selesai pada Flutter | **OPEN QUESTION Q09:** pembuat, pengunggah, penerbit, penandatangan dan validasi |
| PDF/cetak | PDF dibuat melalui generator dan alur cetak | **OPEN QUESTION Q09:** akses, arsip, format final, lampiran |
| Berbagi | Preview BA berbagi ringkasan teks menurut audit, bukan lampiran PDF | **OPEN QUESTION Q09/Q16:** kontrak berbagi file dan akses penerima |

Alur yang dapat didokumentasikan saat ini: **Tim Lapangan mengisi laporan → preview → submit lokal → Admin memeriksa hasil pada prototype**. Langkah resmi penandatanganan BA, penerbitan SK, dan penyerahan final adalah **OPEN QUESTION Q09**; tidak ditambahkan aktor atau urutan rekaan.

Struktur layar yang ada: form laporan bertahap → preview → sukses → riwayat/preview/cetak. UI Web Admin untuk pemeriksaan artefak, status berkas gagal dibuat, gagal diunduh/dibagikan, serta hak edit setelah final adalah **OPEN QUESTION Q09/Q13/Q16**. Komponen yang relevan: metadata berkas, viewer, status laporan, hasil evaluasi, dan aksi PDF.

## 10. DOC01–DOC16 mapping placeholder

**CONFIRMED S01:** dokumentasi menyediakan 16 placeholder DOC01–DOC16 sesuai permintaan pengguna; README juga menyebut 16 slot. Jumlah placeholder dan nomor slot tidak menetapkan jumlah persyaratan produksi, nama dokumen, urutan prosedur, atau kewajibannya. Semua isi pemetaan berikut **OPEN QUESTION Q06/Q07**; jangan memetakan berdasarkan urutan array/seeder.

| Slot | Nama resmi | Key Flutter / ID API | Wajib / kondisional | Format, ukuran, jumlah berkas | Tahap / pemeriksa |
|---|---|---|---|---|---|
| DOC01 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC02 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC03 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC04 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC05 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC06 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC07 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC08 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC09 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC10 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC11 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC12 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC13 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC14 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC15 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |
| DOC16 | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION | OPEN QUESTION |

Inventaris teknis terpisah — **EXISTING IMPLEMENTATION S06**, tidak dipasangkan ke DOC:

| Kelompok form saat ini | Key yang dibaca validasi |
|---|---|
| Dokumen perusahaan | `ktp`, `nib`, `npwp_doc`, `asosiasi`, `legalitas` |
| Administrasi perumahan | `surat_permohonan`, `info_intensitas_ruang`, `bukti_kepemilikan_lahan`, `bukti_tpu`, `kkpr_doc`, `pbg_induk`, `rekomendasi_lingkungan`, `pernyataan_pelepasan`, `pernyataan_keabsahan`, `pernyataan_psu` |
| Teknis | `site_plan_dwg` atau isi `technicalFiles`; ada `selectedCakupanGambar` |
| Tambahan | `pelepasan_lahan` opsional di Flutter; `drainase_doc` tambahan dalam seeder menurut audit |

**OPEN QUESTION Q07:** apakah tambahan tersebut bagian dari 16 slot, lampiran kondisional, atau data prototype yang tidak dipakai? Penetapan label resmi dan persyaratan perlu acuan Disperwaskim.

## 11. Information architecture

| Ruang kerja | Struktur informasi yang dapat dipetakan | Status |
|---|---|---|
| Pengembang mobile | Beranda; Pengajuan (daftar, detail, form bertahap, catatan revisi); Notifikasi; Profil | **EXISTING IMPLEMENTATION** dan empat menu sesuai master |
| Admin web | Domain tugas: pengajuan/verifikasi; penjadwalan/penugasan; hasil survey/BA; proses persetujuan | Tanggung jawab **DOCUMENTED CONTEXT S04**; pengelompokan menu, halaman khusus SK, notifikasi/profil web **OPEN QUESTION Q13** |
| Tim Lapangan mobile | Beranda/penugasan; laporan monitoring; riwayat; preview BA; profil; akses notifikasi | **EXISTING IMPLEMENTATION**; IA produksi **OPEN QUESTION Q13** |

Entitas yang ditemukan: pengajuan, dokumen, hasil verifikasi, metadata revisi, jadwal, laporan monitoring, hasil evaluasi, referensi BA/SK, notifikasi, session role. Hubungan produksi, ID stabil, kepemilikan, versi, dan riwayat audit adalah **OPEN QUESTION Q03/Q15/Q16**. Pencocokan nama perumahan dalam prototype tidak disahkan sebagai relasi data produksi.

## 12. Navigation model

| Platform / role | Model yang tersedia | Batas keputusan |
|---|---|---|
| Pengembang mobile | **CONFIRMED acuan visual S03:** Beranda, Pengajuan, Notifikasi, Profil; bottom bar putih 64px pada master dan FAB tengah `+ AJUKAN` | Penerjemahan ukuran master ke Flutter, safe area, keyboard: **OPEN QUESTION Q13/Q17** |
| Admin web | **CONFIRMED acuan visual S03:** sidebar 260px, utility navbar 64px, breadcrumb | Daftar menu, route web, responsif di luar rentang master: **OPEN QUESTION Q13** |
| Tim Lapangan mobile | **EXISTING IMPLEMENTATION:** home, riwayat, profil dan route notifikasi | Susunan navigasi produksi dan CTA utama: **OPEN QUESTION Q13**; FAB Pengembang tidak otomatis berlaku |
| Masuk/tautan | **EXISTING IMPLEMENTATION:** splash → onboarding → login; redirect sesuai role dan halaman fallback | Onboarding per role, session berakhir, deep link lintas platform: **OPEN QUESTION Q14** |

Route Flutter yang menjadi referensi, bukan kontrak URL produksi: `/dashboard`, `/pengajuan/step1` sampai `/pengajuan/step5`, `/pengajuan/detail/:id`, `/pengajuan/success`, `/admin`, `/admin/pengajuan`, `/admin/pengajuan/detail/:id`, `/monitoring/lapangan`, `/monitoring/lapangan/riwayat`, `/monitoring/tambah`, `/monitoring/preview`, `/monitoring/success`. Sumber: S05.

**EXISTING IMPLEMENTATION:** `/dashboard` memakai `DashboardScreen`; `DeveloperMainScreen` belum menjadi route beranda aktif pada pembacaan ini. Menentukan halaman acuan implementasi berikutnya adalah **OPEN QUESTION Q16**.

## 13. Screen inventory

ID di bawah adalah indeks dokumentasi, bukan nama route baru. Struktur layar Flutter merangkum implementasi/audit; struktur Web Admin yang belum tersedia ditandai OPEN QUESTION.

| ID | Role / platform target | Layar dan tujuan | Struktur informasi / aksi | Bukti dan status |
|---|---|---|---|---|
| AUTH-01 | Mobile | Splash, onboarding, login | Identitas produk, pengantar, form masuk | Flutter tersedia; alur produksi **OPEN QUESTION Q14** |
| AUTH-02 | Admin web | Masuk Web Admin | Metode autentikasi dan pemulihan akun **OPEN QUESTION Q14** | Belum tersedia dalam audit |
| DEV-01 | Pengembang mobile | Beranda | Ringkasan pengajuan dan akses tugas | `dashboard_screen.dart`; **EXISTING IMPLEMENTATION** |
| DEV-02 | Pengembang mobile | Pengajuan Saya | Pencarian/filter, daftar dan akses detail | `pengajuan_saya_list_screen.dart`; pembatasan data **OPEN QUESTION Q03** |
| DEV-03 | Pengembang mobile | Form data perumahan | Nama, NPWP perusahaan, luas, unit, tipe | `pengajuan_step1_screen.dart`; kewajiban field **OPEN QUESTION Q06** |
| DEV-04 | Pengembang mobile | Form dokumen perusahaan | Kelompok slot upload | `pengajuan_step2_screen.dart`; pemetaan **OPEN QUESTION Q07** |
| DEV-05 | Pengembang mobile | Form administrasi perumahan | Kelompok slot upload | `pengajuan_step3_screen.dart`; kondisi dokumen **OPEN QUESTION Q07** |
| DEV-06 | Pengembang mobile | Form teknis | Berkas teknis dan cakupan gambar | `pengajuan_step4_screen.dart`; aturan multi-file **OPEN QUESTION Q06/Q07** |
| DEV-07 | Pengembang mobile | Review dan kirim | Ringkasan, pernyataan, aksi submit | `pengajuan_step5_review_screen.dart`; redaksi pernyataan **OPEN QUESTION Q06** |
| DEV-08 | Pengembang mobile | Sukses pengajuan | ID pengajuan dan akses lanjutan | `pengajuan_success_screen.dart`; **EXISTING IMPLEMENTATION** |
| DEV-09 | Pengembang mobile | Detail dan revisi | Status, berkas, catatan, tindakan revisi | `pengajuan_detail_screen.dart`; bagian 7 |
| ADM-01 | Admin web | Antrean pengajuan/verifikasi | Tugas mengacu README; kolom tabel, filter, urutan **OPEN QUESTION Q13** | Referensi Flutter: `pengajuan_admin_list_screen.dart`; web belum tersedia |
| ADM-02 | Admin web | Detail verifikasi | Dokumen, hasil periksa, alasan, tindakan; susunan web **OPEN QUESTION Q13** | Referensi Flutter: `pengajuan_admin_detail_screen.dart`; keputusan tahap Q04/Q05 |
| ADM-03 | Admin web | Penjadwalan/penugasan | Pengajuan, jadwal, petugas/tim, instruksi; bentuk layar **OPEN QUESTION Q08/Q13** | Referensi modal Flutter S08 |
| ADM-04 | Admin web | Pemeriksaan survey/BA dan persetujuan | Hasil survey dan artefak; pemisahan layar serta aksi SK **OPEN QUESTION Q09/Q13** | Referensi detail Admin/hasil survey Flutter |
| FLD-01 | Tim Lapangan mobile | Beranda/penugasan | Tugas aktif dan mulai survey | `monitoring_main_screen.dart`, `tab_beranda_monitoring.dart`; Q08 |
| FLD-02 | Tim Lapangan mobile | Form laporan bertahap | Umum, temuan, evaluasi, tindak lanjut, foto/pihak terkait | `tambah_monitoring_stepper_screen.dart`; field wajib **OPEN QUESTION Q09** |
| FLD-03 | Tim Lapangan mobile | Preview BA | Isi laporan, preview, submit/cetak/berbagi sesuai konteks prototype | `laporan_preview_screen.dart`; akses dan finalisasi Q09 |
| FLD-04 | Tim Lapangan mobile | Sukses laporan | Hasil submit dan akses laporan | `laporan_success_screen.dart`; **EXISTING IMPLEMENTATION** |
| FLD-05 | Tim Lapangan mobile | Riwayat laporan | Daftar dan preview | `monitoring_list_screen.dart`; keakuratan draft/final perlu penyelarasan |
| SHARED-01 | Mobile | Notifikasi | Daftar pemberitahuan dan akses objek terkait | Implementasi lokal bersama; target/penerima **OPEN QUESTION Q10** |
| SHARED-02 | Mobile | Profil | Identitas/session role | Implementasi tersedia; field/edit/akun **OPEN QUESTION Q03/Q14** |

Nama file layar pengajuan berada di `lib/features/pengajuan/presentation/screens/`; monitoring di `lib/features/monitoring/presentation/screens/` atau `widgets/`; dashboard di `lib/features/dashboard/presentation/screens/`. Tidak ada layar yang dibuat atau diubah melalui dokumen ini.

## 14. UI states, forms, upload, validation, notifications, accessibility

### 14.1 Loading / empty / error / success

**PROPOSAL — OPEN QUESTION Q11/Q13:** status jelas, struktur form panjang mudah dipahami, progres upload terlihat, upload gagal dapat dicoba lagi, perhatian terhadap jaringan lemah, dan modal seperlunya. Ini rekomendasi UX untuk ditinjau; kebutuhan produksi belum dikonfirmasi. Tabel berikut memisahkan pola prototype dari keadaan UI yang perlu diputuskan.

| Konteks | Loading | Empty | Error | Success | Status / keputusan |
|---|---|---|---|---|---|
| Daftar/detail | Indikator pemuatan | Keadaan kosong | Pesan gagal dan retry | Data/objek ditampilkan | **EXISTING IMPLEMENTATION:** pola tersedia, termasuk retry monitoring; pemetaan setiap layar **OPEN QUESTION Q13** |
| Form pengajuan | Proses kirim | Field/slot belum diisi | Kesalahan input/kirim | Halaman sukses | Form lokal tersedia; ketahanan input setelah gagal **OPEN QUESTION Q06/Q11** |
| Upload | Usulan progres per berkas | Slot belum berisi | Usulan pesan gagal dan retry | Arti “terunggah” harus ditetapkan | **PROPOSAL — OPEN QUESTION Q06/Q11/Q16:** progres, retry, status API, cancel/resume/timeout |
| Verifikasi/revisi | Sedang menyimpan keputusan | Tidak ada objek/catatan | Alasan guard memblokir | Status/metadata berubah | Guard lokal tersedia; konflik update/submit berulang **OPEN QUESTION Q05/Q16** |
| Penugasan | Memuat petugas/menyimpan | Tidak ada petugas/tugas | Gagal simpan/jadwal berubah | Tugas tersimpan dan dapat diakses | Perilaku produksi **OPEN QUESTION Q08/Q16** |
| Laporan/BA/SK | Menyimpan/membuat/membuka berkas | Artefak belum tersedia | Gagal simpan/generate/download/share | Hasil operasi dan artefak tersedia | Definisi keberhasilan tiap operasi **OPEN QUESTION Q09/Q16** |
| Jaringan/session | Status pemuatan atau koneksi | Tidak disamakan dengan daftar kosong | Jaringan putus/session berakhir/akses tidak tersedia | Pemulihan operasi | Draft persisten, offline, retry aman **OPEN QUESTION Q11/Q14/Q16** |

Kata “tersimpan”, “terkirim”, “terverifikasi”, “laporan final”, dan “ditandatangani” memiliki makna berbeda. String path lokal tidak membuktikan berkas produksi tersedia. Copy final untuk setiap hasil operasi adalah **OPEN QUESTION Q13/Q16**.

### 14.2 Forms dan validation

| Area | EXISTING IMPLEMENTATION | Requirement produksi |
|---|---|---|
| Data perumahan | Nama/NPWP tidak kosong; luas finite positif; unit positif | **OPEN QUESTION Q06:** format NPWP, satuan, rentang, pilihan tipe, field resmi |
| Dokumen | Validasi berdasarkan key pada bagian 10; teknis dapat multi-file | **OPEN QUESTION Q06/Q07:** format, ukuran, jumlah, kondisi wajib dan cakupan gambar |
| Review | Checkbox pernyataan sebelum kirim | **OPEN QUESTION Q06:** redaksi, pihak yang menyatakan, konsekuensi |
| Revisi | Berkas pengganti dan metadata tahap asal | **OPEN QUESTION Q05:** validasi ulang dan penguncian |
| Survey | Pilihan hasil evaluasi dan tindak lanjut | **OPEN QUESTION Q08/Q09:** nilai resmi, field wajib, hubungan penugasan |
| API | `StorePengajuanRequest` ada, tetapi controller menggunakan `Request` biasa menurut audit | **OPEN QUESTION Q16:** kontrak validasi tunggal dan format error per field |

Tidak menyalin batas ukuran/ekstensi dari label UI sebagai aturan resmi; audit menemukan label dan pemeriksaan picker belum konsisten.

### 14.3 Upload dan jaringan lemah

**EXISTING IMPLEMENTATION:** pemilihan berkas menggunakan nama/path lokal; belum ditemukan antrean upload, sinkronisasi, atau draft persisten dalam audit. **OPEN QUESTION Q06/Q11/Q16:** kapan slot dianggap lengkap, cara menyimpan versi, jumlah upload bersamaan, retry, file yang hilang dari perangkat, kelanjutan sesudah aplikasi ditutup, dan penanganan kiriman yang responsnya terputus. Target UX progres dan retry tidak berarti dukungan offline sudah diimplementasikan.

### 14.4 Notifications

**DOCUMENTED CONTEXT S04:** notifikasi disebut sebagai fitur produk. **EXISTING IMPLEMENTATION:** data lokal bersama; tidak semua approval membuat notifikasi. Klaim real-time pada README belum membuktikan kemampuan produksi.

**OPEN QUESTION Q10:** matriks event → penerima → kanal → isi → objek tujuan, status dibaca per akun, pengiriman ulang, waktu kirim, dan perlakuan terhadap jadwal berubah/revisi/BA/SK. Jenis kanal push/email maupun SLA notifikasi belum ditetapkan. Route tujuan perlu mengikuti platform role yang dikonfirmasi.

### 14.5 Accessibility

**PROPOSAL — OPEN QUESTION Q17:** kontras yang terbaca, label jelas, indikator status yang tidak hanya mengandalkan warna, kontrol mobile mudah dijangkau, dan hierarki yang konsisten. Target standar aksesibilitas, ukuran sentuh minimum, skala teks, keyboard/fokus web, pembacaan status/upload oleh screen reader, pengurangan gerak, serta pemeriksaan kontras pasangan token master belum ditetapkan. Belum ada klaim kelulusan aksesibilitas; nilai warna master tidak otomatis berarti semua pasangan aman untuk teks kecil.

## 15. Design tokens dan reusable components

### 15.1 Acuan visual

**CONFIRMED S01/S03:** gunakan DESIGN SYSTEM & PROMPT MASTER SPECIFICATION, bukan tema rustic prototype, sebagai acuan visual. Nama token di tabel adalah alias dokumentasi; bukan permintaan membuat identifier kode. Detail yang tidak disebut master tetap OPEN QUESTION.

### 15.2 Typography

| Token / penggunaan | Nilai master — CONFIRMED sebagai acuan |
|---|---|
| Font utama | Plus Jakarta Sans; fallback web `sans-serif` |
| Judul layar/nama proyek/brand | 800 |
| Judul kartu/header tabel/tombol utama/badge | 700 |
| Label input/menu aktif | 600 |
| Subtitle/timestamp/metadata berkas | 500 |
| Isi/deskripsi panjang/teks legalitas | 400 |

**OPEN QUESTION Q17:** skala ukuran font, line height, letter spacing, pemetaan `sp` Flutter, fallback mobile, dan distribusi font saat offline. Contoh KPI dalam master tidak menetapkan adanya fitur analitik atau angka dashboard baru.

### 15.3 Colors

| Token dokumentasi | Nilai master | Penggunaan |
|---|---|---|
| Brand primary | `#B91C1C` | Tombol utama, aksi/indikator aktif |
| Brand dark | `#881337`, `#991B1B` | Ujung gradient identitas sesuai konteks master |
| Brand surface | `#FEE2E2` | Menu/chip aktif, latar aksen |
| Brand surface soft | `#FFF1F2` | Header tabel, catatan revisi |
| Brand border | `#FECDD3` | Batas area aksen |
| Canvas | `#F8FAFC` | Latar halaman |
| Surface/sidebar | `#FFFFFF` | Permukaan konten/sidebar |
| Border subtle | `#E2E8F0` | Garis batas netral |
| Divider | `#F1F5F9` | Pemisah |
| Text main | `#0F172A` | Judul/teks utama |
| Text muted | `#64748B` | Teks sekunder |
| Text tertiary | `#94A3B8` | Metadata sesuai master; kelayakan kontras Q17 |
| Text on red | `#FFFFFF`, `#FECDD3` | Judul/subteks pada merah |
| Sesuai/disetujui | Teks/ikon `#16A34A`, latar `#DCFCE7` | Semantik visual, bukan guard bisnis |
| Perlu perbaikan | Teks/ikon `#B45309`, latar `#FEF3C7` | Semantik visual revisi |
| Peringatan | Teks/ikon `#B91C1C`, latar `#FEE2E2` / `#FFF1F2` | Semantik visual perhatian |
| Survey | Teks/ikon `#1D4ED8`, latar `#EFF6FF` | Semantik visual survey |

Master melarang warna `#231916`, `#1c1917`, `#3B2F2F`, nuansa kayu/earth-tone kusam, dan sidebar/header arang. Penyebutan “ditolak”, “SK terbit”, atau “melebihi SLA” dalam contoh badge master tidak mengonfirmasi status, penerbitan, atau SLA bisnis. Pemetaan warna seluruh enum aplikasi masih **OPEN QUESTION Q04/Q17**.

### 15.4 Layout, spacing, radius, elevation, motion

| Parameter | Nilai dari master | Batas pemakaian |
|---|---|---|
| Referensi viewport mobile | 360–412dp | Master untuk Pengembang; adaptasi Tim Lapangan Q13 |
| Referensi viewport desktop | 1280–1440px | Web Admin; breakpoint di luar rentang Q13 |
| Sidebar desktop | Lebar 260px; aksen menu aktif 4px | Acuan visual |
| Navbar desktop | Tinggi 64px; border bawah 2px `#FEE2E2` | Acuan visual |
| Header tabel | `#FFF1F2`; border bawah `#FECDD3` | Acuan visual |
| Bottom bar Pengembang | Putih, 64px menurut teks master, FAB tengah `+ AJUKAN` | Konversi unit/safe area Q17 |
| App bar Pengembang | Merah solid `#B91C1C` atau gradient master | Tidak menetapkan gradient pada semua permukaan |
| Gradient banner | `linear-gradient(135deg, #B91C1C 0%, #881337 100%)` | Area identitas yang disebut master |
| Gradient brand sidebar | `linear-gradient(135deg, #B91C1C 0%, #991B1B 100%)` | Brand header sidebar |
| Dialog web | Putih; border atas 5px `#B91C1C`; radius 18–20px | Hanya dialog, bukan radius global |
| Backdrop dialog web | `rgba(15, 23, 42, 0.65)`; blur 4px | Ketentuan master untuk dialog, bukan glassmorphism semua layar |
| Padding contoh brand sidebar | `20px 18px` | Nilai template JSON, bukan skala spacing global |
| Padding contoh banner | `24px 32px 32px 32px` | Nilai template JSON |
| Padding contoh isi desktop | `24px 32px 64px 32px` | Nilai template JSON |
| Skala spacing global | **OPEN QUESTION Q17** | Belum didefinisikan master |
| Radius input/kartu/tombol, shadow | **OPEN QUESTION Q17** | Tidak mengadopsi angka prototype otomatis |
| Durasi/easing/animasi | **OPEN QUESTION Q17** | Belum didefinisikan master |

**CONFIRMED S01/S03:** nilai visual yang dinyatakan master menjadi acuan. **OPEN QUESTION Q13/Q17:** hierarki, kepadatan, penempatan banner, spacing, dan motion per layar di luar rincian master belum diputuskan. Contoh metrik atau banner dalam master tidak menambahkan fitur analitik maupun requirement konten baru.

### 15.5 Reusable components

| Komponen | Fungsi | Dasar / hal belum diputuskan |
|---|---|---|
| App bar, sidebar, utility navbar, breadcrumb | Orientasi dan perpindahan ruang kerja | S03; menu Admin/Tim Lapangan **OPEN QUESTION Q13** |
| Bottom navigation + FAB Pengembang | Akses empat menu dan pengajuan | S03; adaptasi safe area Q17 |
| Status badge dan indikator tahap | Menjelaskan posisi proses | Prototype + S03; pemetaan status resmi Q04 |
| Daftar/tabel pengajuan dan filter | Menemukan pekerjaan | Prototype; kolom/filter web Q13 |
| Stepper, field berlabel, ringkasan review | Mengisi form panjang | Prototype; validasi resmi Q06 |
| Slot dokumen/progres/retry | Memilih dan memantau berkas | Slot prototype; progres/retry target UX, detail Q06/Q11 |
| Viewer dokumen, hasil verifikasi, catatan revisi | Mendukung pemeriksaan dan alasan | S03/prototype; format viewer dan alasan cepat Q05/Q06 |
| Form jadwal/petugas | Menghubungkan survey dengan penugasan | Prototype belum utuh; kardinalitas Q08 |
| Temuan, foto bukti, hasil evaluasi | Mencatat survey | Prototype; validasi Q09 |
| Preview BA dan aksi PDF | Meninjau hasil serta mencetak/berbagi | Prototype; finalitas/izin Q09 |
| Loading/empty/error/success dan alasan aksi diblokir | Menjelaskan keadaan operasi | Pola prototype; kontrak produksi bagian 14 |

### 15.6 Konflik visual dengan implementasi

**EXISTING IMPLEMENTATION S12:** `AppColors` menggunakan primary `#B92216`, palet rustic, teks cokelat `#402D18`, serta permukaan hangat; `AppTextStyles` menggunakan Inter. Ini berbeda dari master Plus Jakarta Sans, primary `#B91C1C`, canvas `#F8FAFC`, dan teks `#0F172A`. **CONFIRMED:** acuan dokumentasi mengikuti master. Penyesuaian source tetap pekerjaan terpisah; tidak dilakukan pada pembaruan ini.

## 16. Confirmed decisions

| ID | Keputusan | Sumber |
|---|---|---|
| C01 | Pengembang menggunakan Flutter mobile | S01 |
| C02 | Admin Disperwaskim menggunakan Laravel Web Admin | S01 |
| C03 | Tim Perwaskim Lapangan menggunakan Flutter mobile | S01 |
| C04 | Master specification yang tersedia menjadi acuan visual; bagian platform lamanya digantikan C01–C03 | S01/S03 |
| C05 | `design.md` menjadi source of truth produk/UX; informasi belum terkonfirmasi berlabel OPEN QUESTION | S01 |
| C06 | Source code tidak diubah pada tugas dokumentasi ini | S01 |
| C09 | Dokumen menyediakan 16 placeholder DOC01–DOC16; pemetaan dan persyaratan produksi belum ditetapkan | S01 |

ID C07, C08, dan C10 pada versi 1.0 tidak lagi dicatat sebagai keputusan terkonfirmasi: versi stack, tanggung jawab dari README, serta rencana integrasi merupakan konteks dokumentasi/implementasi pada bagian 1–4. Penetapan versi produksi dan kontrak integrasi **OPEN QUESTION Q16**; kewenangan rinci **OPEN QUESTION Q03**. ID lama dipertahankan dalam catatan ini agar perubahan dapat ditelusuri.

## 17. Assumptions

| ID | Asumsi kerja dokumentasi | Status dan batas |
|---|---|---|
| A01 | Working tree saat dibaca, termasuk perubahan lokal sebelumnya, adalah snapshot implementasi untuk dokumentasi ini | **ASSUMPTION** metodologis; tidak membuktikan perilaku runtime/produksi |
| A02 | Audit S02 dipakai sebagai baseline untuk bagian yang tidak dieksekusi ulang | **ASSUMPTION** metodologis; aplikasi/test tidak dijalankan dalam tugas ini |
| A03 | Master yang dimaksud pengguna adalah isi `Design.md` yang ditemukan | **ASSUMPTION — OPEN QUESTION Q18:** apakah ada revisi master lain yang lebih berwenang? |

Tidak dibuat asumsi tentang kewajiban dokumen, pelaku tanda tangan, SLA, izin akses, transisi legal, atau keputusan evaluasi. Ketiadaan jawaban tidak mengubah OPEN QUESTION menjadi CONFIRMED.

## 18. Open questions dan recommended next step

Prioritas di bawah adalah **PROPOSAL** urutan pembahasan, bukan aturan bisnis. Pihak klarifikasi merupakan pihak yang disarankan untuk menjawab, bukan role/izin aplikasi baru.

| ID | Prioritas | Pertanyaan yang harus diputuskan | Pihak klarifikasi yang disarankan / keluaran |
|---|---|---|---|
| Q01 | P0 | Apakah persetujuan site plan bagian layanan PSU, layanan lain, atau istilah prototype? | Pemilik produk/Disperwaskim; batas layanan |
| Q02 | P1 | Apa kepanjangan produk dan nama resmi instansi untuk UI/BA? | Pemilik produk/Disperwaskim; redaksi resmi |
| Q03 | P0 | Apa cakupan data per akun/perusahaan/tim dan hak tiap aksi, termasuk akses artefak? | Pemilik produk/Disperwaskim; matriks izin objek/tindakan |
| Q04 | P0 | Apa status resmi, aktor/guard tiap transisi, arti selesai, finalitas penolakan, pembatalan, pembukaan kembali? | Disperwaskim; tabel transisi resmi |
| Q05 | P0 | Revisi berlaku di tahap mana, mengubah apa, wajib diverifikasi ulang atau tidak, kapan dikunci dan kapan survey ulang? | Disperwaskim; alur revisi dan versi |
| Q06 | P1 | Apa field wajib, redaksi pernyataan, format, satuan, ukuran/jenis/jumlah berkas, serta aturan validasi? | Disperwaskim + tim teknis; kamus field/validasi |
| Q07 | P1 | Apa nama dan pemetaan DOC01–DOC16, kondisi opsional, posisi pelepasan lahan/drainase/multi-file teknis? | Disperwaskim; katalog dokumen resmi |
| Q08 | P1 | Survey satu petugas atau tim, bagaimana penugasan/perubahan/pembatalan, apakah laporan mandiri sah, bagaimana relasi survey ulang? | Disperwaskim; model penugasan dan survey |
| Q09 | P0 | Apa jenis BA/SK, template, nomor, field wajib, aktor penyiapan/pemeriksaan/tanda tangan/penerbitan, arti final, serta hak berbagi? | Disperwaskim; siklus artefak dan persetujuan |
| Q10 | P1 | Event apa memberi notifikasi kepada siapa, melalui kanal apa, dan menuju layar platform mana? | Pemilik produk + tim teknis; matriks notifikasi |
| Q11 | P1 | Apakah draft persisten/offline diwajibkan; bagaimana upload retry/resume dan pemulihan setelah aplikasi ditutup? | Pemilik produk + tim teknis; kebijakan jaringan/draft |
| Q12 | P1 | Apakah ada SLA, tenggat revisi, dan aturan eskalasi yang disahkan? | Disperwaskim; keputusan tanpa menebak durasi |
| Q13 | P1 | Bagaimana susunan menu dan layar Admin web/Tim Lapangan, keadaan UI, copy, serta responsif di luar ukuran master? | Pemilik produk/UX; spesifikasi layar |
| Q14 | P1 | Bagaimana akun dibuat, login/pemulihan/session, onboarding per role, dan deep link? | Pemilik produk + tim teknis; flow identitas |
| Q15 | P1 | Apa kebutuhan audit trail, riwayat keputusan/berkas, retensi, penghapusan dan aksesnya? | Disperwaskim + tim teknis; kebijakan data |
| Q16 | P0 | Versi stack produksi dan kontrak API/database mana yang disepakati, bagaimana status/file/versi dikonfirmasi, dan kapan alur Admin berpindah ke web? | Tim teknis setelah keputusan bisnis; kontrak integrasi dan rencana migrasi |
| Q17 | P1 | Apa token yang belum ada, adaptasi unit Flutter, target aksesibilitas, serta hasil verifikasi kontras/token? | UX + pemilik produk; token lengkap dan kriteria aksesibilitas |
| Q18 | P1 | Apakah master visual di Lampiran A adalah versi acuan terakhir atau ada revisi lain? | Pemilik produk; identitas/versi master |

**Recommended next step — PROPOSAL:** bahas Q03, Q04, Q05, dan Q09 untuk mengesahkan matriks kewenangan serta transisi termasuk revisi/BA/SK. Lanjutkan katalog DOC (Q06/Q07), penugasan (Q08), lalu kontrak integrasi (Q16). Perbarui keputusan pada dokumen ini sebelum mengubah implementasi. Perbaikan backend, pembatasan data, penugasan petugas, notifikasi, dan tema visual tetap rekomendasi audit, bukan pekerjaan yang telah dilakukan.

## 19. Change log

| Tanggal | Versi | Perubahan | Batas perubahan |
|---|---|---|---|
| 3 Oktober 2026 | 1.0 | Mengembangkan master `Design.md` menjadi `design.md` dengan 19 bagian produk/UX; menetapkan pembagian platform dari pengguna; memisahkan implementasi prototype dari keputusan; menambahkan placeholder DOC01–DOC16, register pertanyaan dan konflik visual/workflow | Dokumentasi saja; master asli dipertahankan di Lampiran A; source code dan perubahan lokal sebelumnya tidak diubah |
| 3 Oktober 2026 | 1.1 | Memeriksa ulang kelengkapan 19 bagian; menegaskan platform per role; membedakan konteks README dari keputusan eksplisit; mengoreksi label konfirmasi versi stack, kewenangan, placeholder dokumen, dan usulan UX yang belum disahkan | Hanya `design.md`; 16 placeholder dan lampiran master visual dipertahankan; source code tidak diubah |

## Lampiran A — Master visual asli, dipertahankan sebagai sumber

Isi setelah pembatas berikut dipertahankan dari file awal agar nilai visual dan template prompt tetap dapat ditelusuri. Untuk keputusan aktif, gunakan bagian 1–19 di atas. Pernyataan platform lama tentang Tim Pengawas desktop telah digantikan keputusan mobile; sebutan SLA, penolakan, penerbitan SK, dan teks legalitas dalam contoh master bukan konfirmasi aturan bisnis. Klaim source of truth dalam teks asli dibaca sebagai acuan visual di dalam dokumen ini.

---

# DESIGN SYSTEM & PROMPT MASTER SPECIFICATION
## SISTEM SATU RUMAH — DISPERWASKIM KOTA TASIKMALAYA

Dokumen ini merupakan panduan acuan standar (*single source of truth*) untuk desain UI/UX aplikasi mobile pengembang maupun web portal admin/verifikator desktop.

---

### 1. Identitas Sistem & Sasaran Pengguna
* **Nama Platform:** SATU RUMAH (Sistem Administrasi Terpadu Urusan & Pengawasan Perumahan)
* **Instansi Resmi:** Dinas Perumahan Rakyat dan Kawasan Permukiman (Disperwaskim) Pemerintah Kota Tasikmalaya
* **Lingkup Platform:**
  1. **Mobile App:** Portal Mandiri Pengembang Perumahan (Android & iOS, 360dp–412dp)
  2. **Web Desktop:** Portal Admin Verifikator & Tim Pengawas Perwaskim (Desktop Web, 1280px–1440px)

---

### 2. Standar Tipografi (Typography Token)
* **Font Family Utama:** `'Plus Jakarta Sans', sans-serif`
* **CDN Stylesheet:**  
  `https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap`
* **Hirarki Bobot (Font Weights):**
  * **800 (ExtraBold):** Judul layar utama, angka metrik besar (KPI), nama proyek perumahan, brand logo "SATU RUMAH".
  * **700 (Bold):** Judul kartu, header tabel, tombol aksi (*primary button*), label badge status.
  * **600 (SemiBold):** Label kolom input, item menu navigasi aktif, sub-metrik.
  * **500 (Medium):** Subtitle deskriptif, timestamp/waktu, keterangan metadata berkas.
  * **400 (Regular):** Paragraf isi, teks legalitas, deskripsi panjang.

---

### 3. Palet Warna Resmi (Red & White Balanced Enterprise)

#### A. Warna Inti (Primary Brand Colors)
* **Primary Red (Merah Dinas):** `#B91C1C`  
  *Digunakan untuk tombol utama, ikon aktif, indikator tab aktif, dan border aksen.*
* **Primary Dark / Gradient End:** `#881337` (Merah Marun Pekat) & `#991B1B`  
  *Digunakan sebagai gradasi penutup pada hero banner dan app bar.*
* **Hero Banner Gradient:** `linear-gradient(135deg, #B91C1C 0%, #881337 100%)`

#### B. Permukaan & Aksen (Surfaces & Accents)
* **Primary Surface (Soft Tint):** `#FEE2E2`  
  *Digunakan untuk wadah ikon, menu sidebar aktif, chip filter aktif, dan pill ID berkas.*
* **Primary Surface Soft:** `#FFF1F2`  
  *Digunakan untuk latar form peringatan, header tabel berkas, dan kotak catatan revisi.*
* **Primary Surface Border:** `#FECDD3`  
  *Digunakan untuk garis pembatas kontainer merah muda dan garis bawah tabel.*

#### C. Latar Belakang Netral (Canvas & Neutrals)
* **Background Canvas:** `#F8FAFC` (Abu-abu terang bersih, bukan krem / bukan cokelat)
* **Card Surface:** `#FFFFFF` (Putih murni dengan elevasi halus)
* **Sidebar Background:** `#FFFFFF` (Putih bersih dengan aksen logo merah)
* **Border Subtle:** `#E2E8F0` (Garis pemisah netral)
* **Divider Line:** `#F1F5F9`

#### D. Warna Teks (Typography Colors)
* **Text Main / Headings:** `#0F172A` (Slate 900 — Kontras tinggi, bukan hitam pekat)
* **Text Muted / Secondary:** `#64748B` (Slate 500)
* **Text Tertiary / Timestamp:** `#94A3B8` (Slate 400)
* **Text On Red:** `#FFFFFF` (Putih murni) & `#FECDD3` (Merah muda untuk sub-teks di atas banner)

#### E. Status Semantik Kedinasan (Semantic Status Badges)
| Status | Warna Teks / Ikon | Warna Latar (Surface) | Penggunaan |
|---|---|---|---|
| **Sesuai / Disetujui** | `#16A34A` (Hijau) | `#DCFCE7` | Dokumen valid, SK terbit, verifikasi lolos |
| **Perlu Perbaikan** | `#B45309` (Amber) | `#FEF3C7` | Berkas buram, syarat kurang, butuh revisi |
| **Peringatan / Urgent** | `#B91C1C` (Merah) | `#FEE2E2` / `#FFF1F2` | Melebihi batas SLA, ditolak, tindakan wajib |
| **Survey Lapangan** | `#1D4ED8` (Biru) | `#EFF6FF` | Agenda survey aktif, penugasan surveyor |

#### F. DAFTAR HITAM WARNA (Strict Blacklist)
> **PANTANGAN MUTLAK:** Dilarang merender warna cokelat tua (`#231916`, `#1c1917`, `#3B2F2F`), nuansa kayu/earth-tone kusam, atau dark-mode abu-abu arang pada sidebar dan header.

---

### 4. Aturan Tata Letak (Layout Architecture)

#### A. Web Desktop Verifikator (1280px - 1440px)
1. **Sidebar Kiri (Lebar: 260px):**
   * Bagian atas memiliki brand header berlatar `linear-gradient(135deg, #B91C1C 0%, #991B1B 100%)` berlogo rumah putih.
   * Badan sidebar putih bersih (`#FFFFFF`).
   * Menu aktif berlatar `#FEE2E2`, teks `#B91C1C` tebal, dan aksen kiri `border-left: 4px solid #B91C1C`.
2. **Top Utility Navbar (Tinggi: 64px):**
   * Latar putih bersih dengan border bawah `2px solid #FEE2E2`.
   * Badge merah dinas `KOTA TASIKMALAYA`, breadcrumb rute, ikon notifikasi merah muda, dan pill avatar profil.
3. **Hero Page Banner:**
   * Latar gradien merah dinas (`#B91C1C` ke `#881337`).
   * Berisi breadcrumb kontras, nomor registrasi proyek, judul tebal putih, status badge, dan tombol CTA utama (misal: *Verifikasi Berkas*).
4. **Tabel Data & Antrean:**
   * Header tabel wajib berlatar `#FFF1F2` dengan border bawah `#FECDD3`.
   * Baris data putih bersih berselang-seling halus (*subtle row line*).
   * Tombol aksi baris (misal: *Buka*) menggunakan button chip berlatar `#FEE2E2` dengan teks `#B91C1C`.
5. **Modal Dialog & Lightbox Viewer:**
   * Selalu menggunakan lapisan backdrop gelap transparan: `rgba(15, 23, 42, 0.65)` + `backdrop-filter: blur(4px)`.
   * Kotak modal putih ber-border atas `5px solid #B91C1C` dengan sudut melengkung `18px-20px`.
   * Dilengkapi form catatan revisi (*Quick reason chips* + *textarea*) jika memilih opsi perbaikan dokumen.

#### B. Mobile App Pengembang (360dp - 412dp)
1. **Header App Bar:** Merah solid `#B91C1C` atau gradien dengan teks logo putih dan avatar bulat.
2. **Bottom Navigation Bar:**
   * Bar putih docked (64px) dengan 4 menu utama: Beranda, Pengajuan, Notifikasi, Profil.
   * **Wajib memiliki Center Floating Action Button (FAB):** Tombol bulat merah `#B91C1C` bertuliskan `+ AJUKAN` di bagian tengah yang sedikit menonjol ke atas.

---

### 5. Template Master Prompt JSON (Untuk Digunakan di Stitch)

Gunakan kerangka JSON berikut setiap kali Anda ingin membuat atau merombak halaman baru agar konsistensi desain tetap terjaga:

```json
{
  "task": "generate_desktop_screen_ui",
  "project_context": {
    "app_name": "Satu Rumah - Portal Verifikator Disperwaskim",
    "target_platform": "Responsive Web Desktop (1280px - 1440px viewport)",
    "user_role": "Verifikator Resmi Disperwaskim Kota Tasikmalaya",
    "external_resources": {
      "google_font_stylesheet": "https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
    },
    "typography": {
      "font_family": "'Plus Jakarta Sans', sans-serif"
    },
    "theme": {
      "color_mode": "BALANCED_RED_WHITE_ENTERPRISE",
      "primary_color": "#B91C1C",
      "primary_dark": "#881337",
      "primary_gradient": "linear-gradient(135deg, #B91C1C 0%, #881337 100%)",
      "primary_surface": "#FEE2E2",
      "primary_surface_soft": "#FFF1F2",
      "primary_surface_border": "#FECDD3",
      "background_canvas": "#F8FAFC",
      "card_surface": "#FFFFFF",
      "sidebar_background": "#FFFFFF",
      "text_main": "#0F172A",
      "text_muted": "#64748B",
      "border_subtle": "#E2E8F0",
      "forbidden_tones": ["#231916", "#1c1917", "#3B2F2F", "dark-brown", "warm-earth", "sepia"]
    }
  },
  "screen_definition": {
    "screen_id": "NAMA_SCREEN_KAMU_DISINI",
    "title": "Judul Halaman Disini",
    "layout_type": "desktop_sidebar_with_content_header",
    "global_css": {
      "font_family": "'Plus Jakarta Sans', sans-serif",
      "background": "#F8FAFC"
    },
    "components": [
      {
        "section": "left_sidebar",
        "type": "fixed_sidebar",
        "width": "260px",
        "background": "#FFFFFF",
        "border_right": "1px solid #E2E8F0",
        "padding": "0px",
        "elements": [
          {
            "type": "brand_header_container",
            "background": "linear-gradient(135deg, #B91C1C 0%, #991B1B 100%)",
            "padding": "20px 18px",
            "title": "SATU RUMAH",
            "subtitle": "DISPERWASKIM KOTA TASIKMALAYA"
          }
        ]
      },
      {
        "section": "main_content_area",
        "type": "content_wrapper",
        "flex": 1,
        "background": "#F8FAFC",
        "elements": [
          {
            "section": "desktop_top_header",
            "type": "navbar_desktop",
            "height": "64px",
            "background": "#FFFFFF",
            "border_bottom": "2px solid #FEE2E2"
          },
          {
            "section": "hero_banner",
            "type": "container",
            "background": "linear-gradient(135deg, #B91C1C 0%, #881337 100%)",
            "padding": "24px 32px 32px 32px"
          },
          {
            "section": "workspace_body",
            "type": "container",
            "padding": "24px 32px 64px 32px"
          }
        ]
      }
    ]
  }
}
```
