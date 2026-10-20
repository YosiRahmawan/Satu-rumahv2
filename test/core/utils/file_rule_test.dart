import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/core/utils/file_picker_util.dart';

void main() {
  group('FilePickerUtil.revisionRule / violationOf', () {
    test('berkas biasa hanya menerima PDF maks. 10 MB', () {
      final rule = FilePickerUtil.revisionRule('ktp');
      expect(rule.allowed, ['pdf']);
      expect(rule.maxMb, 10);
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'a.pdf', size: 1024),
          rule,
        ),
        isNull,
      );
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'a.jpg', size: 1024),
          rule,
        )?.message,
        'Format tidak didukung. Gunakan PDF.',
      );
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'a.pdf', size: 10 * 1024 * 1024 + 1),
          rule,
        )?.message,
        'File melebihi batas maksimal 10 MB.',
      );
    });

    test('site plan menerima DWG atau PDF maks. 50 MB', () {
      final rule = FilePickerUtil.revisionRule('site_plan_dwg');
      expect(rule.allowed, ['dwg', 'pdf']);
      expect(rule.maxMb, 50);
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'denah.DWG', size: 30 * 1024 * 1024),
          rule,
        ),
        isNull,
      );
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'denah.zip', size: 1024),
          rule,
        )?.message,
        'Format tidak didukung. Gunakan DWG atau PDF.',
      );
      expect(
        FilePickerUtil.violationOf(
          PlatformFile(name: 'denah.dwg', size: 50 * 1024 * 1024 + 1),
          rule,
        )?.reason,
        'Melebihi batas maksimal',
      );
    });
  });
}
