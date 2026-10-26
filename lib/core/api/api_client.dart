import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/role_session.dart';
import '../auth/token_store.dart';

/// Alamat API, diisi saat build: `--dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`.
/// Kosong berarti mode demo lokal (login prototipe tanpa server).
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Dapat diganti pada tes agar mode API bisa dinyalakan tanpa `--dart-define`.
final apiBaseUrlProvider = Provider<String>((ref) => kApiBaseUrl);

final apiEnabledProvider = Provider<bool>(
  (ref) => ref.watch(apiBaseUrlProvider).isNotEmpty,
);

/// Galat dari server dalam bentuk baku `{"error": {"code", "message", ...}}`
/// atau kegagalan jaringan (`code == 'NETWORK'`).
class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;
  final Map<String, List<String>> fields;
  final DateTime? lockedUntil;

  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.fields = const {},
    this.lockedUntil,
  });

  bool get isNetwork => code == 'NETWORK';

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final rawFields = error['fields'];
      return ApiException(
        code: '${error['code'] ?? 'ERR'}',
        message: '${error['message'] ?? 'Terjadi kesalahan.'}',
        status: e.response?.statusCode,
        fields: rawFields is Map
            ? {
                for (final entry in rawFields.entries)
                  '${entry.key}': [
                    for (final v in (entry.value as List? ?? const [])) '$v',
                  ],
              }
            : const {},
        lockedUntil: DateTime.tryParse('${error['locked_until'] ?? ''}'),
      );
    }
    if (e.response == null) {
      return const ApiException(
        code: 'NETWORK',
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.',
      );
    }
    return ApiException(
      code: 'ERR',
      message: 'Server mengembalikan jawaban yang tidak dikenali.',
      status: e.response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $message)';
}

/// Membangun klien HTTP: token dibaca dari [tokenStore] pada tiap permintaan,
/// dan jawaban 401 mencabut sesi lewat [onUnauthorized].
Dio buildApiDio({
  required String baseUrl,
  required TokenStore tokenStore,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final isLogin = error.requestOptions.path.endsWith('auth/login');
        if (error.response?.statusCode == 401 && !isLogin) {
          await tokenStore.delete();
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}

final apiDioProvider = Provider<Dio>((ref) {
  return buildApiDio(
    baseUrl: ref.watch(apiBaseUrlProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    onUnauthorized: () => ref.read(roleSessionProvider.notifier).signOut(),
  );
});
