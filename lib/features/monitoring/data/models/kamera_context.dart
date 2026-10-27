/// Konteks pembukaan Kamera Lapangan (Mandiri atau Terkait Tugas Survei).
class KameraContext {
  final bool isTaskFlow;
  final String? taskId;
  final String taskTitle;
  final String? nomorRegistrasi;

  const KameraContext({
    required this.isTaskFlow,
    this.taskId,
    required this.taskTitle,
    this.nomorRegistrasi,
  });

  const KameraContext.mandiri()
    : isTaskFlow = false,
      taskId = null,
      taskTitle = 'Dokumentasi Mandiri',
      nomorRegistrasi = null;

  const KameraContext.tugas({
    required this.taskId,
    required this.taskTitle,
    String? nomorRegistrasi,
  }) : isTaskFlow = true,
       nomorRegistrasi = nomorRegistrasi ?? taskId;

  /// Dibuka dari form yang sedang diisi (Langkah 3): foto masuk ke form aktif.
  const KameraContext.formAktif({required this.taskTitle})
    : isTaskFlow = true,
      taskId = null,
      nomorRegistrasi = null;

  bool get usesActiveForm => isTaskFlow && taskId == null;

  @override
  String toString() =>
      'KameraContext(isTaskFlow: $isTaskFlow, taskId: $taskId, taskTitle: $taskTitle, nomorRegistrasi: $nomorRegistrasi)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KameraContext &&
          runtimeType == other.runtimeType &&
          isTaskFlow == other.isTaskFlow &&
          taskId == other.taskId &&
          taskTitle == other.taskTitle &&
          nomorRegistrasi == other.nomorRegistrasi;

  @override
  int get hashCode =>
      isTaskFlow.hashCode ^
      taskId.hashCode ^
      taskTitle.hashCode ^
      nomorRegistrasi.hashCode;
}
