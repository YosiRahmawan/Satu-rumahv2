import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/widgets/fab_tetap.dart';

void main() {
  testWidgets('tombol tengah tidak naik saat SnackBar muncul', (tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: Scaffold(
          floatingActionButtonLocation: const FabTetapDocked(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: const BottomAppBar(
            shape: CircularNotchedRectangle(),
            child: SizedBox(height: 56),
          ),
        ),
      ),
    );
    final awal = tester.getCenter(find.byType(FloatingActionButton));
    key.currentState!.showSnackBar(const SnackBar(content: Text('Halo')));
    await tester.pumpAndSettle();
    expect(find.text('Halo'), findsOneWidget);
    expect(tester.getCenter(find.byType(FloatingActionButton)), awal);
  });
}
