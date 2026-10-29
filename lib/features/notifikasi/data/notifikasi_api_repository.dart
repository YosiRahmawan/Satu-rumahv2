import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/role_session.dart';
import 'models/notifikasi_model.dart';

/// Awalan id notifikasi dari server, agar tidak tertukar dengan yang lokal.
const serverNotifPrefix = 'srv-';

/// Notifikasi di server (ditarik aplikasi; belum ada push).
abstract class NotifikasiRemote {
  Future<List<NotifikasiModel>> list(AppRole role);
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class NotifikasiApiRepository implements NotifikasiRemote {
  final Dio _dio;
  NotifikasiApiRepository(this._dio);

  @override
  Future<List<NotifikasiModel>> list(AppRole role) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('notifications');
      final data = (response.data!['data'] as List)
          .cast<Map<String, dynamic>>();
      return [for (final item in data) notifikasiFromApi(item, role)];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.post<void>(
        'notifications/${id.replaceFirst(serverNotifPrefix, '')}/read',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post<void>('notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final notifikasiRemoteProvider = Provider<NotifikasiRemote>(
  (ref) => NotifikasiApiRepository(ref.watch(apiDioProvider)),
);

/// Jenis notifikasi dari server. Keputusan dibedakan lewat judul ("ditolak" atau disetujui).
JenisNotifikasi jenisFromApi(String? type, [String? title]) => switch (type) {
  'revision_requested' => JenisNotifikasi.perluRevisi,
  'assignment' ||
  'assignment_rescheduled' ||
  'survey_scheduled' => JenisNotifikasi.reminderSurvey,
  'resubmitted' || 'report_submitted' => JenisNotifikasi.dokumenDiunggahUlang,
  'stage_advanced' => JenisNotifikasi.tahapLanjut,
  'decided' =>
    (title ?? '').toLowerCase().contains('ditolak')
        ? JenisNotifikasi.ditolak
        : JenisNotifikasi.disetujui,
  'survey_cancelled' ||
  'assignment_cancelled' ||
  'assignment_reassigned' => JenisNotifikasi.dibatalkan,
  'report_published' => JenisNotifikasi.baTerbit,
  'deadline_reminder' || 'deadline_overdue' => JenisNotifikasi.batasPerbaikan,
  _ => JenisNotifikasi.pengajuanBaru,
};

/// JSON server → model notifikasi. Penerima mengikuti role akun yang masuk.
NotifikasiModel notifikasiFromApi(Map<String, dynamic> json, AppRole role) {
  final number = json['submission_number'] as String?;
  return NotifikasiModel(
    id: '$serverNotifPrefix${json['id']}',
    jenis: jenisFromApi(json['type'] as String?, json['title'] as String?),
    judul: '${json['title'] ?? ''}',
    deskripsi: '${json['body'] ?? ''}',
    waktu:
        DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    isRead: json['read'] == true,
    targetRoute: role == AppRole.developer
        ? (number == null ? null : '/pengajuan/detail/$number')
        : '/monitoring',
    pengajuanId: number,
    penerima: role,
  );
}
