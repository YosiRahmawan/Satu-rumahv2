import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../providers/pengajuan_form_controller.dart';
import '../widgets/pengajuan_draft_ui.dart';
import '../widgets/smart_validation_bottom_sheet.dart';

class PengajuanStep1Screen extends ConsumerStatefulWidget {
  const PengajuanStep1Screen({super.key});

  @override
  ConsumerState<PengajuanStep1Screen> createState() =>
      _PengajuanStep1ScreenState();
}

class _PengajuanStep1ScreenState extends ConsumerState<PengajuanStep1Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _dropdownKey = GlobalKey();
  final _layerLink = LayerLink();

  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  late final AnimationController _dropdownController;
  late final Animation<double> _openCurve;
  late final Animation<double> _chevronAnimation;
  late final ScrollController _dropdownScrollController;

  late TextEditingController _namaPerumahanController;
  late TextEditingController _alamatProyekController;
  late TextEditingController _npwpController;
  late TextEditingController _luasController;
  late TextEditingController _unitController;

  late String _selectedTipePengajuan;
  late String _selectedTipePerumahan;

  static const List<Map<String, String>> _tipePengajuanOptions = [
    {
      'title': 'Pengajuan Site Plan Baru',
      'subtitle': 'Belum memiliki pengesahan teknis sebelumnya',
    },
    {
      'title': 'Perubahan Siteplan',
      'subtitle': 'Revisi tata letak/kaveling eksisting',
    },
    {
      'title': 'Pengembangan Siteplan',
      'subtitle': 'Penambahan luasan tahap berikutnya',
    },
  ];

  static const List<String> _dayaListrikOptions = [
    '450 VA',
    '900 VA',
    '1.300 VA',
    '2.200 VA',
    '3.500 VA',
    '4.400 VA',
    '5.500 VA',
    '6.600 VA ke atas',
  ];

  bool _npwpVerifying = false;
  String? _npwpError;

  static const List<String> _tipePerumahanOptions = [
    'Subsidi',
    'Komersil',
    'Campuran',
  ];

  @override
  void initState() {
    super.initState();
    _dropdownScrollController = ScrollController();
    _dropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _openCurve = CurvedAnimation(
      parent: _dropdownController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _chevronAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_openCurve);

    final state = ref.read(pengajuanFormProvider);
    _namaPerumahanController = TextEditingController(text: state.namaPerumahan)
      ..addListener(_onFieldChanged);
    _alamatProyekController = TextEditingController(text: state.alamatProyek)
      ..addListener(_onFieldChanged);
    _npwpController = TextEditingController(text: state.npwpPerusahaan)
      ..addListener(_onNpwpChanged);
    _luasController = TextEditingController(
      text: state.luasLahan > 0
          ? (state.luasLahan % 1 == 0
                ? state.luasLahan.toInt().toString()
                : state.luasLahan.toString())
          : '',
    )..addListener(_onFieldChanged);
    _unitController = TextEditingController(
      text: state.jumlahUnit > 0 ? state.jumlahUnit.toString() : '',
    )..addListener(_onFieldChanged);
    _selectedTipePengajuan = state.tipePengajuan.isNotEmpty
        ? state.tipePengajuan
        : 'Pengajuan Site Plan Baru';
    _selectedTipePerumahan = state.tipePerumahan.isNotEmpty
        ? state.tipePerumahan
        : 'Komersil';
  }

  @override
  void dispose() {
    _removeOverlay();
    _dropdownScrollController.dispose();
    _dropdownController.dispose();
    _namaPerumahanController.dispose();
    _alamatProyekController.dispose();
    _npwpController.dispose();
    _luasController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onNpwpChanged() {
    ref.read(pengajuanFormProvider.notifier).updateNpwp(_npwpController.text);
    if (_npwpError != null) setState(() => _npwpError = null);
  }

  Future<void> _verifyNpwp() async {
    final text = _npwpController.text;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 15 && digits.length != 16) {
      setState(() => _npwpError = 'NPWP harus 15 atau 16 digit angka');
      return;
    }
    setState(() {
      _npwpVerifying = true;
      _npwpError = null;
    });
    // shortcut: simulasi lokal tanpa API pajak, ganti dengan verifikasi NPWP
    // dari backend saat endpoint tersedia.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_npwpController.text == text) {
      ref.read(pengajuanFormProvider.notifier).setNpwpVerified(true);
    }
    setState(() => _npwpVerifying = false);
  }

  /// Isian teks langsung masuk ke form, jadi ikut tersimpan sebagai draf
  /// tanpa menunggu tombol Lanjut ditekan.
  void _onFieldChanged() => _syncState();

  void _syncState() {
    final notifier = ref.read(pengajuanFormProvider.notifier);
    notifier.updateTipePengajuan(_selectedTipePengajuan);
    notifier.updateNamaPerumahan(_namaPerumahanController.text);
    notifier.updateAlamatProyek(_alamatProyekController.text);
    notifier.updateNpwp(_npwpController.text);
    notifier.updateLuasLahan(double.tryParse(_luasController.text) ?? 0.0);
    notifier.updateJumlahUnit(int.tryParse(_unitController.text) ?? 0);
    notifier.updateTipe(_selectedTipePerumahan);
  }

  bool _isModalShowing = false;

  void _onNext() async {
    _syncState();
    final isValid = _formKey.currentState?.validate() == true;
    final isStateValid = ref.read(pengajuanFormProvider).isStep1Valid;

    final isNpwpVerified = ref.read(pengajuanFormProvider).npwpVerified;

    if (isValid && isStateValid && isNpwpVerified) {
      context.push('/pengajuan/step2');
      return;
    }

    if (_isModalShowing) return;

    final missing = <MissingValidationItem>[];
    if (_namaPerumahanController.text.trim().isEmpty) {
      missing.add(
        const MissingValidationItem(
          key: 'nama',
          title: 'Nama Perumahan *',
          subtitle: 'Wajib diisi sesuai site plan',
          statusText: 'Belum diisi',
          icon: Icons.edit_note,
        ),
      );
    }
    if (_alamatProyekController.text.trim().isEmpty) {
      missing.add(
        const MissingValidationItem(
          key: 'alamat',
          title: 'Alamat Lokasi Proyek *',
          subtitle: 'Wajib diisi lengkap',
          statusText: 'Belum diisi',
          icon: Icons.location_on_outlined,
        ),
      );
    }
    final rawNpwp = _npwpController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (_npwpController.text.trim().isEmpty ||
        (rawNpwp.length != 15 && rawNpwp.length != 16)) {
      missing.add(
        const MissingValidationItem(
          key: 'npwp',
          title: 'NPWP Perusahaan *',
          subtitle: 'Format 15 atau 16 digit angka',
          statusText: 'Belum valid',
          icon: Icons.badge_outlined,
        ),
      );
    } else if (!ref.read(pengajuanFormProvider).npwpVerified) {
      missing.add(
        const MissingValidationItem(
          key: 'npwp',
          title: 'NPWP Perusahaan *',
          subtitle: 'Tekan tombol Verifikasi pada kolom NPWP',
          statusText: 'Belum diverifikasi',
          icon: Icons.badge_outlined,
        ),
      );
    }
    final luas = double.tryParse(_luasController.text) ?? 0.0;
    if (luas <= 0) {
      missing.add(
        const MissingValidationItem(
          key: 'luas',
          title: 'Luas Lahan Proyek (m²) *',
          subtitle: 'Harus berupa angka lebih dari 0',
          statusText: 'Belum diisi',
          icon: Icons.square_foot_outlined,
        ),
      );
    }
    final unit = int.tryParse(_unitController.text) ?? 0;
    if (unit <= 0) {
      missing.add(
        const MissingValidationItem(
          key: 'unit',
          title: 'Jumlah Unit Perumahan *',
          subtitle: 'Harus minimal 1 unit',
          statusText: 'Belum diisi',
          icon: Icons.home_outlined,
        ),
      );
    }

    _isModalShowing = true;
    await showSmartValidationBottomSheet(
      context: context,
      title: 'Data Formulir Belum Lengkap',
      subtitle: 'Lengkapi data wajib sebelum ke Langkah 2.',
      completedCount: 5 - missing.length,
      totalCount: 5,
      statusBadgeText: '${5 - missing.length} dari 5 data terisi',
      warningText: '${missing.length} data wajib belum lengkap',
      sectionTitle: 'DAFTAR DATA YANG PERLU DILENGKAPI',
      missingItems: missing,
      actionButtonText: 'Lengkapi Data Sekarang',
      cancelButtonText: 'Kembali ke Formulir',
    );
    if (mounted) {
      _isModalShowing = false;
    }
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required bool isAvailable,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13.5,
                      fontWeight: isAvailable
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isAvailable
                          ? AppColors.textMain
                          : AppColors.textMuted,
                      fontStyle: isAvailable
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPtCard() {
    // The local session has no verified company profile. Keep account identity
    // unavailable until an actual account data source is connected.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsRegular.identificationBadge,
                  color: AppColors.primaryRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Data PT',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildReadOnlyField(
            label: 'Nomor Induk Berusaha (NIB)',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
          _buildReadOnlyField(
            label: 'Nama Perusahaan (PT)',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
          _buildReadOnlyField(
            label: 'Penanggung Jawab / Direktur',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
          _buildReadOnlyField(
            label: 'Email Perusahaan',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
          _buildReadOnlyField(
            label: 'No. Telepon / WhatsApp',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
          _buildReadOnlyField(
            label: 'Alamat Kantor Perusahaan',
            value: 'Belum tersedia',
            isAvailable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTipePengajuanRadioGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Tipe Pengajuan ',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: AppColors.error),
              ),
              TextSpan(
                text: ' Pilih salah satu',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._tipePengajuanOptions.map((opt) {
          final isSelected = _selectedTipePengajuan == opt['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedTipePengajuan = opt['title']!);
                _syncState();
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurfaceSoft
                      : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryRed
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.grey400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title']!,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryRed
                                  : AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['subtitle']!,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTipePerumahanSegmentedControl() {
    final optionCount = _tipePerumahanOptions.length;
    final selectedIndex = _tipePerumahanOptions.indexOf(_selectedTipePerumahan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Tipe Perumahan ',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Stack(
            children: [
              if (selectedIndex >= 0)
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment(
                      -1 + 2 * selectedIndex / (optionCount - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / optionCount,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: _tipePerumahanOptions.map((opt) {
                  final isSelected = _selectedTipePerumahan == opt;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedTipePerumahan = opt);
                        _syncState();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            child: Text(opt),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNpwpSuffix(bool verified) {
    if (verified) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.check_circle, color: AppColors.statusSuccessText),
      );
    }
    if (_npwpVerifying) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return TextButton(
      onPressed: _verifyNpwp,
      child: const Text(
        'Verifikasi',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;

    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _dropdownController.duration = Duration.zero;
      _dropdownController.reverseDuration = Duration.zero;
    } else {
      _dropdownController.duration = const Duration(milliseconds: 220);
      _dropdownController.reverseDuration = const Duration(milliseconds: 160);
    }

    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    if (disableAnimations) {
      _dropdownController.value = 1.0;
    } else {
      _dropdownController.forward();
    }
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isDropdownOpen) return;
      final selected = ref.read(pengajuanFormProvider).dayaListrik;
      final selectedIndex = _dayaListrikOptions.indexOf(selected);
      if (selectedIndex > 2 && _dropdownScrollController.hasClients) {
        final targetOffset = math.max(0.0, (selectedIndex * 44.0) - 44.0);
        _dropdownScrollController.jumpTo(
          math.min(
            targetOffset,
            _dropdownScrollController.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;

    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _isDropdownOpen = false;
    setState(() {});

    if (disableAnimations) {
      _dropdownController.value = 0.0;
      _removeOverlay();
    } else {
      _dropdownController.reverse().then((_) {
        if (!_isDropdownOpen) {
          _removeOverlay();
        }
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 48);
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingBottom = mediaQuery.padding.bottom;
    final paddingTop = mediaQuery.padding.top;

    // Hitung sisa ruang vertikal: bottom navigation bar tingginya ~72dp
    final availableBelow =
        screenHeight - (offset.dy + size.height) - paddingBottom - 76;
    final availableAbove = offset.dy - paddingTop - 56;

    final bool openUpward =
        availableBelow < 220 && availableAbove > availableBelow;
    final double maxMenuHeight = openUpward
        ? math.min(260.0, math.max(160.0, availableAbove - 16))
        : math.min(260.0, math.max(160.0, availableBelow - 16));

    return OverlayEntry(
      builder: (context) {
        final state = ref.watch(pengajuanFormProvider);
        final dropdownValue = _dayaListrikOptions.contains(state.dayaListrik)
            ? state.dayaListrik
            : null;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: openUpward
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                followerAnchor: openUpward
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                offset: openUpward ? const Offset(0, -4) : const Offset(0, 4),
                child: AnimatedBuilder(
                  animation: _openCurve,
                  builder: (context, child) {
                    final progress = _openCurve.value;
                    final slideDelta = openUpward ? -5.0 : 5.0;
                    return Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, slideDelta * (progress - 1.0)),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxMenuHeight),
                        child: Scrollbar(
                          controller: _dropdownScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _dropdownScrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _dayaListrikOptions.map((opt) {
                                final isSelected = opt == dropdownValue;
                                return InkWell(
                                  onTap: () {
                                    ref
                                        .read(pengajuanFormProvider.notifier)
                                        .updateDayaListrik(opt);
                                    _closeDropdown();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    color: isSelected
                                        ? const Color(
                                            0xFFFEE2E2,
                                          ).withValues(alpha: 0.35)
                                        : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt,
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 13.5,
                                              color: isSelected
                                                  ? AppColors.primaryRed
                                                  : AppColors.textMain,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: AppColors.primaryRed,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayaListrikDropdown() {
    final selected = ref.watch(
      pengajuanFormProvider.select((s) => s.dayaListrik),
    );
    final dropdownValue = _dayaListrikOptions.contains(selected)
        ? selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Daya Listrik PLN per Unit ',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
            children: [
              TextSpan(
                text: '(Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            key: const ValueKey('daya_listrik_dropdown'),
            onTap: () {
              if (_isDropdownOpen) {
                _closeDropdown();
              } else {
                _openDropdown();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              key: _dropdownKey,
              isFocused: _isDropdownOpen,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.borderSubtle,
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.borderSubtle,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryRed,
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dropdownValue ?? 'Pilih daya listrik',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13.5,
                        color: dropdownValue != null
                            ? AppColors.textMain
                            : AppColors.textSecondary,
                        fontWeight: dropdownValue != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _chevronAnimation,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih bila rencana daya listrik per unit sudah ditentukan',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final npwpVerified = ref.watch(
      pengajuanFormProvider.select((s) => s.npwpVerified),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsRegular.buildings,
                  color: AppColors.primaryRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Isi Data Permohonan Site Plan',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // 1. Tipe Pengajuan Radio Group
          _buildTipePengajuanRadioGroup(),
          const SizedBox(height: AppSpacing.md),

          // 2. Nama Kawasan / Perumahan *
          AppTextField(
            label: 'Nama Kawasan / Perumahan *',
            hintText: 'Graha Sukatani Indah',
            controller: _namaPerumahanController,
            prefixIcon: Icons.apartment,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Nama perumahan wajib diisi'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Alamat / Lokasi Proyek *
          AppTextField(
            label: 'Alamat / Lokasi Proyek *',
            hintText: 'Jl. Tamansari KM 4, Kota Tasikmalaya',
            controller: _alamatProyekController,
            prefixIcon: Icons.location_on_outlined,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Alamat lokasi proyek wajib diisi'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. NPWP Perusahaan *
          AppTextField(
            label: 'NPWP Perusahaan *',
            hintText: '01.234.567.8-411.000',
            controller: _npwpController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.badge_outlined,
            suffixIcon: _buildNpwpSuffix(npwpVerified),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'NPWP wajib diisi' : null,
          ),
          if (npwpVerified)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.statusSuccessText,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'NPWP Terdaftar Aktif di KPP Tasikmalaya',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusSuccessText,
                    ),
                  ),
                ],
              ),
            )
          else if (_npwpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _npwpError!,
                style: const TextStyle(fontSize: 11.5, color: AppColors.error),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // 5. Luas Lahan & Jumlah Unit
          Builder(
            builder: (context) {
              final isScaled = MediaQuery.textScalerOf(context).scale(14) > 20;

              final luasField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Luas Lahan *',
                    hintText: '48.500',
                    controller: _luasController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'm²',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    validator: (val) {
                      final value = val == null
                          ? null
                          : double.tryParse(val.trim());
                      return value == null || !value.isFinite || value <= 0
                          ? 'Luas lahan harus > 0'
                          : null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Total luas area master',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              final unitField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Jumlah Unit *',
                    hintText: '320',
                    controller: _unitController,
                    keyboardType: TextInputType.number,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'Unit',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    validator: (val) {
                      final value = val == null
                          ? null
                          : int.tryParse(val.trim());
                      return value == null || value <= 0
                          ? 'Jumlah unit harus > 0'
                          : null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Termasuk kavling fasum',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              if (isScaled) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luasField,
                    const SizedBox(height: AppSpacing.md),
                    unitField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: luasField),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: unitField),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Tipe Perumahan Segmented Control
          _buildTipePerumahanSegmentedControl(),
          const SizedBox(height: AppSpacing.md),

          // 7. Daya Listrik PLN (opsional)
          _buildDayaListrikDropdown(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Canonical Hero Header matching prototype
            PengajuanStepHeader(
              title: 'Pengajuan Baru',
              subtitle: 'Langkah 1 dari 5',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),

            // Stepper indicator
            const StepperHeader(currentStep: 1),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Data PT (Read-Only)
                    _buildDataPtCard(),

                    const SizedBox(height: AppSpacing.md),

                    // Card 2: Isi Data Permohonan Site Plan
                    _buildFormCard(),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DraftStatusRow(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: AppColors.backgroundCanvas,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: const Text(
                        '‹ Kembali',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _onNext,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Lanjut ke Berkas',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
