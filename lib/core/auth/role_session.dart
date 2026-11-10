import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/auth_token_store.dart';

/// The authenticated role.
enum AppRole { guest, developer, admin, perwaskim }

extension AppRoleX on AppRole {
  bool get isAuthenticated => this != AppRole.guest;

  String get label {
    switch (this) {
      case AppRole.guest:
        return 'Tamu';
      case AppRole.developer:
        return 'Pengembang';
      case AppRole.admin:
        return 'Admin Disperwaskim';
      case AppRole.perwaskim:
        return 'Tim Perwaskim';
    }
  }

  String get homeRoute {
    switch (this) {
      case AppRole.guest:
        return '/login';
      case AppRole.developer:
        return '/dashboard';
      case AppRole.admin:
        return '/admin';
      case AppRole.perwaskim:
        return '/monitoring/lapangan';
    }
  }
}

class RoleSessionState {
  final AppRole role;
  final String? username;

  const RoleSessionState({this.role = AppRole.guest, this.username});

  bool get isAuthenticated => role.isAuthenticated;

  RoleSessionState copyWith({AppRole? role, String? username}) {
    return RoleSessionState(
      role: role ?? this.role,
      username: username ?? this.username,
    );
  }
}

class RoleSessionNotifier extends StateNotifier<RoleSessionState> {
  RoleSessionNotifier() : super(const RoleSessionState());

  void signIn(AppRole role, {String? username}) {
    if (role == AppRole.guest) {
      signOut();
      return;
    }
    state = RoleSessionState(role: role, username: username);
  }

  AppRole signInFromUsername(String username) {
    final normalized = username.trim().toLowerCase();
    final role = roleForUsername(normalized);
    signIn(role, username: normalized.isEmpty ? null : normalized);
    return role;
  }

  void signOut() {
    state = const RoleSessionState();
    // Bersihkan token dari storage secara async jika runtime binding telah diinisialisasi
    try {
      const AuthTokenStore().clear();
    } catch (_) {
      // Abaikan jika dipanggil dalam isolated plain unit test tanpa ServicesBinding
    }
  }

  static AppRole roleForUsername(String username) {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return AppRole.guest;

    // Kredensial role demo hanya aktif dalam mode debug/test
    if (kDebugMode) {
      if (normalized == 'admin_disperwaskim' ||
          normalized.startsWith('admin')) {
        return AppRole.admin;
      }
      if (normalized == 'monitoring_perwaskim' ||
          normalized == 'perwaskim' ||
          normalized == 'petugas_lapangan' ||
          normalized.startsWith('tim_')) {
        return AppRole.perwaskim;
      }
    } else {
      // Pada release mode, hanya mapping eksak jika dibutuhkan
      if (normalized == 'admin_disperwaskim') {
        return AppRole.admin;
      }
      if (normalized == 'monitoring_perwaskim') {
        return AppRole.perwaskim;
      }
    }
    return AppRole.developer;
  }
}

final roleSessionProvider =
    StateNotifierProvider<RoleSessionNotifier, RoleSessionState>((ref) {
      return RoleSessionNotifier();
    });
