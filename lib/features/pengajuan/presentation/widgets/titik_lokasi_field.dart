import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../monitoring/presentation/providers/camera_providers.dart';
import '../../../monitoring/services/location_service.dart';
import '../../utils/koordinat_peta.dart';
import '../providers/pengajuan_form_controller.dart';

/// Titik lokasi proyek di peta. Alamat saja sering kurang tepat bagi petugas, jadi pengembang bisa
/// memakai lokasinya saat ini (bila sedang di lokasi) atau menempel tautan Google Maps.
class TitikLokasiField extends ConsumerStatefulWidget {
  const TitikLokasiField({super.key});

  @override
  ConsumerState<TitikLokasiField> createState() => _TitikLokasiFieldState();
}

class _TitikLokasiFieldState extends ConsumerState<TitikLokasiField> {
  final _tautan = TextEditingController();
  String? _pesan;
  bool _mencari = false;

  @override
  void dispose() {
    _tautan.dispose();
    super.dispose();
  }

  void _simpan(double lat, double lng) {
    ref.read(pengajuanFormProvider.notifier).setTitikLokasi(lat, lng);
  }

  Future<void> _pakaiLokasiSaya() async {
    setState(() {
      _mencari = true;
      _pesan = null;
    });
    final hasil = await ref.read(locationServiceProvider).currentFix();
    if (!mounted) return;
    final fix = hasil.fix;
    setState(() {
      _mencari = false;
      if (fix == null) {
        _pesan =
            'Lokasi belum didapat. Aktifkan GPS dan izin lokasi, atau tempel tautan Google Maps.';
      } else {
        _simpan(fix.latitude, fix.longitude);
        _tautan.clear();
      }
    });
  }

  void _tautanBerubah(String teks) {
    if (teks.trim().isEmpty) {
      setState(() => _pesan = null);
      return;
    }
    final k = parseKoordinat(teks);
    setState(() {
      if (k == null) {
        _pesan =
            'Koordinat tidak ditemukan di tautan ini. Tautan pendek (maps.app.goo.gl) tidak bisa dibaca; '
            'buka dulu lalu salin alamat lengkapnya, atau pakai lokasi saya.';
      } else {
        _pesan = null;
        _simpan(k.lat, k.lng);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lat = ref.watch(pengajuanFormProvider.select((s) => s.latitude));
    final lng = ref.watch(pengajuanFormProvider.select((s) => s.longitude));
    final terisi = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Titik lokasi di peta (disarankan)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Petugas survei membuka peta tepat ke titik ini. Tanpa titik, peta mencari berdasarkan alamat.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (terisi)
            Row(
              children: [
                const Icon(Icons.place, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    key: const Key('titik-lokasi-nilai'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('titik-lokasi-hapus'),
                  onPressed: () {
                    ref
                        .read(pengajuanFormProvider.notifier)
                        .setTitikLokasi(null, null);
                    _tautan.clear();
                  },
                  child: const Text('Hapus'),
                ),
              ],
            ),
          if (!terisi) ...[
            OutlinedButton.icon(
              key: const Key('titik-lokasi-saya'),
              onPressed: _mencari ? null : _pakaiLokasiSaya,
              icon: _mencari
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Gunakan lokasi saya sekarang'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('titik-lokasi-tautan'),
              controller: _tautan,
              onChanged: _tautanBerubah,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Atau tempel tautan Google Maps',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_pesan != null) ...[
            const SizedBox(height: 8),
            Text(
              _pesan!,
              key: const Key('titik-lokasi-pesan'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.statusUrgentText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
