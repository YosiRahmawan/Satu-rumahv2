import 'package:flutter/material.dart';

/// Pesan singkat melayang di atas bilah bawah (dan tombol tengah): kartu gelap bersudut membulat
/// dengan ikon, menggantikan SnackBar bawaan yang lebar penuh dan tertutup tombol kamera.
void showAppToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  bool error = false,
}) {
  final warna = error ? const Color(0xFFF87171) : const Color(0xFF34D399);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 104),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(error ? Icons.error_rounded : icon, color: warna, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
