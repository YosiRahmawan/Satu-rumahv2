import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:satu_rumah/features/notifikasi/presentation/screens/notifikasi_list_screen.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';
import 'package:satu_rumah/features/profil/presentation/screens/profil_screen.dart';

void main() {
  // Font uji (Ahem) lebih lebar dari font asli, sehingga beberapa Row meluap
  // di test. Overflow itu bukan yang diuji di sini, jadi dibuang.
  void drainOverflow(WidgetTester tester) {
    while (tester.takeException() != null) {}
  }

  testWidgets('tab hanya dibangun saat pertama dibuka lalu dipertahankan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );
    await tester.pumpAndSettle();
    drainOverflow(tester);

    // Frame pertama: hanya Beranda yang dibangun.
    expect(find.byType(PengajuanSayaListScreen, skipOffstage: false), findsNothing);
    expect(find.byType(NotifikasiListScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ProfilScreen, skipOffstage: false), findsNothing);

    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();
    drainOverflow(tester);
    expect(find.byType(NotifikasiListScreen), findsOneWidget);
    expect(find.byType(PengajuanSayaListScreen, skipOffstage: false), findsNothing);

    // Kembali ke Beranda: Notifikasi tetap hidup di belakang.
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    drainOverflow(tester);
    expect(find.byType(NotifikasiListScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('tombol tambah tidak melayang di atas keyboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget app(double keyboard) => ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    );

    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    drainOverflow(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.pumpWidget(app(300));
    await tester.pumpAndSettle();
    drainOverflow(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
