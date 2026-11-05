import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/features/monitoring/data/models/ba_signature.dart';
import 'package:satu_rumah/features/monitoring/data/models/server_report.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/berita_acara_action_buttons.dart';

class _Daftar extends OfficerReportsNotifier {
  _Daftar(List<ServerReport> isi) : super(null) {
    state = isi;
  }
}

Widget _app({bool api = true, bool terbit = false}) => ProviderScope(
  overrides: [
    if (api) apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
    officerReportsProvider.overrideWith(
      (ref) => _Daftar([
        ServerReport(
          id: 1,
          reportNumber: '001/BA/2026',
          namaPerumahan: 'Griya',
          tanggal: DateTime(2026, 3, 1),
          hasil: StatusHasilEvaluasi.sesuaiSiteplan,
          signatures: BaSignatureStatus(published: terbit),
        ),
      ]),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: BeritaAcaraActionButtons(
        isPdfBusy: false,
        isShareBusy: false,
        nomorBa: '001/BA/2026',
        onPdf: () {},
        onShare: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('BA belum terbit: PDF lokal diberi label pratinjau belum resmi', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('Pratinjau PDF (belum resmi)'), findsOneWidget);
    expect(find.text('Unduh PDF Resmi'), findsNothing);
  });

  testWidgets('BA sudah terbit: tombol mengunduh PDF resmi', (tester) async {
    await tester.pumpWidget(_app(terbit: true));
    await tester.pump();
    expect(find.text('Unduh PDF Resmi'), findsOneWidget);
    expect(find.text('Pratinjau PDF (belum resmi)'), findsNothing);
  });

  testWidgets('mode lokal tanpa server: label lama tetap', (tester) async {
    await tester.pumpWidget(_app(api: false));
    await tester.pump();
    expect(find.text('Download / Cetak PDF'), findsOneWidget);
  });
}
