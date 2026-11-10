import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/auth_token_store.dart';

class AuthUser {
  final int? id;
  final String username;
  final String? name;
  final String? email;
  final String role;

  AuthUser({
    this.id,
    required this.username,
    this.name,
    this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int?,
      username: (json['username'] ?? json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? 'developer').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'role': role,
      };
}

class AuthRepository {
  final DioClient dioClient;
  final AuthTokenStore tokenStore;

  AuthRepository({
    required this.dioClient,
    required this.tokenStore,
  });

  /// Login via backend Sanctum (/api/v1/auth/login)
  /// Mengembalikan token dan user model.
  Future<({String token, AuthUser user})> login({
    required String username,
    required String password,
  }) async {
    try {
      final isEmail = username.contains('@');
      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': isEmail ? username : '$username@saturumah.go.id',
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data;
        final token = (payload['token'] ?? payload['access_token'] ?? '').toString();
        final userJson = payload['user'] is Map<String, dynamic>
            ? payload['user'] as Map<String, dynamic>
            : <String, dynamic>{'username': username, 'role': 'developer'};

        final user = AuthUser.fromJson(userJson);

        if (token.isNotEmpty) {
          await tokenStore.saveToken(token);
          await tokenStore.saveUserData(jsonEncode(user.toJson()));
        }

        return (token: token, user: user);
      }

      throw AppException(message: 'Format respon dari server tidak dikenali.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        message: 'Gagal melakukan login: $e',
        originalError: e,
      );
    }
  }

  /// Logout via backend (/api/v1/auth/logout)
  Future<void> logout() async {
    try {
      await dioClient.post('/auth/logout');
    } catch (_) {
      // Abaikan kegagalan jaringan saat logout
    } finally {
      await tokenStore.clear();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final tokenStore = ref.watch(authTokenStoreProvider);
  return AuthRepository(dioClient: dioClient, tokenStore: tokenStore);
});
