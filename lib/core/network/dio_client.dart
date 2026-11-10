import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/auth_token_store.dart';
import 'app_exception.dart';

/// Provider singleton AuthTokenStore
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return const AuthTokenStore();
});

/// Callback untuk penanganan auto-logout saat HTTP 401
typedef OnUnauthorizedCallback = void Function();

/// DioClient terpusat untuk komunikasi dengan Laravel Backend (/api/v1)
class DioClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  final OnUnauthorizedCallback? onUnauthorized;

  DioClient({
    String? baseUrl,
    AuthTokenStore? tokenStore,
    this.onUnauthorized,
  })  : _tokenStore = tokenStore ?? const AuthTokenStore(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Sisipkan Bearer token jika tersedia
          final token = await _tokenStore.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Auto-clear token saat 401 Unauthorized
          if (error.response?.statusCode == 401) {
            await _tokenStore.clear();
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Wrapper GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Wrapper POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Wrapper PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Wrapper DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

/// Provider DioClient terpusat
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStore = ref.watch(authTokenStoreProvider);
  return DioClient(tokenStore: tokenStore);
});

