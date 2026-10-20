import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan laporan monitoring (draf dan final) di perangkat. Hanya
/// mengurus data mentah; pengubahan dari dan ke model dilakukan oleh
/// `MonitoringRepository`.
abstract class MonitoringStore {
  const MonitoringStore();

  Future<List<Map<String, dynamic>>> loadReports();

  Future<void> saveReports(List<Map<String, dynamic>> reports);
}

class SharedPrefsMonitoringStore extends MonitoringStore {
  const SharedPrefsMonitoringStore();

  static const _reportsKey = 'monitoring_reports_v1';

  @override
  Future<List<Map<String, dynamic>>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) item,
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveReports(List<Map<String, dynamic>> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportsKey, jsonEncode(reports));
  }
}

/// Penyimpanan di memori untuk tes.
class MemoryMonitoringStore extends MonitoringStore {
  List<Map<String, dynamic>> reports = [];

  @override
  Future<List<Map<String, dynamic>>> loadReports() async => [
    for (final r in reports) jsonDecode(jsonEncode(r)) as Map<String, dynamic>,
  ];

  @override
  Future<void> saveReports(List<Map<String, dynamic>> value) async {
    reports = [
      for (final r in value) jsonDecode(jsonEncode(r)) as Map<String, dynamic>,
    ];
  }
}
