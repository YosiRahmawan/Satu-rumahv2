import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/evidence_photo_picker.dart';

Future<void> _pumpPicker(
  WidgetTester tester, {
  required PhotoPathPicker picker,
  CameraPhotoPicker? cameraPicker,
  required ValueChanged<List<String>> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EvidencePhotoPicker(
          photoPaths: const [],
          onPhotosChanged: onChanged,
          pickPhotoPaths: picker,
          pickCameraPhoto: cameraPicker,
        ),
      ),
    ),
  );
}

Finder _addPhotoButton() => find.text('Tambah foto');

void main() {
  testWidgets('canceled picker does not add a fake photo', (tester) async {
    var callbackCount = 0;
    await _pumpPicker(
      tester,
      picker: () async => const [],
      onChanged: (_) => callbackCount++,
    );

    await tester.tap(_addPhotoButton());
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
  });

  testWidgets('stale picker completion is ignored when a newer pick wins', (
    tester,
  ) async {
    final first = Completer<List<String>>();
    final second = Completer<List<String>>();
    var requestCount = 0;
    final updates = <List<String>>[];

    await _pumpPicker(
      tester,
      picker: () {
        requestCount++;
        return requestCount == 1 ? first.future : second.future;
      },
      onChanged: updates.add,
    );

    await tester.tap(_addPhotoButton());
    await tester.pump();
    await tester.tap(_addPhotoButton());
    await tester.pump();

    first.complete(['old.jpg']);
    await tester.pump();
    expect(updates, isEmpty);

    second.complete(['new.jpg']);
    await tester.pump();
    expect(updates, [
      <String>['new.jpg'],
    ]);
  });

  testWidgets('picker completion after disposal is ignored', (tester) async {
    final pending = Completer<List<String>>();
    var callbackCount = 0;
    await _pumpPicker(
      tester,
      picker: () => pending.future,
      onChanged: (_) => callbackCount++,
    );

    await tester.tap(_addPhotoButton());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    pending.complete(['disposed.jpg']);
    await tester.pump();

    expect(callbackCount, 0);
  });

  testWidgets('camera picker adds a returned path', (tester) async {
    final updates = <List<String>>[];
    await _pumpPicker(
      tester,
      picker: () async => const [],
      cameraPicker: () async => 'camera-photo.jpg',
      onChanged: updates.add,
    );

    await tester.tap(_addPhotoButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil Foto Langsung'));
    await tester.pumpAndSettle();

    expect(updates, [<String>['camera-photo.jpg']]);
  });

  testWidgets('camera picker error keeps state unchanged and shows feedback', (
    tester,
  ) async {
    var callbackCount = 0;
    await _pumpPicker(
      tester,
      picker: () async => const [],
      cameraPicker: () async => throw StateError('permission denied'),
      onChanged: (_) => callbackCount++,
    );

    await tester.tap(_addPhotoButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil Foto Langsung'));
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
    expect(find.textContaining('Kamera tidak dapat digunakan'), findsOneWidget);
  });

  testWidgets('renders photo preview using Image.memory when bytes are cached without Image.file', (
    tester,
  ) async {
    final transparentPng = Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    EvidencePhotoPicker.cacheBytes('test-photo.jpg', transparentPng);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvidencePhotoPicker(
            photoPaths: const ['test-photo.jpg'],
            onPhotosChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<MemoryImage>());
    expect(find.text('Tambah foto'), findsOneWidget);
  });
}
