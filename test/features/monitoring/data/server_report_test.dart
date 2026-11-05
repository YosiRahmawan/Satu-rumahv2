import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/models/server_report.dart';

void main() {
  test('ringkasan BA dari server: status tanda tangan dan stub riwayat', () {
    final r = ServerReport.fromJson({
      'id': 7,
      'report_number': '001/BA/2026',
      'nama_perumahan': 'Griya Asri',
      'monitoring_date': '2026-03-01',
      'status_hasil_evaluasi': 'sesuaiSiteplan',
      'published_at': '2026-03-02T01:00:00Z',
      'photo_count': 3,
      'signatures': null,
    });
    expect(r.signatures.published, isTrue);
    final stub = r.toStub();
    expect(stub.id, 'srv-7');
    expect(stub.nomorSuratBA, '001/BA/2026');
    expect(r.isRevisi, isFalse);
  });

  test('BA yang dikembalikan Admin dikenali dari status revisi', () {
    final r = ServerReport.fromJson({
      'id': 8,
      'report_number': '002/BA/2026',
      'nama_perumahan': 'Griya Asri',
      'monitoring_date': '2026-03-01',
      'status': 'revisi',
    });
    expect(r.isRevisi, isTrue);
  });
}
