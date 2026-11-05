import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/tab_beranda_monitoring.dart';

import 'officer_api_mode_test.dart' show FakeOfficerRemote;

class _Remote extends FakeOfficerRemote {
  final accepted = <int>[];
  String status = 'dijadwalkan';
  double? lat;
  double? lng;
  String? revisi;

  @override
  Future<List<OfficerAssignment>> assignments() async => [
    OfficerAssignment(
      id: 5,
      status: status,
      submissionNumber: 'SR-2026-0005',
      namaPerumahan: 'Griya Uji',
      alamatProyek: 'Jl. Karikil, Tasikmalaya',
      latitude: lat,
      longitude: lng,
      revisionNote: revisi,
    ),
  ];

  @override
  Future<void> acceptAssignment(int id) async {
    accepted.add(id);
    status = 'diterima';
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id', null));

  testWidgets('Terima Tugas memanggil server lalu tombol hilang; peta dibuka', (
    tester,
  ) async {
    final remote = _Remote();
    final dibuka = <String>[];
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
          officerRemoteProvider.overrideWithValue(remote),
          mapsLauncherProvider.overrideWithValue((alamat) async {
            dibuka.add(alamat);
            return true;
          }),
          roleSessionProvider.overrideWith(
            (ref) =>
                RoleSessionNotifier()
                  ..signIn(AppRole.perwaskim, username: 'tim_lapangan'),
          ),
        ],
        child: const MaterialApp(home: TabBerandaMonitoring()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tugas-buka-peta')));
    await tester.pump();
    expect(dibuka, ['Jl. Karikil, Tasikmalaya']);

    await tester.ensureVisible(find.byKey(const Key('tugas-terima')));
    await tester.tap(find.byKey(const Key('tugas-terima')));
    await tester.pumpAndSettle();
    expect(remote.accepted, [5]);
    expect(find.byKey(const Key('tugas-terima')), findsNothing);
    expect(find.byKey(const Key('tugas-diterima')), findsOneWidget);
    expect(
      find.text('Tugas diterima. Admin melihat statusnya.'),
      findsOneWidget,
    );
    expect(find.text('Cari Alamat di Peta'), findsOneWidget);
  });

  testWidgets('BA dikembalikan Admin: alasan tampil di kartu tugas', (
    tester,
  ) async {
    final remote = _Remote()..revisi = 'Temuan drainase belum lengkap.';
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
          officerRemoteProvider.overrideWithValue(remote),
          roleSessionProvider.overrideWith(
            (ref) =>
                RoleSessionNotifier()
                  ..signIn(AppRole.perwaskim, username: 'shabik001'),
          ),
        ],
        child: const MaterialApp(home: TabBerandaMonitoring()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tugas-perbaikan-ba')), findsOneWidget);
    expect(find.text('Temuan drainase belum lengkap.'), findsOneWidget);
  });

  testWidgets('titik dari pengembang dipakai untuk peta, bukan alamat', (
    tester,
  ) async {
    final remote = _Remote()
      ..lat = -7.3274
      ..lng = 108.2207;
    final dibuka = <String>[];
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
          officerRemoteProvider.overrideWithValue(remote),
          mapsLauncherProvider.overrideWithValue((q) async {
            dibuka.add(q);
            return true;
          }),
          roleSessionProvider.overrideWith(
            (ref) =>
                RoleSessionNotifier()
                  ..signIn(AppRole.perwaskim, username: 'shabik001'),
          ),
        ],
        child: const MaterialApp(home: TabBerandaMonitoring()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buka Titik Lokasi di Peta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tugas-buka-peta')));
    await tester.pump();
    expect(dibuka, ['-7.3274,108.2207']);
  });
}
