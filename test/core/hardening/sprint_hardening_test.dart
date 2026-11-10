import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/network/app_exception.dart';
import 'package:satu_rumah/core/network/dio_client.dart';
import 'package:satu_rumah/core/utils/geotag_service.dart';
import 'package:satu_rumah/core/utils/media_upload_optimizer.dart';

void main() {
  group('Sprint 1 & 2 Hardening Unit Tests', () {
    test('AppException parses Laravel 422 validation errors correctly', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'status': false,
            'message': 'The given data was invalid.',
            'errors': {
              'username': ['Username wajib diisi.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final appException = AppException.fromDioException(dioError);
      expect(appException.statusCode, 422);
      expect(appException.message, 'Username wajib diisi.');
    });

    test('AppException parses 401 unauthorized correctly', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthenticated.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final appException = AppException.fromDioException(dioError);
      expect(appException.statusCode, 401);
      expect(appException.message, contains('Sesi Anda telah berakhir'));
    });

    test('DioClient initializes with default API baseUrl', () {
      final client = DioClient();
      expect(client.dio.options.baseUrl, DioClient.defaultBaseUrl);
      expect(client.dio.options.connectTimeout, const Duration(seconds: 15));
    });

    test('GeotagService detects and rejects mock location or poor accuracy', () {
      const service = GeotagService();

      final validLocation = GeotagLocation(
        latitude: -7.3274,
        longitude: 108.2207,
        accuracy: 12.5,
        timestamp: DateTime.now(),
        isMocked: false,
      );
      expect(service.validatePositionIntegrity(validLocation), isTrue);

      final mockedLocation = GeotagLocation(
        latitude: -7.3274,
        longitude: 108.2207,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        isMocked: true,
      );
      expect(service.validatePositionIntegrity(mockedLocation), isFalse);

      final lowAccuracyLocation = GeotagLocation(
        latitude: -7.3274,
        longitude: 108.2207,
        accuracy: 85.0, // > 50 meter
        timestamp: DateTime.now(),
        isMocked: false,
      );
      expect(service.validatePositionIntegrity(lowAccuracyLocation), isFalse);
    });

    test('MediaUploadOptimizer validates PDF <= 10MB and DWG <= 50MB', () {
      // PDF 9MB -> valid
      expect(
        MediaUploadOptimizer.validateDocumentSize(
          fileName: 'dokumen.pdf',
          sizeBytes: 9 * 1024 * 1024,
          isDwg: false,
        ),
        isNull,
      );

      // PDF 12MB -> melebihi 10MB
      expect(
        MediaUploadOptimizer.validateDocumentSize(
          fileName: 'dokumen_besar.pdf',
          sizeBytes: 12 * 1024 * 1024,
          isDwg: false,
        ),
        isNotNull,
      );

      // DWG 45MB -> valid
      expect(
        MediaUploadOptimizer.validateDocumentSize(
          fileName: 'siteplan.dwg',
          sizeBytes: 45 * 1024 * 1024,
          isDwg: true,
        ),
        isNull,
      );

      // DWG 55MB -> melebihi 50MB
      expect(
        MediaUploadOptimizer.validateDocumentSize(
          fileName: 'siteplan_jumbo.dwg',
          sizeBytes: 55 * 1024 * 1024,
          isDwg: true,
        ),
        isNotNull,
      );
    });
  });
}

