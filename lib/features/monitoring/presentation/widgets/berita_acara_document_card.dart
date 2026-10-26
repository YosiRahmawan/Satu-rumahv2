import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/monitoring_model.dart';
import 'ba_photo_gallery.dart';
import 'status_hasil_evaluasi_badge_widget.dart';

/// Pratinjau Berita Acara Monitoring dan Evaluasi Lapangan dengan susunan
/// dokumen resmi Dinas: judul tengah, bagian bernomor Romawi, penutup, kolom
/// tanda tangan, lalu dokumentasi foto. Sama dengan PDF yang dicetak.
///
/// Dipakai oleh [LaporanSuccessScreen] dan [LaporanPreviewScreen]. Hanya
/// menampilkan data asli dari [MonitoringModel], tanpa tanda tangan atau QR
/// fiktif.
class BeritaAcaraDocumentCard extends StatelessWidget {
  final MonitoringModel monitoring;
  final bool isSuccessContext;

  const BeritaAcaraDocumentCard({
    super.key,
    required this.monitoring,
    this.isSuccessContext = false,
  });

  static const double _indent = 30;

  static const TextStyle _body = TextStyle(
    fontFamily: 'serif',
    fontSize: 13,
    height: 1.5,
    color: Colors.black,
  );
  static const TextStyle _bold = TextStyle(
    fontFamily: 'serif',
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    final item = monitoring;
    final location = item.lokasiPerumahan.trim();
    final housing = item.namaPerumahan.trim();
    final housingLabel = housing.toLowerCase().startsWith('perumahan')
        ? housing
        : 'Perumahan $housing';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.enterpriseBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: item.isDraft
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.enterpriseWarningSurface,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      'DOKUMEN LOKAL • BELUM DITERBITKAN',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontFamily: AppTextStyles.enterpriseFontFamily,
                        color: AppColors.enterpriseWarning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : StatusHasilEvaluasiBadgeWidget(
                    status: item.statusHasilEvaluasi,
                  ),
          ),
          const SizedBox(height: 14),
          const Text(
            'BERITA ACARA MONITORING DAN EVALUASI LAPANGAN',
            textAlign: TextAlign.center,
            style: _bold,
          ),
          if (item.nomorSuratBA.trim().isNotEmpty)
            Text(
              'Nomor: ${item.nomorSuratBA}',
              textAlign: TextAlign.center,
              style: _body.copyWith(fontSize: 12),
            ),
          const SizedBox(height: 12),
          _paragraph(
            'Pada hari ini, ${_tanggalKata(item.tanggalMonitoring)} telah '
            'dilakukan monitoring dan evaluasi lapangan oleh Tim dari Dinas '
            'Perumahan dan Kawasan Permukiman Kota Tasikmalaya bertempat di '
            '$housingLabel'
            '${location.isEmpty ? '' : ' yang berlokasi di $location'}.',
            indented: false,
          ),
          _heading('I.', 'Maksud dan Tujuan'),
          ..._paragraphs([item.maksudTujuan]),
          _heading('II.', 'Temuan Di Lapangan'),
          ..._bullets(item.temuanLapangan),
          _heading('III.', 'Kesimpulan'),
          ..._paragraphs(item.kesimpulan),
          _heading('IV.', 'Kesepakatan'),
          ..._bullets(item.kesepakatan),
          _heading('V.', 'Rencana Tindak Lanjut'),
          ..._bullets(item.rencanaTindakLanjut),
          const SizedBox(height: 6),
          _paragraph(
            'Demikian Berita Acara ini dibuat dengan sebenarnya dan '
            'ditandatangani untuk digunakan sebagaimana mestinya.',
            indented: false,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _signColumn(
                'Yang Melaksanakan Observasi / Inspeksi',
                _people(
                  item.pelaksana,
                  item.pelaksanaNama,
                  item.pelaksanaJabatan,
                ),
              ),
              const SizedBox(width: 12),
              _signColumn(
                'Yang Ditemui di Lapangan',
                _people(item.ditemui, item.ditemuiNama, item.ditemuiJabatan),
              ),
            ],
          ),
          if (item.photos.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Divider(color: AppColors.enterpriseBorder, height: 1),
            const SizedBox(height: 14),
            const Text('Dokumentasi Lapangan :', style: _bold),
            const SizedBox(height: 8),
            BaPhotoGallery(photos: item.photos),
          ],
        ],
      ),
    );
  }

  Widget _heading(String number, String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _indent,
          child: Text(number, style: _bold),
        ),
        Expanded(child: Text(title, style: _bold)),
      ],
    ),
  );

  Widget _paragraph(String value, {bool indented = true}) => Padding(
    padding: EdgeInsets.only(left: indented ? _indent : 0, bottom: 4),
    child: Text(value, textAlign: TextAlign.justify, style: _body),
  );

  List<Widget> _paragraphs(List<String> items) {
    final valid = items.where((e) => e.trim().isNotEmpty).toList();
    return [
      for (final e in valid.isEmpty ? const ['-'] : valid) _paragraph(e),
    ];
  }

  List<Widget> _bullets(List<String> items) {
    final valid = items.where((e) => e.trim().isNotEmpty).toList();
    return [
      for (final e in valid.isEmpty ? const ['-'] : valid)
        Padding(
          padding: const EdgeInsets.only(left: _indent, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 20,
                child: Padding(
                  padding: EdgeInsets.only(top: 9, left: 6),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(e, textAlign: TextAlign.justify, style: _body),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _signColumn(String title, List<MonitoringPerson> people) {
    final shown = people.isEmpty ? const [MonitoringPerson()] : people;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title\n(Nama, Jabatan, Tanda Tangan)',
            textAlign: TextAlign.center,
            style: _body.copyWith(fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 44),
          for (final person in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Nama     : ${_orDash(person.nama)}\n'
                'Jabatan : ${_orDash(person.jabatan)}',
                style: _bold.copyWith(fontSize: 12, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  static List<MonitoringPerson> _people(
    List<MonitoringPerson> list,
    String name,
    String role,
  ) {
    final valid = list.where((p) => p.nama.trim().isNotEmpty).toList();
    if (valid.isNotEmpty) return valid;
    if (name.trim().isNotEmpty) {
      return [MonitoringPerson(nama: name, jabatan: role)];
    }
    return const [];
  }

  static String _orDash(String value) => value.trim().isEmpty ? '-' : value;

  static String _tanggalKata(DateTime dt) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      '',
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
    return '${hari[dt.weekday - 1]} tanggal ${dt.day} bulan ${bulan[dt.month]} tahun ${dt.year}';
  }
}
