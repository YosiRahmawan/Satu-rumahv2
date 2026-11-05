import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/camera_providers.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/titik_lokasi_field.dart';

import '../../../../support/camera_fakes.dart';

void main() {
  testWidgets('lokasi saya dan tautan Maps mengisi titik; hapus mengosongkan', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
    );
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: TitikLokasiField())),
      ),
    );

    // Tautan tak dikenali: pesan, titik tetap kosong.
    await tester.enterText(
      find.byKey(const Key('titik-lokasi-tautan')),
      'https://maps.app.goo.gl/abc',
    );
    await tester.pump();
    expect(find.byKey(const Key('titik-lokasi-pesan')), findsOneWidget);
    expect(container.read(pengajuanFormProvider).latitude, isNull);

    // Tautan lengkap: titik terisi.
    await tester.enterText(
      find.byKey(const Key('titik-lokasi-tautan')),
      'https://www.google.com/maps/@-7.3274,108.2207,17z',
    );
    await tester.pump();
    expect(container.read(pengajuanFormProvider).latitude, -7.3274);
    expect(find.byKey(const Key('titik-lokasi-nilai')), findsOneWidget);

    await tester.tap(find.byKey(const Key('titik-lokasi-hapus')));
    await tester.pump();
    expect(container.read(pengajuanFormProvider).latitude, isNull);

    // Lokasi saya (GPS palsu pada tes).
    await tester.tap(find.byKey(const Key('titik-lokasi-saya')));
    await tester.pumpAndSettle();
    expect(container.read(pengajuanFormProvider).latitude, isNotNull);
  });
}
