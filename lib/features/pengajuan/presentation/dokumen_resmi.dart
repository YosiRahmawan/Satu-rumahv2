import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/app_toast.dart';
import '../../monitoring/data/models/monitoring_model.dart';
import '../../monitoring/data/models/status_hasil_evaluasi.dart';
import '../data/models/pengajuan_model.dart';
import '../data/repositories/pengajuan_api_repository.dart';

/// Kartu BA untuk daftar unduhan dari BA resmi di server (isi PDF diambil saat diunduh).
MonitoringModel? baResmiSebagaiModel(Pengajuan p) {
  final id = p.serverBaReportId;
  if (id == null) return null;
  return MonitoringModel(
    id: 'srv-$id',
    tanggalMonitoring: p.serverBaTanggal ?? DateTime.now(),
    namaPerumahan: p.namaPerumahan,
    statusHasilEvaluasi: StatusHasilEvaluasi.sesuaiSiteplan,
    nomorSuratBA: p.serverBaNomor ?? '',
  );
}

/// Mengunduh PDF BA resmi lalu membukanya untuk dilihat, dicetak, atau dibagikan.
Future<void> bukaBaResmi(BuildContext context, WidgetRef ref, Pengajuan p) =>
    _bukaResmi(
      context,
      () => ref
          .read(pengajuanRemoteProvider)
          .downloadBaPdf(p.id, p.serverBaReportId!),
      'BA-${(p.serverBaNomor ?? p.id).replaceAll('/', '-')}.pdf',
    );

/// Mengunduh berkas SK resmi lalu membukanya.
Future<void> bukaSkResmi(BuildContext context, WidgetRef ref, Pengajuan p) =>
    _bukaResmi(
      context,
      () => ref.read(pengajuanRemoteProvider).downloadSk(p.id),
      'SK-${p.id}.pdf',
    );

Future<void> _bukaResmi(
  BuildContext context,
  Future<List<int>> Function() ambil,
  String nama,
) async {
  try {
    final bytes = await ambil();
    await Printing.sharePdf(
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      filename: nama,
    );
  } on ApiException catch (e) {
    if (context.mounted) showAppToast(context, e.message, error: true);
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        context,
        'Dokumen belum bisa dibuka. Coba lagi.',
        error: true,
      );
    }
  }
}
