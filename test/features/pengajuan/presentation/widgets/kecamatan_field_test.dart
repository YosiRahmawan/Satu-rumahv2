import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/widgets/kecamatan_field.dart';
import 'package:satu_rumah/features/pengajuan/utils/kecamatan.dart';

void main() {
  testWidgets(
    'memilih kecamatan menyimpannya di form dan ikut tersimpan di draf',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: KecamatanField())),
        ),
      );

      expect(find.text('Pilih kecamatan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('kecamatan-proyek')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kawalu').last);
      await tester.pumpAndSettle();

      final state = container.read(pengajuanFormProvider);
      expect(state.kecamatan, 'Kawalu');
      expect(PengajuanFormState.fromJson(state.toJson()).kecamatan, 'Kawalu');
    },
  );

  test(
    'daftar kecamatan memuat 10 kecamatan Kota Tasikmalaya tanpa duplikat',
    () {
      expect(kKecamatanTasikmalaya, hasLength(10));
      expect(kKecamatanTasikmalaya.toSet(), hasLength(10));
    },
  );
}
