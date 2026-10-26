import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
  bool _submitting = false;
  AppRole _selectedRole = AppRole.developer;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithApi(String username) async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: _passwordController.text);
      if (!mounted) return;
      ref
          .read(roleSessionProvider.notifier)
          .signIn(
            result.user.role,
            username: result.user.username,
            mustChangePassword: result.mustChangePassword,
          );
      context.go(
        result.mustChangePassword ? '/ganti-sandi' : result.user.role.homeRoute,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_loginMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _loginMessage(ApiException e) {
    final until = e.lockedUntil?.toLocal();
    if (e.code == 'ERR-021' && until != null) {
      final hh = until.hour.toString().padLeft(2, '0');
      final mm = until.minute.toString().padLeft(2, '0');
      return 'Akun terkunci sementara. Coba lagi pukul $hh.$mm.';
    }
    return e.message;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate() && !_submitting) {
      final username = _usernameController.text.trim().toLowerCase();
      if (ref.read(apiEnabledProvider)) {
        await _loginWithApi(username);
        return;
      }
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
                  AppColors.primaryRed, // #B91C1C
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                        onLongPress: ref.read(apiEnabledProvider)
                            ? null
                            : _showDemoSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(
                                alpha: 0.6,
                              ),
                              width: 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18.0,
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
                                  color: AppColors.textMain,
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
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: isDeveloper ? 1 : 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = AppRole.developer;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.apartment_rounded,
                                                color: isDeveloper
                                                    ? Colors.white
                                                    : AppColors.textMain,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 8),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Pengembang',
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles
                                                        .fontFamily,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDeveloper
                                                        ? Colors.white
                                                        : AppColors.textMain,
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
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: !isDeveloper ? 1 : 0,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = AppRole.perwaskim;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.engineering_outlined,
                                                color: !isDeveloper
                                                    ? Colors.white
                                                    : AppColors.textMain,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 8),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Pengawas Lapangan',
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles
                                                        .fontFamily,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: !isDeveloper
                                                        ? Colors.white
                                                        : AppColors.textMain,
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

                      const SizedBox(height: 16),

                      // Card 2: Main Form Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20.0),
                          ),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(
                              alpha: 0.6,
                            ),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 18.0,
                              offset: Offset(0, 4),
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
                              // Field 1: Username / NIB
                              RichText(
                                text: TextSpan(
                                  text: isDeveloper
                                      ? 'Username / NIB Pengembang'
                                      : 'Username / NIP Petugas',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                  children: [
                                    if (isDeveloper)
                                      const TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          color: AppColors.primaryRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                      ? 'Masukkan 13 digit NIB...'
                                      : 'Masukkan username / NIP...',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
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
                                    Icons.apartment_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedErrorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return isDeveloper
                                        ? 'NIB tidak boleh kosong'
                                        : 'NIP tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isDeveloper
                                    ? 'Contoh: 1234000567890 (NIB resmi terdaftar)'
                                    : 'Contoh: 1234000567890 (NIP)',
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
                                        text: 'Kata Sandi',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                              color: AppColors.primaryRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Touch target for "Bantuan Akses?"
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _showAdminContact,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Bantuan Akses?',
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
                              const SizedBox(height: 8),
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
                                  hintStyle: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
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
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.borderSubtle.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedErrorBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
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
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                            fontFamily:
                                                AppTextStyles.fontFamily,
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
                                  onPressed: _submitting ? null : _login,
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
                                            fontFamily:
                                                AppTextStyles.fontFamily,
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
