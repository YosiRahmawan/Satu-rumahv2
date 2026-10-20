import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'features/monitoring/data/repositories/monitoring_repository.dart';
import 'features/monitoring/data/repositories/monitoring_store.dart';
import 'features/monitoring/presentation/providers/monitoring_form_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);

  // Draf dan laporan monitoring dipulihkan dari penyimpanan perangkat. Bila
  // gagal dibaca, aplikasi tetap berjalan dengan data awal.
  final monitoringRepository = MonitoringRepository(
    store: const SharedPrefsMonitoringStore(),
  );
  try {
    await monitoringRepository.hydrate();
  } catch (error) {
    debugPrint('Gagal memulihkan draf monitoring: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        monitoringRepositoryProvider.overrideWithValue(monitoringRepository),
      ],
      child: const SatuRumahApp(),
    ),
  );
}
