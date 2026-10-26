import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/auth/role_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Wajib dilewati saat server menandai kata sandi masih sementara
/// (`must_change_password`). Mengganti kata sandi mencabut token perangkat lain.
class GantiSandiScreen extends ConsumerStatefulWidget {
  const GantiSandiScreen({super.key});

  @override
  ConsumerState<GantiSandiScreen> createState() => _GantiSandiScreenState();
}

class _GantiSandiScreenState extends ConsumerState<GantiSandiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      ref.read(roleSessionProvider.notifier).passwordChanged();
      context.go(ref.read(roleSessionProvider).role.homeRoute);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _error = e.fields.values.expand((v) => v).firstOrNull ?? e.message,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel() async {
    await performLogout(ref);
    if (mounted) context.go('/login');
  }

  String? _validateNew(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Harus memuat huruf dan angka';
    }
    if (v == _current.text) {
      return 'Tidak boleh sama dengan kata sandi saat ini';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cardSurface,
        appBar: AppBar(
          title: const Text('Ganti Kata Sandi'),
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.cardSurface,
          foregroundColor: AppColors.textMain,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kata sandi Anda masih sementara. Buat kata sandi baru sebelum melanjutkan.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    _current,
                    'Kata sandi saat ini',
                    validator: (v) => (v ?? '').isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(_next, 'Kata sandi baru', validator: _validateNew),
                  const SizedBox(height: 14),
                  _field(
                    _confirm,
                    'Ulangi kata sandi baru',
                    validator: (v) => v != _next.text
                        ? 'Tidak sama dengan kata sandi baru'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Kata Sandi Baru'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _submitting ? null : _cancel,
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
