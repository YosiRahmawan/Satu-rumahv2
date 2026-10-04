import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/route_feedback.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  AppRole _selectedRole = AppRole.developer;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim().toLowerCase();
      final AppRole role;
      if (_selectedRole == AppRole.perwaskim &&
          RoleSessionNotifier.roleForUsername(username) == AppRole.developer) {
        ref
            .read(roleSessionProvider.notifier)
            .signIn(AppRole.perwaskim, username: username);
        role = AppRole.perwaskim;
      } else {
        role = ref
            .read(roleSessionProvider.notifier)
            .signInFromUsername(username);
      }
      context.go(role.homeRoute);
    }
  }

  void _loginAsDeveloper() {
    setState(() => _selectedRole = AppRole.developer);
    _usernameController.text = 'pt_tasik_indah';
    _passwordController.text = 'demo123';
    ref
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.developer, username: 'pt_tasik_indah');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Masuk sebagai Pengembang Demo (PT. Tasik Indah Sentosa)',
        ),
        duration: Duration(seconds: 2),
      ),
    );
    context.go('/dashboard');
  }

  void _loginAsTimMonitoring() {
    setState(() => _selectedRole = AppRole.perwaskim);
    _usernameController.text = 'tim_monitoring_perwaskim';
    _passwordController.text = 'monitoring123';
    ref
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.perwaskim, username: 'tim_monitoring_perwaskim');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Masuk sebagai Tim Perwaskim Monitoring (Drs. Rian Hidayat, M.Si)',
        ),
        duration: Duration(seconds: 2),
      ),
    );
    context.go('/monitoring/lapangan');
  }

  void _showAdminContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hubungi Administrator',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        content: const Text(
          'Untuk pembuatan akun baru atau kendala masuk, silakan hubungi Admin Disperwaskim melalui WhatsApp di +62-812-3456-7890.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Akun Demo Pengujian',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih peran untuk langsung masuk dengan data demonstrasi.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.primaryRed,
                  ),
                ),
                title: const Text(
                  'Pengembang (PT. Tasik Indah Sentosa)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                subtitle: const Text(
                  'pt_tasik_indah',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _loginAsDeveloper();
                },
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.slate800,
                  ),
                ),
                title: const Text(
                  'Tim Monitoring Perwaskim',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                subtitle: const Text(
                  'tim_monitoring_perwaskim',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _loginAsTimMonitoring();
                },
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusSurveySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.statusSurveyText,
                  ),
                ),
                title: const Text(
                  'Admin Disperwaskim',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                subtitle: const Text(
                  'admin_disperwaskim',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _usernameController.text = 'admin_disperwaskim';
                  _passwordController.text = 'admin123';
                  ref
                      .read(roleSessionProvider.notifier)
                      .signIn(AppRole.admin, username: 'admin_disperwaskim');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masuk sebagai Admin Disperwaskim'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  context.go('/admin');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = _selectedRole == AppRole.developer;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Stack(
        children: [
          // Red top gradient background banner
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark, // #881337
                  AppColors.primaryRed,  // #B91C1C
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Fixed vertical offset ensuring stable overlap regardless of screen height
                      const SizedBox(height: 56),

                      // Card 1: Role Selector Card (Overlaps the red header banner)
                      GestureDetector(
                        onLongPress: _showDemoSheet,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: AppColors.dividerLine,
                                width: 1.0,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 20.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'PILIH PERAN AKUN PENGGUNA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  // Tab Pengembang
                                  Expanded(
                                    child: Material(
                                      color: isDeveloper
                                          ? AppColors.primaryRed
                                          : AppColors.dividerLine,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = AppRole.developer;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.apartment_rounded,
                                                color: isDeveloper
                                                    ? Colors.white
                                                    : AppColors.slate800,
                                                size: 26,
                                              ),
                                              const SizedBox(height: 6),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Pengembang',
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles.fontFamily,
                                                    fontSize: 13.5,
                                                    fontWeight: isDeveloper
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: isDeveloper
                                                        ? Colors.white
                                                        : AppColors.slate800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Tab Pengawas Lapangan
                                  Expanded(
                                    child: Material(
                                      color: !isDeveloper
                                          ? AppColors.primaryRed
                                          : AppColors.dividerLine,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = AppRole.perwaskim;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.manage_accounts_outlined,
                                                color: !isDeveloper
                                                    ? Colors.white
                                                    : AppColors.slate800,
                                                size: 26,
                                              ),
                                              const SizedBox(height: 6),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Pengawas Lapangan',
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles.fontFamily,
                                                    fontSize: 13.5,
                                                    fontWeight: !isDeveloper
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: !isDeveloper
                                                        ? Colors.white
                                                        : AppColors.slate800,
                                                  ),
                                                ),
                                              ),
                                            ],
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

                      const SizedBox(height: 14),

                      // Card 2: Main Form Card
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: AppColors.dividerLine,
                              width: 1.0,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 24.0,
                              spreadRadius: 0.0,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 22.0,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sub-banner info
                              GestureDetector(
                                onLongPress: _showDemoSheet,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.dividerLine,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDeveloper
                                            ? Icons.apartment_rounded
                                            : Icons.manage_accounts_rounded,
                                        color: AppColors.primaryRed,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isDeveloper
                                                  ? 'Login Mitra Pengembang Terdaftar'
                                                  : 'Login Tim Pengawas Lapangan',
                                              style: const TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isDeveloper
                                                  ? 'Gunakan kredensial OSS / NIB perusahaan'
                                                  : 'Gunakan NIP / akun dinas yang terdaftar',
                                              style: const TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Field 1: Username / NIB / Email
                              RichText(
                                text: TextSpan(
                                  text: isDeveloper
                                      ? 'Email / NIB / Username Pengembang '
                                      : 'NIP / Username Pengawas Lapangan ',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: AppColors.primaryRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13.5,
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: isDeveloper
                                      ? 'Masukkan NIB atau email resmi...'
                                      : 'Masukkan NIP atau username resmi...',
                                  hintStyle: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardSurface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  prefixIcon: Icon(
                                    isDeveloper
                                        ? Icons.apartment_outlined
                                        : Icons.badge_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedErrorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return isDeveloper
                                        ? 'NIB atau email tidak boleh kosong'
                                        : 'NIP atau username tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDeveloper
                                    ? 'Contoh: 123400056789 atau pt.ciptakarya@gmail.com'
                                    : 'Contoh: 198503152010011002 atau tim_monitoring_perwaskim',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Field 2: Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: RichText(
                                      text: const TextSpan(
                                        text: 'Kata Sandi ',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '*',
                                            style: TextStyle(
                                              color: AppColors.primaryRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Enlarged touch target for "Lupa Kata Sandi?"
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _showAdminContact,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Lupa Kata Sandi?',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13.5,
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan kata sandi...',
                                  hintStyle: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardSurface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedErrorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Kata sandi tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Remember Me Checkbox
                              InkWell(
                                onTap: () => setState(
                                  () => _rememberMe = !_rememberMe,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primaryRed,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          side: const BorderSide(
                                            color: AppColors.slate300,
                                            width: 1.5,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) => setState(
                                            () => _rememberMe = val ?? false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Ingat saya di perangkat ini',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 12.5,
                                            color: AppColors.slate700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Primary Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _login,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.login_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isDeveloper
                                              ? 'Masuk sebagai Pengembang'
                                              : 'Masuk sebagai Pengawas Lapangan',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Divider "ATAU MASUK"
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.borderSubtle,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'ATAU MASUK',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.borderSubtle,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Google Login Button (Kept as prototype action)
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.cardSurface,
                                    foregroundColor: AppColors.slate800,
                                    side: const BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => showUnavailableAction(
                                    context,
                                    'Masuk dengan Google',
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GoogleLogoWidget(),
                                      SizedBox(width: 10),
                                      Text(
                                        'Masuk dengan Google',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Footer (WCAG AA Compliant contrast)
                      const Text(
                        'Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogoWidget extends StatelessWidget {
  const _GoogleLogoWidget();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(18, 18),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2 - 1.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.6, 1.8, false, paint);

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.6, false, paint);

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.8, false, paint);

    // Yellow arc (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.6, 1.1, false, paint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(center.dx - 1, center.dy),
      Offset(w - 1.5, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
