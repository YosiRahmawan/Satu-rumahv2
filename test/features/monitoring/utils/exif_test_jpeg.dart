import 'dart:typed_data';

/// JPEG minimal berisi blok EXIF dengan GPS (7°19'38,64" LS, 108°13'14,52" BT).
Uint8List jpegWithGps() {
  final tiff = ByteData(128);
  void u16(int o, int v) => tiff.setUint16(o, v, Endian.little);
  void u32(int o, int v) => tiff.setUint32(o, v, Endian.little);
  // Header TIFF little-endian, IFD0 di offset 8.
  tiff.setUint8(0, 0x49);
  tiff.setUint8(1, 0x49);
  u16(2, 42);
  u32(4, 8);
  // IFD0: satu entri penunjuk GPS IFD (offset 26).
  u16(8, 1);
  u16(10, 0x8825);
  u16(12, 4);
  u32(14, 1);
  u32(18, 26);
  u32(22, 0);
  // GPS IFD: 4 entri.
  u16(26, 4);
  void entry(int index, int tag, int type, int count, int value) {
    final base = 28 + index * 12;
    u16(base, tag);
    u16(base + 2, type);
    u32(base + 4, count);
    u32(base + 8, value);
  }

  entry(0, 1, 2, 2, 0x53); // LatitudeRef "S"
  entry(1, 2, 5, 3, 80);
  entry(2, 3, 2, 2, 0x45); // LongitudeRef "E"
  entry(3, 4, 5, 3, 104);
  u32(76, 0);
  void rational(int offset, List<(int, int)> values) {
    for (var i = 0; i < values.length; i++) {
      u32(offset + i * 8, values[i].$1);
      u32(offset + i * 8 + 4, values[i].$2);
    }
  }

  rational(80, [(7, 1), (19, 1), (3864, 100)]);
  rational(104, [(108, 1), (13, 1), (1452, 100)]);

  final exifPayload = <int>[
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
    ...tiff.buffer.asUint8List(),
  ];
  final length = exifPayload.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, length >> 8, length & 0xFF,
    ...exifPayload,
    0xFF, 0xD9, // EOI
  ]);
}
