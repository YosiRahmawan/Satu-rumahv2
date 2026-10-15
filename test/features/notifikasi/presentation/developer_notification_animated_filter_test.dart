import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:satu_rumah/features/notifikasi/presentation/widgets/developer_notification_tile.dart';
import 'package:satu_rumah/features/notifikasi/presentation/widgets/developer_notification_view.dart';

void main() {
  final sampleItems = [
    NotifikasiModel(
      id: '1',
      jenis: JenisNotifikasi.pengajuanBaru,
      judul: 'Notifikasi 1',
      deskripsi: 'Deskripsi 1',
      waktu: DateTime(2026, 10, 1),
      isRead: false,
    ),
    NotifikasiModel(
      id: '2',
      jenis: JenisNotifikasi.reminderSurvey,
      judul: 'Notifikasi 2',
      deskripsi: 'Deskripsi 2',
      waktu: DateTime(2026, 10, 2),
      isRead: true,
    ),
  ];

  Widget buildView({
    required bool unreadOnly,
    required ValueChanged<bool> onFilterChanged,
    int unreadCount = 1,
    bool disableAnimations = false,
  }) {
    final filtered = unreadOnly
        ? sampleItems.where((i) => !i.isRead).toList()
        : sampleItems;
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: DeveloperNotificationView(
          items: filtered,
          unreadCount: unreadCount,
          unreadOnly: unreadOnly,
          onFilterChanged: onFilterChanged,
          onMarkAllRead: () {},
          onOpen: (_) {},
        ),
      ),
    );
  }

  testWidgets(
    'animates active indicator smoothly on filter change and respects unread count',
    (tester) async {
      bool currentFilter = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildView(
              unreadOnly: currentFilter,
              onFilterChanged: (val) => setState(() => currentFilter = val),
              unreadCount: 3,
            );
          },
        ),
      );

      // Initial state: "Semua" active, "Belum dibaca (3)" inactive
      expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Belum dibaca (3)'),
        findsOneWidget,
      );
      expect(find.byType(DeveloperNotificationTile), findsNWidgets(2));

      // Tap "Belum dibaca (3)" to trigger 220ms animation
      await tester.tap(find.widgetWithText(ChoiceChip, 'Belum dibaca (3)'));
      await tester.pump(); // Start of animation (0ms)
      await tester.pump(const Duration(milliseconds: 110)); // Mid-way (110ms)
      await tester.pump(
        const Duration(milliseconds: 150),
      ); // Finished (260ms total)

      expect(currentFilter, isTrue);
      expect(find.byType(DeveloperNotificationTile), findsOneWidget);

      // Rapid toggle: Tap "Semua" immediately then "Belum dibaca"
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Belum dibaca (3)'));
      await tester.pumpAndSettle();

      expect(currentFilter, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('respects reduced-motion setting without breaking state', (
    tester,
  ) async {
    bool currentFilter = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildView(
            unreadOnly: currentFilter,
            onFilterChanged: (val) => setState(() => currentFilter = val),
            disableAnimations: true,
          );
        },
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Belum dibaca (1)'));
    await tester
        .pump(); // When disableAnimations: true, completes without timer

    expect(currentFilter, isTrue);
    expect(tester.takeException(), isNull);
  });
}
