import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/monitoring_model.dart';
import '../data/models/report_photo.dart';
import '../data/photo_bytes_cache.dart';

/// Berita Acara Monitoring dan Evaluasi Lapangan, mengikuti format dokumen
/// resmi Dinas: kertas F4, Times 12, judul tengah, bagian bernomor Romawi,
/// penutup, kolom tanda tangan, lalu halaman dokumentasi foto.
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

  /// Kertas F4 (215,9 x 330,2 mm), seperti dokumen contoh Dinas.
  static const PdfPageFormat _f4 = PdfPageFormat(
    609.6,
    935.5,
    marginLeft: 57,
    marginRight: 57,
    marginTop: 72,
    marginBottom: 57,
  );

  static const double _indent = 28;

  /// Generate PDF dokumen BA dan tampilkan native print preview.
  static Future<void> printAndShare(MonitoringModel monitoring) async {
    final doc = buildDocument(monitoring);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  /// Menyusun dokumen BA tanpa membuka pratinjau cetak.
  static pw.Document buildDocument(MonitoringModel monitoring) {
    final doc = pw.Document();
    final base = pw.Font.times();
    final bold = pw.Font.timesBold();
    final text = pw.TextStyle(font: base, fontSize: 12, lineSpacing: 4);
    final strong = text.copyWith(font: bold, fontWeight: pw.FontWeight.bold);

    pw.Widget heading(String number, String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: _indent,
            child: pw.Text(number, style: strong),
          ),
          pw.Expanded(child: pw.Text(title, style: strong)),
        ],
      ),
    );

    pw.Widget paragraph(String value, {bool indented = true}) => pw.Padding(
      padding: pw.EdgeInsets.only(left: indented ? _indent : 0, bottom: 4),
      child: pw.Text(value, style: text, textAlign: pw.TextAlign.justify),
    );

    pw.Widget bullet(String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(left: _indent, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Titik digambar sendiri: font Times bawaan tidak punya glyph "•".
          pw.SizedBox(
            width: 24,
            child: pw.Align(
              alignment: pw.Alignment.topLeft,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(left: 7, top: 7),
                child: pw.Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: text, textAlign: pw.TextAlign.justify),
          ),
        ],
      ),
    );

    List<pw.Widget> bullets(List<String> items) {
      final valid = items.where((e) => e.trim().isNotEmpty).toList();
      return [
        for (final e in valid.isEmpty ? const ['-'] : valid) bullet(e),
      ];
    }

    List<pw.Widget> paragraphs(List<String> items) {
      final valid = items.where((e) => e.trim().isNotEmpty).toList();
      return [
        for (final e in valid.isEmpty ? const ['-'] : valid) paragraph(e),
      ];
    }

    final pelaksana = _people(
      monitoring.pelaksana,
      monitoring.pelaksanaNama,
      monitoring.pelaksanaJabatan,
    );
    final ditemui = _people(
      monitoring.ditemui,
      monitoring.ditemuiNama,
      monitoring.ditemuiJabatan,
    );

    pw.Widget signColumn(String title, List<MonitoringPerson> people) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(title, style: text, textAlign: pw.TextAlign.center),
                  pw.Text(
                    '(Nama, Jabatan, Tanda Tangan)',
                    style: text,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 64),
            for (final person
                in people.isEmpty ? const [MonitoringPerson()] : people)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6, left: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nama     : ${_orDash(person.nama)}',
                      style: strong,
                    ),
                    pw.Text(
                      'Jabatan : ${_orDash(person.jabatan)}',
                      style: strong,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final location = monitoring.lokasiPerumahan.trim();
    final housing = monitoring.namaPerumahan.trim();
    final housingLabel = housing.toLowerCase().startsWith('perumahan')
        ? housing
        : 'Perumahan $housing';

    doc.addPage(
      pw.MultiPage(
        pageFormat: _f4,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (pw.Context context) => [
          if (monitoring.isDraft)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'DRAF - belum final',
                style: text.copyWith(fontSize: 9),
              ),
            ),
          pw.Center(
            child: pw.Text(
              'BERITA ACARA MONITORING DAN EVALUASI LAPANGAN',
              style: strong,
            ),
          ),
          if (monitoring.nomorSuratBA.trim().isNotEmpty)
            pw.Center(
              child: pw.Text(
                'Nomor: ${monitoring.nomorSuratBA}',
                style: text.copyWith(fontSize: 11),
              ),
            ),
          pw.SizedBox(height: 14),
          paragraph(
            'Pada hari ini, ${_tanggalKata(monitoring.tanggalMonitoring)} '
            'telah dilakukan monitoring dan evaluasi lapangan oleh Tim dari '
            'Dinas Perumahan dan Kawasan Permukiman Kota Tasikmalaya '
            'bertempat di $housingLabel'
            '${location.isEmpty ? '' : ' yang berlokasi di $location'}.',
            indented: false,
          ),
          heading('I.', 'Maksud dan Tujuan'),
          ...paragraphs([monitoring.maksudTujuan]),
          heading('II.', 'Temuan Di Lapangan'),
          ...bullets(monitoring.temuanLapangan),
          heading('III.', 'Kesimpulan'),
          ...paragraphs(monitoring.kesimpulan),
          heading('IV.', 'Kesepakatan'),
          ...bullets(monitoring.kesepakatan),
          heading('V.', 'Rencana Tindak Lanjut'),
          ...bullets(monitoring.rencanaTindakLanjut),
          pw.SizedBox(height: 4),
          paragraph(
            'Demikian Berita Acara ini dibuat dengan sebenarnya dan '
            'ditandatangani untuk digunakan sebagaimana mestinya.',
            indented: false,
          ),
          pw.SizedBox(height: 36),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              signColumn('Yang Melaksanakan Observasi / Inspeksi', pelaksana),
              pw.SizedBox(width: 24),
              signColumn('Yang Ditemui di Lapangan', ditemui),
            ],
          ),
          if (monitoring.photos.isNotEmpty) ...[
            pw.NewPage(),
            ..._buildPhotoSection(monitoring, strong),
          ],
        ],
      ),
    );

    return doc;
  }

  /// Halaman dokumentasi: foto bergeotag dua kolom dalam bingkai tipis.
  /// Watermark (waktu, alamat, koordinat) sudah menempel di foto, jadi foto
  /// ditampilkan utuh tanpa keterangan terpisah.
  static List<pw.Widget> _buildPhotoSection(
    MonitoringModel monitoring,
    pw.TextStyle headingStyle,
  ) {
    const columnWidth = 240.0;
    pw.Widget cell(ReportPhoto photo) {
      final bytes = photo.needsReselect ? null : PhotoBytesCache.get(photo.id);
      return pw.Container(
        width: columnWidth,
        padding: const pw.EdgeInsets.all(2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700, width: 0.6),
        ),
        child: bytes == null
            ? pw.Container(
                height: 120,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Foto tidak tersedia',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              )
            : _fitted(bytes, columnWidth - 4),
      );
    }

    return [
      pw.Text('Dokumentasi Lapangan :', style: headingStyle),
      pw.SizedBox(height: 8),
      pw.Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final photo in monitoring.photos) cell(photo)],
      ),
    ];
  }

  /// Foto selebar kolom dengan tinggi mengikuti rasio aslinya.
  static pw.Widget _fitted(Uint8List bytes, double width) {
    final image = pw.MemoryImage(bytes);
    final w = image.width ?? 1;
    final h = image.height ?? 1;
    return pw.SizedBox(
      width: width,
      height: width * h / w,
      child: pw.Image(image, fit: pw.BoxFit.fill),
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
    final hari = _hariIndonesia[dt.weekday - 1];
    final bulan = _bulanIndonesia[dt.month];
    return '$hari tanggal ${dt.day} bulan $bulan tahun ${dt.year}';
  }
}
