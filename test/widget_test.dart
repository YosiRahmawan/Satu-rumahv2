import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satu_rumah/app.dart';

void main() {
  testWidgets('App renders login screen on start', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SatuRumahApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('PILIH PERAN AKUN PENGGUNA'), findsOneWidget);
  });
}
