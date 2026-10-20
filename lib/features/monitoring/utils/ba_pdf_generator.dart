import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/evidence_photo_item.dart';
import '../data/models/monitoring_model.dart';
import '../data/models/project_reference.dart';
import '../data/photo_bytes_cache.dart';
import 'photo_location_summary.dart';
import 'photo_validation.dart';

class BaPdfGenerator {
  static const List<String> _bulanIndonesia = [
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

  static const List<String> _hariIndonesia = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String _angkaKataTanggal(DateTime dt) {
    final hari = _hariIndonesia[dt.weekday - 1];
    final bulan = _bulanIndonesia[dt.month];
    return 'hari $hari tanggal ${dt.day} bulan $bulan tahun ${dt.year}';
  }

  /// Generate PDF dokumen BA dan tampilkan native print preview.
  ///
  /// [reference] adalah titik proyek dari Pengembang bila tersedia; tanpa itu
  /// jarak foto ke proyek dicatat sebagai tidak dihitung.
  static Future<void> printAndShare(
    MonitoringModel monitoring, {
    ProjectReference? reference,
  }) async {
    final doc = buildDocument(monitoring, reference: reference);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  /// Menyusun dokumen BA tanpa membuka pratinjau cetak.
  static pw.Document buildDocument(
    MonitoringModel monitoring, {
    ProjectReference? reference,
  }) {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Text(
              'DOKUMEN LOKAL - BELUM DITERBITKAN ATAU DIKONFIRMASI SERVER',
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          // Kop Surat
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'PEMERINTAH KOTA TASIKMALAYA',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'DINAS PERUMAHAN DAN KAWASAN PERMUKIMAN',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 8),
                pw.Text(
                  'BERITA ACARA MONITORING DAN EVALUASI LAPANGAN',
                  style: const pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Nomor: ${monitoring.nomorSuratBA}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Paragraf pembuka
          pw.Text(
            'Data lokal ini mencatat monitoring pada ${_angkaKataTanggal(monitoring.tanggalMonitoring)} '
            'untuk ${monitoring.namaPerumahan} yang berlokasi di '
            '${monitoring.lokasiPerumahan.isNotEmpty ? monitoring.lokasiPerumahan : "-"}. '
            'Dokumen ini merupakan preview/hasil lokal dan bukan bukti penerbitan resmi.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),

          // Poin I-V
          _buildPdfSection('I. Maksud dan Tujuan', [monitoring.maksudTujuan]),
          _buildPdfSection('II. Temuan Di Lapangan', monitoring.temuanLapangan),
          _buildPdfSection('III. Kesimpulan', monitoring.kesimpulan),
          _buildPdfSection('IV. Kesepakatan', monitoring.kesepakatan),
          _buildPdfSection(
            'V. Rencana Tindak Lanjut',
            monitoring.rencanaTindakLanjut,
          ),
          ..._buildPhotoSection(monitoring, reference),

          if (monitoring.pelaksanaNama.trim().isNotEmpty ||
              monitoring.ditemuiNama.trim().isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Identitas pihak yang tercatat',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (monitoring.pelaksanaNama.trim().isNotEmpty)
              pw.Text(
                'Pelaksana: ${monitoring.pelaksanaNama}${monitoring.pelaksanaJabatan.trim().isNotEmpty ? ' (${monitoring.pelaksanaJabatan})' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (monitoring.ditemuiNama.trim().isNotEmpty)
              pw.Text(
                'Ditemui: ${monitoring.ditemuiNama}${monitoring.ditemuiJabatan.trim().isNotEmpty ? ' (${monitoring.ditemuiJabatan})' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ],
      ),
    );

    return doc;
  }

  static List<pw.Widget> _buildPhotoSection(
    MonitoringModel monitoring,
    ProjectReference? reference,
  ) {
    final photos = [
      for (final photo in monitoring.photos)
        if (photo.localRef.trim().isNotEmpty) photo,
    ];
    if (photos.isEmpty) return const [];
    return [
      pw.Text(
        'VI. Dokumentasi Foto Lapangan',
        style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      for (var i = 0; i < photos.length; i++)
        _buildPhotoRow(i + 1, photos[i], reference),
    ];
  }

  static pw.Widget _buildPhotoRow(
    int number,
    EvidencePhotoItem photo,
    ProjectReference? reference,
  ) {
    final summary = summarizePhotoLocation(photo, reference: reference);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, height: 105, child: _photoImage(photo)),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Foto $number',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                for (final line in summary.lines)
                  pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Paket pdf hanya dapat menyisipkan JPEG dan PNG; format lain diganti
  /// keterangan agar dokumen tetap jujur tentang isinya.
  static pw.Widget _photoImage(EvidencePhotoItem photo) {
    final bytes = PhotoBytesCache.get(photo.localRef);
    final format = bytes == null ? null : detectPhotoFormat(bytes);
    if (bytes != null &&
        (format == PhotoFormat.jpeg || format == PhotoFormat.png)) {
      try {
        return pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
      } catch (_) {
        // jatuh ke keterangan di bawah
      }
    }
    return pw.Container(
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
      ),
      child: pw.Text(
        bytes == null ? 'Foto tidak tersedia' : 'Foto tidak dapat disisipkan',
        style: const pw.TextStyle(fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildPdfSection(String title, List<String> items) {
    final valid = items.where((e) => e.trim().isNotEmpty).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        if (valid.isEmpty)
          pw.Text('• -', style: const pw.TextStyle(fontSize: 11))
        else
          ...valid.map(
            (e) => pw.Text('• $e', style: const pw.TextStyle(fontSize: 11)),
          ),
        pw.SizedBox(height: 10),
      ],
    );
  }
}
