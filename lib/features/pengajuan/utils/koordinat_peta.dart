/// Membaca koordinat dari tautan Google Maps atau teks "lintang, bujur".
/// Tautan pendek (maps.app.goo.gl) tidak bisa dibaca tanpa membukanya, jadi dikembalikan null.
({double lat, double lng})? parseKoordinat(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  const angka = r'(-?\d{1,3}(?:\.\d+)?)';
  final pola = [
    RegExp('@$angka,\\s*$angka'), // .../@-7.3274,108.2207,17z
    RegExp('[?&](?:q|query|ll|destination)=$angka(?:,|%2C)\\s*$angka'),
    RegExp('!3d$angka!4d$angka'), // data=!3d-7.32!4d108.22
    RegExp('^$angka\\s*[,; ]\\s*$angka\$'), // "-7.3274, 108.2207"
  ];
  for (final p in pola) {
    final m = p.firstMatch(text);
    if (m == null) continue;
    final lat = double.parse(m.group(1)!);
    final lng = double.parse(m.group(2)!);
    if (lat.abs() <= 90 && lng.abs() <= 180) return (lat: lat, lng: lng);
  }
  return null;
}
