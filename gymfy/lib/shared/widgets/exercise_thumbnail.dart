import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/accent_color.dart';
import '../models/exercise.dart' show isBundledAsset;
import '../utils/exercise_display.dart';
import '../utils/exercise_preview.dart';

/// Default side, matching `AppGlyph` so rows keep their height and the left
/// edge of a list stays a straight column.
const defaultThumbnailSize = 42.0;

/// A still frame of an exercise's animation, for use in a list.
///
/// Deliberately *not* animated. The detail screen plays the loop; a list plays
/// seventy-eight of them, each decoding and compositing on every frame while
/// you scroll. That is the single most reliable way to make this app stutter on
/// the older Android hardware it targets.
///
/// Falls back to the shared exercise icon when the exercise has no animation
/// bundled, which is a supported state — the library is browsable long before
/// the asset folder is full.
class ExerciseThumbnail extends ConsumerWidget {
  const ExerciseThumbnail({
    super.key,
    required this.gifPath,
    this.selected = false,
  });

  /// The exercise's declared asset path, or null for one with no animation.
  final String? gifPath;

  /// Multi-select in the library replaces the thumbnail with a tick, the same
  /// way `AppGlyph` does — the row has to say "picked" more loudly than it
  /// says which exercise it is.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final path = gifPath;

    if (selected || path == null || !isBundledAsset(path)) {
      // A custom exercise's image is a file the user picked, not a bundled
      // asset, and this widget only reads the bundle. Those keep the icon.
      return _Fallback(accent: accent, selected: selected, size: size);
    }

    return ClipRRect(
      // Same radius as AppGlyph, so a list that mixes thumbnails and icons
      // still reads as one column.
      borderRadius: BorderRadius.circular(size / 3.2),
      child: SizedBox(
        width: size,
        height: size,
        child: Image(
          image: FirstFrame(
            path,
            // Decoded at the size it is drawn at, in device pixels. Passing
            // this to the decoder rather than scaling afterwards means the
            // 360px source is resampled once, properly, and never held in
            // memory at full size — 78 rows of 360×360 RGBA would be 40MB.
            pixelWidth:
                (size * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          // The bundle read is fast but not instantaneous; fading in beats a
          // column of grey squares snapping into place as you scroll.
          frameBuilder: (context, child, frame, wasSynchronous) {
            if (wasSynchronous || frame != null) return child;
            return const SizedBox.expand();
          },
          errorBuilder: (context, _, _) =>
              _Fallback(accent: accent, selected: selected),
        ),
      ),
    );
  }
}

/// The exercise icon in an accent-tinted square — `AppGlyph`'s look, reused
/// for exercises with no animation and for the selected state.
class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.accent,
    required this.selected,
    required this.size,
  });

  final Color accent;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? accent : accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size / 3.2),
      ),
      child: Icon(
        selected ? Icons.check : exerciseIcon,
        size: size / 2,
        color: selected ? Colors.white : accent,
      ),
    );
  }
}

/// An [ImageProvider] that yields only the first frame of an animated asset.
///
/// Flutter has no way to ask `Image.asset` for a still: handed a GIF it plays
/// it, and there is no flag to stop that. So the frame is decoded here — which
/// is also the only place `targetWidth` can be applied, since downsampling has
/// to happen inside the decoder to save anything.
///
/// Written as an ImageProvider rather than a `FutureBuilder` with a hand-rolled
/// cache so it joins Flutter's own [ImageCache]: eviction under memory
/// pressure, LRU, and de-duplication between rows all come for free, and a
/// thumbnail scrolled off and back does not decode twice.
@immutable
class FirstFrame extends ImageProvider<FirstFrame> {
  const FirstFrame(this.asset, {required this.pixelWidth});

  /// The declared asset path. Resolved through [previewCandidates], so a
  /// `.gif` path finds a `.webp` file where one was shipped instead.
  final String asset;

  /// Decode width in device pixels.
  final int pixelWidth;

  @override
  Future<FirstFrame> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<FirstFrame>(this);

  @override
  ImageStreamCompleter loadImage(FirstFrame key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      key._decodeFirstFrame(),
      informationCollector: () => [ErrorDescription('asset: ${key.asset}')],
    );
  }

  /// The decode, exposed for tests.
  ///
  /// Worth reaching directly: driving it through an `Image` widget only ever
  /// tells you *that* something failed, and every failure here renders as the
  /// fallback icon — which is also what a healthy exercise with no animation
  /// looks like.
  @visibleForTesting
  Future<ImageInfo> decodeForTest() => _decodeFirstFrame();

  Future<ImageInfo> _decodeFirstFrame() async {
    final bytes = await _load();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    // `targetWidth` is *not* passed here, and that is not an oversight: for an
    // animated source the decoder ignores it and hands back the full 360px
    // frame regardless. Asking for 126 and silently getting 360 is exactly the
    // bug this used to have — every row would have sat in the image cache at
    // full size, about 40MB across the library.
    final codec = await descriptor.instantiateCodec();
    ui.Image full;
    try {
      full = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
      descriptor.dispose();
    }

    if (full.width <= pixelWidth) return ImageInfo(image: full);
    return ImageInfo(image: await _scaled(full, pixelWidth));
  }

  /// Redraws [source] at [width], preserving its aspect ratio.
  ///
  /// The full-size frame is disposed on the way out, so what reaches the cache
  /// is only ever the thumbnail.
  static Future<ui.Image> _scaled(ui.Image source, int width) async {
    // Height follows the source rather than being forced square: a non-square
    // asset should letterbox inside the tile, not stretch.
    final height = (source.height * width / source.width).round();

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      source,
      Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
      source.dispose();
    }
  }

  /// The first candidate spelling that is actually bundled.
  Future<Uint8List> _load() async {
    Object? lastError;
    for (final candidate in previewCandidates(asset)) {
      try {
        final data = await rootBundle.load(candidate);
        return data.buffer.asUint8List();
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('No bundled animation for $asset ($lastError)');
  }

  @override
  bool operator ==(Object other) =>
      other is FirstFrame &&
      other.asset == asset &&
      other.pixelWidth == pixelWidth;

  @override
  int get hashCode => Object.hash(asset, pixelWidth);

  @override
  String toString() => 'FirstFrame($asset, ${pixelWidth}px)';
}
