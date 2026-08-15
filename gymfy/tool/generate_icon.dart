// Draws Gymfy's app icon artwork and writes it out as PNG.
//
// Run from the project root:
//   dart run tool/generate_icon.dart
//
// Deliberately dependency-free: it writes PNG bytes by hand using only
// `dart:io`'s zlib. That keeps a one-off art step out of pubspec.yaml, and
// means the icon is reproducible source rather than a binary nobody can edit.
//
// Four files come out of it:
//   assets/icon/gymfy_icon.png            full-bleed square, dark plate + mark
//   assets/icon/gymfy_icon_foreground.png transparent, mark only, safe-zone
//                                         sized for an Android adaptive icon
//   assets/icon/gymfy_splash.png          centre image for the legacy splash
//   assets/icon/gymfy_splash_android12.png 1152px, mark inside the 768px circle
//                                         Android 12+ masks the splash icon to
//
// Edit the constants below to change the art, then re-run. After changing the
// art, re-run the two generators that consume these files:
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create

import 'dart:io';
import 'dart:typed_data';

/// Samples per pixel per axis. 4 means 16 coverage samples, which is enough to
/// hide stair-stepping on the rounded corners without being slow.
const samples = 4;

/// App background plate — the dark surface the theme already uses.
const plate = (r: 0x15, g: 0x18, b: 0x21);

/// The mark itself, in the default accent (AccentPalette.blue, 0xFF4F8CFF).
const mark = (r: 0x4F, g: 0x8C, b: 0xFF);

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Legacy launcher icon and store listing: shown full-bleed and uncropped, so
  // the mark can fill most of the plate. 1024px is what the store wants.
  _write('assets/icon/gymfy_icon.png', canvas: 1024, scale: 0.80, plated: true);

  // Adaptive icon foreground (Android 8+). Sized large on purpose: the launcher
  // masks the icon down to roughly the middle 66%, but flutter_launcher_icons
  // *also* wraps this drawable in a 16% inset, so the mark ends up at about
  // 0.83 x 0.68 = 56% of the icon — just inside the safe zone. Scaling this to
  // the safe zone here as well would double-shrink it to a speck.
  _write(
    'assets/icon/gymfy_icon_foreground.png',
    canvas: 1024,
    scale: 0.90,
    plated: false,
  );

  // Legacy splash: drawn centred at its own size over the splash colour, so it
  // needs no plate of its own and can run a little larger.
  _write(
    'assets/icon/gymfy_splash.png',
    canvas: 768,
    scale: 0.70,
    plated: false,
  );

  // Android 12+ splash: the image must be 1152px and the mark has to fit inside
  // a 768px circle, i.e. 384px of radius. The mark's furthest corner sits about
  // 472 design units out, so 0.78 leaves a little margin.
  _write(
    'assets/icon/gymfy_splash_android12.png',
    canvas: 1152,
    scale: 0.78,
    plated: false,
  );
}

/// A rounded rectangle in the 1024 design space, centred on the canvas.
///
/// Coordinates are the half-extents from centre, so the shapes below read as
/// "this wide, this tall", which is easier to nudge than raw edges.
class _Bar {
  const _Bar({
    required this.cx,
    required this.halfWidth,
    required this.halfHeight,
    required this.radius,
  });

  final double cx;
  final double halfWidth;
  final double halfHeight;
  final double radius;

  /// True when the point is inside the rounded rect. Corner rounding is the
  /// usual "shrink the box by the radius, then test distance" trick.
  bool contains(double x, double y) {
    final dx = (x - cx).abs() - (halfWidth - radius);
    final dy = y.abs() - (halfHeight - radius);
    if (dx <= 0 && dy <= 0) return true;
    if (dx > 0 && dy > 0) return dx * dx + dy * dy <= radius * radius;
    return dx <= 0 ? dy <= radius : dx <= radius;
  }
}

/// A barbell, read left to right: end cap, outer plate, inner plate, the bar
/// across the middle, then the same three mirrored.
///
/// A barbell rather than a monogram because it says "gym" at 48dp, where a
/// letter would just be a blue smudge.
const _shapes = <_Bar>[
  // The bar. Thick enough to still read as a bar at 48dp, where a hairline
  // would disappear into the background.
  _Bar(cx: 0, halfWidth: 470, halfHeight: 46, radius: 46),
  // Inner plates — the tallest pair, closest to the centre.
  _Bar(cx: -250, halfWidth: 50, halfHeight: 232, radius: 44),
  _Bar(cx: 250, halfWidth: 50, halfHeight: 232, radius: 44),
  // Outer plates, stepped down.
  _Bar(cx: -360, halfWidth: 42, halfHeight: 145, radius: 36),
  _Bar(cx: 360, halfWidth: 42, halfHeight: 145, radius: 36),
  // End caps.
  _Bar(cx: -448, halfWidth: 30, halfHeight: 82, radius: 28),
  _Bar(cx: 448, halfWidth: 30, halfHeight: 82, radius: 28),
];

/// Coverage of the mark at a pixel, 0..1, by supersampling.
double _coverage(int px, int py, int canvas, double scale) {
  var hits = 0;
  for (var sy = 0; sy < samples; sy++) {
    for (var sx = 0; sx < samples; sx++) {
      // Sample at sub-pixel centres, then move into the centred design space.
      final x = (px + (sx + 0.5) / samples - canvas / 2) / scale;
      final y = (py + (sy + 0.5) / samples - canvas / 2) / scale;
      for (final shape in _shapes) {
        if (shape.contains(x, y)) {
          hits++;
          break;
        }
      }
    }
  }
  return hits / (samples * samples);
}

/// Renders the mark at [canvas] pixels square, with the design scaled by
/// [scale], and writes it as an RGBA PNG.
///
/// With [plated] the mark is composited over the dark surface and the result is
/// fully opaque; without it the mark sits on transparency, which is what both an
/// adaptive icon's foreground layer and a splash image need.
void _write(
  String path, {
  required int canvas,
  required double scale,
  required bool plated,
}) {
  // One filter byte per row, then RGBA per pixel.
  final raw = Uint8List(canvas * (1 + canvas * 4));
  var i = 0;
  for (var y = 0; y < canvas; y++) {
    raw[i++] = 0; // filter type 0 (None)
    for (var x = 0; x < canvas; x++) {
      final a = _coverage(x, y, canvas, scale);
      if (plated) {
        raw[i++] = _mix(plate.r, mark.r, a);
        raw[i++] = _mix(plate.g, mark.g, a);
        raw[i++] = _mix(plate.b, mark.b, a);
        raw[i++] = 255;
      } else {
        raw[i++] = mark.r;
        raw[i++] = mark.g;
        raw[i++] = mark.b;
        raw[i++] = (a * 255).round();
      }
    }
  }

  File(path).writeAsBytesSync(_png(raw, canvas));
  stdout.writeln('Wrote $path (${canvas}px)');
}

int _mix(int from, int to, double t) => (from + (to - from) * t).round();

/// Assembles a minimal 8-bit RGBA PNG: signature, IHDR, IDAT, IEND.
Uint8List _png(Uint8List raw, int canvas) {
  final out = BytesBuilder();
  out.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder()
    ..add(_be32(canvas))
    ..add(_be32(canvas))
    ..add([
      8, // bit depth
      6, // colour type 6 = RGBA
      0, // deflate
      0, // adaptive filtering
      0, // no interlace
    ]);
  out.add(_chunk('IHDR', ihdr.toBytes()));
  out.add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw) as Uint8List));
  out.add(_chunk('IEND', Uint8List(0)));

  return out.toBytes();
}

/// Length, type, payload, CRC32 of type+payload.
Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final body = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);

  return (BytesBuilder()
        ..add(_be32(data.length))
        ..add(body)
        ..add(_be32(_crc32(body))))
      .toBytes();
}

Uint8List _be32(int value) => Uint8List(4)
  ..[0] = (value >> 24) & 0xFF
  ..[1] = (value >> 16) & 0xFF
  ..[2] = (value >> 8) & 0xFF
  ..[3] = value & 0xFF;

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
