import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/monitoring/data/repositories/monitoring_store.dart';

void main() {
  late Directory dir;
  FileMonitoringStore buka() => FileMonitoringStore(direktori: () async => dir);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('foto_uji_');
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test(
    'foto besar dan banyak tersimpan (tidak dibatasi 3 MB seperti sebelumnya)',
    () async {
      final store = buka();
      final besar = Uint8List.fromList(List.filled(5 * 1024 * 1024, 7));

      for (var i = 0; i < 4; i++) {
        expect(await store.savePhoto('foto_$i', besar), isTrue);
      }
      expect((await store.storedPhotoIds()), {
        'foto_0',
        'foto_1',
        'foto_2',
        'foto_3',
      });
      expect((await store.loadPhoto('foto_2'))!.length, 5 * 1024 * 1024);
    },
  );

  test(
    'foto bertahan setelah aplikasi dibuka kembali (objek baru, folder sama)',
    () async {
      await buka().savePhoto('foto_a', Uint8List.fromList([1, 2, 3]));

      final setelahBuka = buka();
      expect(await setelahBuka.loadPhoto('foto_a'), [1, 2, 3]);
      expect(await setelahBuka.storedPhotoIds(), {'foto_a'});
    },
  );

  test('timpa, hapus, dan foto yang tidak ada', () async {
    final store = buka();
    await store.savePhoto('f', Uint8List.fromList([1]));
    await store.savePhoto('f', Uint8List.fromList([9, 9]));
    expect(await store.loadPhoto('f'), [9, 9]);

    await store.deletePhoto('f');
    expect(await store.loadPhoto('f'), isNull);
    expect(await store.storedPhotoIds(), isEmpty);
    await store.deletePhoto('tidak_ada'); // tidak melempar
    expect(await store.loadPhoto('tidak_ada'), isNull);
  });

  test(
    'id foto dengan karakter berbahaya tidak keluar dari folder foto',
    () async {
      final store = buka();
      expect(
        await store.savePhoto('../../x/../luar', Uint8List.fromList([1])),
        isTrue,
      );

      // Semua berkas berada langsung di dalam folder foto.
      final isi = dir.listSync().whereType<File>().toList();
      expect(isi, hasLength(1));
      expect(isi.single.parent.path, dir.path);
      expect(
        await Directory(
          dir.parent.path,
        ).list().where((e) => e.path.endsWith('luar.img')).isEmpty,
        isTrue,
      );
    },
  );

  test(
    'gagal menulis (folder berupa berkas) mengembalikan false, bukan melempar',
    () async {
      final berkas = File('${dir.path}${Platform.pathSeparator}bukan_folder');
      await berkas.writeAsString('x');
      final store = FileMonitoringStore(
        direktori: () async => Directory(berkas.path),
      );

      expect(await store.savePhoto('f', Uint8List.fromList([1])), isFalse);
      expect(await store.loadPhoto('f'), isNull);
    },
  );
}
