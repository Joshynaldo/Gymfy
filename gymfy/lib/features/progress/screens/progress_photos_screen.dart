import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/utils/dates.dart';
import '../../../shared/utils/format.dart';
import '../data/photo_repository.dart';
import '../widgets/photo_file_image.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';
import '../../../shared/widgets/glass_dialog.dart';

/// What the add-photo dialog collects before the file is copied in.
typedef _PhotoDetails = ({DateTime day, String? note});

/// Progress photos: a grid of everything you've taken, newest first.
class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Progress photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare',
            onPressed: () => context.go('/more/progress/photos/compare'),
          ),
        ],
      ),
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
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : GridView.builder(
                padding:
                    const EdgeInsets.fromLTRB(12, 12, 12, 96) +
                    barInsets(context),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _PhotoTile(
                  item: items[index],
                  onTap: () => _openPhoto(items[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addPhoto,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add photo'),
      ),
    );
  }

  Future<void> _addPhoto() async {
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Progress photos are viewed on a phone screen; a 12 MP original would
        // be slow to decode and waste storage for no visible benefit.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final details = await showDialog<_PhotoDetails>(
        context: context,
        builder: (context) => const _PhotoDetailsDialog(),
      );
      if (details == null || !mounted) return;

      await ref
          .read(photoRepositoryProvider)
          .addPhoto(
            day: details.day,
            source: File(picked.path),
            note: details.note,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPhoto(PhotoItem item) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => _PhotoViewer(item: item),
    );
    if (delete != true) return;
    await ref.read(photoRepositoryProvider).deletePhoto(item.photo);
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item, required this.onTap});

  final PhotoItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final note = item.photo.note;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoFileImage(path: item.path, thumbnail: true),
            // A date needs to be readable over both bright and dark photos.
            // A gradient rather than a flat bar: the bar cut a hard grey line
            // across the bottom of every photo, which is what made the grid
            // look like a file listing instead of a set of pictures.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(7, 14, 7, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatShortDate(item.photo.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // The note is why you took *this* shot — "front relaxed"
                    // is the difference between two photos taken the same day.
                    if (note != null && note.isNotEmpty)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen view of one photo. Pops `true` when the user confirms deletion.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.item});

  final PhotoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = item.photo.note;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: PhotoFileImage(path: item.path),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    note == null || note.isEmpty
                        ? formatDayLabel(item.photo.date)
                        : '${formatDayLabel(item.photo.date)} • $note',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  tooltip: 'Delete photo',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: const Text('Delete photo?'),
        content: const Text(
          'This removes the photo from Gymfy for good. The original in your '
          'gallery is untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Close the viewer, telling the screen to do the deleting.
    Navigator.of(context).pop(true);
  }
}

/// Asks which day the photo belongs to (today by default) plus an optional note.
class _PhotoDetailsDialog extends StatefulWidget {
  const _PhotoDetailsDialog();

  @override
  State<_PhotoDetailsDialog> createState() => _PhotoDetailsDialogState();
}

class _PhotoDetailsDialogState extends State<_PhotoDetailsDialog> {
  late DateTime _day = dateOnly(DateTime.now());
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 5),
      lastDate: dateOnly(now),
    );
    if (picked != null) setState(() => _day = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final note = _note.text.trim();

    return GlassDialog(
      title: const Text('Add photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(formatDayLabel(_day)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. front relaxed',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((day: _day, note: note.isEmpty ? null : note)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.photo_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No photos yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a photo from your gallery and Gymfy keeps its own copy, so '
              'your progress shots stay put even if you clear your gallery.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
