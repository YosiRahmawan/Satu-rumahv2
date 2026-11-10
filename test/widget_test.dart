import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satu_rumah/app.dart';

void main() {
  testWidgets('App renders screen and displays brand text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SatuRumahApp(),
      ),
    );

    // Initial frame on splash screen renders brand title
    await tester.pump();
    expect(find.textContaining('SATU RUMAH'), findsWidgets);
  });
}
