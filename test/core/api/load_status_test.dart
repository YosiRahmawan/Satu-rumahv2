import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/api/remote_load.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/widgets/connection_banner.dart';
import 'package:satu_rumah/features/monitoring/data/models/monitoring_model.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/officer_api_repository.dart';
import 'package:satu_rumah/features/monitoring/data/models/ba_signature.dart';
import 'package:satu_rumah/features/monitoring/presentation/providers/monitoring_list_provider.dart';
import 'package:satu_rumah/features/pengajuan/data/models/pengajuan_model.dart';
import 'package:satu_rumah/features/pengajuan/data/repositories/pengajuan_api_repository.dart';
import 'package:satu_rumah/features/pengajuan/presentation/providers/pengajuan_form_controller.dart';
import 'package:satu_rumah/features/pengajuan/presentation/screens/pengajuan_saya_list_screen.dart';

class _Remote implements PengajuanRemote {
  Completer<List<Pengajuan>>? gate;
  Object? error;
  List<Pengajuan> items = [];

  @override
  Future<List<Pengajuan>> list() {
    if (gate != null) return gate!.future;
    if (error != null) return Future.error(error!);
    return Future.value(items);
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
  Object? error;

  @override
  Future<List<OfficerAssignment>> assignments() =>
      error == null ? Future.value(const []) : Future.error(error!);

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

Pengajuan _item(String id) => Pengajuan(
  id: id,
  namaPerumahan: 'Griya $id',
  namaPt: 'PT',
  namaDirektur: 'D',
  npwpPerusahaan: '1',
  luasLahan: 1,
  jumlahUnit: 1,
  tipePerumahan: 'Subsidi',
  status: 'Dalam Proses',
  tanggal: '1 Nov 2026',
  uploadedDocs: const {},
);

const _offline = ApiException(code: 'NETWORK', message: 'x');

void main() {
  group('pemetaan galat jaringan', () {
    test('waktu habis dibedakan dari tanpa sambungan', () {
      DioException e(DioExceptionType t) =>
          DioException(requestOptions: RequestOptions(path: 'x'), type: t);

      final timeout = ApiException.fromDio(e(DioExceptionType.receiveTimeout));
      final offline = ApiException.fromDio(e(DioExceptionType.connectionError));

      expect(timeout.code, 'TIMEOUT');
      expect(timeout.isNetwork, isTrue);
      expect(timeout.message, contains('terlalu lama'));
      expect(offline.code, 'NETWORK');
    });

    test('awalan menyebut berkas yang gagal tanpa mengubah kode', () {
      const err = ApiException(
        code: 'ERR-003',
        message: 'Berkas rusak.',
        status: 422,
      );
      final prefixed = err.withPrefix('Berkas "ktp.pdf" gagal diunggah.');
      expect(
        prefixed.message,
        'Berkas "ktp.pdf" gagal diunggah. Berkas rusak.',
      );
      expect(prefixed.code, 'ERR-003');
      expect(prefixed.status, 422);
    });

    test('teks galat pemuatan', () {
      expect(loadErrorText(_offline), 'Tidak ada sambungan internet.');
      expect(
        loadErrorText(const ApiException(code: 'TIMEOUT', message: 'x')),
        'Server terlalu lama menjawab.',
      );
    });
  });

  group('status pemuatan daftar', () {
    test('Pengajuan: memuat lalu selesai; gagal tidak menghapus data lama', () async {
      final remote = _Remote()..items = [_item('SR-1')];
      final n = PengajuanListNotifier(remote: remote);
      addTearDown(n.dispose);

      expect(n.load.value.state, LoadState.idle);
      final future = n.refresh();
      expect(n.load.value.isLoading, isTrue);
      await future;
      expect(n.load.value.state, LoadState.loaded);
      expect(n.state, hasLength(1));

      remote.error = _offline;
      final error = await n.refresh();
      expect(error, same(_offline));
      expect(n.load.value.isFailed, isTrue);
      expect(n.state, hasLength(1)); // data terakhir tetap ada
    });

    test('tugas Pengawas: gagal tercatat lalu pulih', () async {
      final remote = _Officer()..error = _offline;
      final n = OfficerAssignmentsNotifier(remote);
      addTearDown(n.dispose);
      await n.refresh();
      expect(n.load.value.isFailed, isTrue);
      remote.error = null;
      await n.refresh();
      expect(n.load.value.state, LoadState.loaded);
    });
  });

  group('layar daftar Pengajuan', () {
    Future<ProviderContainer> pump(WidgetTester tester, _Remote remote) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
          pengajuanRemoteProvider.overrideWithValue(remote),
        ],
      );
      addTearDown(c.dispose);
      c
          .read(roleSessionProvider.notifier)
          .signIn(AppRole.developer, username: 'dev1');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: PengajuanSayaListScreen()),
        ),
      );
      return c;
    }

    // Font uji lebih lebar dari font asli; overflow bukan yang diuji di sini.
    void drain(WidgetTester tester) {
      while (tester.takeException() != null) {}
    }

    testWidgets('kosong saat memuat: loader, bukan "Belum ada pengajuan"', (
      tester,
    ) async {
      final remote = _Remote()..gate = Completer();
      await pump(tester, remote);
      await tester.pump();
      drain(tester);

      expect(find.text('Memuat pengajuan'), findsOneWidget);
      expect(find.text('Belum ada pengajuan'), findsNothing);
    });

    testWidgets('kosong karena gagal: pesan sinyal dan Coba lagi', (
      tester,
    ) async {
      final remote = _Remote()..error = _offline;
      final c = await pump(tester, remote);
      await tester.pumpAndSettle();
      drain(tester);

      expect(find.text('Tidak ada sambungan internet.'), findsOneWidget);
      expect(find.text('Belum ada pengajuan'), findsNothing);

      remote
        ..error = null
        ..items = [];
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      drain(tester);
      expect(
        c.read(pengajuanListProvider.notifier).load.value.state,
        LoadState.loaded,
      );
      expect(find.text('Tidak ada sambungan internet.'), findsNothing);
    });

    testWidgets('data ada tetapi gagal diperbarui: pita peringatan', (
      tester,
    ) async {
      final remote = _Remote()..items = [_item('SR-1')];
      final c = await pump(tester, remote);
      await tester.pumpAndSettle();
      drain(tester);
      expect(find.byType(ConnectionBanner), findsNothing);

      remote.error = _offline;
      await c.read(pengajuanListProvider.notifier).refresh();
      await tester.pumpAndSettle();
      drain(tester);

      expect(find.byType(ConnectionBanner), findsOneWidget);
      expect(find.textContaining('Menampilkan data terakhir'), findsOneWidget);
    });
  });
}
