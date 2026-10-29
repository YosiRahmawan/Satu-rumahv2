import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_picker_util.dart';
import '../../../pengajuan/data/repositories/pengajuan_api_repository.dart'
    show newDraftKey;
import '../../data/models/ba_signature.dart';
import '../../data/repositories/officer_api_repository.dart';

/// Gambar yang dipilih pengguna: isi berkas dan ekstensinya.
typedef PickedSignature = ({Uint8List bytes, String ext});

/// Pemilih gambar; bisa diganti pada tes.
typedef SignaturePicker = Future<PickedSignature?> Function();

Future<PickedSignature?> _pilihDariPerangkat() async {
  final result = await FilePickerUtil.pickSingleFileResult(
    allowedExtensions: const ['png', 'jpg', 'jpeg'],
  );
  final file = result.value;
  if (!result.isSelected || file == null) return null;
  final bytes =
      file.bytes ??
      (file.path == null ? null : await File(file.path!).readAsBytes());
  if (bytes == null) return null;
  return (bytes: bytes, ext: (file.extension ?? '').toLowerCase());
}

/// Ketua Pengawas menandatangani BA yang sudah dikirim dengan mengunggah visualisasi TTE
/// (diunduh dari Suresman memakai NIP), lalu mengonfirmasi dengan sandi.
class TandaTanganBaScreen extends ConsumerStatefulWidget {
  const TandaTanganBaScreen({
    super.key,
    required this.number,
    this.namaPerumahan,
    this.picker = _pilihDariPerangkat,
  });

  final String number;
  final String? namaPerumahan;
  final SignaturePicker picker;

  @override
  ConsumerState<TandaTanganBaScreen> createState() =>
      _TandaTanganBaScreenState();
}

class _TandaTanganBaScreenState extends ConsumerState<TandaTanganBaScreen> {
  static const _maxBytes = 4 * 1024 * 1024;

  final _password = TextEditingController();
  // Kunci tetap selama layar ini terbuka: percobaan ulang setelah jaringan putus tidak menyimpan ganda.
  final String _key = newDraftKey();

  Uint8List? _image;
  String _ext = 'png';
  bool _obscure = true;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting && _image != null && _password.text.isNotEmpty;

  Future<void> _pick() async {
    final picked = await widget.picker();
    if (picked == null) return;
    final problem = await _validate(picked);
    if (!mounted) return;
    setState(() {
      if (problem != null) {
        _error = problem;
      } else {
        _image = picked.bytes;
        _ext = picked.ext;
        _error = null;
      }
    });
  }

  /// Pesan masalah, atau null bila gambar layak dikirim.
  Future<String?> _validate(PickedSignature p) async {
    if (p.bytes.isEmpty) return 'Gambar tidak bisa dibaca. Pilih berkas lain.';
    if (p.bytes.length > _maxBytes) return 'Ukuran gambar maksimal 4 MB.';
    if (p.ext != 'png' && p.ext != 'jpg' && p.ext != 'jpeg') {
      return 'Gunakan gambar PNG atau JPEG.';
    }
    try {
      final decoded = await decodeImageFromList(p.bytes);
      final tooSmall = decoded.width < 40 || decoded.height < 20;
      decoded.dispose();
      if (tooSmall) return 'Gambar terlalu kecil (minimal 40x20 piksel).';
    } catch (_) {
      return 'Berkas bukan gambar yang valid.';
    }
    return null;
  }

  Future<void> _confirm() async {
    final image = _image;
    if (image == null || _submitting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui dan tandatangani BA?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.enterpriseBorder),
              ),
              child: Image.memory(image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(
              'BA ${widget.number} akan Anda setujui sebagai Ketua Pengawas. '
              'Isi BA tidak dapat diubah setelah ini.',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, tandatangani'),
          ),
        ],
      ),
    );
    if (ok == true) await _submit();
  }

  Future<void> _submit() async {
    final image = _image;
    if (image == null || _submitting) return; // cegah kirim ganda
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(officerRemoteProvider)
          .signReport(
            reportNumber: widget.number,
            image: SignatureImage(
              bytes: image,
              filename: _ext == 'png' ? 'ttd.png' : 'ttd.jpg',
              contentType: _ext == 'png' ? 'image/png' : 'image/jpeg',
            ),
            password: _password.text,
            idempotencyKey: _key,
          );
      ref.invalidate(baSignatureStatusProvider(widget.number));
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isNetwork
            ? 'Koneksi bermasalah. Gambar Anda masih tersimpan di layar ini; coba kirim lagi.'
            : (e.fields.isNotEmpty ? e.fields.values.first.first : e.message);
        if (e.fields.containsKey('password')) _password.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Tanda tangan belum terkirim. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(baSignatureStatusProvider(widget.number));

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.enterpriseCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.enterpriseTextMain,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/monitoring/lapangan'),
        ),
        title: Text(
          'Tanda Tangan BA',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: AppTextStyles.enterpriseFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.enterpriseTextMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: status.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _loadError(e),
          data: (s) {
            if (s == null) {
              return _info(
                Icons.cloud_off_outlined,
                'Tanda tangan BA memerlukan koneksi ke server.',
              );
            }
            if (_done || s.ketuaSigned) return _signed(s);
            return _form();
          },
        ),
      ),
    );
  }

  Widget _loadError(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            e is ApiException
                ? e.message
                : 'Status tanda tangan belum bisa dimuat.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                ref.invalidate(baSignatureStatusProvider(widget.number)),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );

  Widget _info(IconData icon, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.enterpriseTextMuted),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _signed(BaSignatureStatus s) {
    final when = s.ketuaAt == null
        ? ''
        : DateFormat('d MMM y, HH.mm', 'id_ID').format(s.ketuaAt!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.enterpriseSuccessSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 34,
                color: AppColors.enterpriseSuccess,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda sudah menandatangani BA ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'BA ${widget.number}${when.isEmpty ? '' : ' · $when WIB'}\n'
              '${s.adminSigned ? 'Admin juga sudah menandatangani.' : 'Menunggu tanda tangan Admin sebelum diterbitkan.'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.enterpriseTextMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/monitoring/lapangan'),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'BA ${widget.number}${widget.namaPerumahan == null ? '' : '\n${widget.namaPerumahan}'}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Anda menandatangani sebagai Ketua Pengawas Lapangan. Periksa kembali isi BA; setelah ditandatangani, isinya terkunci.',
          style: TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusSurveySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Unduh visualisasi TTE Anda di suresman.tasikmalayakota.go.id/visualcustom '
            'dengan memasukkan NIP, lalu pilih gambarnya di sini.',
            key: Key('ttd-petunjuk'),
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('ttd-pilih'),
          onPressed: _submitting ? null : _pick,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            _image == null ? 'Pilih gambar visualisasi TTE' : 'Ganti gambar',
          ),
        ),
        if (_image != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => setState(() => _image = null),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus gambar'),
            ),
          ),
        const Text(
          'PNG atau JPEG, maksimal 4 MB. Ukurannya menyesuaikan di PDF.',
          style: TextStyle(color: AppColors.enterpriseTextMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pratinjau',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          key: const Key('ttd-pratinjau'),
          constraints: const BoxConstraints(minHeight: 90, maxHeight: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.enterpriseBorder),
          ),
          child: _image == null
              ? const SizedBox(
                  height: 78,
                  child: Center(
                    child: Text(
                      'Belum ada gambar',
                      style: TextStyle(
                        color: AppColors.enterpriseTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Image.memory(_image!, fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('ttd-sandi'),
          controller: _password,
          obscureText: _obscure,
          enabled: !_submitting,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Konfirmasi dengan sandi Anda',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Tampilkan sandi' : 'Sembunyikan sandi',
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.statusUrgentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.statusUrgentText,
                fontSize: 13,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const Key('ttd-kirim'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.enterprisePrimary,
            ),
            onPressed: _canSubmit ? _confirm : null,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _error == null
                        ? 'Setujui dan Tandatangani'
                        : 'Coba kirim lagi',
                  ),
          ),
        ),
      ],
    );
  }
}
