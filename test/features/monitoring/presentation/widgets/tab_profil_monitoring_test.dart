import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/models/status_hasil_evaluasi.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_profil_monitoring.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';

class _FakeMonitoringRepository {
  final List<MonitoringModel> items;

  _FakeMonitoringRepository(this.items);

  List<MonitoringModel> getAllMonitoring() => List.unmodifiable(items);
}

void main() {
  final items = [
    MonitoringModel(
      id: 'complete',
      tanggalMonitoring: DateTime(2026, 5, 20),
      namaPerumahan: 'Permata Hijau Residence',
      statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
    ),
    MonitoringModel(
      id: 'follow-up',
      tanggalMonitoring: DateTime(2026, 5, 18),
      namaPerumahan: 'Bumi Asri Kawalu',
      statusHasilEvaluasi: StatusHasilEvaluasi.perluEvaluasiLanjutan,
    ),
  ];

  final activeAssignment = Pengajuan(
    id: 'survey-1',
    namaPerumahan: 'Griya Mangkubumi Asri',
    namaPt: 'PT Griya Utama',
    namaDirektur: 'Budi Santoso',
    npwpPerusahaan: '01.234.567.8-901.000',
    luasLahan: 5000,
    jumlahUnit: 45,
    tipePerumahan: 'Subsidi',
    status: 'Survey Dijadwalkan',
    tanggal: '2026-05-10',
    uploadedDocs: const {},
    tanggalSurvey: DateTime.now(),
  );

  Widget buildSubject({
    String? username = 'tim_monitoring_perwaskim',
    List<Pengajuan>? assignments,
    RoleSessionNotifier? customNotifier,
  }) {
    return ProviderScope(
      overrides: [
        roleSessionProvider.overrideWith((ref) {
          if (customNotifier != null) return customNotifier;
          final notifier = RoleSessionNotifier();
          notifier.signIn(AppRole.perwaskim, username: username);
          return notifier;
        }),
        monitoringListProvider.overrideWith(
          (ref) => MonitoringListNotifier(_FakeMonitoringRepository(items)),
        ),
        surveyAktifProvider.overrideWithValue(assignments ?? <Pengajuan>[]),
      ],
      child: const MaterialApp(home: TabProfilMonitoring()),
    );
  }

  testWidgets('renders all redesigned sections and actual data correctly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject(assignments: [activeAssignment]));
    await tester.pumpAndSettle();

    // 1. Header elements: Centered identity, avatar initials, verified badge
    expect(find.text('RH'), findsOneWidget);
    expect(find.text('Drs. Rian Hidayat, M.Si'), findsOneWidget);
    expect(find.text('NIP: 197805122006041008'), findsOneWidget);
    expect(find.text('Terverifikasi'), findsOneWidget);

    // Removed elements must not be present
    expect(find.text('DINAS PERKIM KOTA TASIKMALAYA'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(find.text('Tim Verifikator Perwaskim'), findsNothing);

    // 2. Stats
    expect(find.text('Tugas Aktif'), findsOneWidget);
    expect(find.text('Survei Selesai'), findsOneWidget);
    expect(find.text('Perlu Evaluasi'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 1 active task & 1 perlu evaluasi
    expect(find.text('2'), findsOneWidget); // 2 completed surveys

    // 3. Assignment
    expect(find.text('PENUGASAN LAPANGAN HARI INI'), findsOneWidget);
    expect(find.text('Griya Mangkubumi Asri'), findsOneWidget);

    // 4. Account Info
    expect(find.text('INFORMASI AKUN DINAS'), findsOneWidget);
    expect(find.text('Email Resmi Dinas'), findsOneWidget);
    expect(find.text('Nomor Kontak'), findsOneWidget);
    expect(find.text('Belum ditautkan'), findsOneWidget);
    expect(find.text('Instansi Kerja'), findsOneWidget);
    expect(find.text('Dinas Perumahan & Kawasan Permukiman'), findsOneWidget);
    expect(find.text('Akun login'), findsOneWidget);
    expect(find.text('Peran akses'), findsOneWidget);

    // 5. Settings & Guides
    expect(find.text('PENGATURAN & PANDUAN'), findsOneWidget);
    expect(find.text('Hubungi Admin / CS'), findsOneWidget);
    expect(find.text('Panduan SOP Verifikasi Lapangan'), findsOneWidget);
    expect(find.text('Ubah Password'), findsNothing);

    // 6. Logout & Footer
    expect(find.text('Keluar dari Akun'), findsOneWidget);
    expect(find.textContaining('SATU RUMAH'), findsOneWidget);
    expect(find.textContaining('v1.0.0'), findsOneWidget);
    expect(find.textContaining('Production Build'), findsNothing);
    expect(
      find.text('Sistem Integrasi Perumahan & Kawasan Permukiman'),
      findsOneWidget,
    );
  });

  testWidgets('renders unverified badge when officer NIP is not available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject(username: 'petugas_baru'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Terverifikasi'), findsOneWidget);
  });

  testWidgets('renders empty state when no assignments available', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject(assignments: []));
    await tester.pumpAndSettle();

    expect(find.text('PENUGASAN LAPANGAN'), findsOneWidget);
    expect(find.text('Belum ada penugasan lapangan aktif.'), findsOneWidget);
  });

  testWidgets('tapping unavailable guide item shows feedback snackbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hubungi Admin / CS'));
    await tester.tap(find.text('Hubungi Admin / CS'));
    await tester.pump();

    expect(
      find.textContaining(
        'Hubungi Admin / CS belum tersedia di prototipe lokal.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('logout button invokes signOut on RoleSessionNotifier', (
    tester,
  ) async {
    final notifier = RoleSessionNotifier();
    notifier.signIn(AppRole.perwaskim, username: 'petugas_lapangan');
    expect(notifier.state.isAuthenticated, isTrue);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(buildSubject(customNotifier: notifier));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Keluar dari Akun'));
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    expect(notifier.state.isAuthenticated, isFalse);
  });

  for (final width in [360.0, 390.0, 412.0, 420.0]) {
    testWidgets(
      'responsive layout on width ${width}dp with 200% text scale without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: buildSubject(assignments: [activeAssignment]),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  }
}
