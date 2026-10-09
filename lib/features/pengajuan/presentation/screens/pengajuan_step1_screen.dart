import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pengajuan_step_header.dart';
import '../../../../core/widgets/stepper_header.dart';
import '../providers/pengajuan_form_controller.dart';

class PengajuanStep1Screen extends ConsumerStatefulWidget {
  const PengajuanStep1Screen({super.key});

  @override
  ConsumerState<PengajuanStep1Screen> createState() =>
      _PengajuanStep1ScreenState();
}

class _PengajuanStep1ScreenState extends ConsumerState<PengajuanStep1Screen> {
  final _formKey = GlobalKey<FormState>();

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

  static const List<String> _tipePerumahanOptions = [
    'Subsidi',
    'Komersil',
    'Campuran',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(pengajuanFormProvider);
    _namaPerumahanController = TextEditingController(text: state.namaPerumahan);
    _alamatProyekController = TextEditingController(text: state.alamatProyek);
    _npwpController = TextEditingController(text: state.npwpPerusahaan);
    _luasController = TextEditingController(
      text: state.luasLahan > 0
          ? (state.luasLahan % 1 == 0
              ? state.luasLahan.toInt().toString()
              : state.luasLahan.toString())
          : '',
    );
    _unitController = TextEditingController(
      text: state.jumlahUnit > 0 ? state.jumlahUnit.toString() : '',
    );
    _selectedTipePengajuan = state.tipePengajuan.isNotEmpty
        ? state.tipePengajuan
        : 'Pengajuan Site Plan Baru';
    _selectedTipePerumahan = state.tipePerumahan.isNotEmpty
        ? state.tipePerumahan
        : 'Komersil';
  }

  @override
  void dispose() {
    _namaPerumahanController.dispose();
    _alamatProyekController.dispose();
    _npwpController.dispose();
    _luasController.dispose();
    _unitController.dispose();
    super.dispose();
  }

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

  void _onNext() {
    _syncState();
    final isValid = _formKey.currentState?.validate() == true;
    final isStateValid = ref.read(pengajuanFormProvider).isStep1Valid;

    if (isValid && isStateValid) {
      context.push('/pengajuan/step2');
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
                      fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w400,
                      color: isAvailable ? AppColors.textMain : AppColors.textMuted,
                      fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
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

  Widget _buildDataPtCard(RoleSessionState session) {
    // Only resolve demo PT data when the current session actually owns it.
    // Otherwise show truthful unavailable state, never faking account identity.
    final isDemoDeveloper = session.username == 'pt_tasik_indah';

    final String nibValue = isDemoDeveloper ? '912000341882' : 'Belum tersedia';
    final String namaPtValue = isDemoDeveloper
        ? 'PT. Tasik Indah Sentosa'
        : (session.username != null && session.username!.isNotEmpty
            ? 'Pengembang (${session.username})'
            : 'Belum tersedia');
    final String direkturValue = isDemoDeveloper ? 'H. Tatang Sutisna' : 'Belum tersedia';
    final String emailValue = isDemoDeveloper ? 'tasikindah@developer.com' : 'Belum tersedia';
    final String telpValue = isDemoDeveloper ? '0812-9876-5432' : 'Belum tersedia';
    final String alamatKantorValue = isDemoDeveloper ? 'Belum diatur di profil' : 'Belum tersedia';

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
            value: nibValue,
            isAvailable: isDemoDeveloper,
          ),
          _buildReadOnlyField(
            label: 'Nama Perusahaan (PT)',
            value: namaPtValue,
            isAvailable: isDemoDeveloper || session.username != null,
          ),
          _buildReadOnlyField(
            label: 'Penanggung Jawab / Direktur',
            value: direkturValue,
            isAvailable: isDemoDeveloper,
          ),
          _buildReadOnlyField(
            label: 'Email Perusahaan',
            value: emailValue,
            isAvailable: isDemoDeveloper,
          ),
          _buildReadOnlyField(
            label: 'No. Telepon / WhatsApp',
            value: telpValue,
            isAvailable: isDemoDeveloper,
          ),
          _buildReadOnlyField(
            label: 'Alamat Kantor Perusahaan',
            value: alamatKantorValue,
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
            color: AppColors.backgroundCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: _tipePerumahanOptions.map((opt) {
              final isSelected = _selectedTipePerumahan == opt;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedTipePerumahan = opt);
                    _syncState();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryRed
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
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
            prefixIcon: Icons.badge_outlined,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'NPWP wajib diisi'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Luas Lahan & Jumlah Unit
          Builder(
            builder: (context) {
              final isScaled =
                  MediaQuery.textScalerOf(context).scale(14) > 20;

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
                      final value =
                          val == null ? null : int.tryParse(val.trim());
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(roleSessionProvider);

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
              badgeText: 'DISPERWASKIM KOTA TASIKMALAYA',
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),

            // Stepper indicator
            const StepperHeader(
              currentStep: 1,
              stepTitles: StepperHeader.prototypeTitles,
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Data PT (Read-Only)
                    _buildDataPtCard(session),

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
          child: Row(
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lanjut ke Berkas',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
