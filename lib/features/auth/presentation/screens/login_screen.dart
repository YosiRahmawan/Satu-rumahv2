// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/role_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loading_spinner.dart';
import '../../../dashboard/presentation/screens/tab_beranda.dart';

/// Screen Login SATU RUMAH V2 dengan desain hero food-grade visual & motion entrance
/// terkoordinasi sesuai spesifikasi Google Stitch.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  AppRole _selectedRole = AppRole.developer;

  // Transition & Auth States
  bool _isAuthenticating = false;
  bool _isTransitioning = false;
  AppRole _targetRole = AppRole.developer;

  // Single Coordinated Entrance Animation Timeline (2200ms)
  late final AnimationController _entranceController;

  // Act 1: Hero Slides Down from above (0.00 - 0.38)
  late final Animation<Offset> _heroSlideAnim;
  late final Animation<double> _topRowFadeAnim;
  late final Animation<Offset> _topRowSlideAnim;
  late final Animation<double> _brandFadeAnim;
  late final Animation<Offset> _brandSlideAnim;

  // Act 2: Housing Illustration Settles into Place (0.32 - 0.62)
  late final Animation<double> _housingFadeAnim;
  late final Animation<Offset> _housingSlideAnim;
  late final Animation<double> _housingScaleAnim;
  late final Animation<double> _hillsAnim;
  late final Animation<double> _treesAnim;
  late final Animation<double> _house1Anim;
  late final Animation<double> _house2Anim;
  late final Animation<double> _house3Anim;
  late final Animation<double> _roadAnim;

  // Act 3: White Login Card Fades In & Rises from Below (0.58 - 1.00)
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;
  late final Animation<double> _roleFadeAnim;
  late final Animation<double> _roleScaleAnim;
  late final Animation<double> _usernameFadeAnim;
  late final Animation<Offset> _usernameSlideAnim;
  late final Animation<double> _passwordFadeAnim;
  late final Animation<Offset> _passwordSlideAnim;
  late final Animation<double> _rememberFadeAnim;
  late final Animation<Offset> _rememberSlideAnim;
  late final Animation<double> _submitFadeAnim;
  late final Animation<Offset> _submitSlideAnim;
  late final Animation<double> _footerFadeAnim;

  // Login-to-Home Header Shared Transition Timeline (700ms)
  late final AnimationController _transitionController;

  // Step B: Form Exit (0.00 - 0.36, ~250ms)
  late final Animation<double> _formExitFadeAnim;
  late final Animation<Offset> _formExitSlideAnim;

  // Step C: Hero Collapse & Smooth Move-Up (0.15 - 0.88, 500-700ms)
  late final Animation<double> _heroShrinkAnim;
  late final Animation<double> _heroRadiusAnim;

  // Step D: Housing Illustration & Top Chip Fade-Out (0.00 - 0.35)
  late final Animation<double> _topChipFadeOutAnim;
  late final Animation<double> _illustrationFadeOutAnim;

  // Step E: Branding SATU RUMAH Transition on Hero (0.12 - 0.80)
  late final Animation<double> _loginBrandFadeOutAnim;
  late final Animation<double> _homeHeaderFadeInAnim;
  late final Animation<double> _homeHeaderScaleAnim;

  // Step G: First Home Card Fade-In & Slide-Up Overlapping Header Bottom (0.38 - 0.82)
  late final Animation<double> _card1FadeInAnim;
  late final Animation<Offset> _card1SlideUpAnim;

  // Step H: Dashboard Subsequent Content & Bottom Nav (0.55 - 1.00)
  late final Animation<double> _dashboardContentFadeAnim;
  late final Animation<Offset> _dashboardContentSlideAnim;
  late final Animation<Offset> _bottomNavSlideAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _setupEntranceAnimations();
    _setupTransitionAnimations();
    _entranceController.forward();
  }

  void _setupEntranceAnimations() {
    // Act 1: Hero Slides Down from Top (0.00 - 0.38)
    _heroSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.65),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.00, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _topRowFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.38, curve: Curves.easeOut),
    );
    _topRowSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.10, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _brandFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.38, curve: Curves.easeOut),
    );
    _brandSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // Act 2: Housing Illustration Settles (0.32 - 0.62)
    _housingFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.55, curve: Curves.easeOut),
    );
    _housingSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.32, 0.62, curve: Curves.easeOutCubic),
      ),
    );
    _housingScaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.32, 0.62, curve: Curves.easeOutBack),
      ),
    );

    _hillsAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.46, curve: Curves.easeOut),
    );
    _treesAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.52, curve: Curves.easeOutCubic),
    );
    _house1Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 0.56, curve: Curves.easeOutCubic),
    );
    _house2Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.60, curve: Curves.easeOutCubic),
    );
    _house3Anim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.46, 0.62, curve: Curves.easeOutCubic),
    );
    _roadAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.62, curve: Curves.easeOutCubic),
    );

    // Act 3: Login Card Fades In & Rises from Below (0.58 - 1.00)
    _cardFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.58, 0.88, curve: Curves.easeOut),
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.58, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _roleFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.64, 0.90, curve: Curves.easeOut),
    );
    _roleScaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.64, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _usernameFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.68, 0.92, curve: Curves.easeOut),
    );
    _usernameSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.68, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _passwordFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.72, 0.95, curve: Curves.easeOut),
    );
    _passwordSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.72, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _rememberFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.76, 0.98, curve: Curves.easeOut),
    );
    _rememberSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.76, 0.98, curve: Curves.easeOutCubic),
      ),
    );

    _submitFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.80, 1.00, curve: Curves.easeOut),
    );
    _submitSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.80, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    _footerFadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.82, 1.00, curve: Curves.easeOut),
    );
  }

  void _setupTransitionAnimations() {
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go(_targetRole.homeRoute);
      }
    });

    // Step B: Form Exit (0.00 - 0.36, ~250ms)
    _formExitFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.00, 0.36, curve: Curves.easeIn),
      ),
    );
    _formExitSlideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.06),
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.00, 0.36, curve: Curves.easeInCubic),
      ),
    );

    // Step D: Housing Illustration & Top Chip Fade-Out (0.00 - 0.35)
    _topChipFadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.00, 0.25, curve: Curves.easeOut),
      ),
    );
    _illustrationFadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOut),
      ),
    );

    // Step C: Hero Collapse & Smooth Move-Up (0.15 - 0.88, 500-700ms)
    _heroShrinkAnim = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.15, 0.88, curve: Curves.easeInOutCubic),
    );
    _heroRadiusAnim = Tween<double>(begin: 38.0, end: 28.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.20, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // Step E: Branding SATU RUMAH Transition on Hero (0.12 - 0.80)
    _loginBrandFadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.12, 0.40, curve: Curves.easeOut),
      ),
    );
    _homeHeaderFadeInAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _homeHeaderScaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Step G: First Home Card Fade-In & Slide-Up Overlapping Header Bottom (0.38 - 0.82)
    _card1FadeInAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.38, 0.78, curve: Curves.easeOut),
      ),
    );
    _card1SlideUpAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.38, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Step H: Dashboard Subsequent Content & Bottom Nav (0.55 - 1.00)
    _dashboardContentFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
      ),
    );
    _dashboardContentSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _bottomNavSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.60, 1.00, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (prefersReducedMotion) {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _transitionController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final username = _usernameController.text.trim().toLowerCase();
    final AppRole role;
    if (_selectedRole == AppRole.perwaskim &&
        RoleSessionNotifier.roleForUsername(username) == AppRole.developer) {
      role = AppRole.perwaskim;
    } else {
      role = RoleSessionNotifier.roleForUsername(username);
    }

    setState(() {
      _isAuthenticating = true;
      _targetRole = role;
    });

    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Button displays loading state during authentication process
    if (!prefersReducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;

    if (_selectedRole == AppRole.perwaskim &&
        RoleSessionNotifier.roleForUsername(username) == AppRole.developer) {
      ref
          .read(roleSessionProvider.notifier)
          .signIn(AppRole.perwaskim, username: username);
    } else {
      ref
          .read(roleSessionProvider.notifier)
          .signInFromUsername(username);
    }

    if (prefersReducedMotion) {
      context.go(role.homeRoute);
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _isTransitioning = true;
    });

    _transitionController.forward();
  }

  Future<void> _loginAsDeveloper() async {
    setState(() {
      _selectedRole = AppRole.developer;
      _isAuthenticating = true;
      _targetRole = AppRole.developer;
    });
    _usernameController.text = 'pt_tasik_indah';
    _passwordController.text = 'demo123';

    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!prefersReducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;

    ref
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.developer, username: 'pt_tasik_indah');

    if (prefersReducedMotion) {
      context.go('/dashboard');
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _isTransitioning = true;
    });

    _transitionController.forward();
  }

  Future<void> _loginAsTimMonitoring() async {
    setState(() {
      _selectedRole = AppRole.perwaskim;
      _isAuthenticating = true;
      _targetRole = AppRole.perwaskim;
    });
    _usernameController.text = 'tim_monitoring_perwaskim';
    _passwordController.text = 'monitoring123';

    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!prefersReducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;

    ref
        .read(roleSessionProvider.notifier)
        .signIn(AppRole.perwaskim, username: 'tim_monitoring_perwaskim');

    if (prefersReducedMotion) {
      context.go('/monitoring/lapangan');
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _isTransitioning = true;
    });

    _transitionController.forward();
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
    final topSafePadding = MediaQuery.paddingOf(context).top;
    // Spacing so the login card surface starts neatly underneath the hero curve
    final cardTopSpacer = 160.0 + topSafePadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundCanvas,
        bottomNavigationBar: _isTransitioning
            ? SlideTransition(
                position: _bottomNavSlideAnim,
                child: _buildBottomNavPreview(_targetRole),
              )
            : null,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // =======================================================
              // LAYER 1 (BEHIND): WHITE LOGIN CARD & LEGAL FOOTER
              // =======================================================
              Column(
                children: [
                  SizedBox(height: cardTopSpacer),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FadeTransition(
                        opacity: _isTransitioning
                            ? _formExitFadeAnim
                            : _cardFadeAnim,
                        child: SlideTransition(
                          position: _isTransitioning
                              ? _formExitSlideAnim
                              : _cardSlideAnim,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.slate100,
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F0F172A),
                                  blurRadius: 36,
                                  offset: Offset(0, 14),
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 30, 18, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role Selector Header Label
                                FadeTransition(
                                  opacity: _roleFadeAnim,
                                  child: const Text(
                                    'PILIH PERAN AKUN PENGGUNA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate500,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Animated Sliding Role Selector (280ms)
                                FadeTransition(
                                  opacity: _roleFadeAnim,
                                  child: ScaleTransition(
                                    scale: _roleScaleAnim,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final itemWidth =
                                            (constraints.maxWidth - 8) / 2;

                                        return Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors.slate200,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // Sliding active red pill indicator
                                              AnimatedAlign(
                                                key: const ValueKey(
                                                  'role_active_indicator_align',
                                                ),
                                                duration: const Duration(
                                                  milliseconds: 280,
                                                ),
                                                curve: Curves.easeInOutCubic,
                                                alignment: isDeveloper
                                                    ? Alignment.centerLeft
                                                    : Alignment.centerRight,
                                                child: AnimatedContainer(
                                                  key: const ValueKey(
                                                    'role_active_indicator_container',
                                                  ),
                                                  duration: const Duration(
                                                    milliseconds: 280,
                                                  ),
                                                  curve: Curves.easeInOutCubic,
                                                  width: itemWidth,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFB91C1C,
                                                    ), // AppColors.primaryRed
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Color(0x33B91C1C),
                                                        blurRadius: 8,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Foreground interactive buttons
                                              Row(
                                                children: [
                                                  // Role: Pengembang
                                                  Expanded(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                      child: InkWell(
                                                        key: const ValueKey(
                                                          'role_tab_pengembang',
                                                        ),
                                                        onTap: () {
                                                          if (_selectedRole !=
                                                              AppRole.developer) {
                                                            setState(() {
                                                              _selectedRole =
                                                                  AppRole
                                                                      .developer;
                                                            });
                                                          }
                                                        },
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          14,
                                                        ),
                                                        child: Container(
                                                          height: 42,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .apartment_rounded,
                                                                  size: 18,
                                                                  color: isDeveloper
                                                                      ? Colors
                                                                          .white
                                                                      : AppColors
                                                                          .slate600,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text(
                                                                  'Pengembang',
                                                                  style: TextStyle(
                                                                    fontFamily:
                                                                        AppTextStyles
                                                                            .fontFamily,
                                                                    fontSize:
                                                                        12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: isDeveloper
                                                                        ? Colors
                                                                            .white
                                                                        : AppColors
                                                                            .slate700,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Role: Pengawas Lapangan
                                                  Expanded(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                      child: InkWell(
                                                        key: const ValueKey(
                                                          'role_tab_pengawas_lapangan',
                                                        ),
                                                        onTap: () {
                                                          if (_selectedRole !=
                                                              AppRole.perwaskim) {
                                                            setState(() {
                                                              _selectedRole =
                                                                  AppRole
                                                                      .perwaskim;
                                                            });
                                                          }
                                                        },
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          14,
                                                        ),
                                                        child: Container(
                                                          height: 42,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .engineering_rounded,
                                                                  size: 18,
                                                                  color: !isDeveloper
                                                                      ? Colors
                                                                          .white
                                                                      : AppColors
                                                                          .slate600,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text(
                                                                  'Pengawas Lapangan',
                                                                  style: TextStyle(
                                                                    fontFamily:
                                                                        AppTextStyles
                                                                            .fontFamily,
                                                                    fontSize:
                                                                        12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: !isDeveloper
                                                                        ? Colors
                                                                            .white
                                                                        : AppColors
                                                                            .slate700,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Form with sequential motion & AnimatedSwitcher
                                Form(
                                  key: _formKey,
                                  child: AnimatedSwitcher(
                                    key: const ValueKey('form_animated_switcher'),
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeInOut,
                                    switchOutCurve: Curves.easeInOut,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.03),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey<AppRole>(_selectedRole),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Field 1: Username / NIB / NIP
                                          FadeTransition(
                                            opacity: _usernameFadeAnim,
                                            child: SlideTransition(
                                              position: _usernameSlideAnim,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (isDeveloper)
                                                    const Text.rich(
                                                      TextSpan(
                                                        text:
                                                            'Username / NIB Pengembang ',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppTextStyles
                                                                  .fontFamily,
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.slate800,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: '*',
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .primaryRed,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else
                                                    const Text(
                                                      'Username / NIP Petugas',
                                                      style: TextStyle(
                                                        fontFamily: AppTextStyles
                                                            .fontFamily,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.slate800,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 6),
                                                  TextFormField(
                                                    controller:
                                                        _usernameController,
                                                    style: const TextStyle(
                                                      fontFamily: AppTextStyles
                                                          .fontFamily,
                                                      fontSize: 13,
                                                      color: AppColors.textMain,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: isDeveloper
                                                          ? 'Masukkan 13 digit NIB...'
                                                          : 'Masukkan username / NIP...',
                                                      hintStyle: const TextStyle(
                                                        fontFamily: AppTextStyles
                                                            .fontFamily,
                                                        color:
                                                            AppColors.slate400,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                      filled: true,
                                                      fillColor:
                                                          AppColors.slate50,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 14,
                                                        vertical: 13,
                                                      ),
                                                      prefixIcon: Icon(
                                                        isDeveloper
                                                            ? Icons
                                                                .apartment_rounded
                                                            : Icons
                                                                .engineering_rounded,
                                                        color:
                                                            AppColors.slate400,
                                                        size: 19,
                                                      ),
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.slate200,
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.slate200,
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.primaryRed,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      errorBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color: AppColors.error,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      focusedErrorBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color: AppColors.error,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                    validator: (val) {
                                                      if (val == null ||
                                                          val.trim().isEmpty) {
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
                                                        ? 'Contoh: 1234000567890 (NIB resmi terdaftar)'
                                                        : 'Contoh: 1234000567890 (NIP)',
                                                    style: const TextStyle(
                                                      fontFamily: AppTextStyles
                                                          .fontFamily,
                                                      fontSize: 10.5,
                                                      color: AppColors.slate500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 14),

                                          // Field 2: Password
                                          FadeTransition(
                                            opacity: _passwordFadeAnim,
                                            child: SlideTransition(
                                              position: _passwordSlideAnim,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Flexible(
                                                        child: Text.rich(
                                                          TextSpan(
                                                            text: 'Kata Sandi ',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppTextStyles
                                                                      .fontFamily,
                                                              fontSize: 12.5,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              color: AppColors
                                                                  .slate800,
                                                            ),
                                                            children: [
                                                              TextSpan(
                                                                text: '*',
                                                                style: TextStyle(
                                                                  color: AppColors
                                                                      .primaryRed,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        behavior: HitTestBehavior
                                                            .opaque,
                                                        onTap: _showAdminContact,
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                            vertical: 4,
                                                          ),
                                                          child: Text(
                                                            'Bantuan Akses?',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppTextStyles
                                                                      .fontFamily,
                                                              fontSize: 11.5,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              color: AppColors
                                                                  .primaryRed,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  TextFormField(
                                                    controller:
                                                        _passwordController,
                                                    obscureText: _obscurePassword,
                                                    style: const TextStyle(
                                                      fontFamily: AppTextStyles
                                                          .fontFamily,
                                                      fontSize: 13,
                                                      color: AppColors.textMain,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Masukkan kata sandi...',
                                                      hintStyle: const TextStyle(
                                                        fontFamily: AppTextStyles
                                                          .fontFamily,
                                                        color:
                                                            AppColors.slate400,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                      filled: true,
                                                      fillColor:
                                                          AppColors.slate50,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 14,
                                                        vertical: 13,
                                                      ),
                                                      prefixIcon: const Icon(
                                                        Icons.lock_outline_rounded,
                                                        color:
                                                            AppColors.slate400,
                                                        size: 19,
                                                      ),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                  .visibility_outlined
                                                              : Icons
                                                                  .visibility_off_outlined,
                                                          color:
                                                              AppColors.slate400,
                                                          size: 19,
                                                        ),
                                                        onPressed: () => setState(
                                                          () => _obscurePassword =
                                                              !_obscurePassword,
                                                        ),
                                                      ),
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.slate200,
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.slate200,
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              AppColors.primaryRed,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      errorBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color: AppColors.error,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      focusedErrorBorder:
                                                          const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(12),
                                                        ),
                                                        borderSide: BorderSide(
                                                          color: AppColors.error,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                    validator: (val) {
                                                      if (val == null ||
                                                          val.isEmpty) {
                                                        return 'Kata sandi tidak boleh kosong';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Remember Me Checkbox
                                          FadeTransition(
                                            opacity: _rememberFadeAnim,
                                            child: SlideTransition(
                                              position: _rememberSlideAnim,
                                              child: InkWell(
                                                onTap: () => setState(
                                                  () =>
                                                      _rememberMe = !_rememberMe,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: Checkbox(
                                                          value: _rememberMe,
                                                          activeColor: AppColors
                                                              .primaryRed,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(4),
                                                          ),
                                                          side: const BorderSide(
                                                            color:
                                                                AppColors.slate300,
                                                            width: 1.5,
                                                          ),
                                                          materialTapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                          onChanged: (val) =>
                                                              setState(
                                                            () => _rememberMe =
                                                                val ?? false,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Flexible(
                                                        child: Text(
                                                          'Ingat saya di perangkat ini',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppTextStyles
                                                                    .fontFamily,
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .slate700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                        ),
                                                      ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 18),

                                          // Primary CTA Button (without arrow icon!)
                                          FadeTransition(
                                            opacity: _submitFadeAnim,
                                            child: SlideTransition(
                                              position: _submitSlideAnim,
                                              child: Container(
                                                width: double.infinity,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFB91C1C),
                                                      Color(0xFF991B1B),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x33B91C1C),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    foregroundColor: Colors.white,
                                                    shadowColor:
                                                        Colors.transparent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: _isAuthenticating || _isTransitioning ? null : _login,
                                                  child: _isAuthenticating
                                                      ? const AppLoadingSpinner.buttonWhite(
                                                          customDimension: 22,
                                                          strokeWidth: 2.2,
                                                        )
                                                      : Text(
                                                          isDeveloper
                                                              ? 'Masuk sebagai Pengembang'
                                                              : 'Masuk sebagai Pengawas Lapangan',
                                                          textAlign: TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                AppTextStyles
                                                                    .fontFamily,
                                                            fontSize: 13.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.white,
                                                            letterSpacing: 0.2,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =======================================================
                  // 3. FOOTER DISPERWASKIM LEGAL NOTE
                  // =======================================================
                  FadeTransition(
                    opacity: _isTransitioning
                        ? _formExitFadeAnim
                        : _footerFadeAnim,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        children: [
                          Text(
                            'Pemerintah Kota Tasikmalaya • Disperwaskim © 2026',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate400,
                            ),
                          ),
                          SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 12,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'TLS Enkripsi',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate400,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'v${AppConfig.appVersion} ${AppConfig.appBuild}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // =======================================================
              // LAYER 1.5 (TRANSITION): HOME DASHBOARD PREVIEW
              // Fades in & slides up, overlapping the bottom of the compact header
              // =======================================================
              if (_isTransitioning)
                Positioned(
                  top: topSafePadding +
                      (_targetRole == AppRole.developer ? 112.0 : 70.0),
                  left: 0,
                  right: 0,
                  child: _buildHomeDashboardPreview(context, _targetRole),
                ),

              // =======================================================
              // LAYER 2 (IN FRONT): RED HERO HEADER & HOUSING ILLUSTRATION
              // AnimatedBuilder smoothly contracts hero into compact Home header
              // =======================================================
              SlideTransition(
                position: _heroSlideAnim,
                child: AnimatedBuilder(
                  animation: _transitionController,
                  builder: (context, _) {
                    final heroInitialHeight = topSafePadding + 195.0;
                    final heroCompactHeight = _targetRole == AppRole.developer
                        ? (topSafePadding + 96.0)
                        : (topSafePadding + 70.0);
                    final heroHeight = _isTransitioning
                        ? ui.lerpDouble(
                            heroInitialHeight,
                            heroCompactHeight,
                            _heroShrinkAnim.value,
                          )
                        : null;
                    final heroRadius = _isTransitioning
                        ? _heroRadiusAnim.value
                        : 38.0;

                    return Container(
                      width: double.infinity,
                      height: heroHeight,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(heroRadius),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x38881337),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            _isTransitioning
                                ? ui.lerpDouble(10, 16, _heroShrinkAnim.value)!
                                : 10,
                            20,
                            _isTransitioning
                                ? ui.lerpDouble(26, 0, _heroShrinkAnim.value)!
                                : 26,
                          ),
                          child: Stack(
                                children: [
                                  // 1. LOGIN HERO CONTENT (Dissolves smoothly on transition)
                                  FadeTransition(
                                    opacity: _isTransitioning
                                        ? _loginBrandFadeOutAnim
                                        : const AlwaysStoppedAnimation(1.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Hero Top Row: Disperwaskim chip (No replay button!)
                                        FadeTransition(
                                          opacity: _isTransitioning
                                              ? _topChipFadeOutAnim
                                              : _topRowFadeAnim,
                                          child: SlideTransition(
                                            position: _topRowSlideAnim,
                                            child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.20),
                                        width: 1,
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Glowing pulse dot
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFBBF24),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0x88FBBF24),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          const Text(
                                            'KOTA TASIKMALAYA',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFFDE68A),
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.4),
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'DISPERWASKIM',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Integrated Branding & Housing Illustration Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Left branding column (No V2, No verification chip!)
                                  Expanded(
                                    child: FadeTransition(
                                      opacity: _brandFadeAnim,
                                      child: SlideTransition(
                                        position: _brandSlideAnim,
                                        child: GestureDetector(
                                          onLongPress: _showDemoSheet,
                                          child: const Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'SATU RUMAH',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTextStyles.fontFamily,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    letterSpacing: 0.2,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Layanan Perumahan Terpadu Kota Tasikmalaya',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTextStyles.fontFamily,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFFFEE2E2),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Right Housing Illustration (Clean, Spaced, Settle Motion)
                                  SlideTransition(
                                    position: _housingSlideAnim,
                                    child: ScaleTransition(
                                      scale: _housingScaleAnim,
                                      child: FadeTransition(
                                        opacity: _isTransitioning
                                            ? _illustrationFadeOutAnim
                                            : _housingFadeAnim,
                                        child: AnimatedBuilder(
                                          animation: _entranceController,
                                          builder: (context, _) {
                                            return SizedBox(
                                              width: 155,
                                              height: 100,
                                              child: CustomPaint(
                                                painter: HousingClusterPainter(
                                                  hillsProgress:
                                                      _hillsAnim.value,
                                                  treesProgress:
                                                      _treesAnim.value,
                                                  house1Progress:
                                                      _house1Anim.value,
                                                  house2Progress:
                                                      _house2Anim.value,
                                                  house3Progress:
                                                      _house3Anim.value,
                                                  roadProgress:
                                                      _roadAnim.value,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 2. HOME COMPACT HEADER (Fades in & scales gently into place)
                        if (_isTransitioning)
                          FadeTransition(
                            opacity: _homeHeaderFadeInAnim,
                            child: ScaleTransition(
                              scale: _homeHeaderScaleAnim,
                              child: _buildHomeCompactHeader(context, _targetRole),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
  ],
),
),
),
);
  }

  // =========================================================================
  // HOME TRANSITION PREVIEW BUILDERS (Pixel-perfect matching Home screens)
  // =========================================================================

  Widget _buildHomeCompactHeader(BuildContext context, AppRole role) {
    if (role == AppRole.developer) {
      final username = _usernameController.text.trim();
      final String avatarLabel = username.isNotEmpty
          ? (username.length >= 2
              ? username.substring(0, 2).toUpperCase()
              : username.toUpperCase())
          : 'DA';

      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Satu Rumah',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PORTAL PENGEMBANG',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOnRedSubtle,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  avatarLabel,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Role: Pengawas Lapangan
      final dateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.8,
                  ),
                ),
                const Text(
                  'SATU RUMAH',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      );
    }
  }

  Widget _buildHomeDashboardPreview(BuildContext context, AppRole role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. FIRST HOME CARD (Overlaps bottom of compact header)
        FadeTransition(
          opacity: _card1FadeInAnim,
          child: SlideTransition(
            position: _card1SlideUpAnim,
            child: role == AppRole.developer
                ? _buildDeveloperCard1Preview()
                : _buildInspectorCard1Preview(),
          ),
        ),

        const SizedBox(height: 12),

        // 2. SUBSEQUENT DASHBOARD CONTENT
        FadeTransition(
          opacity: _dashboardContentFadeAnim,
          child: SlideTransition(
            position: _dashboardContentSlideAnim,
            child: role == AppRole.developer
                ? _buildDeveloperSubsequentPreview()
                : _buildInspectorSubsequentPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard1Preview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFEE2E2),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: AppColors.primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PT. Tasik Indah Sentosa',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'ID Pengembang: Dev-2026-082',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Terverifikasi',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorCard1Preview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.champagneToast,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('RH', style: AppTextStyles.titleMedium),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Drs. Rian Hidayat, M.Si',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ketua Tim Monitoring & Evaluasi Disperwaskim',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.statusSuccessSurface,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Text(
                      '● Tim Perwaskim Lapangan',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperSubsequentPreview() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PengajuanTerakhirCard(
          projectName: 'Perumahan Green Tasik',
          regNumber: 'REG-2026-0142',
        ),
        SizedBox(height: 18),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Layanan Pengembang',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                '4 Layanan',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorSubsequentPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode Pengujian Data Lapangan Aktif',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.actionPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+ Tambah Laporan Baru',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Catat hasil inspeksi hari ini',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavPreview(AppRole role) {
    if (role == AppRole.developer) {
      return Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomItemPreview('Beranda', Icons.home_rounded, true),
                  _buildBottomItemPreview('Pengajuan', Icons.assignment_outlined, false),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x38B91C1C),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomItemPreview('Notifikasi', Icons.notifications_none_rounded, false),
                  _buildBottomItemPreview('Profil', Icons.person_outline_rounded, false),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomItemPreview('Beranda', Icons.home, true),
            _buildBottomItemPreview('Riwayat', Icons.assignment_turned_in_outlined, false),
            _buildBottomItemPreview('Profil', Icons.person_outline, false),
          ],
        ),
      );
    }
  }

  Widget _buildBottomItemPreview(String label, IconData icon, bool isActive) {
    final color = isActive ? AppColors.primaryRed : AppColors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk merekonstruksi Cluster Perumahan 2.5D Isometric secara rapi & tidak bertumpuk.
class HousingClusterPainter extends CustomPainter {
  final double hillsProgress;
  final double treesProgress;
  final double house1Progress;
  final double house2Progress;
  final double house3Progress;
  final double roadProgress;

  HousingClusterPainter({
    this.hillsProgress = 1.0,
    this.treesProgress = 1.0,
    this.house1Progress = 1.0,
    this.house2Progress = 1.0,
    this.house3Progress = 1.0,
    this.roadProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scaleX = size.width / 200.0;
    final scaleY = size.height / 120.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.translate(size.width - 200.0 * scale, size.height - 120.0 * scale);
    canvas.scale(scale, scale);

    // 1. Soft Landscape Background Hills
    if (hillsProgress > 0) {
      final hillPaint = Paint()
        ..color = const Color(0xFF650C26).withOpacity(0.55 * hillsProgress)
        ..style = PaintingStyle.fill;
      final hillPath = Path()
        ..moveTo(0, 110)
        ..quadraticBezierTo(60, 84, 130, 96)
        ..quadraticBezierTo(170, 102, 200, 108)
        ..lineTo(200, 120)
        ..lineTo(0, 120)
        ..close();
      canvas.drawPath(hillPath, hillPaint);
    }

    // 2. Beautifully Spaced Trees
    if (treesProgress > 0) {
      _paintTrees(canvas, treesProgress);
    }

    // 3. House 1 (Left - Setback Home)
    if (house1Progress > 0) {
      canvas.save();
      final dy = (1.0 - house1Progress) * 10.0;
      canvas.translate(16, 46 + dy);
      canvas.scale(0.65);
      _paintHouse1(canvas, house1Progress);
      canvas.restore();
    }

    // 4. House 2 (Center Main - 2.5D Isometric Architecture)
    if (house2Progress > 0) {
      canvas.save();
      final dy = (1.0 - house2Progress) * 14.0;
      canvas.translate(62, 34 + dy);
      canvas.scale(0.82);
      _paintHouse2(canvas, house2Progress);
      canvas.restore();
    }

    // 5. House 3 (Right - Adjoining Modern Villa)
    if (house3Progress > 0) {
      canvas.save();
      final dy = (1.0 - house3Progress) * 12.0;
      canvas.translate(132, 44 + dy);
      canvas.scale(0.72);
      _paintHouse3(canvas, house3Progress);
      canvas.restore();
    }

    // 6. Clean Curved Road (Passing underneath without collision)
    if (roadProgress > 0) {
      _paintRoad(canvas, roadProgress);
    }

    canvas.restore();
  }

  void _paintTrees(Canvas canvas, double progress) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF78350F).withOpacity(progress)
      ..style = PaintingStyle.fill;

    // Tree 1 (Far Left - clear of House 1)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 88, 3, 14),
        const Radius.circular(1.5),
      ),
      trunkPaint,
    );
    final treeGrad1 = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF34D399), Color(0xFF059669)],
    ).createShader(const Rect.fromLTWH(0, 68, 22, 22));
    final foliage1 = Paint()
      ..shader = treeGrad1
      ..color = Colors.white.withOpacity(0.95 * progress);
    canvas.drawCircle(const Offset(9.5, 78), 11 * progress, foliage1);

    // Tree 2 (Center Background between House 1 & 2)
    final foliage2 = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.85 * progress);
    canvas.drawCircle(const Offset(56, 54), 8 * progress, foliage2);

    // Tree 3 (Right Perimeter - clear of House 3)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(184, 82, 3.5, 16),
        const Radius.circular(1.5),
      ),
      trunkPaint,
    );
    final treeGrad3 = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF34D399), Color(0xFF059669)],
    ).createShader(const Rect.fromLTWH(172, 58, 26, 26));
    final foliage3 = Paint()
      ..shader = treeGrad3
      ..color = Colors.white.withOpacity(0.95 * progress);
    canvas.drawCircle(const Offset(185, 72), 13 * progress, foliage3);

    // Tree 4 (Right Small Front Bush)
    final foliage4 = Paint()
      ..color = const Color(0xFF059669).withOpacity(0.80 * progress);
    canvas.drawCircle(const Offset(172, 84), 7 * progress, foliage4);
  }

  void _paintHouse1(Canvas canvas, double progress) {
    final opacity = progress.clamp(0.0, 1.0);
    // Wall
    final wallShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    ).createShader(const Rect.fromLTWH(0, 18, 60, 60));
    final wallPaint = Paint()
      ..shader = wallShader
      ..color = Colors.white.withOpacity(opacity);
    final wallPath = Path()
      ..moveTo(30, 18)
      ..lineTo(60, 38)
      ..lineTo(60, 78)
      ..lineTo(0, 78)
      ..lineTo(0, 38)
      ..close();
    canvas.drawPath(wallPath, wallPaint);

    // Gable Roof
    final roofPaint = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(30, 8)
      ..lineTo(66, 36)
      ..lineTo(56, 40)
      ..lineTo(30, 20)
      ..lineTo(4, 40)
      ..lineTo(-6, 36)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Window
    final winPaint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 46, 14, 16),
        const Radius.circular(2),
      ),
      winPaint,
    );
  }

  void _paintHouse2(Canvas canvas, double progress) {
    final opacity = progress.clamp(0.0, 1.0);

    // Isometric Side Wall
    final sideWallShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(const Rect.fromLTWH(58, 24, 28, 60));
    final sideWallPaint = Paint()
      ..shader = sideWallShader
      ..color = Colors.white.withOpacity(opacity);
    final sideWallPath = Path()
      ..moveTo(58, 38)
      ..lineTo(86, 24)
      ..lineTo(86, 72)
      ..lineTo(58, 84)
      ..close();
    canvas.drawPath(sideWallPath, sideWallPaint);

    // Front Wall
    final frontWallShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    ).createShader(const Rect.fromLTWH(0, 16, 58, 68));
    final frontWallPaint = Paint()
      ..shader = frontWallShader
      ..color = Colors.white.withOpacity(opacity);
    final frontWallPath = Path()
      ..moveTo(28, 16)
      ..lineTo(58, 38)
      ..lineTo(58, 84)
      ..lineTo(0, 84)
      ..lineTo(0, 38)
      ..close();
    canvas.drawPath(frontWallPath, frontWallPaint);

    // Main Gable Roof
    final gableShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    ).createShader(const Rect.fromLTWH(-5, 5, 70, 35));
    final gablePaint = Paint()
      ..shader = gableShader
      ..color = Colors.white.withOpacity(opacity);
    final gablePath = Path()
      ..moveTo(28, 5)
      ..lineTo(63, 33)
      ..lineTo(58, 38)
      ..lineTo(28, 16)
      ..lineTo(0, 38)
      ..lineTo(-5, 33)
      ..close();
    canvas.drawPath(gablePath, gablePaint);

    // Side Roof Plane
    final roofRedShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFECDD3), Color(0xFFFDA4AF)],
    ).createShader(const Rect.fromLTWH(28, -5, 62, 38));
    final roofRedPaint = Paint()
      ..shader = roofRedShader
      ..color = Colors.white.withOpacity(opacity);
    final roofRedPath = Path()
      ..moveTo(28, 5)
      ..lineTo(63, 33)
      ..lineTo(91, 19)
      ..lineTo(56, -5)
      ..close();
    canvas.drawPath(roofRedPath, roofRedPaint);

    // Door (#B91C1C)
    final doorPaint = Paint()
      ..color = const Color(0xFFB91C1C).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 50, 13, 34),
        const Radius.circular(2),
      ),
      doorPaint,
    );

    // Window (#38BDF8)
    final winPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 48, 19, 17),
        const Radius.circular(2.5),
      ),
      winPaint,
    );

    // Window cross divider
    final divPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(40.5, 48), const Offset(40.5, 65), divPaint);

    // Pathway curb
    final curbPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 81, 20, 3),
        const Radius.circular(1.5),
      ),
      curbPaint,
    );
  }

  void _paintHouse3(Canvas canvas, double progress) {
    final opacity = progress.clamp(0.0, 1.0);

    // Side wall
    final sideShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(const Rect.fromLTWH(35, 20, 25, 55));
    final sidePaint = Paint()
      ..shader = sideShader
      ..color = Colors.white.withOpacity(opacity);
    final sidePath = Path()
      ..moveTo(35, 34)
      ..lineTo(58, 20)
      ..lineTo(58, 64)
      ..lineTo(35, 76)
      ..close();
    canvas.drawPath(sidePath, sidePaint);

    // Front wall
    final frontShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    ).createShader(const Rect.fromLTWH(0, 14, 35, 62));
    final frontPaint = Paint()
      ..shader = frontShader
      ..color = Colors.white.withOpacity(opacity);
    final frontPath = Path()
      ..moveTo(17, 14)
      ..lineTo(35, 34)
      ..lineTo(35, 76)
      ..lineTo(0, 76)
      ..lineTo(0, 34)
      ..close();
    canvas.drawPath(frontPath, frontPaint);

    // Gable roof
    final gablePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final gablePath = Path()
      ..moveTo(17, 7)
      ..lineTo(39, 29)
      ..lineTo(35, 34)
      ..lineTo(17, 14)
      ..lineTo(0, 34)
      ..lineTo(-4, 29)
      ..close();
    canvas.drawPath(gablePath, gablePaint);

    // Side roof
    final roofShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFECDD3), Color(0xFFFDA4AF)],
    ).createShader(const Rect.fromLTWH(17, -5, 45, 34));
    final roofPaint = Paint()
      ..shader = roofShader
      ..color = Colors.white.withOpacity(opacity);
    final roofPath = Path()
      ..moveTo(17, 7)
      ..lineTo(39, 29)
      ..lineTo(62, 17)
      ..lineTo(40, -5)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Window
    final winPaint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.85 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 44, 11, 18),
        const Radius.circular(2),
      ),
      winPaint,
    );
  }

  void _paintRoad(Canvas canvas, double progress) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.85 * progress)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(0, 114)
      ..quadraticBezierTo(100, 108, 200, 112);

    for (final metric in roadPath.computeMetrics()) {
      double distance = 0.0;
      const double dashWidth = 6.0;
      const double dashSpace = 6.0;
      final maxDistance = metric.length * progress;
      while (distance < maxDistance) {
        final next = (distance + dashWidth).clamp(0.0, maxDistance);
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, roadPaint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(HousingClusterPainter oldDelegate) {
    return oldDelegate.hillsProgress != hillsProgress ||
        oldDelegate.treesProgress != treesProgress ||
        oldDelegate.house1Progress != house1Progress ||
        oldDelegate.house2Progress != house2Progress ||
        oldDelegate.house3Progress != house3Progress ||
        oldDelegate.roadProgress != roadProgress;
  }
}
