import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/features/monitoring/data/models/server_report.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/ba_signature_entry_card.dart';

class _Daftar extends OfficerReportsNotifier {
  _Daftar(List<ServerReport> isi) : super(null) {
    state = isi;
  }
}

void main() {
  testWidgets(
    'BA yang dikembalikan Admin: tanpa tombol tanda tangan, ada penjelasan',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
            officerReportsProvider.overrideWith(
              (ref) => _Daftar([
                ServerReport(
                  id: 8,
                  reportNumber: '002/BA/2026',
                  namaPerumahan: 'Griya',
                  tanggal: DateTime(2026, 3, 1),
                  hasil: ServerReport.fromJson({
                    'id': 1,
                    'status_hasil_evaluasi': 'sesuaiSiteplan',
                  }).hasil,
                  status: 'revisi',
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BaSignatureEntryCard(number: '002/BA/2026')),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('ba-dikembalikan')), findsOneWidget);
      expect(find.byKey(const Key('ba-tandatangani')), findsNothing);
      expect(find.textContaining('BA pengganti'), findsOneWidget);
    },
  );
}
