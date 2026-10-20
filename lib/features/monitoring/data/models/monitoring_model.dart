import 'status_hasil_evaluasi.dart';

/// A repeatable person captured during a field monitoring session.
///
/// The current local/API contract still consumes the legacy singular person
/// fields below. These typed entries are therefore local compatibility data
/// until a server contract for multiple identities is available.
class MonitoringPerson {
  static int _nextId = 0;

  final String id;
  final String nama;
  final String jabatan;

  const MonitoringPerson({this.id = '', this.nama = '', this.jabatan = ''});

  factory MonitoringPerson.create({String nama = '', String jabatan = ''}) {
    return MonitoringPerson(
      id: 'monitoring-person-${++_nextId}',
      nama: nama,
      jabatan: jabatan,
    );
  }

  MonitoringPerson copyWith({String? id, String? nama, String? jabatan}) {
    return MonitoringPerson(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      jabatan: jabatan ?? this.jabatan,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'jabatan': jabatan};

  static MonitoringPerson fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return MonitoringPerson(
      id: map['id'] as String? ?? '',
      nama: map['nama'] as String? ?? '',
      jabatan: map['jabatan'] as String? ?? '',
    );
  }
}

class MonitoringModel {
  static const String defaultMaksudTujuan =
      'Kegiatan ini dilaksanakan guna memastikan kesesuaian pelaksanaan dengan '
      'perencanaan sebagai bagian dari fungsi pengawasan dan pengendalian '
      'terhadap proses pembangunan perumahan beserta penyediaan PSU-nya.';

  static const List<String> _bulanRomawi = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
  ];

  /// Nomor surat BA: 600.2.5/BA-MON/[bulanRomawi]/[tahun], dengan urutan
  /// tiga digit di belakangnya bila [urutan] > 0 (mis. .../X/2026/002).
  ///
  /// Tanpa [urutan] hasilnya sama dengan format lama, sehingga laporan lama
  /// tidak berubah.
  static String generateNomorSuratBA(DateTime tanggal, {int urutan = 0}) {
    final bulan = _bulanRomawi[tanggal.month - 1];
    final tahun = tanggal.year;
    final base = '600.2.5/BA-MON/$bulan/$tahun';
    return urutan > 0 ? '$base/${urutan.toString().padLeft(3, '0')}' : base;
  }

  final String id;
  final String? pengajuanId;
  final DateTime tanggalMonitoring;
  final String namaPerumahan;
  final String namaDeveloper;
  final String lokasiPerumahan;
  final String maksudTujuan;
  final List<String> temuanLapangan;
  final List<String> kesimpulan;
  final List<String> kesepakatan;
  final List<String> rencanaTindakLanjut;
  final StatusHasilEvaluasi statusHasilEvaluasi;
  final String pelaksanaNama;
  final String pelaksanaJabatan;
  final String ditemuiNama;
  final String ditemuiJabatan;
  final List<MonitoringPerson> pelaksana;
  final List<MonitoringPerson> ditemui;

  final DateTime createdAt;
  final String nomorSuratBA;
  final bool isDraft;

  MonitoringModel({
    required this.id,
    this.pengajuanId,
    required this.tanggalMonitoring,
    required this.namaPerumahan,
    this.namaDeveloper = '',
    this.lokasiPerumahan = '',
    this.maksudTujuan = defaultMaksudTujuan,
    this.temuanLapangan = const [],
    this.kesimpulan = const [],
    this.kesepakatan = const [],
    this.rencanaTindakLanjut = const [],
    this.statusHasilEvaluasi = StatusHasilEvaluasi.sesuaiSiteplan,
    this.pelaksanaNama = '',
    this.pelaksanaJabatan = '',
    this.ditemuiNama = '',
    this.ditemuiJabatan = '',
    this.pelaksana = const [],
    this.ditemui = const [],
    DateTime? createdAt,
    String? nomorSuratBA,
    this.isDraft = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       nomorSuratBA = nomorSuratBA ?? generateNomorSuratBA(tanggalMonitoring);

  Map<String, dynamic> toJson() => {
    'id': id,
    if (pengajuanId != null) 'pengajuanId': pengajuanId,
    'tanggalMonitoring': tanggalMonitoring.toIso8601String(),
    'namaPerumahan': namaPerumahan,
    'namaDeveloper': namaDeveloper,
    'lokasiPerumahan': lokasiPerumahan,
    'maksudTujuan': maksudTujuan,
    'temuanLapangan': temuanLapangan,
    'kesimpulan': kesimpulan,
    'kesepakatan': kesepakatan,
    'rencanaTindakLanjut': rencanaTindakLanjut,
    'statusHasilEvaluasi': statusHasilEvaluasi.name,
    'pelaksanaNama': pelaksanaNama,
    'pelaksanaJabatan': pelaksanaJabatan,
    'ditemuiNama': ditemuiNama,
    'ditemuiJabatan': ditemuiJabatan,
    'pelaksana': [for (final p in pelaksana) p.toJson()],
    'ditemui': [for (final p in ditemui) p.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'nomorSuratBA': nomorSuratBA,
    'isDraft': isDraft,
  };

  /// Membaca laporan dari JSON; null bila data inti rusak.
  static MonitoringModel? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final date = DateTime.tryParse('${json['tanggalMonitoring']}');
    final name = json['namaPerumahan'];
    if (id is! String || id.isEmpty || date == null || name is! String) {
      return null;
    }
    List<String> strings(Object? value) => [
      if (value is List)
        for (final item in value)
          if (item is String) item,
    ];
    List<MonitoringPerson> people(Object? value) => [
      if (value is List)
        for (final item in value) MonitoringPerson.fromJson(item),
    ];
    final status = StatusHasilEvaluasi.values.where(
      (v) => v.name == json['statusHasilEvaluasi'],
    );
    return MonitoringModel(
      id: id,
      pengajuanId: json['pengajuanId'] as String?,
      tanggalMonitoring: date,
      namaPerumahan: name,
      namaDeveloper: json['namaDeveloper'] as String? ?? '',
      lokasiPerumahan: json['lokasiPerumahan'] as String? ?? '',
      maksudTujuan: json['maksudTujuan'] as String? ?? defaultMaksudTujuan,
      temuanLapangan: strings(json['temuanLapangan']),
      kesimpulan: strings(json['kesimpulan']),
      kesepakatan: strings(json['kesepakatan']),
      rencanaTindakLanjut: strings(json['rencanaTindakLanjut']),
      statusHasilEvaluasi: status.isEmpty
          ? StatusHasilEvaluasi.sesuaiSiteplan
          : status.first,
      pelaksanaNama: json['pelaksanaNama'] as String? ?? '',
      pelaksanaJabatan: json['pelaksanaJabatan'] as String? ?? '',
      ditemuiNama: json['ditemuiNama'] as String? ?? '',
      ditemuiJabatan: json['ditemuiJabatan'] as String? ?? '',
      pelaksana: people(json['pelaksana']),
      ditemui: people(json['ditemui']),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      nomorSuratBA: json['nomorSuratBA'] as String?,
      isDraft: json['isDraft'] == true,
    );
  }

  MonitoringModel copyWith({
    String? id,
    String? pengajuanId,
    DateTime? tanggalMonitoring,
    String? namaPerumahan,
    String? namaDeveloper,
    String? lokasiPerumahan,
    String? maksudTujuan,
    List<String>? temuanLapangan,
    List<String>? kesimpulan,
    List<String>? kesepakatan,
    List<String>? rencanaTindakLanjut,
    StatusHasilEvaluasi? statusHasilEvaluasi,
    String? pelaksanaNama,
    String? pelaksanaJabatan,
    String? ditemuiNama,
    String? ditemuiJabatan,
    List<MonitoringPerson>? pelaksana,
    List<MonitoringPerson>? ditemui,
    DateTime? createdAt,
    String? nomorSuratBA,
    bool? isDraft,
  }) {
    return MonitoringModel(
      id: id ?? this.id,
      pengajuanId: pengajuanId ?? this.pengajuanId,
      tanggalMonitoring: tanggalMonitoring ?? this.tanggalMonitoring,
      namaPerumahan: namaPerumahan ?? this.namaPerumahan,
      namaDeveloper: namaDeveloper ?? this.namaDeveloper,
      lokasiPerumahan: lokasiPerumahan ?? this.lokasiPerumahan,
      maksudTujuan: maksudTujuan ?? this.maksudTujuan,
      temuanLapangan: temuanLapangan ?? this.temuanLapangan,
      kesimpulan: kesimpulan ?? this.kesimpulan,
      kesepakatan: kesepakatan ?? this.kesepakatan,
      rencanaTindakLanjut: rencanaTindakLanjut ?? this.rencanaTindakLanjut,
      statusHasilEvaluasi: statusHasilEvaluasi ?? this.statusHasilEvaluasi,
      pelaksanaNama: pelaksanaNama ?? this.pelaksanaNama,
      pelaksanaJabatan: pelaksanaJabatan ?? this.pelaksanaJabatan,
      ditemuiNama: ditemuiNama ?? this.ditemuiNama,
      ditemuiJabatan: ditemuiJabatan ?? this.ditemuiJabatan,
      pelaksana: pelaksana ?? this.pelaksana,
      ditemui: ditemui ?? this.ditemui,
      createdAt: createdAt ?? this.createdAt,
      nomorSuratBA: nomorSuratBA ?? this.nomorSuratBA,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
