import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/utils/format.dart';
import '../data/photo_repository.dart';
import '../widgets/photo_file_image.dart';

/// Side-by-side before/after of two progress photos.
///
/// Defaults to the widest span available — oldest on the left, newest on the
/// right — since that's the comparison people actually want. Either side can be
/// swapped for any other photo.
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Slot(
                          label: 'Before',
                          item: before,
                          onTap: () => _choose(items, isBefore: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Slot(
                          label: 'After',
                          item: after,
                          onTap: () => _choose(items, isBefore: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

/// One half of the comparison: the photo, its date, and a tap to swap it.
class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.item, required this.onTap});

  final String label;
  final PhotoItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = item.photo.note;

    // The whole slot is the target, caption included — tapping the date to
    // change the photo is the obvious move.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                // contain, not cover: cropping a body shot to fill the box is
                // exactly how a comparison starts lying.
                child: PhotoFileImage(path: item.path),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatShortDate(item.photo.date),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (note != null && note.isNotEmpty)
            Text(
              note,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
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
              'Add at least two progress photos and you can put any two of '
              'them side by side here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

