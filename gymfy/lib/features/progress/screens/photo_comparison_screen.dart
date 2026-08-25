import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../data/photo_repository.dart';
import '../widgets/photo_file_image.dart';

/// Two progress photos stacked on top of each other, with a slider to fade
/// between them.
///
/// Overlaid rather than side by side, which is what this screen used to do. Two
/// small images a thumb's width apart is the wrong tool for the job: real change
/// over eight weeks is a couple of centimetres, and spotting that means holding
/// the outlines against each other, not glancing back and forth between two
/// half-width photos. Faded on top of one another, the difference is the part
/// that moves.
///
/// Defaults to the widest span available — oldest against newest — since that's
/// the comparison people actually want. Either photo can be swapped.
class PhotoComparisonScreen extends ConsumerStatefulWidget {
  const PhotoComparisonScreen({super.key});

  @override
  ConsumerState<PhotoComparisonScreen> createState() =>
      _PhotoComparisonScreenState();
}

class _PhotoComparisonScreenState
    extends ConsumerState<PhotoComparisonScreen> {
  /// Chosen photo ids. Null means "still on the default", which is resolved
  /// against the current list — so the screen survives the chosen photo being
  /// deleted elsewhere.
  int? _beforeId;
  int? _afterId;

  /// Where the fade sits: 0 shows only the older photo, 1 only the newer.
  ///
  /// Starts in the middle, because a screen that opened on either extreme would
  /// look like it was showing one photo and hiding the other — the overlay is
  /// the whole point, so it has to be visible before anything is touched.
  double _fade = 0.5;

  PhotoItem? _resolve(List<PhotoItem> items, int? id, PhotoItem fallback) {
    if (id == null) return fallback;
    for (final item in items) {
      if (item.photo.id == id) return item;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load photos.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.length < 2) return const _NotEnoughPhotos();

          // The provider streams newest first.
          final newest = items.first;
          final oldest = items.last;
          final before = _resolve(items, _beforeId, oldest)!;
          final after = _resolve(items, _afterId, newest)!;

          return Column(
            children: [
              _SpanBanner(before: before, after: after),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _Overlay(before: before, after: after, fade: _fade),
                ),
              ),
              _FadeSlider(
                fade: _fade,
                onChanged: (value) => setState(() => _fade = value),
              ),
              _Ends(
                before: before,
                after: after,
                onTapBefore: () => _choose(items, isBefore: true),
                onTapAfter: () => _choose(items, isBefore: false),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Future<void> _choose(
    List<PhotoItem> items, {
    required bool isBefore,
  }) async {
    final chosen = await showModalBottomSheet<PhotoItem>(
      context: context,
      builder: (context) => _PhotoPickerSheet(
        items: items,
        title: isBefore ? 'Pick the "before" photo' : 'Pick the "after" photo',
      ),
    );
    if (chosen == null) return;
    setState(() {
      if (isBefore) {
        _beforeId = chosen.photo.id;
      } else {
        _afterId = chosen.photo.id;
      }
    });
  }
}

/// The headline: how much time separates the two photos on screen.
class _SpanBanner extends ConsumerWidget {
  const _SpanBanner({required this.before, required this.after});

  final PhotoItem before;
  final PhotoItem after;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);
    // Absolute, because nothing stops the user putting the newer photo on the
    // left if that's the comparison they want.
    final days = after.photo.date.difference(before.photo.date).inDays.abs();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        switch (days) {
          0 => 'Same day',
          1 => '1 day apart',
          _ when days < 14 => '$days days apart',
          _ when days < 60 => '${(days / 7).round()} weeks apart',
          _ => '${(days / 30).round()} months apart',
        },
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(color: accent),
      ),
    );
  }
}

/// The two photos in one frame, the older fading out as [fade] rises.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.before,
    required this.after,
    required this.fade,
  });

  final PhotoItem before;
  final PhotoItem after;
  final double fade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Both `contain` and both filling the same box, so the two bodies
            // are drawn at the same scale and centred on the same point. Any
            // other fit would move one photo relative to the other and invent a
            // difference that isn't there.
            PhotoFileImage(path: after.path, opacity: fade),
            PhotoFileImage(path: before.path, opacity: 1 - fade),
          ],
        ),
      ),
    );
  }
}

/// Scrubs between the two photos.
class _FadeSlider extends ConsumerWidget {
  const _FadeSlider({required this.fade, required this.onChanged});

  final double fade;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    return Slider(
      value: fade,
      activeColor: accent,
      // Continuous, no divisions: easing the newer photo in a few percent at a
      // time is how you catch a change that fixed steps would jump straight
      // over.
      onChanged: onChanged,
    );
  }
}

/// The two dates under the slider, each a tap target for swapping that photo.
class _Ends extends StatelessWidget {
  const _Ends({
    required this.before,
    required this.after,
    required this.onTapBefore,
    required this.onTapAfter,
  });

  final PhotoItem before;
  final PhotoItem after;
  final VoidCallback onTapBefore;
  final VoidCallback onTapAfter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Laid out to match the slider: the older photo is what you see at
          // the left end, the newer at the right.
          _End(label: 'Before', item: before, onTap: onTapBefore),
          _End(
            label: 'After',
            item: after,
            onTap: onTapAfter,
            alignEnd: true,
          ),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({
    required this.label,
    required this.item,
    required this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final PhotoItem item;
  final VoidCallback onTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = item.photo.note;

    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: alignEnd
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatShortDate(item.photo.date),
                style: theme.textTheme.bodyMedium,
              ),
              if (note != null && note.isNotEmpty)
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal strip of every photo to choose from.
class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet({required this.items, required this.title});

  final List<PhotoItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: PhotoFileImage(
                                path: item.path,
                                thumbnail: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatShortDate(item.photo.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotEnoughPhotos extends StatelessWidget {
  const _NotEnoughPhotos();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Nothing to compare yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add at least two progress photos and you can fade between any '
              'two of them here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

