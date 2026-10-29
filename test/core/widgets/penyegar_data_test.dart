import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/widgets/penyegar_data.dart';
import 'package:satu_rumah/features/monitoring/data/models/ba_signature.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/data/notifikasi_api_repository.dart';
import 'package:satu_rumah/features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';

class _Notif implements NotifikasiRemote {
  int lists = 0;
  @override
  Future<List<NotifikasiModel>> list(AppRole role) async {
    lists++;
    return const [];
  }

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}

class _Pengajuan implements PengajuanRemote {
  int lists = 0;
  Object? error;
  @override
  Future<List<Pengajuan>> list() async {
    lists++;
    if (error != null) throw error!;
    return const [];
  }

  @override
  Future<Pengajuan> submit(
    PengajuanFormState form, {
    required String draftKey,
    void Function(String message, double fraction)? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<Pengajuan> resubmit(String number, Map<String, String> revisedDocs) =>
      throw UnimplementedError();
}

class _Officer implements OfficerRemote {
  int lists = 0;
  @override
  Future<List<OfficerAssignment>> assignments() async {
    lists++;
    return const [];
  }

  @override
  Future<String> submitReport(
    MonitoringModel draft, {
    required String draftKey,
    required double latitude,
    required double longitude,
    void Function(String message, double fraction)? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<BaSignatureStatus> signatureStatus(String reportNumber) =>
      throw UnimplementedError();

  @override
  Future<BaSignatureStatus> signReport({
    required String reportNumber,
    required SignatureImage image,
    required String password,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  late _Notif notif;
  late _Pengajuan pengajuan;
  late _Officer officer;

  Future<ProviderContainer> pasang(
    WidgetTester tester, {
    required AppRole role,
    bool api = true,
  }) async {
    notif = _Notif();
    pengajuan = _Pengajuan();
    officer = _Officer();
    final container = ProviderContainer(
      overrides: [
        apiEnabledProvider.overrideWithValue(api),
        notifikasiRemoteProvider.overrideWithValue(notif),
        pengajuanRemoteProvider.overrideWithValue(pengajuan),
        officerRemoteProvider.overrideWithValue(officer),
      ],
    );
    addTearDown(container.dispose);
    container.read(roleSessionProvider.notifier).signIn(role);
    // Membuat provider data (muat awal terjadi di sini), lalu catat angka dasar.
    container.read(notifikasiProvider);
    container.read(pengajuanListProvider);
    container.read(officerAssignmentsProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PenyegarData(
          interval: Duration(seconds: 30),
          child: SizedBox(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets(
    'Pengembang: notifikasi dan daftar pengajuan dimuat ulang tiap putaran',
    (tester) async {
      await pasang(tester, role: AppRole.developer);
      final n0 = notif.lists;
      final p0 = pengajuan.lists;

      await tester.pump(const Duration(seconds: 31));
      expect(notif.lists, n0 + 1);
      expect(pengajuan.lists, p0 + 1);
      expect(officer.lists, 0); // data milik Pengawas tidak disentuh

      await tester.pump(const Duration(seconds: 30));
      expect(notif.lists, n0 + 2);
    },
  );

  testWidgets('Pengawas: notifikasi dan tugas dimuat ulang', (tester) async {
    await pasang(tester, role: AppRole.perwaskim);
    final n0 = notif.lists;
    final o0 = officer.lists;

    await tester.pump(const Duration(seconds: 31));
    expect(notif.lists, n0 + 1);
    expect(officer.lists, o0 + 1);
    expect(pengajuan.lists, 0);
  });

  testWidgets(
    'aplikasi dibuka kembali dari latar belakang memuat ulang segera, dan berhenti saat di latar belakang',
    (tester) async {
      await pasang(tester, role: AppRole.developer);
      final n0 = notif.lists;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 95)); // lama di latar belakang
      expect(notif.lists, n0); // pewaktu berhenti

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(
        notif.lists,
        n0 + 1,
      ); // segera setelah dibuka kembali, tanpa menunggu 30 detik
    },
  );

  testWidgets('mode lokal (tanpa server) dan Admin tidak memuat apa pun', (
    tester,
  ) async {
    await pasang(tester, role: AppRole.developer, api: false);
    await tester.pump(const Duration(seconds: 65));
    expect(notif.lists + pengajuan.lists + officer.lists, 0);
  });

  testWidgets(
    'gagal di latar belakang diam-diam: tidak menandai daftar gagal',
    (tester) async {
      final container = await pasang(tester, role: AppRole.developer);
      pengajuan.error = const ApiException(code: 'NETWORK', message: 'putus');
      final notifier = container.read(pengajuanListProvider.notifier);
      final sebelum = notifier.load.value.state;

      await tester.pump(const Duration(seconds: 31));
      await tester.pump();

      expect(
        notifier.load.value.state,
        sebelum,
      ); // tidak menjadi gagal atau memuat
    },
  );
}
