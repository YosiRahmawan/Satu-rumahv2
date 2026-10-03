import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:satu_rumah/features/auth/presentation/screens/splash_screen.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
}

Widget _testApp(GoRouter router) {
  return MaterialApp.router(routerConfig: router);
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

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('LOGIN'), findsOneWidget);
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
