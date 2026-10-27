import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/profil/data/developer_profile_repository.dart';

void main() {
  test('profil server dipetakan dan tipe pengajuan dikenali', () {
    final p = DeveloperProfileData.fromJson({
      'nib': '1234567890123',
      'nama_pt': 'PT Uji',
      'nama_direktur': 'Pak Direktur',
      'email_pt': 'pt@uji.id',
      'no_hp_direktur': '0812',
      'tipe_pengajuan': 'perubahan_siteplan',
    });
    expect(p.namaPt, 'PT Uji');
    expect(p.namaDirektur, 'Pak Direktur');
    expect(p.tipePengajuanLabel, 'Perubahan Siteplan');
    expect(p.alamatPt, '');
  });

  test('tipe pengajuan tak dikenal tidak menimpa pilihan form', () {
    expect(
      const DeveloperProfileData(tipePengajuan: 'lain').tipePengajuanLabel,
      '',
    );
  });
}
