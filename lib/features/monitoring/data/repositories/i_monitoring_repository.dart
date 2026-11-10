import '../models/monitoring_model.dart';

/// Contract repository untuk data monitoring (PSU Perumahan)
abstract class IMonitoringRepository {
  List<MonitoringModel> getAllMonitoring();

  MonitoringModel? getMonitoringById(String id);

  void addMonitoring(MonitoringModel item);

  List<MonitoringModel> searchMonitoring({
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  });
}

