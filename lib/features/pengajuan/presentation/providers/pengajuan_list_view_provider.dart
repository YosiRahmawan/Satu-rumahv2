import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pengajuan_model.dart';
import '../../data/models/status_tahap_pengajuan.dart';
import 'pengajuan_form_controller.dart';

enum PengajuanFilter {
  semua('Semua'),
  menungguVerifikasi('Menunggu Verifikasi Perbaikan'),
  perbaikan('Perlu Perbaikan'),
  proses('Dalam Proses'),
  selesai('Disetujui');

  const PengajuanFilter(this.label);
  final String label;

  bool matches(Pengajuan item) => switch (this) {
    semua => true,
    menungguVerifikasi =>
      item.status.toLowerCase() == 'menunggu verifikasi perbaikan' ||
          (item.revisionSubmitted &&
              item.statusTahap != StatusTahapPengajuan.selesai &&
              item.status.toLowerCase() != 'dalam proses'),
    perbaikan =>
      item.statusTahap == StatusTahapPengajuan.perluPerbaikan &&
          !item.revisionSubmitted &&
          item.status.toLowerCase() != 'menunggu verifikasi perbaikan',
    selesai => item.statusTahap == StatusTahapPengajuan.selesai,
    proses =>
      item.statusTahap != StatusTahapPengajuan.perluPerbaikan &&
          item.statusTahap != StatusTahapPengajuan.selesai &&
          item.status.toLowerCase() != 'menunggu verifikasi perbaikan' &&
          !item.revisionSubmitted,
  };
}

enum PengajuanSort {
  terbaru('Terbaru'),
  terlama('Terlama');

  const PengajuanSort(this.label);
  final String label;
}

DateTime parsePengajuanDate(String tanggal) {
  final matchYear = RegExp(r'\b(19|20)\d{2}\b').firstMatch(tanggal);
  final year = matchYear != null ? int.tryParse(matchYear.group(0)!) ?? 2026 : 2026;

  final lower = tanggal.toLowerCase();
  int month = 1;
  if (lower.contains('jan')) {
    month = 1;
  } else if (lower.contains('feb')) {
    month = 2;
  } else if (lower.contains('mar')) {
    month = 3;
  } else if (lower.contains('apr')) {
    month = 4;
  } else if (lower.contains('mei') || lower.contains('may')) {
    month = 5;
  } else if (lower.contains('jun')) {
    month = 6;
  } else if (lower.contains('jul')) {
    month = 7;
  } else if (lower.contains('agu') || lower.contains('aug')) {
    month = 8;
  } else if (lower.contains('sep')) {
    month = 9;
  } else if (lower.contains('okt') || lower.contains('oct')) {
    month = 10;
  } else if (lower.contains('nov')) {
    month = 11;
  } else if (lower.contains('des') || lower.contains('dec')) {
    month = 12;
  }

  final matchDay = RegExp(r'\b\d{1,2}\b').firstMatch(tanggal);
  final day = matchDay != null ? int.tryParse(matchDay.group(0)!) ?? 1 : 1;

  return DateTime(year, month, day);
}

String pengajuanMonthYear(Pengajuan item) {
  final dt = parsePengajuanDate(item.tanggal);
  const months = [
    'JANUARI',
    'FEBRUARI',
    'MARET',
    'APRIL',
    'MEI',
    'JUNI',
    'JULI',
    'AGUSTUS',
    'SEPTEMBER',
    'OKTOBER',
    'NOVEMBER',
    'DESEMBER',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
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
    this.sort = PengajuanSort.terbaru,
  });

  final String search;
  final PengajuanFilter filter;
  final int? year;
  final int limit;
  final PengajuanSort sort;
}

class PengajuanListQueryNotifier extends StateNotifier<PengajuanListQuery> {
  PengajuanListQueryNotifier() : super(const PengajuanListQuery());

  void search(String value) => state = PengajuanListQuery(
    search: value,
    filter: state.filter,
    year: state.year,
    limit: 3,
    sort: state.sort,
  );

  void filter(PengajuanFilter value) => state = PengajuanListQuery(
    search: state.search,
    filter: value,
    year: state.year,
    limit: state.limit,
    sort: state.sort,
  );

  void year(int? value) => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: value,
    limit: state.limit,
    sort: state.sort,
  );

  void toggleSort() => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: state.year,
    limit: state.limit,
    sort: state.sort == PengajuanSort.terbaru
        ? PengajuanSort.terlama
        : PengajuanSort.terbaru,
  );

  void setSort(PengajuanSort value) => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: state.year,
    limit: state.limit,
    sort: value,
  );

  void loadMore() => state = PengajuanListQuery(
    search: state.search,
    filter: state.filter,
    year: state.year,
    limit: state.limit + 3,
    sort: state.sort,
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
  final filtered = <Pengajuan>[];

  for (final item in items) {
    if (!query.filter.matches(item) ||
        (query.year != null && pengajuanYear(item) != query.year) ||
        !(item.namaPerumahan.toLowerCase().contains(search) ||
            item.id.toLowerCase().contains(search))) {
      continue;
    }
    filtered.add(item);
  }

  filtered.sort((a, b) {
    final dateA = parsePengajuanDate(a.tanggal);
    final dateB = parsePengajuanDate(b.tanggal);
    return query.sort == PengajuanSort.terbaru
        ? dateB.compareTo(dateA)
        : dateA.compareTo(dateB);
  });

  return filtered;
});
