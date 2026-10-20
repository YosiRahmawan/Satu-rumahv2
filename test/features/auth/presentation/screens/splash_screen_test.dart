import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/core/auth/role_session.dart';
import 'package:satu_rumah/features/auth/presentation/screens/splash_screen.dart';

GoRouter _testRouter({List<GoRoute>? additionalRoutes}) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('LOGIN')),
      ),
      ...?additionalRoutes,
    ],
  );
}

Widget _testApp(GoRouter router, {ProviderContainer? container}) {
  final app = MaterialApp.router(routerConfig: router);
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return app;
}

void main() {
  testWidgets('Splash transitions to login after its delay', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('tapping on splash screen immediately navigates to login', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Tap to skip before 2600ms delay
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('navigates to role homeRoute if user is already authenticated', (
    tester,
  ) async {
    final router = _testRouter(
      additionalRoutes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Set authenticated session as developer
    container
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.developer, username: 'dev_user');

    await tester.pumpWidget(_testApp(router, container: container));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  testWidgets('disposing Splash before its delay leaves no pending callback', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_testApp(router));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    router.go('/login');
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
