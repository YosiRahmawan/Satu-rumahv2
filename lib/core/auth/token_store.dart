import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tempat menyimpan token API. Token tidak boleh disimpan di
/// SharedPreferences karena tidak terenkripsi.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStore implements TokenStore {
  static const _key = 'api_token';
  final FlutterSecureStorage _storage;

  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Penyimpanan rusak (mis. setelah restore cadangan): anggap belum masuk.
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

/// Untuk tes.
class MemoryTokenStore implements TokenStore {
  String? token;

  MemoryTokenStore([this.token]);

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);
