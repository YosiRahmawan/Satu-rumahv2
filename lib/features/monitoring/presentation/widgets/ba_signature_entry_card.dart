import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ba_signature.dart';
import '../../data/repositories/officer_api_repository.dart';

/// Status persetujuan BA (Ketua lalu Admin) dan jalan masuk ke layar tanda tangan.
/// Tidak tampil di mode lokal (tanpa server).
class BaSignatureEntryCard extends ConsumerWidget {
  const BaSignatureEntryCard({
    super.key,
    required this.number,
    this.namaPerumahan,
  });

  final String number;
  final String? namaPerumahan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(apiEnabledProvider) || number.trim().isEmpty)
      return const SizedBox.shrink();
    final status = ref.watch(baSignatureStatusProvider(number));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.enterpriseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanda Tangan Berita Acara',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'BA diterbitkan Admin setelah Anda (Ketua Pengawas) dan Admin menandatanganinya dengan visualisasi TTE.',
            style: TextStyle(
              color: AppColors.enterpriseTextMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          status.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    e is ApiException && e.isNetwork
                        ? 'Tidak ada koneksi.'
                        : 'Status belum bisa dimuat.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(baSignatureStatusProvider(number)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
            data: (s) =>
                s == null ? const SizedBox.shrink() : _content(context, s),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, BaSignatureStatus s) {
    Widget chip(String text, bool done) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? AppColors.enterpriseSuccessSurface
            : AppColors.statusWarningSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: done
              ? AppColors.statusSuccessText
              : AppColors.statusWarningText,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            chip(
              s.ketuaSigned
                  ? 'Ketua: sudah menandatangani'
                  : 'Ketua: belum menandatangani',
              s.ketuaSigned,
            ),
            chip(
              s.adminSigned
                  ? 'Admin: sudah menandatangani'
                  : 'Admin: belum menandatangani',
              s.adminSigned,
            ),
            if (s.published) chip('Diterbitkan', true),
          ],
        ),
        if (!s.ketuaSigned) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              key: const Key('ba-tandatangani'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.enterprisePrimary,
              ),
              onPressed: () => context.push(
                '/monitoring/tanda-tangan',
                extra: {'number': number, 'nama': namaPerumahan},
              ),
              icon: const Icon(Icons.draw_outlined, size: 18),
              label: const Text('Tanda tangani BA'),
            ),
          ),
        ],
      ],
    );
  }
}
