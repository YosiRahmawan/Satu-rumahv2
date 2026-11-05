import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../utils/kecamatan.dart';
import '../providers/pengajuan_form_controller.dart';

/// Pilihan kecamatan lokasi proyek. Dipakai Dinas untuk rekap sebaran pengajuan per kecamatan,
/// jadi pilihan ini lebih akurat daripada menebak dari teks alamat.
class KecamatanField extends ConsumerWidget {
  const KecamatanField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pilihan = ref.watch(pengajuanFormProvider.select((s) => s.kecamatan));
    return DropdownButtonFormField<String>(
      key: const Key('kecamatan-proyek'),
      initialValue: kKecamatanTasikmalaya.contains(pilihan) ? pilihan : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kecamatan lokasi proyek',
        helperText:
            'Dipakai untuk rekap sebaran pengajuan per kecamatan di Dinas.',
        helperMaxLines: 2,
        prefixIcon: Icon(
          Icons.map_outlined,
          size: 20,
          color: AppColors.slate500,
        ),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih kecamatan'),
      items: [
        for (final k in kKecamatanTasikmalaya)
          DropdownMenuItem(value: k, child: Text(k)),
      ],
      onChanged: (v) =>
          ref.read(pengajuanFormProvider.notifier).setKecamatan(v ?? ''),
    );
  }
}
