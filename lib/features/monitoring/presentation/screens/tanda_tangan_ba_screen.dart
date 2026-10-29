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
import '../widgets/signature_pad.dart';

/// Ketua Pengawas menyetujui BA yang sudah dikirim: gambar langsung atau unggah gambar,
/// pratinjau, lalu konfirmasi sandi. Ini persetujuan elektronik berbasis akun, bukan TTE tersertifikasi.
class TandaTanganBaScreen extends ConsumerStatefulWidget {
  const TandaTanganBaScreen({
    super.key,
    required this.number,
    this.namaPerumahan,
  });

  final String number;
  final String? namaPerumahan;

  @override
  ConsumerState<TandaTanganBaScreen> createState() =>
      _TandaTanganBaScreenState();
}

class _TandaTanganBaScreenState extends ConsumerState<TandaTanganBaScreen> {
  static const _maxBytes = 4 * 1024 * 1024;

  final _pad = SignaturePadController();
  final _password = TextEditingController();
  // Kunci tetap selama layar ini terbuka: percobaan ulang setelah jaringan putus tidak menyimpan ganda.
  final String _key = newDraftKey();

  String _method = 'draw';
  Uint8List? _drawn;
  Uint8List? _uploaded;
  String _uploadName = 'ttd.png';
  String _uploadType = 'image/png';
  bool _obscure = true;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _pad.dispose();
    _password.dispose();
    super.dispose();
  }

  SignatureImage? get _image {
    final bytes = _method == 'draw' ? _drawn : _uploaded;
    if (bytes == null) return null;
    return SignatureImage(
      bytes: bytes,
      method: _method,
      filename: _method == 'draw' ? 'ttd.png' : _uploadName,
      contentType: _method == 'draw' ? 'image/png' : _uploadType,
    );
  }

  bool get _canSubmit =>
      !_submitting && _image != null && _password.text.isNotEmpty;

  Future<void> _refreshDrawn() async {
    final png = await _pad.toPng();
    if (mounted) setState(() => _drawn = png);
  }

  void _clearDrawn() {
    _pad.clear();
    setState(() => _drawn = null);
  }

  Future<void> _pickUpload() async {
    final result = await FilePickerUtil.pickSingleFileResult(
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (result.isCancelled) return;
    final file = result.value;
    if (!result.isSelected || file == null) {
      return _setUploadError('Gambar tidak bisa dibuka. Pilih berkas lain.');
    }
    try {
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty)
        return _setUploadError('Gambar tidak bisa dibaca. Pilih berkas lain.');
      if (bytes.length > _maxBytes)
        return _setUploadError('Ukuran gambar maksimal 4 MB.');
      final ext = (file.extension ?? '').toLowerCase();
      if (ext != 'png' && ext != 'jpg' && ext != 'jpeg')
        return _setUploadError('Gunakan gambar PNG atau JPEG.');
      final decoded = await _decode(bytes);
      if (decoded == null)
        return _setUploadError('Berkas bukan gambar yang valid.');
      if (decoded.$1 < 40 || decoded.$2 < 20)
        return _setUploadError('Gambar terlalu kecil (minimal 40x20 piksel).');
      setState(() {
        _uploaded = bytes;
        _uploadName = ext == 'png' ? 'ttd.png' : 'ttd.jpg';
        _uploadType = ext == 'png' ? 'image/png' : 'image/jpeg';
        _error = null;
      });
    } catch (_) {
      _setUploadError('Gambar tidak bisa dibaca. Pilih berkas lain.');
    }
  }

  Future<(int, int)?> _decode(Uint8List bytes) async {
    try {
      final image = await decodeImageFromList(bytes);
      final size = (image.width, image.height);
      image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  void _setUploadError(String message) => setState(() => _error = message);

  void _selectMethod(String method) => setState(() {
    _method = method;
    _error = null;
  });

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
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.enterpriseBorder),
              ),
              child: Image.memory(
                Uint8List.fromList(image.bytes),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BA ${widget.number} akan ditandai Anda setujui sebagai Ketua Pengawas. '
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
            image: image,
            password: _password.text,
            idempotencyKey: _key,
          );
      ref.invalidate(baSignatureStatusProvider(widget.number));
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isNetwork
            ? 'Koneksi bermasalah. Tanda tangan Anda masih tersimpan di layar ini; coba kirim lagi.'
            : e.fields['password']?.first ?? e.message;
        if (e.fields.containsKey('password')) _password.clear();
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Tanda tangan belum terkirim. Coba lagi.');
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
              'Anda sudah menyetujui BA ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'BA ${widget.number}${when.isEmpty ? '' : ' · $when WIB'}\n'
              '${s.adminSigned ? 'Admin juga sudah menyetujui.' : 'Menunggu persetujuan Admin sebelum diterbitkan.'}',
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
    final image = _image;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'BA ${widget.number}${widget.namaPerumahan == null ? '' : '\n${widget.namaPerumahan}'}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Anda menandatangani sebagai Ketua Pengawas Lapangan. Periksa kembali isi BA; setelah disetujui, isinya terkunci.',
          style: TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'draw',
              label: Text('Gambar langsung'),
              icon: Icon(Icons.draw_outlined),
            ),
            ButtonSegment(
              value: 'upload',
              label: Text('Unggah gambar'),
              icon: Icon(Icons.upload_file_outlined),
            ),
          ],
          selected: {_method},
          onSelectionChanged: _submitting
              ? null
              : (v) => _selectMethod(v.first),
        ),
        const SizedBox(height: 12),
        if (_method == 'draw') ...[
          SignaturePad(controller: _pad, onChanged: _refreshDrawn),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _submitting ? null : _clearDrawn,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Hapus dan ulangi'),
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickUpload,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _uploaded == null ? 'Pilih gambar tanda tangan' : 'Ganti gambar',
            ),
          ),
          if (_uploaded != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _uploaded = null),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus gambar'),
              ),
            ),
          const Text(
            'Gambar visualisasi TTE (unduh di suresman.tasikmalayakota.go.id/visualcustom dengan NIP Anda) atau gambar tanda tangan. PNG atau JPEG, maksimal 4 MB; ukurannya menyesuaikan di PDF.',
            style: TextStyle(
              color: AppColors.enterpriseTextMuted,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Pratinjau',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          key: const Key('ttd-pratinjau'),
          height: 90,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.enterpriseBorder),
          ),
          child: image == null
              ? const Center(
                  child: Text(
                    'Belum ada tanda tangan',
                    style: TextStyle(
                      color: AppColors.enterpriseTextMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : Image.memory(
                  Uint8List.fromList(image.bytes),
                  fit: BoxFit.contain,
                ),
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
        const SizedBox(height: 10),
        const Text(
          'Ini persetujuan elektronik berbasis akun Anda, bukan tanda tangan elektronik tersertifikasi.',
          style: TextStyle(
            color: AppColors.enterpriseTextMuted,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
