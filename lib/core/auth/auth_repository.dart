import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'role_session.dart';
import 'token_store.dart';

/// Pengguna yang sedang masuk, sebagaimana dikirim server.
class AuthUser {
  final int id;
  final String name;
  final String username;
  final AppRole role;
  final String? jabatan;

  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.jabatan,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    name: '${json['name']}',
    username: '${json['username']}',
    role: appRoleFromApi('${json['role']}'),
    jabatan: json['jabatan'] as String?,
  );
}

class AuthResult {
  final AuthUser user;
  final bool mustChangePassword;
  const AuthResult(this.user, this.mustChangePassword);
}

/// Nilai `users.role` di server → role aplikasi. Role web (verifikator,
/// administrator) tidak boleh masuk lewat aplikasi sehingga menjadi `guest`.
AppRole appRoleFromApi(String role) => switch (role) {
  'pengembang' => AppRole.developer,
  'tim_lapangan' => AppRole.perwaskim,
  _ => AppRole.guest,
};

abstract class AuthRepository {
  Future<AuthResult> login({
    required String username,
    required String password,
    String deviceName,
  });

  /// Memulihkan sesi dari token tersimpan; null bila belum masuk atau token
  /// tidak berlaku lagi. Kegagalan jaringan dilempar sebagai [ApiException].
  Future<AuthResult?> restore();

  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  final TokenStore _tokens;

  ApiAuthRepository(this._dio, this._tokens);

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
    String deviceName = 'mobile',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login',
        data: {
          'username': username,
          'password': password,
          'device_name': deviceName,
        },
      );
      final body = response.data!;
      final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
      if (user.role == AppRole.guest) {
        throw const ApiException(
          code: 'ERR-022',
          message: 'Akun ini memakai Web Admin, bukan aplikasi mobile.',
        );
      }
      await _tokens.write('${body['token']}');
      return AuthResult(user, body['must_change_password'] == true);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AuthResult?> restore() async {
    if (await _tokens.read() == null) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('me');
      final body = response.data!;
      final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
      if (user.role == AppRole.guest) {
        await _tokens.delete();
        return null;
      }
      return AuthResult(user, body['must_change_password'] == true);
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      // 401 sudah menghapus token di interceptor: sesi memang berakhir.
      if (error.status == 401) return null;
      throw error;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('auth/logout');
    } on DioException {
      // Keluar tetap berlaku di perangkat walau server tak terjangkau.
    } finally {
      await _tokens.delete();
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        'auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(apiDioProvider),
    ref.watch(tokenStoreProvider),
  ),
);

/// Keluar: mencabut token di server (bila mode API) lalu menghapus sesi lokal.
Future<void> performLogout(WidgetRef ref) async {
  if (ref.read(apiEnabledProvider)) {
    await ref.read(authRepositoryProvider).logout();
  }
  ref.read(roleSessionProvider.notifier).signOut();
}
