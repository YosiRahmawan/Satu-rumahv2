import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/api/api_client.dart';
import 'package:satu_rumah/core/auth/auth_repository.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/auth/presentation/screens/ganti_sandi_screen.dart';
import 'package:satu_rumah/features/auth/presentation/screens/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  AuthResult? loginResult;
  ApiException? loginError;
  ApiException? changeError;
  int logouts = 0;
  String? changedTo;

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
    String deviceName = 'mobile',
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<AuthResult?> restore() async => null;

  @override
  Future<void> logout() async => logouts++;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (changeError != null) throw changeError!;
    changedTo = newPassword;
  }
}

AuthResult _result(AppRole role, {bool must = false}) => AuthResult(
  AuthUser(
    id: 1,
    name: 'Uji',
    username: role == AppRole.developer ? 'pengembang' : 'tim_lapangan',
    role: role,
  ),
  must,
);

void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;
  late GoRouter router;

  Future<void> pump(WidgetTester tester, {String start = '/login'}) async {
    repo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://uji.test/api/v1/'),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/ganti-sandi',
          builder: (_, __) => const GantiSandiScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
        ),
        GoRoute(
          path: '/monitoring/lapangan',
          builder: (_, __) => const Scaffold(body: Text('MONITORING')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitLogin(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'pengembang');
    await tester.enterText(fields.at(1), 'rahasia123');
    await tester.tap(find.textContaining('Masuk sebagai'));
    await tester.pumpAndSettle();
  }

  testWidgets('login API: pengembang masuk ke beranda pengembang', (
    tester,
  ) async {
    await pump(tester);
    repo.loginResult = _result(AppRole.developer);

    await submitLogin(tester);

    expect(find.text('DASHBOARD'), findsOneWidget);
    final session = container.read(roleSessionProvider);
    expect(session.role, AppRole.developer);
    expect(session.username, 'pengembang');
  });

  testWidgets('login API: role ditentukan server, bukan tab yang dipilih', (
    tester,
  ) async {
    await pump(tester);
    repo.loginResult = _result(AppRole.perwaskim);

    await submitLogin(tester); // tab bawaan: Pengembang

    expect(find.text('MONITORING'), findsOneWidget);
    expect(container.read(roleSessionProvider).role, AppRole.perwaskim);
  });

  testWidgets('login API: sandi sementara mengarah ke Ganti Kata Sandi', (
    tester,
  ) async {
    await pump(tester);
    repo.loginResult = _result(AppRole.developer, must: true);

    await submitLogin(tester);

    expect(find.text('Ganti Kata Sandi'), findsWidgets);
    expect(container.read(roleSessionProvider).mustChangePassword, isTrue);
  });

  testWidgets('login API: galat server tampil dan sesi tetap tamu', (
    tester,
  ) async {
    await pump(tester);
    repo.loginError = const ApiException(
      code: 'ERR-020',
      message: 'Username atau kata sandi salah.',
      status: 401,
    );

    await submitLogin(tester);

    expect(find.text('Username atau kata sandi salah.'), findsOneWidget);
    expect(container.read(roleSessionProvider).isAuthenticated, isFalse);
  });

  testWidgets('login API: pintasan demo (tekan lama logo) dinonaktifkan', (
    tester,
  ) async {
    await pump(tester);

    final logo = find.byWidgetPredicate(
      (w) => w is GestureDetector && w.onLongPress != null,
    );
    expect(logo, findsNothing);
  });

  testWidgets('ganti sandi: validasi lokal lalu berhasil menuju beranda', (
    tester,
  ) async {
    await pump(tester, start: '/ganti-sandi');
    container
        .read(roleSessionProvider.notifier)
        .signIn(
          AppRole.developer,
          username: 'pengembang',
          mustChangePassword: true,
        );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Lama-2026a');
    await tester.enterText(fields.at(1), 'pendek');
    await tester.enterText(fields.at(2), 'pendek');
    await tester.tap(find.text('Simpan Kata Sandi Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    expect(repo.changedTo, isNull);

    await tester.enterText(fields.at(1), 'Baru-2026a');
    await tester.enterText(fields.at(2), 'Baru-2026a');
    await tester.tap(find.text('Simpan Kata Sandi Baru'));
    await tester.pumpAndSettle();

    expect(repo.changedTo, 'Baru-2026a');
    expect(container.read(roleSessionProvider).mustChangePassword, isFalse);
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  testWidgets('ganti sandi: galat kolom dari server ditampilkan', (
    tester,
  ) async {
    await pump(tester, start: '/ganti-sandi');
    repo.changeError = const ApiException(
      code: 'ERR-010',
      message: 'Isian tidak valid.',
      status: 422,
      fields: {
        'current_password': ['Kata sandi saat ini salah.'],
      },
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Salah-2026a');
    await tester.enterText(fields.at(1), 'Baru-2026a');
    await tester.enterText(fields.at(2), 'Baru-2026a');
    await tester.tap(find.text('Simpan Kata Sandi Baru'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi saat ini salah.'), findsOneWidget);
  });

  testWidgets('ganti sandi: Keluar mencabut sesi dan kembali ke login', (
    tester,
  ) async {
    await pump(tester, start: '/ganti-sandi');
    container
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.developer, mustChangePassword: true);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(repo.logouts, 1);
    expect(container.read(roleSessionProvider).isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('mode demo (tanpa API_BASE_URL): pintasan demo tetap ada', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    final logo = find.byWidgetPredicate(
      (w) => w is GestureDetector && w.onLongPress != null,
    );
    expect(logo, findsOneWidget);
  });
}
