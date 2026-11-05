import 'package:url_launcher/url_launcher.dart';

/// Membuka aplikasi peta untuk alamat proyek. Dipisahkan agar mudah diganti pada tes.
typedef MapsLauncher = Future<bool> Function(String alamat);

Future<bool> bukaDiPeta(String alamat) => launchUrl(
  Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': alamat}),
  mode: LaunchMode.externalApplication,
);
