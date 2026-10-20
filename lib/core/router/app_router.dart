import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/admin_main_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/monitoring/data/models/monitoring_model.dart';
import '../../features/monitoring/presentation/screens/laporan_preview_screen.dart';
import '../../features/monitoring/presentation/screens/laporan_success_screen.dart';
import '../../features/monitoring/presentation/screens/monitoring_list_screen.dart';
import '../../features/monitoring/presentation/screens/monitoring_draft_screen.dart';
import '../../features/monitoring/presentation/screens/monitoring_main_screen.dart';
import '../../features/monitoring/presentation/screens/tambah_monitoring_stepper_screen.dart';
import '../../features/monitoring/presentation/providers/monitoring_form_provider.dart';
import '../../features/notifikasi/presentation/screens/notifikasi_list_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_admin_detail_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_detail_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_step1_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_step2_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_step3_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_step4_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_step5_review_screen.dart';
import '../../features/pengajuan/presentation/screens/pengajuan_success_screen.dart';
import '../../features/pengajuan/presentation/screens/detail_perbarui_dokumen_screen.dart';
import '../../features/pengajuan/presentation/screens/jadwal_survey_screen.dart';
import '../../features/pengajuan/presentation/screens/perbarui_berkas_screen.dart';
import '../../features/pengajuan/presentation/screens/status_perbaikan_berkas_screen.dart';
import '../../features/pengajuan/presentation/screens/unduh_sk_ba_screen.dart';
import '../../features/pengajuan/presentation/screens/template_berkas_screen.dart';
import '../../features/bantuan/presentation/screens/pusat_bantuan_screen.dart';
import '../../features/profil/presentation/screens/tentang_aplikasi_screen.dart';
import '../auth/role_session.dart';
import 'route_policy.dart';
import '../widgets/route_feedback.dart';

export 'route_policy.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<RoleSessionState>(roleSessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/') {
        return '/splash';
      }
      return roleRouteRedirect(
        role: ref.read(roleSessionProvider).role,
        path: path,
      );
    },
    errorBuilder: (context, state) {
      final session = ref.read(roleSessionProvider);
      return RouteUnavailableScreen(
        title: 'Halaman tidak ditemukan',
        message: 'Tautan yang dibuka tidak tersedia atau sudah berubah.',
        safeDestination: session.isAuthenticated
            ? session.role.homeRoute
            : '/login',
        destinationLabel: session.isAuthenticated
            ? 'Kembali ke Beranda'
            : 'Ke Halaman Login',
      );
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/splash'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', redirect: (_, __) => '/login'),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: _withNotice(state, const DashboardScreen()),
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, state) =>
            _withNotice(state, const AdminMainScreen(initialIndex: 0)),
      ),
      GoRoute(
        path: '/admin/pengajuan',
        builder: (_, state) =>
            _withNotice(state, const AdminMainScreen(initialIndex: 1)),
      ),
      GoRoute(
        path: '/admin/pengajuan/detail/:id',
        builder: (_, state) =>
            PengajuanAdminDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/notifikasi',
        builder: (_, state) =>
            _withNotice(state, const AdminMainScreen(initialIndex: 3)),
      ),
      GoRoute(
        path: '/admin/profil',
        builder: (_, state) =>
            _withNotice(state, const AdminMainScreen(initialIndex: 4)),
      ),
      GoRoute(
        path: '/monitoring',
        builder: (_, state) =>
            _withNotice(state, const AdminMainScreen(initialIndex: 2)),
      ),
      GoRoute(
        path: '/monitoring/lapangan',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: Duration.zero,
          child: _withNotice(
            state,
            const MonitoringMainScreen(initialIndex: 0),
          ),
          // Memudar dari layar sebelumnya (mis. login) agar tidak terasa
          // terpotong.
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/monitoring/lapangan/riwayat',
        builder: (context, __) => MonitoringListScreen(
          showBottomNav: false,
          onBack: () => context.canPop()
              ? context.pop()
              : context.go('/monitoring/lapangan'),
        ),
      ),
      GoRoute(
        path: '/monitoring/lapangan/profil',
        builder: (_, state) =>
            _withNotice(state, const MonitoringMainScreen(initialIndex: 2)),
      ),
      GoRoute(
        path: '/monitoring/lapangan/notifikasi',
        builder: (_, state) => _withNotice(state, const NotifikasiListScreen()),
      ),
      GoRoute(
        path: '/monitoring/draft',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is MonitoringModel) {
            return MonitoringDraftScreen(monitoring: extra);
          }
          if (extra is Map && extra['model'] is MonitoringModel) {
            return MonitoringDraftScreen(
              monitoring: extra['model'] as MonitoringModel,
            );
          }
          final id =
              state.uri.queryParameters['id'] ?? (extra is String ? extra : null);
          if (id != null) {
            final repo = ref.read(monitoringRepositoryProvider);
            final item = repo.getMonitoringById(id);
            if (item != null) {
              return MonitoringDraftScreen(monitoring: item);
            }
          }
          final role = ref.read(roleSessionProvider).role;
          return RouteUnavailableScreen(
            title: 'Draft monitoring tidak tersedia',
            message:
                'Data draft monitoring tidak ditemukan. Silakan buka kembali dari daftar monitoring.',
            safeDestination: monitoringFailureDestination(role),
            destinationLabel: monitoringFailureDestinationLabel(role),
          );
        },
      ),
      GoRoute(
        path: '/monitoring/tambah',
        builder: (_, __) => const TambahMonitoringStepperScreen(),
      ),
      GoRoute(
        path: '/monitoring/success',
        builder: (_, state) {
          final item = state.extra;
          if (item is! MonitoringModel) {
            final role = ref.read(roleSessionProvider).role;
            return RouteUnavailableScreen(
              title: 'Laporan monitoring tidak tersedia',
              message:
                  'Laporan tidak dapat ditampilkan karena data hasil survey tidak ditemukan.',
              safeDestination: monitoringFailureDestination(role),
              destinationLabel: monitoringFailureDestinationLabel(role),
            );
          }
          return LaporanSuccessScreen(monitoring: item);
        },
      ),
      GoRoute(
        path: '/monitoring/preview',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is MonitoringModel) {
            return LaporanPreviewScreen(
              monitoring: extra,
              isDraft: extra.isDraft,
            );
          }
          if (extra is Map) {
            final model = extra['model'];
            final draft = extra['isDraft'];
            if (model is MonitoringModel && (draft == null || draft is bool)) {
              return LaporanPreviewScreen(
                monitoring: model,
                isDraft: draft as bool? ?? model.isDraft,
              );
            }
          }
          final role = ref.read(roleSessionProvider).role;
          return RouteUnavailableScreen(
            title: 'Preview laporan tidak tersedia',
            message:
                'Data draft atau laporan monitoring tidak ditemukan. Silakan buka kembali dari daftar monitoring.',
            safeDestination: monitoringFailureDestination(role),
            destinationLabel: monitoringFailureDestinationLabel(role),
          );
        },
      ),
      GoRoute(
        path: '/pengajuan/step1',
        builder: (_, __) => const PengajuanStep1Screen(),
      ),
      GoRoute(
        path: '/pengajuan/step2',
        builder: (_, __) => const PengajuanStep2Screen(),
      ),
      GoRoute(
        path: '/pengajuan/step3',
        builder: (_, __) => const PengajuanStep3Screen(),
      ),
      GoRoute(
        path: '/pengajuan/step4',
        builder: (_, __) => const PengajuanStep4Screen(),
      ),
      GoRoute(
        path: '/pengajuan/step5',
        builder: (_, __) => const PengajuanStep5ReviewScreen(),
      ),
      GoRoute(
        path: '/pengajuan/success',
        builder: (_, state) {
          final id = state.extra;
          if (id is! String || id.trim().isEmpty) {
            return const RouteUnavailableScreen(
              title: 'Pengajuan tidak tersedia',
              message:
                  'Nomor pengajuan tidak ditemukan. Buka daftar pengajuan untuk melanjutkan.',
              safeDestination: '/dashboard',
              destinationLabel: 'Kembali ke Pengajuan',
            );
          }
          return PengajuanSuccessScreen(pengajuanId: id);
        },
      ),
      GoRoute(
        path: '/pengajuan/detail/:id',
        builder: (_, state) =>
            PengajuanDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/pengajuan/perbarui-berkas/:id',
        builder: (_, state) =>
            PerbaruiBerkasScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/pengajuan/perbarui-berkas/:id/dokumen/:docKey',
        // Tanpa data dokumen layar ini hanya menampilkan contoh prototipe,
        // jadi akses langsung dialihkan ke daftar dokumen pengajuan.
        redirect: (_, state) => state.extra == null
            ? '/pengajuan/perbarui-berkas/${state.pathParameters['id'] ?? ''}'
            : null,
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? 'REG-2026-0142';
          final docKey = state.pathParameters['docKey'] ?? 'ktp';
          final extra = state.extra as Map<String, dynamic>?;
          return DetailPerbaruiDokumenScreen(
            pengajuanId: id,
            docKey: docKey,
            docData: extra,
          );
        },
      ),
      GoRoute(
        path: '/pengajuan/perbarui-berkas',
        builder: (_, state) {
          final id = (state.extra as String?) ?? 'REG-2026-0142';
          return PerbaruiBerkasScreen(id: id);
        },
      ),
      GoRoute(
        path: '/pengajuan/status-perbaikan/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? 'REG-2026-0142';
          return StatusPerbaikanBerkasScreen(pengajuanId: id);
        },
      ),
      GoRoute(
        path: '/jadwal-survey',
        builder: (_, state) =>
            _withNotice(state, const JadwalSurveyScreen()),
      ),
      GoRoute(
        path: '/unduh-sk-ba',
        builder: (_, state) => _withNotice(
          state,
          UnduhSkBaScreen(focusId: state.uri.queryParameters['id']),
        ),
      ),
      GoRoute(
        path: '/template-berkas',
        builder: (_, state) =>
            _withNotice(state, const TemplateBerkasScreen()),
      ),
      GoRoute(
        path: '/bantuan',
        builder: (_, state) =>
            _withNotice(state, const PusatBantuanScreen()),
      ),
      GoRoute(
        path: '/tentang',
        builder: (_, state) =>
            _withNotice(state, const TentangAplikasiScreen()),
      ),
    ],
  );
});

Widget _withNotice(GoRouterState state, Widget child) {
  return RouteNotice(
    message: state.uri.queryParameters['notice'],
    child: child,
  );
}
