import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../widgets/survey_not_found_illustration.dart';

/// Enum kelompok fase dokumen pengajuan
enum TemplateBerkasGroup {
  perusahaan('Perusahaan', 'Berkas Perusahaan — Fase 2', 5),
  perumahan('Perumahan', 'Berkas Perumahan — Fase 3', 11);

  final String chipLabel;
  final String sectionTitle;
  final int count;
  const TemplateBerkasGroup(this.chipLabel, this.sectionTitle, this.count);
}

/// Klasifikasi status ketersediaan & sumber dokumen pengajuan
enum DocumentAvailabilityStatus {
  /// Dokumen asli diterbitkan oleh instansi atau lembaga berwenang terkait.
  externalDocument(
    badgeLabel: 'Dokumen instansi terkait',
    dotColor: Color(0xFF3B82F6),
    title: 'Dokumen Instansi Terkait',
    message:
        'Gunakan dokumen resmi yang diterbitkan oleh instansi berwenang sesuai persyaratan pengajuan.',
    backgroundColor: Color(0xFFF0F9FF),
    borderColor: Color(0xFFBAE6FD),
    iconColor: Color(0xFF0284C7),
    titleColor: Color(0xFF0369A1),
    messageColor: Color(0xFF0C4A6E),
    icon: Icons.account_balance_outlined,
  ),

  /// Tersedia penjelasan persyaratan atau panduan, tetapi tidak ada file template terverifikasi.
  guidanceOnly(
    badgeLabel: 'Panduan tersedia',
    dotColor: Color(0xFF10B981),
    title: 'Panduan Persyaratan',
    message:
        'Informasi persyaratan dapat digunakan sebagai acuan. Belum ada file template yang tersedia untuk diunduh.',
    backgroundColor: Color(0xFFF8FAFC),
    borderColor: Color(0xFFE2E8F0),
    iconColor: Color(0xFF64748B),
    titleColor: Color(0xFF334155),
    messageColor: Color(0xFF475569),
    icon: Icons.menu_book_outlined,
  ),

  /// Dokumen yang berpotensi memiliki format baku, tetapi file template belum disediakan.
  templatePending(
    badgeLabel: 'Format belum tersedia',
    dotColor: Color(0xFFF59E0B),
    title: 'Template Belum Tersedia',
    message:
        'Format unduhan belum disediakan. Silakan mengikuti ketentuan dokumen yang berlaku.',
    backgroundColor: Color(0xFFFFFBEB),
    borderColor: Color(0xFFFDE68A),
    iconColor: Color(0xFFD97706),
    titleColor: Color(0xFF92400E),
    messageColor: Color(0xFF78350F),
    icon: Icons.schedule_outlined,
  );

  final String badgeLabel;
  final Color dotColor;
  final String title;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
  final IconData icon;

  const DocumentAvailabilityStatus({
    required this.badgeLabel,
    required this.dotColor,
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
    required this.icon,
  });

  String get label => badgeLabel;
}

/// Alias for backwards compatibility with existing UI contracts
typedef DocumentTypeCategory = DocumentAvailabilityStatus;

/// Kategori filter chip halaman Template Berkas
enum TemplateFilterCategory {
  semua('Semua (16)'),
  perusahaan('Perusahaan (5)'),
  perumahan('Perumahan (11)');

  final String label;
  const TemplateFilterCategory(this.label);
}

/// Model data item Template Berkas yang diinisialisasi berdasarkan kontrak dokumen riil.
class TemplateBerkasItem {
  final String slotNumber;
  final String key;
  final String title;
  final TemplateBerkasGroup group;
  final DocumentAvailabilityStatus availabilityStatus;
  final String purpose;
  final String issuingAgency;
  final String fileFormat;
  final String maxFileSize;
  final String guidance;
  final bool isOptional;
  final bool allowsMultiple;
  final String? templateAssetPath;
  final String? templateFileName;
  final String? templateMimeType;
  final bool templateVerified;
  final List<String> searchKeywords;

  const TemplateBerkasItem({
    required this.slotNumber,
    required this.key,
    required this.title,
    required this.group,
    required this.availabilityStatus,
    required this.purpose,
    required this.issuingAgency,
    this.fileFormat = 'PDF',
    this.maxFileSize = '10 MB',
    required this.guidance,
    this.isOptional = false,
    this.allowsMultiple = false,
    this.templateAssetPath,
    this.templateFileName,
    this.templateMimeType,
    this.templateVerified = false,
    this.searchKeywords = const [],
  });

  DocumentTypeCategory get category => availabilityStatus;

  /// Determines if the Format & Template section should be shown.
  /// Only relevant for GUIDANCE_ONLY and TEMPLATE_PENDING categories.
  bool get hasFormatAndTemplateSection =>
      availabilityStatus != DocumentAvailabilityStatus.externalDocument;
}

/// Canonical catalog of the 16 document slots derived from Step 2 & Step 3 contracts.
class TemplateBerkasCatalog {
  static const List<TemplateBerkasItem> items = [
    // ─── FASE 2: BERKAS PERUSAHAAN (5 SLOT) ───
    TemplateBerkasItem(
      slotNumber: '01',
      key: 'ktp',
      title: 'KTP-el Pemohon / Direktur Utama',
      group: TemplateBerkasGroup.perusahaan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Verifikasi legalitas identitas pemohon perseorangan atau direktur utama perusahaan pengembang yang berwenang bertindak secara hukum.',
      issuingAgency:
          'Dinas Kependudukan dan Pencatatan Sipil (Disdukcapil) / Kemendagri',
      guidance:
          'Unggah hasil pemindaian KTP-el asli, bukan fotokopi buram. Pastikan seluruh teks NIK, nama, dan foto terlihat jelas tanpa pantulan cahaya.',
      searchKeywords: ['ktp', 'identitas', 'direktur', 'kependudukan', 'nik', 'disdukcapil'],
    ),
    TemplateBerkasItem(
      slotNumber: '02',
      key: 'nib',
      title: 'Nomor Induk Berusaha (NIB)',
      group: TemplateBerkasGroup.perusahaan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Tanda daftar usaha resmi dan identitas pelaku usaha dalam menyelenggarakan kegiatan real estat berstandar OSS RBA.',
      issuingAgency: 'Kementerian Investasi / BKPM (Sistem OSS-RBA)',
      guidance:
          'Pastikan NIB masih aktif dan mencantumkan KBLI Real Estat / Pengembang Perumahan yang sesuai dengan lokasi pengajuan proyek.',
      searchKeywords: ['nib', 'bkpm', 'oss', 'oss-rba', 'investasi', 'kbli', 'usaha'],
    ),
    TemplateBerkasItem(
      slotNumber: '03',
      key: 'npwp_doc',
      title: 'NPWP Perusahaan',
      group: TemplateBerkasGroup.perusahaan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Bukti pendaftaran perpajakan badan usaha pengembang untuk pemenuhan kewajiban fiskal pembangunan.',
      issuingAgency: 'Direktorat Jenderal Pajak (DJP) Kementerian Keuangan',
      guidance:
          'Gunakan kartu NPWP 16 digit format terbaru berstatus valid dan aktif di portal DJP.',
      searchKeywords: ['npwp', 'pajak', 'djp', 'fiskal', 'perusahaan'],
    ),
    TemplateBerkasItem(
      slotNumber: '04',
      key: 'asosiasi',
      title: 'Bukti Keanggotaan Asosiasi',
      group: TemplateBerkasGroup.perusahaan,
      availabilityStatus: DocumentAvailabilityStatus.guidanceOnly,
      purpose:
          'Keterangan sertifikasi keanggotaan aktif dari asosiasi pengembang perumahan yang diakui pemerintah (REI, APERSI, HIMPERRA, dll).',
      issuingAgency:
          'Dewan Pengurus Pusat / Daerah Asosiasi Pengembang Perumahan',
      guidance:
          'Sertakan tanda keanggotaan atau surat keterangan lunas iuran tahun berjalan yang masih berlaku pada periode pengajuan.',
      searchKeywords: ['asosiasi', 'rei', 'apersi', 'himperra', 'pengembang'],
    ),
    TemplateBerkasItem(
      slotNumber: '05',
      key: 'legalitas',
      title: 'Akta Pendirian & SK Kemenkumham',
      group: TemplateBerkasGroup.perusahaan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Landasan legalitas pendirian badan hukum perseroan terbatas (PT) serta pengesahan susunan direksi terbaru.',
      issuingAgency: 'Notaris & Ditjen AHU Kementerian Hukum dan HAM RI',
      guidance:
          'Gabungkan salinan akta pendirian, akta perubahan anggaran dasar terakhir (jika ada), beserta SK pengesahan Kemenkumham dalam satu file PDF runut.',
      searchKeywords: ['akta', 'pendirian', 'sk', 'kemenkumham', 'notaris', 'ahu', 'legalitas'],
    ),

    // ─── FASE 3: BERKAS PERUMAHAN (11 SLOT) ───
    TemplateBerkasItem(
      slotNumber: '06',
      key: 'surat_permohonan',
      title: 'Surat Permohonan Persetujuan Site Plan',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.templatePending,
      purpose:
          'Surat resmi pengajuan persetujuan rancangan tapak (site plan) perumahan yang diajukan oleh direktur kepada Kepala Dinas Teknis.',
      issuingAgency: 'Pengembang / Pemohon ditujukan ke Kepala Dinas',
      guidance:
          'Gunakan kop resmi perusahaan, bertanda tangan basah direktur dan dibubuhi meterai Rp10.000.',
      searchKeywords: ['surat permohonan', 'permohonan', 'site plan', 'kepala dinas', 'disperwaskim'],
    ),
    TemplateBerkasItem(
      slotNumber: '07',
      key: 'info_intensitas_ruang',
      title: 'Informasi Intensitas Pemanfaatan Ruang (IPR / KRK)',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Keterangan kesesuaian zonasi tata ruang wilayah (KKPR/IIPR), koefisien dasar bangunan (KDB), dan batas garis sempadan.',
      issuingAgency: 'Dinas Tata Ruang / DPMPTSP / Kementerian ATR-BPN',
      guidance:
          'Lampirkan lembar IIPR atau PKKPR yang telah diterbitkan lengkap beserta peta koordinat batas kavling perencanaan.',
      searchKeywords: ['ipr', 'krk', 'iipr', 'kkpr', 'tata ruang', 'kdb', 'atr', 'bpn'],
    ),
    TemplateBerkasItem(
      slotNumber: '08',
      key: 'bukti_kepemilikan_lahan',
      title: 'Bukti Kepemilikan Lahan / Sertifikat Induk a.n. PT',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Sertifikat hak atas tanah (SHM / SHGB / HPL) atau akta perolehan tanah resmi yang membuktikan penguasaan fisik dan yuridis lahan.',
      issuingAgency: 'Kantor Pertanahan (Kantah ATR/BPN)',
      guidance:
          'Pastikan sertifikat atas nama badan hukum pemohon atau dilengkapi perjanjian pengikatan jual beli (PPJB) notariil yang sah.',
      searchKeywords: ['sertifikat', 'lahan', 'tanah', 'shm', 'shgb', 'hpl', 'ppjb', 'bpn'],
    ),
    TemplateBerkasItem(
      slotNumber: '09',
      key: 'bukti_tpu',
      title: 'Bukti Penyediaan Lahan TPU Perumahan',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.guidanceOnly,
      purpose:
          'Bukti alokasi penyediaan lahan Tempat Pemakaman Umum sebesar 2% sesuai kewajiban perda daerah setempat.',
      issuingAgency:
          'Dinas Lingkungan Hidup / Dinas Perkim / Pengelola TPU Daerah',
      guidance:
          'Dapat berupa bukti sertifikat lahan pemakaman tersendiri atau perjanjian kerjasama retribusi penyediaan makam dengan TPU pemerintah daerah.',
      searchKeywords: ['tpu', 'makam', 'pemakaman', 'lahan tpu', 'perda'],
    ),
    TemplateBerkasItem(
      slotNumber: '10',
      key: 'rekomendasi_lingkungan',
      title: 'Rekomendasi Teknis dari Dinas Terkait',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Dokumen persetujuan lingkungan hidup berupa SPPL, UKL-UPL, atau AMDAL serta rekomendasi teknis tapak drainase.',
      issuingAgency: 'Dinas Lingkungan Hidup (DLH) Kota/Kabupaten',
      guidance:
          'Pastikan surat keputusan persetujuan lingkungan memuat komitmen pengelolaan air limbah domestik dan persampahan.',
      allowsMultiple: true,
      searchKeywords: ['lingkungan', 'amdal', 'ukl', 'upl', 'sppl', 'dlh', 'drainase'],
    ),
    TemplateBerkasItem(
      slotNumber: '11',
      key: 'andalalin',
      title: 'Persetujuan ANDALALIN / Dishub',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Persetujuan Hasil Analisis Dampak Lalu Lintas untuk menjamin akses sirkulasi keluar-masuk kawasan perumahan tidak mengganggu jalan umum.',
      issuingAgency:
          'Dinas Perhubungan (Dishub) / Balai Pengelola Transportasi Darat',
      guidance:
          'Wajib menyertakan rekomendasi teknis mitigasi simpang masuk perumahan dan pemasangan rambu keselamatan lalu lintas.',
      searchKeywords: ['andalalin', 'dishub', 'lalu lintas', 'transportasi', 'perhubungan'],
    ),
    TemplateBerkasItem(
      slotNumber: '12',
      key: 'rekomendasi_air_bersih',
      title: 'Rekomendasi Air Bersih (PDAM / Surat Izin)',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Surat jaminan ketersediaan debit air bersih untuk kebutuhan seluruh unit hunian perumahan dari perusahaan air minum.',
      issuingAgency: 'Perumda Air Minum / PDAM Setempat',
      guidance:
          'Jika di luar jaringan PDAM, lampirkan kajian teknis pengeboran air tanah dalam (sumur dalam) serta izin SIPA dari instansi ESDM.',
      searchKeywords: ['air bersih', 'pdam', 'air', 'sipa', 'sumur'],
    ),
    TemplateBerkasItem(
      slotNumber: '13',
      key: 'rekomendasi_listrik',
      title: 'Rekomendasi Listrik PLN',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.externalDocument,
      purpose:
          'Konfirmasi ketersediaan daya dan rencana pembangunan jaringan transmisi serta gardu distribusi listrik perumahan.',
      issuingAgency:
          'PT PLN (Persero) Unit Pelaksana Pelayanan Pelanggan (UP3)',
      guidance:
          'Memuat estimasi kebutuhan total daya (kVA) untuk penerangan jalan umum (PJU) dan seluruh kavling hunian.',
      searchKeywords: ['listrik', 'pln', 'daya', 'gardu', 'pju'],
    ),
    TemplateBerkasItem(
      slotNumber: '14',
      key: 'pernyataan_psu',
      title: 'Surat Pernyataan Kesanggupan Penyerahan PSU',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.templatePending,
      purpose:
          'Komitmen mengikat dari pengembang untuk menyerahkan Prasarana, Sarana, dan Utilitas umum kepada Pemerintah Kota sesuai regulasi.',
      issuingAgency: 'Pengembang / Direksi Pemohon dengan Notulen Dinas',
      guidance:
          'Ditandatangani di atas meterai Rp10.000 dengan melampirkan rincian luasan RTH, jalan, drainase, dan fasilitas ibadah/sosial.',
      searchKeywords: ['psu', 'prasarana', 'sarana', 'utilitas', 'penyerahan psu'],
    ),
    TemplateBerkasItem(
      slotNumber: '15',
      key: 'penanggung_jawab_teknis',
      title: 'Data Penanggung Jawab Dokumen Teknis',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.guidanceOnly,
      purpose:
          'Identitas dan sertifikasi keahlian profesional perencana teknis arsitektur, sipil, atau perencana wilayah kota (SKA/STRA).',
      issuingAgency:
          'Lembaga Pengembangan Jasa Konstruksi (LPJK) / Asosiasi Profesi',
      guidance:
          'Lampirkan KTP arsitek perencana, STRA/SKA aktif, dan surat penunjukan resmi dari perusahaan pengembang.',
      isOptional: true,
      searchKeywords: ['penanggung jawab', 'teknis', 'tenaga ahli', 'arsitek', 'ska', 'skk', 'stra'],
    ),
    TemplateBerkasItem(
      slotNumber: '16',
      key: 'proposal_pembangunan',
      title: 'Proposal Rencana Pembangunan Ditandatangani Direktur',
      group: TemplateBerkasGroup.perumahan,
      availabilityStatus: DocumentAvailabilityStatus.guidanceOnly,
      purpose:
          'Uraian komprehensif rencana pembangunan perumahan mencakup jadwal tahapan konstruksi, tipe rumah, sistem drainase, dan estimasi investasi.',
      issuingAgency: 'Tim Teknis Pengembang Pemohon',
      guidance:
          'Disusun sistematis dilengkapi narasi konsep lingkungan ramah anak, persentase RTH minimal 30%, serta peta pembagian zonasi kavling.',
      searchKeywords: ['proposal', 'rencana pembangunan', 'tahapan', 'jadwal', 'konstruksi'],
    ),
  ];
}

/// Layar Template Berkas untuk Pengembang — SATU RUMAH V2
/// Mengikuti spesifikasi visual Google Stitch & Design System:
/// - Sticky Header Merah Gradient dengan Back Button & Subtitle
/// - Search bar dengan clear button
/// - Horizontal Filter Chips (Semua, Perusahaan, Perumahan) tanpa scale/shadow
/// - Compact List terbagi 2 kelompok (Fase 2: 5 slot, Fase 3: 11 slot)
/// - Reusable Document Detail Bottom Sheet dengan metadata terverifikasi
/// - Empty state ketika pencarian / filter tidak menemukan hasil
class TemplateBerkasScreen extends StatefulWidget {
  const TemplateBerkasScreen({super.key});

  @override
  State<TemplateBerkasScreen> createState() => _TemplateBerkasScreenState();
}

class _TemplateBerkasScreenState extends State<TemplateBerkasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TemplateFilterCategory _selectedFilter = TemplateFilterCategory.semua;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedFilter = TemplateFilterCategory.semua;
    });
  }

  bool _matchesSearch(TemplateBerkasItem item) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase().trim();

    if (item.title.toLowerCase().contains(query)) return true;
    if (item.slotNumber.contains(query)) return true;
    if (int.tryParse(query) != null &&
        int.tryParse(item.slotNumber) == int.tryParse(query)) {
      return true;
    }
    if (item.key.toLowerCase().contains(query)) return true;
    if (item.issuingAgency.toLowerCase().contains(query)) return true;
    if (item.category.label.toLowerCase().contains(query)) return true;
    for (final kw in item.searchKeywords) {
      if (kw.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  void _openDetailBottomSheet(TemplateBerkasItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateBerkasDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    const allItems = TemplateBerkasCatalog.items;

    // Filter by category
    final filterPerusahaan = _selectedFilter == TemplateFilterCategory.semua ||
        _selectedFilter == TemplateFilterCategory.perusahaan;
    final filterPerumahan = _selectedFilter == TemplateFilterCategory.semua ||
        _selectedFilter == TemplateFilterCategory.perumahan;

    final visiblePerusahaan = filterPerusahaan
        ? allItems
            .where((it) => it.group == TemplateBerkasGroup.perusahaan)
            .where(_matchesSearch)
            .toList()
        : <TemplateBerkasItem>[];

    final visiblePerumahan = filterPerumahan
        ? allItems
            .where((it) => it.group == TemplateBerkasGroup.perumahan)
            .where(_matchesSearch)
            .toList()
        : <TemplateBerkasItem>[];

    final bool isEmpty =
        visiblePerusahaan.isEmpty && visiblePerumahan.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ─── 1. STICKY HEADER SATU RUMAH V2 ──────────────────────────────
          _buildHeader(context),

          // ─── 2. SEARCH & HORIZONTAL FILTER CHIPS ─────────────────────────
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildFilterChips(),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // ─── 3. SCROLLABLE DOCUMENT LIST / EMPTY STATE ───────────────────
          Expanded(
            child: isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // GROUP 1: Berkas Perusahaan — Fase 2
                      if (visiblePerusahaan.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Berkas Perusahaan — Fase 2',
                          countText: '${visiblePerusahaan.length} Dokumen',
                          dotColor: const Color(0xFFB91C1C),
                        ),
                        const SizedBox(height: 8),
                        _buildGroupCard(visiblePerusahaan),
                        const SizedBox(height: 16),
                      ],

                      // GROUP 2: Berkas Perumahan — Fase 3
                      if (visiblePerumahan.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Berkas Perumahan — Fase 3',
                          countText: '${visiblePerumahan.length} Dokumen',
                          dotColor: const Color(0xFF881337),
                        ),
                        const SizedBox(height: 8),
                        _buildGroupCard(visiblePerumahan),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER (Matches Jadwal Survey standard)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadii.hero,
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Back Button
          Semantics(
            label: 'Kembali',
            button: true,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  try {
                    context.go('/dashboard');
                  } catch (_) {}
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Template Berkas',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Panduan persyaratan pengajuan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xDAFFFFFF),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari dokumen atau persyaratan...',
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HORIZONTAL FILTER CHIPS (Standardized 36dp Visual Height, 44dp Touch Target)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TemplateFilterCategory.values.map((category) {
          final isSelected = _selectedFilter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: category.label,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = category;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                mouseCursor: SystemMouseCursors.click,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color:
                          isSelected ? const Color(0xFFB91C1C) : Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0x00E2E8F0)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      child: Text(category.label),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION HEADER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String countText,
    required Color dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              countText,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP CARD (Enclosing the rows)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildGroupCard(List<TemplateBerkasItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F5F9),
              ),
            _buildDocRow(items[i]),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPACT DOCUMENT ROW (72–84dp Flexible Height)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDocRow(TemplateBerkasItem item) {
    return InkWell(
      onTap: () => _openDetailBottomSheet(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Slot number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              alignment: Alignment.center,
              child: Text(
                item.slotNumber,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.category.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      if (item.isOptional) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Opsional',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMPTY STATE: SEARCH NOT FOUND
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SurveyNotFoundIllustration(
              width: 180,
              height: 140,
            ),
            const SizedBox(height: 14),
            const Text(
              'Dokumen Tidak Ditemukan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba gunakan kata kunci lain atau periksa filter kategori.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _resetSearchAndFilter,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Color(0xFF0F172A),
              ),
              label: const Text(
                'Reset Pencarian & Filter',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail Bottom Sheet Modal for a selected document slot.
///
/// Features:
/// - Guarantees scroll offset starts at 0 on every document view.
/// - Unclipped metadata grid below clean non-overlapping header.
/// - Maximum height ~85% screen with scrollable center body.
/// - Fixed footer with Tutup Informasi button respecting SafeArea.
/// - Contextual document availability status callouts.
/// - Dedicated Format & Template download section for GUIDANCE_ONLY and TEMPLATE_PENDING.
/// - Disabled Unduh Template button when physical asset is not available (zero fake files).
class _TemplateBerkasDetailSheet extends StatefulWidget {
  final TemplateBerkasItem item;

  const _TemplateBerkasDetailSheet({required this.item});

  @override
  State<_TemplateBerkasDetailSheet> createState() =>
      _TemplateBerkasDetailSheetState();
}

class _TemplateBerkasDetailSheetState extends State<_TemplateBerkasDetailSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // ── Header: Slot + Phase + Title + Close Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.slotNumber,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.group.sectionTitle,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF64748B),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // ── Scrollable Body ──
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata Grid: Format & Max File Size
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FORMAT BERKAS',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.fileFormat,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MAKSIMAL UKURAN',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.maxFileSize,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Tujuan Dokumen
                    const Text(
                      'TUJUAN DOKUMEN',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.purpose,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Instansi Penerbit Terkait
                    const Text(
                      'INSTANSI PENERBIT TERKAIT',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.account_balance_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.issuingAgency,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Panduan Persiapan
                    const Text(
                      'PANDUAN PERSIAPAN',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.guidance,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Contextual Availability Notice
                    _buildAvailabilityCallout(item),

                    // ── Format & Template Section (Only for GUIDANCE_ONLY & TEMPLATE_PENDING) ──
                    if (item.hasFormatAndTemplateSection) ...[
                      const SizedBox(height: 18),
                      _buildFormatAndTemplateSection(item),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer Action: Tutup Informasi ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tutup Informasi',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds context-aware availability box based on DocumentAvailabilityStatus
  Widget _buildAvailabilityCallout(TemplateBerkasItem item) {
    final status = item.availabilityStatus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.icon,
            size: 18,
            color: status.iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status.titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.message,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: status.messageColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dedicated "Format & Template" section for GUIDANCE_ONLY and TEMPLATE_PENDING.
  ///
  /// Ready for future verified assets without dummy links or fake downloads.
  Widget _buildFormatAndTemplateSection(TemplateBerkasItem item) {
    final bool isAvailable =
        item.templateVerified && item.templateAssetPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FORMAT & TEMPLATE',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Icon + Name + Availability Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.templateFileName ?? item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAvailable
                              ? (item.templateMimeType ?? 'Berkas Tersedia')
                              : 'Format dokumen belum disediakan untuk diunduh.',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAvailable
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      isAvailable ? 'Tersedia' : 'Belum Tersedia',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Button (Active only when verified asset exists, otherwise cleanly disabled)
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: isAvailable
                      ? () {
                          // Future download handler when official files are registered
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isAvailable
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text(
                    'Unduh Template',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
