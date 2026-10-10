import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/status_hasil_evaluasi.dart';
import '../providers/monitoring_form_provider.dart';
import '../widgets/dynamic_bullet_field.dart';
import '../widgets/evidence_photo_picker.dart';
import '../widgets/status_hasil_evaluasi_selector_widget.dart';

class TambahMonitoringStepperScreen extends ConsumerStatefulWidget {
  const TambahMonitoringStepperScreen({super.key});

  @override
  ConsumerState<TambahMonitoringStepperScreen> createState() =>
      _TambahMonitoringStepperScreenState();
}

class _TambahMonitoringStepperScreenState
    extends ConsumerState<TambahMonitoringStepperScreen> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _namaPerumahanController;
  late TextEditingController _lokasiController;
  late TextEditingController _pelaksanaNamaController;
  late TextEditingController _pelaksanaJabatanController;
  late TextEditingController _ditemuiNamaController;
  late TextEditingController _ditemuiJabatanController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(monitoringFormProvider);
    _namaPerumahanController = TextEditingController(text: state.namaPerumahan);
    _lokasiController = TextEditingController(text: state.lokasiPerumahan);
    _pelaksanaNamaController = TextEditingController(text: state.pelaksanaNama);
    _pelaksanaJabatanController = TextEditingController(
      text: state.pelaksanaJabatan,
    );
    _ditemuiNamaController = TextEditingController(text: state.ditemuiNama);
    _ditemuiJabatanController = TextEditingController(
      text: state.ditemuiJabatan,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _namaPerumahanController.dispose();
    _lokasiController.dispose();
    _pelaksanaNamaController.dispose();
    _pelaksanaJabatanController.dispose();
    _ditemuiNamaController.dispose();
    _ditemuiJabatanController.dispose();
    super.dispose();
  }

  void _syncControllers(MonitoringFormState next) {
    if (_namaPerumahanController.text != next.namaPerumahan) {
      _namaPerumahanController.text = next.namaPerumahan;
    }
    if (_lokasiController.text != next.lokasiPerumahan) {
      _lokasiController.text = next.lokasiPerumahan;
    }
    if (_pelaksanaNamaController.text != next.pelaksanaNama) {
      _pelaksanaNamaController.text = next.pelaksanaNama;
    }
    if (_pelaksanaJabatanController.text != next.pelaksanaJabatan) {
      _pelaksanaJabatanController.text = next.pelaksanaJabatan;
    }
    if (_ditemuiNamaController.text != next.ditemuiNama) {
      _ditemuiNamaController.text = next.ditemuiNama;
    }
    if (_ditemuiJabatanController.text != next.ditemuiJabatan) {
      _ditemuiJabatanController.text = next.ditemuiJabatan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(monitoringFormProvider);
    final notifier = ref.read(monitoringFormProvider.notifier);

    ref.listen<MonitoringFormState>(monitoringFormProvider, (previous, next) {
      _syncControllers(next);
      if (previous != null && previous.currentStep != next.currentStep) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.enterpriseCanvas,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHero(context, formState, notifier),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStepperHeader(formState.currentStep),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _buildCurrentStep(context, formState, notifier),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, formState, notifier),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    MonitoringFormState state,
    MonitoringFormNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 16,
        right: 16,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.enterprisePrimary,
            AppColors.enterprisePrimaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: () {
                  if (state.currentStep > 0) {
                    notifier.setStep(state.currentStep - 1);
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/monitoring/lapangan');
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: AppRadii.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'DISPERWASKIM KOTA TASIKMALAYA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontFamily: AppTextStyles.enterpriseFontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Formulir Pengawasan',
            style: AppTextStyles.h2.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Langkah ${state.currentStep + 1} dari 3: ${_stepTitle(state.currentStep)}',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterprisePrimaryBorder,
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
    0 => 'Info Umum',
    1 => 'Info Lanjutan',
    _ => 'Dokumentasi Lapangan',
  };

  Widget _buildStepperHeader(int currentStep) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.card,
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          // Stepper Circles & Labels Row
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 17,
                left: 52,
                right: 52,
                child: Container(height: 2, color: AppColors.enterpriseBorder),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildStepItem(1, '1. Info Umum', currentStep),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildStepItem(2, '2. Info Lanjutan', currentStep),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildStepItem(
                      3,
                      '3. Dokumentasi Lapangan',
                      currentStep,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String label, int currentStep) {
    final isDone = (currentStep + 1) > stepNumber;
    final isActive = (currentStep + 1) == stepNumber;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isDone)
                ? AppColors.actionPrimary
                : Colors.white,
            border: Border.all(
              color: (isActive || isDone)
                  ? AppColors.actionPrimary
                  : AppColors.grey400,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.grey600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? AppColors.enterprisePrimary
                  : AppColors.enterpriseTextMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    MonitoringFormState formState,
    MonitoringFormNotifier notifier,
  ) {
    switch (formState.currentStep) {
      case 0:
        return _buildStep1(context, formState, notifier);
      case 1:
        return _buildStep2(context, formState, notifier);
      case 2:
        return _buildStep3(context, formState, notifier);
      default:
        return _buildStep1(context, formState, notifier);
    }
  }

  // STEP 1: Informasi Umum (Mockup 1)
  Widget _buildStep1(
    BuildContext context,
    MonitoringFormState state,
    MonitoringFormNotifier notifier,
  ) {
    final dateStr = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(state.tanggalMonitoring);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetaRow(state),
        const SizedBox(height: 16),
        _buildFieldCard(
          label: 'Hari/Tanggal Monitoring',
          badge: 'Wajib',
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.tanggalMonitoring,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) notifier.updateTanggal(picked);
            },
            borderRadius: AppRadii.small,
            child: _buildInputSurface(
              child: Row(
                children: [
                  Expanded(child: Text(dateStr, style: _inputTextStyle)),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.enterpriseTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldCard(
          label: 'Nama Perumahan',
          badge: 'Wajib',
          child: _buildTextFieldBody(
            _namaPerumahanController,
            notifier.updateNamaPerumahan,
            'Masukkan nama perumahan',
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldCard(
          label: 'Lokasi Perumahan',
          badge: 'Opsional',
          child: _buildTextFieldBody(
            _lokasiController,
            notifier.updateLokasi,
            'Masukkan lokasi perumahan',
            prefixIcon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(height: 16),
        _buildPurposeCard(state.maksudTujuan),
        const SizedBox(height: 16),
        _buildBulletCard(
          label: 'Temuan di Lapangan',
          badge: 'Opsional',
          icon: Icons.warning_amber_outlined,
          color: AppColors.enterpriseWarning,
          items: state.temuanLapangan,
          onChanged: notifier.updateTemuan,
          placeholder: 'Tuliskan temuan baru...',
        ),
        const SizedBox(height: 16),
        _buildBulletCard(
          label: 'Kesimpulan',
          badge: 'Opsional',
          icon: Icons.fact_check_outlined,
          color: AppColors.statusInfo,
          items: state.kesimpulan,
          onChanged: notifier.updateKesimpulan,
          placeholder: 'Tuliskan kesimpulan...',
        ),
      ],
    );
  }

  TextStyle get _inputTextStyle => AppTextStyles.bodyMedium.copyWith(
    fontFamily: AppTextStyles.enterpriseFontFamily,
    color: AppColors.enterpriseTextMain,
  );

  Widget _buildMetaRow(MonitoringFormState state) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: AppColors.enterpriseSuccess,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Perubahan tersimpan sementara di formulir ini',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        ),
        if (state.pengajuanId != null)
          Flexible(
            child: Text(
              'ID: ${state.pengajuanId}',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelSmall.copyWith(
                fontFamily: AppTextStyles.enterpriseFontFamily,
                color: AppColors.enterpriseTextMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldCard({
    required String label,
    required String badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildBadge(badge),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    final required = text == 'Wajib';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: required
            ? AppColors.enterprisePrimarySurfaceSoft
            : AppColors.enterpriseCanvas,
        borderRadius: AppRadii.small,
        border: required
            ? Border.all(color: AppColors.enterprisePrimaryBorder)
            : null,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontFamily: AppTextStyles.enterpriseFontFamily,
          color: required
              ? AppColors.enterprisePrimary
              : AppColors.enterpriseTextMuted,
        ),
      ),
    );
  }

  Widget _buildInputSurface({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.small,
      ),
      child: child,
    );
  }

  Widget _buildTextFieldBody(
    TextEditingController controller,
    ValueChanged<String> onChanged,
    String hint, {
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: _inputTextStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _inputTextStyle.copyWith(
          color: AppColors.enterpriseTextMuted,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.enterpriseTextMuted),
        filled: true,
        fillColor: AppColors.enterpriseSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.small,
          borderSide: const BorderSide(color: AppColors.enterpriseBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.small,
          borderSide: const BorderSide(color: AppColors.enterpriseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.small,
          borderSide: const BorderSide(
            color: AppColors.enterprisePrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeCard(String narrative) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.enterpriseCanvas,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.enterpriseTextMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Maksud dan Tujuan',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildBadge('Terkunci narasi Dinas'),
            ],
          ),
          const SizedBox(height: 10),
          _buildInputSurface(
            child: Text(
              narrative,
              style: _inputTextStyle.copyWith(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '* Bagian ini otomatis dan tidak perlu diisi',
            style: AppTextStyles.labelSmall.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletCard({
    required String label,
    required String badge,
    required IconData icon,
    required Color color,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
    required String placeholder,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.enterpriseSurface,
        border: Border.all(color: AppColors.enterpriseBorder),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontFamily: AppTextStyles.enterpriseFontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildBadge(badge),
            ],
          ),
          const SizedBox(height: 10),
          DynamicBulletField(
            label: '',
            items: items,
            onItemsChanged: onChanged,
            placeholderText: placeholder,
          ),
        ],
      ),
    );
  }

  // STEP 2: Informasi Lanjutan
  Widget _buildStep2(
    BuildContext context,
    MonitoringFormState state,
    MonitoringFormNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LANGKAH 02',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.actionPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Informasi lanjutan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.cocoaBeanRoast,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Isi temuan, kesimpulan, dan status evaluasi lapangan.',
          style: TextStyle(fontSize: 13, color: AppColors.grey600),
        ),
        const SizedBox(height: 20),

        // Maksud & Tujuan
        Text(
          'Maksud dan Tujuan',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: AppRadii.control,
            border: Border.all(color: AppColors.grey300),
          ),
          child: Text(
            state.maksudTujuan,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.grey800,
            ),
          ),
        ),
        const SizedBox(height: 20),

        DynamicBulletField(
          label: 'Temuan di Lapangan',
          items: state.temuanLapangan,
          onItemsChanged: notifier.updateTemuan,
          placeholderText: 'Masukkan temuan di lapangan',
        ),
        const SizedBox(height: 20),

        DynamicBulletField(
          label: 'Kesimpulan',
          items: state.kesimpulan,
          onItemsChanged: notifier.updateKesimpulan,
          placeholderText: 'Masukkan kesimpulan',
        ),
        const SizedBox(height: 20),

        DynamicBulletField(
          label: 'Kesepakatan',
          items: state.kesepakatan,
          onItemsChanged: notifier.updateKesepakatan,
          placeholderText: 'Masukkan kesepakatan',
        ),
        const SizedBox(height: 20),

        DynamicBulletField(
          label: 'Rencana Tindak Lanjut',
          items: state.rencanaTindakLanjut,
          onItemsChanged: notifier.updateRTL,
          placeholderText: 'Masukkan rencana tindak lanjut',
        ),
        const SizedBox(height: 20),

        StatusHasilEvaluasiSelectorWidget(
          selectedStatus: state.statusHasilEvaluasi,
          onChanged: notifier.updateStatusHasilEvaluasi,
        ),
      ],
    );
  }

  // STEP 3: Evidence & Tanda Tangan (Mockup 5)
  Widget _buildStep3(
    BuildContext context,
    MonitoringFormState state,
    MonitoringFormNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LANGKAH 03',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.actionPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Evidence & tanda tangan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.cocoaBeanRoast,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload foto evidence dan isi data penandatangan.',
          style: TextStyle(fontSize: 13, color: AppColors.grey600),
        ),
        const SizedBox(height: 24),

        // Photo Picker Widget
        EvidencePhotoPicker(
          photoPaths: state.photoPaths,
          onPhotosChanged: notifier.updatePhotos,
        ),
        const SizedBox(height: 28),

        // Wet Signature Section Header
        Row(
          children: [
            const Text(
              'Tanda Tangan Basah ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.cocoaBeanRoast,
              ),
            ),
            Text(
              '(Wet Signature)',
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2 Side-by-side Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Petugas Monitoring
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.control,
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Petugas Monitoring',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cocoaBeanRoast,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUnderlineField(
                      'Nama lengkap',
                      _pelaksanaNamaController,
                      notifier.updatePelaksanaNama,
                    ),
                    const SizedBox(height: 8),
                    _buildUnderlineField(
                      'Jabatan',
                      _pelaksanaJabatanController,
                      notifier.updatePelaksanaJabatan,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Card 2: Pihak Perumahan / Developer
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.control,
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pihak Perumahan / Developer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cocoaBeanRoast,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUnderlineField(
                      'Nama lengkap',
                      _ditemuiNamaController,
                      notifier.updateDitemuiNama,
                    ),
                    const SizedBox(height: 8),
                    _buildUnderlineField(
                      'Jabatan',
                      _ditemuiJabatanController,
                      notifier.updateDitemuiJabatan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const Text(
          '*Dokumen hasil generate akan diprint untuk Tanda Tangan Basah di lokasi.',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildUnderlineField(
    String hintText,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.actionPrimary),
        ),
      ),
    );
  }

  // Pinned Bottom Button Bar
  Widget _buildBottomBar(
    BuildContext context,
    MonitoringFormState formState,
    MonitoringFormNotifier notifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final useStackedActions =
            constraints.maxWidth < 380 || textScale > 1.35;

        final cancelButton = TextButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/monitoring/lapangan');
            }
          },
          child: Text(
            'Batal',
            style: AppTextStyles.labelMedium.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
              color: AppColors.enterpriseTextMuted,
            ),
          ),
        );

        final saveDraftButton = OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.small),
          ),
          child: Text(
            'Simpan Draft',
            style: AppTextStyles.labelMedium.copyWith(
              fontFamily: AppTextStyles.enterpriseFontFamily,
            ),
          ),
        );

        final nextButton = SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.enterprisePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.small),
            ),
            onPressed: () {
              if (formState.currentStep == 0) {
                if (_namaPerumahanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama Perumahan wajib diisi.'),
                    ),
                  );
                  return;
                }
                notifier.setStep(1);
              } else if (formState.currentStep == 1) {
                final rtl = formState.rencanaTindakLanjut
                    .where((e) => e.trim().isNotEmpty)
                    .toList();
                if (formState.statusHasilEvaluasi.wajibRencanaTindakLanjut &&
                    rtl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Untuk status "${formState.statusHasilEvaluasi.label}", wajib mengisikan minimal 1 poin Rencana Tindak Lanjut.',
                      ),
                      backgroundColor: AppColors.actionPrimary,
                    ),
                  );
                  return;
                }
                notifier.setStep(2);
              } else {
                // Last step -> Navigate to Preview Screen
                final previewModel = notifier.buildPreviewModel();
                if (previewModel != null) {
                  context.push(
                    '/monitoring/preview',
                    extra: {'model': previewModel, 'isDraft': true},
                  );
                } else {
                  final err = ref.read(monitoringFormProvider).errorMessage;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.actionPrimary,
                      ),
                    );
                  }
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    formState.currentStep == 0
                        ? 'Lanjut ke Langkah 2'
                        : formState.currentStep == 1
                        ? 'Lanjut ke Langkah 3'
                        : 'Preview & Kirim',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontFamily: AppTextStyles.enterpriseFontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: AppColors.enterpriseSurface,
            border: const Border(
              top: BorderSide(color: AppColors.enterpriseBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: useStackedActions
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: cancelButton),
                          Expanded(child: saveDraftButton),
                        ],
                      ),
                      const SizedBox(height: 8),
                      nextButton,
                    ],
                  )
                : Row(
                    children: [
                      cancelButton,
                      saveDraftButton,
                      const SizedBox(width: 8),
                      Expanded(child: nextButton),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
