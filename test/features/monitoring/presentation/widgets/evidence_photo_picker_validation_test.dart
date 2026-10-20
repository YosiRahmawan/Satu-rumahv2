import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:satu_rumah/features/monitoring/data/photo_bytes_cache.dart';
import 'package:satu_rumah/features/monitoring/presentation/widgets/evidence_photo_picker.dart';

class _FakeImagePicker extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  List<XFile> gallery = [];
  XFile? camera;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => gallery;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => camera;
}

Uint8List _jpeg(int seed, {int size = 64}) => Uint8List(size)
  ..fillRange(0, size, seed)
  ..setRange(0, 3, [0xFF, 0xD8, 0xFF]);

final Uint8List _heic = Uint8List.fromList([
  0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63, //
  0, 0, 0, 0,
]);

XFile _file(String name, Uint8List bytes) =>
    XFile.fromData(bytes, name: name, path: 'blob:$name');

void main() {
  late _FakeImagePicker fake;
  late ImagePickerPlatform original;
  late List<List<String>> changes;

  setUp(() {
    original = ImagePickerPlatform.instance;
    fake = _FakeImagePicker();
    ImagePickerPlatform.instance = fake;
    changes = [];
    PhotoBytesCache.clear();
  });

  tearDown(() {
    ImagePickerPlatform.instance = original;
  });

  Future<void> pump(
    WidgetTester tester, {
    List<String> existing = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EvidencePhotoPicker(
              photoPaths: existing,
              onPhotosChanged: changes.add,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> chooseGallery(WidgetTester tester) async {
    await tester.tap(find.text('Tambah foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih dari Galeri / Berkas'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'foto valid masuk; HEIC, bukan foto, dan duplikat ditolak jelas',
    (tester) async {
      fake.gallery = [
        _file('a.jpg', _jpeg(1)),
        _file('b.heic', _heic),
        _file('c.txt', Uint8List.fromList([1, 2, 3, 4, 5])),
        _file('a-lagi.jpg', _jpeg(1)),
      ];
      await pump(tester);
      await chooseGallery(tester);

      expect(changes, [
        ['blob:a.jpg'],
      ]);
      expect(PhotoBytesCache.contains('blob:a.jpg'), isTrue);
      expect(PhotoBytesCache.contains('blob:b.heic'), isFalse);

      expect(find.textContaining('3 foto tidak ditambahkan'), findsOneWidget);
      expect(
        find.textContaining('b.heic: format HEIC belum didukung'),
        findsOne,
      );
      expect(find.textContaining('c.txt: format tidak didukung'), findsOne);
      expect(find.textContaining('dan 1 foto lainnya'), findsOneWidget);
    },
  );

  testWidgets('foto yang sama dengan yang sudah ada ditolak', (tester) async {
    PhotoBytesCache.put('blob:lama.jpg', _jpeg(7));
    fake.gallery = [_file('baru.jpg', _jpeg(7))];
    await pump(tester, existing: ['blob:lama.jpg']);
    await chooseGallery(tester);

    expect(changes, isEmpty);
    expect(
      find.textContaining('baru.jpg: foto yang sama sudah ditambahkan'),
      findsOneWidget,
    );
  });

  testWidgets('lebih dari 10 MB ditolak dengan alasan ukuran', (tester) async {
    fake.gallery = [_file('besar.jpg', _jpeg(9, size: 10 * 1024 * 1024 + 1))];
    await pump(tester);
    await chooseGallery(tester);

    expect(changes, isEmpty);
    expect(find.textContaining('besar.jpg: lebih dari 10 MB'), findsOneWidget);
  });

  testWidgets('membatalkan galeri tidak menampilkan pesan apa pun', (
    tester,
  ) async {
    fake.gallery = [];
    await pump(tester);
    await chooseGallery(tester);

    expect(changes, isEmpty);
    expect(find.textContaining('tidak ditambahkan'), findsNothing);
  });

  testWidgets('foto kamera HEIC ditolak dengan petunjuk', (tester) async {
    fake.camera = _file('kamera.heic', _heic);
    await pump(tester);
    await tester.tap(find.text('Tambah foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil Foto Langsung'));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.textContaining('kamera.heic: format HEIC'), findsOneWidget);
  });

  testWidgets('foto kamera valid diterima', (tester) async {
    fake.camera = _file('kamera.jpg', _jpeg(5));
    await pump(tester);
    await tester.tap(find.text('Tambah foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil Foto Langsung'));
    await tester.pumpAndSettle();

    expect(changes, [
      ['blob:kamera.jpg'],
    ]);
  });
}
