import 'package:flutter_test/flutter_test.dart';
import 'package:satu_rumah/features/pengajuan/data/models/hasil_survey_model.dart';

HasilSurveyItem _survey({
  required bool isDraft,
  List<String> photos = const [],
}) {
  return HasilSurveyItem(
    id: 's-1',
    tanggalSurvey: DateTime(2026, 10, 20),
    pelaksanaNama: 'Tim',
    pelaksanaJabatan: 'Ketua',
    lokasiPerumahan: 'Kota Tasikmalaya',
    statusHasilEvaluasi: 'sesuai',
    photoPaths: photos,
    isDraft: isDraft,
  );
}

void main() {
  test('laporan final dianggap terlaksana walau tanpa foto', () {
    expect(_survey(isDraft: false).sudahTerlaksana, isTrue);
  });

  test('draf belum terlaksana, ada foto atau tidak', () {
    expect(_survey(isDraft: true).sudahTerlaksana, isFalse);
    expect(
      _survey(isDraft: true, photos: const ['a.jpg']).sudahTerlaksana,
      isFalse,
    );
  });
}
