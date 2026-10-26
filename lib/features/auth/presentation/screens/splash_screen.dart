import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Premium Motion Animation Splash Screen untuk SATU RUMAH V2.
/// Memadukan logo line-art reveal, smooth brand typography slide-up,
/// accent line reveal, serta transisi penutup yang elegan.
class SplashScreen extends StatefulWidget {
  final Duration duration;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation A — Logo Rumah (0 - 800ms)
  late final Animation<double> _logoRevealAnim;
  late final Animation<double> _logoFadeAnim;
  late final Animation<double> _logoScaleAnim;

  // Animation B — SATU RUMAH & Garis Kuning (600 - 1250ms)
  late final Animation<double> _titleFadeAnim;
  late final Animation<double> _titleSlideAnim;
  late final Animation<double> _linesExpandAnim;
  late final Animation<double> _linesFadeAnim;

  // Animation C — Subtitle (1150 - 1600ms)
  late final Animation<double> _subtitleFadeAnim;
  late final Animation<double> _subtitleSlideAnim;

  // Animation D — Final Transition Exit (2250 - 2600ms)
  late final Animation<double> _exitFadeAnim;

  bool _hasNavigated = false;
  bool _reducedMotionHandled = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _setupAnimationTimeline();

    _controller.forward();
    _navigationTimer = Timer(widget.duration, _navigateNext);
  }

  void _setupAnimationTimeline() {
    // Phase A: Logo Rumah (~800ms, Curves.easeOutCubic)
    _logoRevealAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 800 / 2600, curve: Curves.easeOutCubic),
    );
    _logoFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 500 / 2600, curve: Curves.easeOut),
    );
    _logoScaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 800 / 2600, curve: Curves.easeOutCubic),
      ),
    );

    // Phase B: SATU RUMAH Title & Yellow Lines (~650ms)
    _titleFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(600 / 2600, 1250 / 2600, curve: Curves.easeOut),
    );
    _titleSlideAnim = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          600 / 2600,
          1250 / 2600,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _linesExpandAnim = Tween<double>(begin: 0.0, end: 24.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          650 / 2600,
          1250 / 2600,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _linesFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(650 / 2600, 1050 / 2600, curve: Curves.easeOut),
    );

    // Phase C: Subtitle (~450ms)
    _subtitleFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(1150 / 2600, 1600 / 2600, curve: Curves.easeOut),
    );
    _subtitleSlideAnim = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          1150 / 2600,
          1600 / 2600,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // Phase D: Final Transition Out (2250ms - 2600ms)
    _exitFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(2250 / 2600, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefersReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (prefersReducedMotion && !_reducedMotionHandled) {
      _reducedMotionHandled = true;
      // Skip entrance motion straight to fully-assembled brand lockup
      _controller.value = 0.85;
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 350));
    }
  }

  void _navigateNext() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      _navigationTimer?.cancel();
      _navigationTimer = null;
      _controller.stop();

      // Periksa sesi pengguna jika ProviderScope tersedia (Riverpod session guard)
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final session = container.read(roleSessionProvider);
        if (session.isAuthenticated) {
          context.go(session.role.homeRoute);
          return;
        }
        if (container.read(apiEnabledProvider)) {
          _restoreSession(container);
          return;
        }
      } catch (_) {
        // Fallback jika ProviderScope belum ada di hierarki (misal testing)
      }

      context.go('/login');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _controller.dispose();
    super.dispose();
  }

  /// Mode API: pulihkan sesi dari token tersimpan; gagal atau kedaluwarsa → login.
  Future<void> _restoreSession(ProviderContainer container) async {
    try {
      final result = await container.read(authRepositoryProvider).restore();
      if (!mounted) return;
      if (result != null) {
        container
            .read(roleSessionProvider.notifier)
            .signIn(
              result.user.role,
              username: result.user.username,
              mustChangePassword: result.mustChangePassword,
            );
        context.go(
          result.mustChangePassword
              ? '/ganti-sandi'
              : result.user.role.homeRoute,
        );
        return;
      }
    } catch (_) {
      // Tidak ada jaringan: token tetap tersimpan, masuk lagi manual.
    }
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateNext,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryRed, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _exitFadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animation A: Logo Rumah Mask Reveal & Subtle Scale
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _logoFadeAnim,
                              child: Transform.scale(
                                scale: _logoScaleAnim.value,
                                child: ClipRect(
                                  clipper: _HorizontalMaskRevealClipper(
                                    _logoRevealAnim.value,
                                  ),
                                  child: SizedBox(
                                    width: 196,
                                    child: Image.asset(
                                      'assets/images/splash_logo_icon.png',
                                      width: 196,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const SizedBox(
                                              width: 196,
                                              height: 46,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // Animation B: SATU RUMAH Title + Expanding Gold Lines
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final lineWidth = _linesExpandAnim.value;
                            final spacing =
                                12.0 * (lineWidth / 24.0).clamp(0.0, 1.0);

                            return Transform.translate(
                              offset: Offset(0, _titleSlideAnim.value),
                              child: Opacity(
                                opacity: _titleFadeAnim.value,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Garis dekoratif kiri
                                    Opacity(
                                      opacity: _linesFadeAnim.value,
                                      child: Container(
                                        width: lineWidth,
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5A823),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing),

                                    // Tulisan SATU RUMAH
                                    const Text(
                                      'SATU RUMAH',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(width: spacing),

                                    // Garis dekoratif kanan
                                    Opacity(
                                      opacity: _linesFadeAnim.value,
                                      child: Container(
                                        width: lineWidth,
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5A823),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Animation C: Subtitle Fade-in & Gentle Slide-up
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _subtitleSlideAnim.value),
                              child: Opacity(
                                opacity: _subtitleFadeAnim.value,
                                child: const Text(
                                  'Sistem Layanan Terpadu Perumahan di Kota\nTasikmalaya',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom clipper untuk unmasking logo PNG secara horizontal dari kiri ke kanan.
class _HorizontalMaskRevealClipper extends CustomClipper<Rect> {
  final double progress;

  const _HorizontalMaskRevealClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width * progress.clamp(0.0, 1.0),
      size.height,
    );
  }

  @override
  bool shouldReclip(_HorizontalMaskRevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
