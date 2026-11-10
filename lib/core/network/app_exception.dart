import 'package:dio/dio.dart';

/// Representasi exception standar aplikasi untuk memetakan error HTTP/Network
/// ke dalam format dan pesan yang user-friendly.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final dynamic originalError;

  AppException({
    required this.message,
    this.statusCode,
    this.errors,
    this.originalError,
  });

  /// Factory untuk memetakan DioException dan response JSON backend Laravel
  /// Format Laravel lazim: `{ "status": false, "message": "...", "data": ..., "errors": { ... } }`
  factory AppException.fromDioException(DioException dioException) {
    int? code = dioException.response?.statusCode;
    dynamic data = dioException.response?.data;
    String message = 'Terjadi kesalahan pada koneksi jaringan.';
    Map<String, dynamic>? validationErrors;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('message') && data['message'] != null) {
        message = data['message'].toString();
      }
      if (data.containsKey('errors') && data['errors'] is Map) {
        validationErrors = Map<String, dynamic>.from(data['errors'] as Map);
      }
    }

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Batas waktu koneksi terlampaui. Periksa stabilitas internet Anda.',
          statusCode: code,
          originalError: dioException,
        );
      case DioExceptionType.connectionError:
        return AppException(
          message: 'Gagal terhubung ke server. Pastikan Anda memiliki koneksi internet aktif.',
          statusCode: code,
          originalError: dioException,
        );
      case DioExceptionType.badResponse:
        switch (code) {
          case 400:
            return AppException(
              message: message.isNotEmpty ? message : 'Permintaan tidak valid (Bad Request).',
              statusCode: 400,
              errors: validationErrors,
              originalError: dioException,
            );
          case 401:
            return AppException(
              message: 'Sesi Anda telah berakhir atau belum terautentikasi. Silakan masuk kembali.',
              statusCode: 401,
              errors: validationErrors,
              originalError: dioException,
            );
          case 403:
            return AppException(
              message: message.isNotEmpty ? message : 'Anda tidak memiliki hak akses untuk tindakan ini.',
              statusCode: 403,
              errors: validationErrors,
              originalError: dioException,
            );
          case 404:
            return AppException(
              message: message.isNotEmpty ? message : 'Data atau layanan tidak ditemukan (404).',
              statusCode: 404,
              originalError: dioException,
            );
          case 422:
            // Laravel Form Validation Error
            String friendlyMessage = message;
            if (validationErrors != null && validationErrors.isNotEmpty) {
              final firstEntry = validationErrors.values.first;
              if (firstEntry is List && firstEntry.isNotEmpty) {
                friendlyMessage = firstEntry.first.toString();
              } else {
                friendlyMessage = firstEntry.toString();
              }
            }
            return AppException(
              message: friendlyMessage,
              statusCode: 422,
              errors: validationErrors,
              originalError: dioException,
            );
          case 500:
          case 502:
          case 503:
            return AppException(
              message: 'Terjadi gangguan internal pada server (500). Silakan coba beberapa saat lagi.',
              statusCode: code,
              originalError: dioException,
            );
          default:
            return AppException(
              message: message.isNotEmpty ? message : 'Terjadi kesalahan ($code).',
              statusCode: code,
              errors: validationErrors,
              originalError: dioException,
            );
        }
      case DioExceptionType.cancel:
        return AppException(
          message: 'Permintaan dibatalkan.',
          statusCode: code,
          originalError: dioException,
        );
      default:
        return AppException(
          message: dioException.message ?? 'Terjadi kesalahan tidak terduga.',
          statusCode: code,
          originalError: dioException,
        );
    }
  }

  @override
  String toString() => message;
}

