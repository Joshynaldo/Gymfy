import 'dart:io';

import 'package:flutter/material.dart';

/// Renders a progress photo from disk.
///
/// Degrades to a placeholder rather than throwing if the file has gone missing —
/// possible if storage was wiped or a database was restored without its photos.
class PhotoFileImage extends StatelessWidget {
  const PhotoFileImage({
    super.key,
    required this.path,
    this.thumbnail = false,
    this.opacity = 1,
  });

  final String path;

  /// Thumbnails crop to fill and decode small; full views fit inside their box
  /// (cropping a body shot to fill is how a comparison starts lying).
  final bool thumbnail;

  /// How solid to draw the photo, 0–1. Used by the comparison overlay.
  ///
  /// Passed to [Image]'s own `opacity` rather than wrapping the widget in an
  /// [Opacity]: that would force a `saveLayer` — an offscreen buffer the size of
  /// the photo, allocated and composited every frame the slider moves. Blending
  /// during the paint costs nothing extra, which matters when the thing being
  /// faded is a full-screen 12 MP photo on an older phone.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Image.file(
      File(path),
      opacity: AlwaysStoppedAnimation(opacity),
      fit: thumbnail ? BoxFit.cover : BoxFit.contain,
      // Decode at roughly display size — full-resolution decodes of a dozen
      // 12 MP photos will stutter on older hardware.
      cacheWidth: thumbnail ? 400 : 1000,
      errorBuilder: (context, _, _) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
