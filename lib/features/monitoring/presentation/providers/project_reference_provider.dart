import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project_reference.dart';

/// Titik referensi proyek untuk sebuah pengajuan.
///
/// Sumber datanya adalah branch Pengembang (`Pengajuan.lokasiProyek`) yang
/// belum tersedia di branch ini, jadi hasilnya `null` ("titik proyek belum
/// tersedia"). Saat kontraknya masuk, cukup ganti isi provider ini; semua
/// layar Perwaskim hanya membaca dan tidak pernah menulis.
final projectReferenceProvider = Provider.family<ProjectReference?, String?>(
  (ref, pengajuanId) => null,
);
