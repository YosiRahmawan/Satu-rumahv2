import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_form_provider.dart';
import '../../utils/ba_pdf_generator.dart';

class LaporanPreviewScreen extends ConsumerStatefulWidget {
  final MonitoringModel monitoring;
  final bool isDraft;

  const LaporanPreviewScreen({
    super.key,
    required this.monitoring,
    this.isDraft = false,
  });

  @override
  ConsumerState<LaporanPreviewScreen> createState() =>
      _LaporanPreviewScreenState();
}

class _LaporanPreviewScreenState extends ConsumerState<LaporanPreviewScreen> {
  bool _isPdfBusy = false;
  bool _isShareBusy = false;
  String _formatFullIndonesianDate(DateTime dt) {
    const hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulanList = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hari = hariList[dt.weekday - 1];
    final bulan = bulanList[dt.month - 1];
    return 'hari $hari tanggal ${dt.day} bulan $bulan tahun ${dt.year}';
  }

  String _sanitizePerumahan(String name) {
    if (name.toLowerCase().startsWith('perumahan ')) {
      return name;
    }
    return 'Perumahan $name';
  }

  @override
  Widget build(BuildContext context) {
    final monitoring = widget.monitoring;

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/monitoring/lapangan');
              }
            },
            borderRadius: AppRadii.pill,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.enterpriseBorder),
                color: AppColors.enterpriseSurface,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.enterpriseTextMain,
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          'Preview Berita Acara',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            color: AppColors.enterpriseTextMain,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildBeritaAcaraDocument(monitoring),
            ),
          ),
          _buildBottomActions(context, monitoring),
        ],
      ),
    );
  }

  Widget _buildBeritaAcaraDocument(MonitoringModel item) {
    final fullDateSentence = _formatFullIndonesianDate(item.tanggalMonitoring);
    final perumahanFormatted = item.namaPerumahan.isNotEmpty
        ? _sanitizePerumahan(item.namaPerumahan)
        : 'nama perumahan yang belum diisi';

    return DefaultTextStyle(
      style: AppTextStyles.bodySmall.copyWith(
        fontFamily: AppTextStyles.enterpriseFontFamily,
        color: AppColors.enterpriseTextMain,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.enterpriseSurface,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.enterpriseBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kop Surat Disperwaskim
            const Text(
              'PEMERINTAH KOTA TASIKMALAYA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            const Text(
              'DINAS PERUMAHAN DAN KAWASAN PERMUKIMAN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Judul Dokumen & Nomor BA
            const Text(
              'BERITA ACARA MONITORING\nDAN EVALUASI LAPANGAN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.enterpriseTextMain,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Nomor: ${item.nomorSuratBA}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.enterpriseTextMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Divider(thickness: 1.5, color: AppColors.enterpriseTextMain),
            const SizedBox(height: 16),

            // Paragraf Pembuka
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pada hari ini, $fullDateSentence, telah dilakukan monitoring pada $perumahanFormatted.',
                style: const TextStyle(fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 14),

            // Poin I: Temuan di Lapangan
            _buildSectionTitle('I. Temuan di Lapangan'),
            _buildBulletList(item.temuanLapangan),
            const SizedBox(height: 12),

            // Poin II: Kesimpulan
            _buildSectionTitle('II. Kesimpulan'),
            _buildBulletList(item.kesimpulan),
            const SizedBox(height: 12),

            // Poin III: Kesepakatan
            _buildSectionTitle('III. Kesepakatan'),
            _buildBulletList(item.kesepakatan),
            const SizedBox(height: 12),

            // Poin IV: Rencana Tindak Lanjut
            _buildSectionTitle('IV. Rencana Tindak Lanjut'),
            _buildBulletList(item.rencanaTindakLanjut),
            const SizedBox(height: 16),

            // Grid Foto Evidence
            if (item.photoPaths.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: item.photoPaths.length,
                itemBuilder: (context, index) {
                  final path = item.photoPaths[index];
                  final isUrl = path.startsWith('http');
                  return ClipRRect(
                    borderRadius: AppRadii.small,
                    child: isUrl
                        ? Image.network(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.enterpriseBorder,
                              child: const Icon(
                                Icons.image,
                                color: AppColors.enterpriseTextMuted,
                              ),
                            ),
                          )
                        : Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.enterpriseBorder,
                              child: const Icon(
                                Icons.image,
                                color: AppColors.enterpriseTextMuted,
                              ),
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (_hasSignatoryData(item)) ...[
              const Divider(thickness: 1, color: AppColors.enterpriseBorder),
              const SizedBox(height: AppSpacing.lg),
              _buildSignatoryInfo(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.enterpriseTextMain,
          ),
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    final validItems = items.where((e) => e.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('• -', style: TextStyle(fontSize: 11)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: validItems
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomActions(BuildContext context, MonitoringModel monitoring) {
    final formState = ref.watch(monitoringFormProvider);
    if (widget.isDraft) {
      // Mode Draft (Before submit)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: AppColors.enterpriseSurface),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.enterprisePrimary,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  onPressed: formState.isSubmitting
                      ? null
                      : () {
                          final result = ref
                              .read(monitoringFormProvider.notifier)
                              .submitFinal(monitoring);
                          if (!context.mounted) return;
                          if (result.isSuccess && result.model != null) {
                            context.go(
                              '/monitoring/success',
                              extra: result.model,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.errorMessage ??
                                      'Laporan gagal dikirim.',
                                ),
                                backgroundColor: AppColors.enterprisePrimary,
                              ),
                            );
                          }
                        },
                  icon: formState.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                  label: const Text(
                    'SUBMIT LAPORAN SEKARANG',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.enterpriseBorder),
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/monitoring/tambah');
                    }
                  },
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.enterpriseTextMain,
                    size: 16,
                  ),
                  label: const Text(
                    'Kembali & Edit Form',
                    style: TextStyle(
                      color: AppColors.enterpriseTextMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mode Final / Preview (Mockup 2 buttons layout)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: AppColors.enterpriseSurface),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button 1: Download / print the locally generated PDF.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.enterprisePrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(46),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                  ),
                  onPressed: _isBusy
                      ? null
                      : () async {
                          if (_isBusy) return;
                          setState(() => _isPdfBusy = true);
                          try {
                            await BaPdfGenerator.printAndShare(monitoring);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal menyiapkan PDF. Coba lagi.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isPdfBusy = false);
                          }
                        },
                  icon: _isPdfBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.file_download,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isPdfBusy ? 'Menyiapkan PDF...' : 'Download / Cetak PDF',
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Sharing remains a general platform action; no channel is fabricated.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.enterpriseSuccess,
                      width: 1.2,
                    ),
                    minimumSize: const Size.fromHeight(46),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  onPressed: _isBusy
                      ? null
                      : () async {
                          if (_isBusy) return;
                          setState(() => _isShareBusy = true);
                          final teks =
                              'RINGKASAN BERITA ACARA MONITORING (DIBUAT LOKAL)\n'
                              'Perumahan: ${monitoring.namaPerumahan}\n'
                              'Nomor BA: ${monitoring.nomorSuratBA}\n'
                              'Status: ${monitoring.statusHasilEvaluasi.label}';
                          try {
                            await SharePlus.instance.share(
                              ShareParams(text: teks),
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal membuka menu berbagi.'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isShareBusy = false);
                            }
                          }
                        },
                  icon: const Icon(
                    Icons.near_me,
                    color: AppColors.enterpriseSuccess,
                    size: 16,
                  ),
                  label: Text(
                    _isShareBusy
                        ? 'Membuka menu berbagi...'
                        : 'Bagikan ringkasan',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: AppColors.enterpriseSuccess,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.enterpriseBorder,
                      width: 1.2,
                    ),
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  onPressed: null,
                  icon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.enterpriseTextMain,
                    size: 16,
                  ),
                  label: Text(
                    'Email: Belum tersedia',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: AppColors.enterpriseTextMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Button 4: Simpan ke Arsip Sistem (Red Outlined Pill)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.enterprisePrimary,
                      width: 1.2,
                    ),
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  onPressed: null,
                  icon: const Icon(
                    Icons.archive_outlined,
                    color: AppColors.enterpriseTextMuted,
                    size: 16,
                  ),
                  label: const Text(
                    'Arsip Sistem: Belum tersedia',
                    style: TextStyle(
                      color: AppColors.enterpriseTextMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  static TextStyle get _documentBodyStyle => AppTextStyles.bodySmall.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    height: 1.45,
    color: AppColors.enterpriseTextMain,
  );

  bool _hasSignatoryData(MonitoringModel item) =>
      item.pelaksanaNama.trim().isNotEmpty ||
      item.ditemuiNama.trim().isNotEmpty;

  Widget _buildSignatoryInfo(MonitoringModel item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Identitas pihak yang tercatat',
        style: AppTextStyles.labelMedium.copyWith(
          fontFamily: AppTextStyles.enterpriseFontFamily,
          fontWeight: FontWeight.bold,
          color: AppColors.enterpriseTextMain,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (item.pelaksanaNama.trim().isNotEmpty)
        _buildIdentityRow(
          'Pelaksana',
          item.pelaksanaNama,
          item.pelaksanaJabatan,
        ),
      if (item.ditemuiNama.trim().isNotEmpty)
        _buildIdentityRow('Ditemui', item.ditemuiNama, item.ditemuiJabatan),
    ],
  );

  Widget _buildIdentityRow(String label, String name, String role) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.labelSmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
          TextSpan(
            text: name,
            style: _documentBodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          if (role.trim().isNotEmpty)
            TextSpan(
              text: ' ($role)',
              style: AppTextStyles.labelSmall.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                color: AppColors.enterpriseTextMuted,
              ),
            ),
        ],
      ),
    ),
  );

  bool get _isBusy => _isPdfBusy || _isShareBusy;
}
