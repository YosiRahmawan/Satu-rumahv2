import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/pengajuan_form_controller.dart';

/// Melanjutkan draf: memulihkan isian (bila form di memori masih kosong) lalu
/// membuka langkah pertama yang belum lengkap. False bila draf tak bisa dibuka.
Future<bool> lanjutkanDraf(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(pengajuanFormProvider.notifier);
  if (!ref.read(pengajuanFormProvider).hasContent &&
      !await notifier.restoreDraft()) {
    return false;
  }
  if (!context.mounted) return false;
  context.push(ref.read(pengajuanFormProvider).resumeRoute);
  return true;
}

/// Memulai pengajuan baru. Bila ada draf tersimpan, tanya dulu apakah mau
/// dilanjutkan atau diganti pengajuan baru, supaya draf tidak hilang diam-diam.
Future<void> mulaiPengajuanBaru(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(pengajuanFormProvider.notifier);
  if (await notifier.hasDraft()) {
    if (!context.mounted) return;
    final lanjutkan = await showDialog<bool>(
      context: context,
      builder: (_) => const _DraftDialog(),
    );
    if (lanjutkan == null || !context.mounted) return;
    if (lanjutkan && await lanjutkanDraf(context, ref)) return;
  }
  notifier.reset();
  if (context.mounted) context.push('/pengajuan/step1');
}

/// Menyimpan draf sekarang. Berhasil disampaikan lewat animasi tombol (tanpa
/// snackbar, supaya tidak mengganggu); kosong atau gagal diberi tahu lewat
/// snackbar karena pengguna perlu tahu.
Future<DraftSaveResult> simpanDraf(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(pengajuanFormProvider.notifier).saveDraft();
  if (result != DraftSaveResult.saved && context.mounted) {
    final message = result == DraftSaveResult.empty
        ? 'Belum ada isian yang perlu disimpan.'
        : 'Draf belum bisa disimpan. Coba lagi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  return result;
}

/// Keterangan status simpan: waktu draf terakhir tersimpan, bukan jam karangan.
class DraftSavedLabel extends ConsumerWidget {
  const DraftSavedLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSavedAt = ref.read(pengajuanFormProvider.notifier).lastSavedAt;
    return ValueListenableBuilder<DateTime?>(
      valueListenable: lastSavedAt,
      builder: (context, savedAt, _) {
        final text = savedAt == null
            ? 'Disimpan otomatis di perangkat ini'
            : 'Tersimpan otomatis pukul ${DateFormat('HH:mm').format(savedAt)}';
        return AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, if (current != null) current],
          ),
          child: Text(text, key: ValueKey(text), style: style),
        );
      },
    );
  }
}

/// Baris status simpan di bawah form: titik hijau dan waktu simpan di kiri,
/// tombol Simpan Draft di kanan. Dipakai sama persis di Langkah 2 sampai 4.
///
/// Tombol memberi umpan balik halus: mengecil sedikit saat ditekan, lalu
/// berubah hijau "Tersimpan" dan tetap hijau selama isian belum berubah.
/// Begitu form diubah lagi, tombol kembali ke "Simpan Draft".
class DraftStatusRow extends ConsumerStatefulWidget {
  const DraftStatusRow({super.key});

  @override
  ConsumerState<DraftStatusRow> createState() => _DraftStatusRowState();
}

class _DraftStatusRowState extends ConsumerState<DraftStatusRow> {
  /// Isi form saat tombol terakhir berhasil menyimpan. State form tidak
  /// dimutasi (selalu objek baru), jadi `identical` cukup untuk tahu ada
  /// perubahan sesudahnya.
  PengajuanFormState? _savedState;
  bool _pressed = false;

  Future<void> _save() async {
    final result = await simpanDraf(context, ref);
    if (result == DraftSaveResult.saved && mounted) {
      setState(() => _savedState = ref.read(pengajuanFormProvider));
    }
  }

  Widget _buildButton(bool reduceMotion, bool isSaved) {
    final fade = reduceMotion ? Duration.zero : const Duration(milliseconds: 180);
    final color = isSaved ? AppColors.statusSuccessText : AppColors.primaryRed;
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.95 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: _save,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: AnimatedSize(
            duration: fade,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: fade,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    isSaved
                        ? PhosphorIconsRegular.checkCircle
                        : PhosphorIconsRegular.bookmarkSimple,
                    key: ValueKey(isSaved),
                    size: 15,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedDefaultTextStyle(
                  duration: fade,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  child: Text(isSaved ? 'Tersimpan' : 'Simpan Draft'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTextScaled = MediaQuery.textScalerOf(context).scale(14) > 20;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isSaved = identical(ref.watch(pengajuanFormProvider), _savedState);

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.statusSuccessText,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Flexible(
          child: DraftSavedLabel(
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
    final button = _buildButton(reduceMotion, isSaved);

    if (isTextScaled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: button),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: status),
        const SizedBox(width: 8),
        button,
      ],
    );
  }
}

/// Pasangan tombol dialog draf: pilihan aman dan utama berupa tombol merah
/// terisi, pilihan yang menghapus berupa teks abu tipis agar tidak terpencet
/// tidak sengaja.
class _TombolUtama extends StatelessWidget {
  const _TombolUtama({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _TombolTenang extends StatelessWidget {
  const _TombolTenang({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _DraftDialog extends StatelessWidget {
  const _DraftDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lanjutkan draf pengajuan?'),
      content: const Text(
        'Ada draf pengajuan yang belum dikirim. Lanjutkan dari bagian '
        'terakhir, atau mulai pengajuan baru. Mulai baru akan menghapus draf ini.',
      ),
      actions: [
        _TombolTenang(
          label: 'Mulai baru',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        _TombolUtama(
          label: 'Lanjutkan',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Kartu "Draf pengajuan belum dikirim" untuk Beranda dan daftar Pengajuan.
/// Tidak tampil bila tidak ada draf tersimpan.
class PengajuanDraftCard extends ConsumerWidget {
  const PengajuanDraftCard({super.key});

  static String _savedLabel(DateTime savedAt) {
    final now = DateTime.now();
    final sameDay =
        savedAt.year == now.year &&
        savedAt.month == now.month &&
        savedAt.day == now.day;
    return sameDay
        ? 'Disimpan pukul ${DateFormat('HH:mm').format(savedAt)}'
        : 'Disimpan ${DateFormat('dd/MM/yyyy HH:mm').format(savedAt)}';
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus draf pengajuan?'),
        content: const Text(
          'Isian dan berkas yang sudah dipilih pada draf ini akan dihapus.',
        ),
        actions: [
          _TombolTenang(
            label: 'Hapus',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          _TombolUtama(
            label: 'Batal',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (yakin == true) ref.read(pengajuanFormProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(pengajuanFormProvider.notifier);
    return ValueListenableBuilder<PengajuanDraftInfo?>(
      valueListenable: notifier.draftInfo,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();
        final nama = info.nama.isEmpty ? 'Belum diberi nama' : info.nama;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.bookmarkSimple,
                        size: 20,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Draf pengajuan belum dikirim',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$nama · ${_savedLabel(info.savedAt)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppColors.primarySurfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => lanjutkanDraf(context, ref),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 11),
                            child: Center(
                              child: Text(
                                'Lanjutkan',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _hapus(context, ref),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
