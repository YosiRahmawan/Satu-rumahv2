import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk menyimpan dan mengelola token autentikasi (Sanctum)
/// serta profil sesi user secara aman di perangkat.
class AuthTokenStore {
  static const String _keyToken = 'sanctum_auth_token';
  static const String _keyUser = 'auth_user_data';

  final FlutterSecureStorage _storage;

  const AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Simpan Bearer token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Ambil Bearer token tersimpan
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Periksa apakah user memiliki token
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Simpan data user / role (JSON string)
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _keyUser, value: userData);
  }

  /// Ambil data user
  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUser);
  }

  /// Hapus seluruh token dan sesi kredensial (saat logout / 401)
  Future<void> clear() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
    } catch (_) {
      // Menangani environment tanpa platform channel binding (misal isolated unit test)
    }
  }
}

