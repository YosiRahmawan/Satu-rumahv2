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

/// Jenis notifikasi dari server. Keputusan dibedakan lewat judul ("tolak" atau disetujui).
JenisNotifikasi jenisFromApi(String? type, [String? title]) => switch (type) {
  'revision_requested' => JenisNotifikasi.perluRevisi,
  'assignment' => JenisNotifikasi.penugasanSurvei,
  'survey_scheduled' || 'assignment_rescheduled' => JenisNotifikasi.reminderSurvey,
  'resubmitted' || 'report_submitted' => JenisNotifikasi.dokumenDiunggahUlang,
  'stage_advanced' => JenisNotifikasi.tahapLanjut,
  'survey_cancelled' => JenisNotifikasi.jadwalDibatalkan,
  'assignment_cancelled' ||
  'assignment_reassigned' => JenisNotifikasi.penugasanDibatalkan,
  'report_published' => JenisNotifikasi.baDiterbitkan,
  'deadline_reminder' || 'deadline_overdue' => JenisNotifikasi.batasPerbaikan,
  'decided' => (title?.toLowerCase().contains('tolak') ?? false)
      ? JenisNotifikasi.keputusanDitolak
      : JenisNotifikasi.keputusanDisetujui,
  _ => JenisNotifikasi.pengajuanBaru,
};

/// JSON server → model notifikasi. Penerima mengikuti role akun yang masuk.
NotifikasiModel notifikasiFromApi(Map<String, dynamic> json, AppRole role) {
  final number = json['submission_number'] as String?;
  final title = '${json['title'] ?? ''}';
  final type = json['type'] as String?;
  final data = (json['data'] as Map?)?.cast<String, dynamic>();
  final defaultTarget = role == AppRole.developer
      ? (number == null ? null : '/pengajuan/detail/$number')
      : '/monitoring/lapangan';

  return NotifikasiModel(
    id: '$serverNotifPrefix${json['id']}',
    jenis: jenisFromApi(type, title),
    judul: title,
    deskripsi: '${json['body'] ?? ''}',
    waktu:
        DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    isRead: json['read'] == true,
    targetRoute: defaultTarget,
    pengajuanId: number,
    penerima: role,
    data: data,
  );
}
