import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/monitoring_model.dart';
import '../data/models/report_photo.dart';
import '../data/photo_bytes_cache.dart';
import '../services/stamp_renderer.dart';

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
  static Future<void> printAndShare(MonitoringModel monitoring) async {
    final doc = buildDocument(monitoring);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  /// Menyusun dokumen BA tanpa membuka pratinjau cetak.
  static pw.Document buildDocument(MonitoringModel monitoring) {
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
          if (monitoring.photos.isNotEmpty) ..._buildPhotoSection(monitoring),

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

  /// Bagian "VI. Dokumentasi Lapangan": foto bergeotag dua kolom beserta
  /// keterangan waktu, alamat, dan koordinat.
  static List<pw.Widget> _buildPhotoSection(MonitoringModel monitoring) {
    const columnWidth = 245.0;
    const imageHeight = 170.0;
    pw.Widget cell(ReportPhoto photo, int number) {
      final bytes = photo.needsReselect ? null : PhotoBytesCache.get(photo.id);
      final stamp = photo.stamp;
      final note = stamp.note?.trim();
      final address = stamp.address?.trim();
      return pw.Container(
        width: columnWidth,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: columnWidth,
              height: imageHeight,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
              ),
              child: bytes == null
                  ? pw.Center(
                      child: pw.Text(
                        'Foto tidak tersedia',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    )
                  : pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Foto $number${note == null || note.isEmpty ? '' : ' - $note'}',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              StampRenderer.formatStampTime(stamp.capturedAt),
              style: const pw.TextStyle(fontSize: 8),
            ),
            if (address != null && address.isNotEmpty)
              pw.Text(address, style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
              StampRenderer.formatStampCoordinates(stamp),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );
    }

    return [
      pw.Text(
        'VI. Dokumentasi Lapangan',
        style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      pw.Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < monitoring.photos.length; i++)
            cell(monitoring.photos[i], i + 1),
        ],
      ),
      pw.SizedBox(height: 10),
    ];
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
