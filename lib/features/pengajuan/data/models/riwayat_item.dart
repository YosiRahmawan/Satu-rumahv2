/// Satu baris riwayat aktivitas pengajuan dari server.
class RiwayatItem {
  const RiwayatItem({
    required this.type,
    required this.title,
    this.description,
    this.actor,
    this.createdAt,
  });

  final String type;
  final String title;
  final String? description;
  final String? actor;
  final DateTime? createdAt;

  factory RiwayatItem.fromJson(Map<String, dynamic> json) => RiwayatItem(
    type: '${json['type'] ?? ''}',
    title: '${json['title'] ?? ''}',
    description: json['description'] as String?,
    actor: json['actor'] as String?,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
  );

  bool get ditolak =>
      type == 'decided' && title.toLowerCase().contains('ditolak');
}
