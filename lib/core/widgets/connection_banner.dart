import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/remote_load.dart';
import '../theme/app_colors.dart';

/// Teks galat pemuatan yang bisa dipahami: beda antara tanpa sambungan,
/// server lambat, dan galat lain.
String loadErrorText(ApiException? e) {
  if (e == null) return 'Data belum dapat dimuat.';
  return switch (e.code) {
    'NETWORK' => 'Tidak ada sambungan internet.',
    'TIMEOUT' => 'Server terlalu lama menjawab.',
    _ => e.message,
  };
}

/// Pita peringatan di atas daftar yang datanya sudah ada tetapi gagal
/// diperbarui: menjelaskan penyebabnya dan menawarkan coba lagi.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final ApiException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: Color(0xFFB45309),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${loadErrorText(error)} Menampilkan data terakhir.',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                minimumSize: const Size(48, 40),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner yang hanya tampil bila pemuatan gagal; dipasang di atas daftar yang
/// sudah punya data.
class LoadFailedBanner extends StatelessWidget {
  const LoadFailedBanner({
    super.key,
    required this.load,
    required this.hasData,
    required this.onRetry,
  });

  final ValueNotifier<RemoteLoad> load;
  final bool hasData;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RemoteLoad>(
      valueListenable: load,
      builder: (context, value, _) => value.isFailed && hasData
          ? ConnectionBanner(error: value.error, onRetry: onRetry)
          : const SizedBox.shrink(),
    );
  }
}

/// Memberi tahu bahwa tarik-untuk-muat-ulang gagal (sebelumnya diam saja).
void showRefreshError(BuildContext context, ApiException? error) {
  if (error == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('${loadErrorText(error)} Data tidak diperbarui.')),
    );
}
