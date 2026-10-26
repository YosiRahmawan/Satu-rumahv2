import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/auth_repository.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/core/auth/token_store.dart';

/// Penjawab HTTP palsu: antrean jawaban, dan catatan permintaan.
class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody Function()> replies = [];

  void reply(int status, Object body) => replies.add(
    () => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  void fail() => replies.add(() => throw const SocketLikeError());

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return replies.removeAt(0)();
  }

  @override
  void close({bool force = false}) {}
}

class SocketLikeError implements Exception {
  const SocketLikeError();
}

Map<String, dynamic> _loginBody({
  String role = 'pengembang',
  bool must = false,
}) => {
  'token': '1|abc',
  'user': {
    'id': 7,
    'name': 'PT Uji',
    'username': 'pengembang',
    'role': role,
    'jabatan': 'Direktur',
  },
  'must_change_password': must,
};

void main() {
  late FakeAdapter adapter;
  late MemoryTokenStore tokens;
  late int unauthorized;
  late ApiAuthRepository repo;

  setUp(() {
    adapter = FakeAdapter();
    tokens = MemoryTokenStore();
    unauthorized = 0;
    final dio = buildApiDio(
      baseUrl: 'http://uji.test/api/v1/',
      tokenStore: tokens,
      onUnauthorized: () => unauthorized++,
    )..httpClientAdapter = adapter;
    repo = ApiAuthRepository(dio, tokens);
  });

  test('role server dipetakan ke role aplikasi; role web menjadi guest', () {
    expect(appRoleFromApi('pengembang'), AppRole.developer);
    expect(appRoleFromApi('tim_lapangan'), AppRole.perwaskim);
    expect(appRoleFromApi('verifikator'), AppRole.guest);
    expect(appRoleFromApi('administrator'), AppRole.guest);
    expect(appRoleFromApi('apa-saja'), AppRole.guest);
  });

  test('login berhasil menyimpan token dan memetakan pengguna', () async {
    adapter.reply(200, _loginBody(must: true));

    final result = await repo.login(username: 'pengembang', password: 'x');

    expect(result.user.role, AppRole.developer);
    expect(result.user.username, 'pengembang');
    expect(result.mustChangePassword, isTrue);
    expect(await tokens.read(), '1|abc');
    expect(adapter.requests.single.path, 'auth/login');
    expect(adapter.requests.single.data['device_name'], 'mobile');
  });

  test('login role web ditolak dan token tidak disimpan', () async {
    adapter.reply(200, _loginBody(role: 'verifikator'));

    await expectLater(
      repo.login(username: 'v', password: 'x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'ERR-022')),
    );
    expect(await tokens.read(), isNull);
  });

  test('galat server dibaca sesuai format baku', () async {
    adapter.reply(401, {
      'error': {
        'code': 'ERR-020',
        'message': 'Username atau kata sandi salah.',
      },
    });
    adapter.reply(423, {
      'error': {
        'code': 'ERR-021',
        'message': 'Akun terkunci.',
        'locked_until': '2026-10-26T10:15:00+07:00',
      },
    });

    await expectLater(
      repo.login(username: 'a', password: 'b'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    await expectLater(
      repo.login(username: 'a', password: 'b'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'ERR-021')
            .having((e) => e.lockedUntil, 'lockedUntil', isNotNull),
      ),
    );
    // 401 pada login tidak boleh dianggap sesi berakhir.
    expect(unauthorized, 0);
  });

  test('tanpa jaringan: galat NETWORK dengan pesan yang jelas', () async {
    adapter.fail();

    await expectLater(
      repo.login(username: 'a', password: 'b'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
      ),
    );
  });

  test('permintaan membawa token tersimpan', () async {
    await tokens.write('9|zzz');
    adapter.reply(200, {
      'user': _loginBody()['user'],
      'must_change_password': false,
    });

    final result = await repo.restore();

    expect(result!.user.name, 'PT Uji');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer 9|zzz');
  });

  test(
    'restore: tanpa token null; token kedaluwarsa menghapus token',
    () async {
      expect(await repo.restore(), isNull);
      expect(adapter.requests, isEmpty);

      await tokens.write('lama');
      adapter.reply(401, {
        'error': {'code': 'ERR-020', 'message': 'Token tidak berlaku.'},
      });

      expect(await repo.restore(), isNull);
      expect(await tokens.read(), isNull);
      expect(unauthorized, 1);
    },
  );

  test('restore: gangguan jaringan dilempar dan token dipertahankan', () async {
    await tokens.write('masih-ada');
    adapter.fail();

    await expectLater(repo.restore(), throwsA(isA<ApiException>()));
    expect(await tokens.read(), 'masih-ada');
  });

  test('logout menghapus token walau server tidak terjangkau', () async {
    await tokens.write('abc');
    adapter.fail();

    await repo.logout();

    expect(await tokens.read(), isNull);
  });

  test('ganti sandi meneruskan galat isian per kolom', () async {
    adapter.reply(422, {
      'error': {
        'code': 'ERR-010',
        'message': 'Isian tidak valid.',
        'fields': {
          'current_password': ['Kata sandi saat ini salah.'],
        },
      },
    });

    await expectLater(
      repo.changePassword(currentPassword: 'salah', newPassword: 'Baru-2026a'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.fields['current_password'],
          'fields',
          ['Kata sandi saat ini salah.'],
        ),
      ),
    );
  });
}
