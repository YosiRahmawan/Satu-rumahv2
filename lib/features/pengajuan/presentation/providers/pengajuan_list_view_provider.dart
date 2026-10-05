import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import 'pengajuan_form_controller.dart';

enum PengajuanFilter {
  semua('Semua'),
  perbaikan('Perlu Perbaikan'),
  proses('Dalam Proses'),
  selesai('Disetujui');

  const PengajuanFilter(this.label);
  final String label;

  bool matches(Pengajuan item) => switch (this) {
    semua => true,
    perbaikan => item.statusTahap == StatusTahapPengajuan.perluPerbaikan,
    selesai => item.statusTahap == StatusTahapPengajuan.selesai,
    proses =>
      item.statusTahap != StatusTahapPengajuan.perluPerbaikan &&
          item.statusTahap != StatusTahapPengajuan.selesai,
  };
}

/// Dates in the local prototype are display strings, sometimes with a time.
/// Unknown dates stay in an explicit group instead of borrowing the ID's year.
int? pengajuanYear(Pengajuan item) {
  final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(item.tanggal);
  return match == null ? null : int.tryParse(match.group(0)!);
}

class PengajuanListQuery {
  const PengajuanListQuery({
    this.search = '',
    this.filter = PengajuanFilter.semua,
    this.year,
    this.limit = 3,
  });

  final String search;
  final PengajuanFilter filter;
  final int? year;
  final int limit;
}

class PengajuanListQueryNotifier extends StateNotifier<PengajuanListQuery> {
  PengajuanListQueryNotifier() : super(const PengajuanListQuery());

  void search(String value) => state = PengajuanListQuery(
    search: value,
    filter: state.filter,
    year: state.year,
  );

  void filter(PengajuanFilter value) => state = PengajuanListQuery(
    search: state.search,
    filter: value,
    year: state.year,
  );

  void year(int? value) => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: value,
  );

  void loadMore() => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: state.year,
    limit: state.limit + 3,
  );

  void reset() => state = const PengajuanListQuery();
}

final pengajuanListQueryProvider =
    StateNotifierProvider.autoDispose<
      PengajuanListQueryNotifier,
      PengajuanListQuery
    >((ref) => PengajuanListQueryNotifier());

final filteredPengajuanProvider = Provider.autoDispose<List<Pengajuan>>((ref) {
  final items = ref.watch(pengajuanListProvider);
  final query = ref.watch(pengajuanListQueryProvider);
  final search = query.search.trim().toLowerCase();
  final groups = <int, List<Pengajuan>>{};
  for (final item in items) {
    if (!query.filter.matches(item) ||
        (query.year != null && pengajuanYear(item) != query.year) ||
        !(item.namaPerumahan.toLowerCase().contains(search) ||
            item.id.toLowerCase().contains(search))) {
      continue;
    }
    (groups[pengajuanYear(item) ?? 0] ??= []).add(item);
  }
  final years = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final year in years) ...groups[year]!];
});
