import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/auth/role_session.dart';
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
    if (!ref.watch(apiEnabledProvider) || number.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    // BA yang dikembalikan Admin tidak bisa ditandatangani; petugas membuat BA pengganti.
    if (ref.watch(serverReportProvider(number))?.isRevisi ?? false) {
      return Container(
        key: const Key('ba-dikembalikan'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Text(
          'BA ini dikembalikan Admin untuk diperbaiki. Buat BA pengganti dari tugas survei di Beranda; '
          'BA ini tidak perlu ditandatangani.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
      );
    }
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
                s == null ? const SizedBox.shrink() : _content(context, s, ref),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, BaSignatureStatus s, WidgetRef ref) {
    final nipKosong = (ref.watch(roleSessionProvider).nip ?? '').trim().isEmpty;
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
        if (s.published) ...[
          const SizedBox(height: 12),
          _UnduhPdfResmi(number: number),
        ],
        if (!s.ketuaSigned && nipKosong) ...[
          const SizedBox(height: 10),
          const Text(
            'NIP akun Anda belum diisi. Minta Admin melengkapinya (menu Akun) sebelum menandatangani.',
            key: Key('ba-nip-kosong'),
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.statusWarningText,
            ),
          ),
        ],
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

/// Mengunduh PDF final BA yang diterbitkan Admin (dibuat server) lalu membukanya untuk dilihat,
/// dicetak, atau dibagikan. Berbeda dari PDF pratinjau buatan HP yang bukan dokumen resmi.
class _UnduhPdfResmi extends ConsumerStatefulWidget {
  const _UnduhPdfResmi({required this.number});

  final String number;

  @override
  ConsumerState<_UnduhPdfResmi> createState() => _UnduhPdfResmiState();
}

class _UnduhPdfResmiState extends ConsumerState<_UnduhPdfResmi> {
  bool _sibuk = false;

  Future<void> _unduh() async {
    if (_sibuk) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sibuk = true);
    try {
      final bytes = await ref
          .read(officerRemoteProvider)
          .downloadPdf(widget.number);
      final nama = 'BA-${widget.number.replaceAll('/', '-')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: nama);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF belum bisa dibuka. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton.icon(
      key: const Key('ba-unduh-pdf'),
      onPressed: _sibuk ? null : _unduh,
      icon: _sibuk
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: const Text('Unduh PDF Resmi'),
    ),
  );
}
