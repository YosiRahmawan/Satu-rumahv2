import 'ba_signature.dart';
import 'monitoring_model.dart';
import 'status_hasil_evaluasi.dart';

/// Ringkasan BA milik petugas dari server (`GET officer/reports`): sumber riwayat yang tahan
/// pasang ulang aplikasi, beserta status tanda tangan dan penerbitan.
class ServerReport {
  const ServerReport({
    required this.id,
    required this.reportNumber,
    required this.namaPerumahan,
    required this.tanggal,
    required this.hasil,
    this.submittedAt,
    this.photoCount = 0,
    this.signatures = const BaSignatureStatus(),
    this.status = 'final',
  });

  final int id;
  final String reportNumber;
  final String namaPerumahan;
  final DateTime tanggal;
  final StatusHasilEvaluasi hasil;
  final DateTime? submittedAt;
  final int photoCount;

  /// `final`, atau `revisi` bila Admin mengembalikannya dan petugas perlu membuat BA pengganti.
  final String status;

  bool get isRevisi => status == 'revisi';

  /// Status Ketua, Admin, dan penerbitan.
  final BaSignatureStatus signatures;

  factory ServerReport.fromJson(Map<String, dynamic> json) {
    final published = json['published_at'] != null;
    final base = BaSignatureStatus.fromReport(json);
    return ServerReport(
      id: json['id'] as int,
      reportNumber: '${json['report_number'] ?? ''}',
      namaPerumahan: '${json['nama_perumahan'] ?? ''}',
      tanggal:
          DateTime.tryParse('${json['monitoring_date'] ?? ''}') ??
          DateTime.now(),
      hasil: _hasil(json['status_hasil_evaluasi']),
      submittedAt: DateTime.tryParse(
        '${json['submitted_at'] ?? ''}',
      )?.toLocal(),
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? 'final'}',
      signatures: BaSignatureStatus(
        ketuaSigned: base.ketuaSigned,
        adminSigned: base.adminSigned,
        ketuaAt: base.ketuaAt,
        published: published,
        version: base.version,
      ),
    );
  }

  static StatusHasilEvaluasi _hasil(Object? v) =>
      StatusHasilEvaluasi.values.firstWhere(
        (e) => e.name == v,
        orElse: () => StatusHasilEvaluasi.sesuaiSiteplan,
      );

  /// Kartu riwayat untuk BA yang hanya ada di server (isi lengkap diambil saat dibuka).
  MonitoringModel toStub() => MonitoringModel(
    id: 'srv-$id',
    tanggalMonitoring: tanggal,
    namaPerumahan: namaPerumahan,
    statusHasilEvaluasi: hasil,
    nomorSuratBA: reportNumber,
    createdAt: submittedAt ?? tanggal,
  );

  /// Isi BA lengkap dari `GET officer/reports/{id}`. Foto tidak diunduh ulang (ada di server).
  static MonitoringModel detailToModel(Map<String, dynamic> json) {
    List<String> teks(Object? v) => [
      if (v is List)
        for (final e in v)
          if ('$e'.trim().isNotEmpty) '$e',
    ];
    List<MonitoringPerson> orang(Object? v) => [
      if (v is List)
        for (final e in v)
          if (e is Map)
            MonitoringPerson(
              nama: '${e['nama'] ?? ''}',
              jabatan: '${e['jabatan'] ?? ''}',
            ),
    ];
    final id = json['id'];
    return MonitoringModel(
      id: 'srv-$id',
      tanggalMonitoring:
          DateTime.tryParse('${json['monitoring_date'] ?? ''}') ??
          DateTime.now(),
      namaPerumahan: '${json['nama_perumahan'] ?? ''}',
      lokasiPerumahan: '${json['lokasi'] ?? ''}',
      maksudTujuan: '${json['maksud_tujuan'] ?? ''}',
      temuanLapangan: teks(json['temuan']),
      kesimpulan: teks(json['kesimpulan']),
      kesepakatan: teks(json['kesepakatan']),
      rencanaTindakLanjut: teks(json['rtl']),
      statusHasilEvaluasi: _hasil(json['status_hasil_evaluasi']),
      pelaksana: orang(json['tim_pelaksana']),
      ditemui: orang(json['pihak_ditemui']),
      nomorSuratBA: '${json['report_number'] ?? ''}',
      createdAt: DateTime.tryParse('${json['submitted_at'] ?? ''}')?.toLocal(),
    );
  }
}
