import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/exercise_display.dart';
import '../data/muscle_colors.dart';
import 'muscle_map.dart';

/// A self-contained muscle-map panel: a front/back toggle, the heatmap for the
/// selected side, and a caption. Fed a ready [AsyncValue] of intensities so the
/// same widget serves both the weekly view (Muscles tab) and the per-workout
/// view (summary screen).
///
/// Expects its parent to give it a bounded height (e.g. an [Expanded] or a
/// [SizedBox]).
class MuscleMapView extends StatefulWidget {
  const MuscleMapView({
    super.key,
    required this.intensities,
    required this.emptyMessage,
    this.caption,
    this.contrastCaption =
        'Each muscle has its own colour. Brighter still means more volume.',
  });

  /// The intensities to display (loading / error / data).
  final AsyncValue<Map<String, double>> intensities;

  /// Shown under the map when there's no training data to display.
  final String emptyMessage;

  /// Shown under the map when there IS data. Omit to show nothing.
  final String? caption;

  /// Replaces [caption] while per-muscle colours are on. Defaults to the volume
  /// wording, which is what every caller but the fatigue map wants — brightness
  /// means something different there and saying "volume" would be wrong.
  final String contrastCaption;

  @override
  State<MuscleMapView> createState() => _MuscleMapViewState();
}

class _MuscleMapViewState extends State<MuscleMapView> {
  BodySide _side = BodySide.front;

  /// View state, like [_side] — not a stored preference. The toggle sits on the
  /// map itself, so flipping it is as cheap as flipping back, and a setting
  /// would be a second place for the same answer to live.
  MuscleMapMode _mode = MuscleMapMode.heatmap;

  bool get _isContrast => _mode == MuscleMapMode.contrast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trained = _trainedMuscles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              const Spacer(),
              SegmentedButton<BodySide>(
                segments: const [
                  ButtonSegment(value: BodySide.front, label: Text('Front')),
                  ButtonSegment(value: BodySide.back, label: Text('Back')),
                ],
                selected: {_side},
                onSelectionChanged: (selection) =>
                    setState(() => _side = selection.first),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _isContrast ? Icons.palette : Icons.palette_outlined,
                    ),
                    color: _isContrast ? theme.colorScheme.primary : null,
                    tooltip: _isContrast
                        ? 'Switch to heatmap'
                        : 'Switch to per-muscle colours',
                    onPressed: () => setState(() {
                      _mode = _isContrast
                          ? MuscleMapMode.heatmap
                          : MuscleMapMode.contrast;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.intensities.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the muscle map.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (intensities) => Center(
              child: MuscleMap(
                side: _side,
                intensities: intensities,
                mode: _mode,
              ),
            ),
          ),
        ),
        // Only in contrast mode, and only for muscles that actually have
        // volume: a legend of all eighteen would be longer than the map and
        // mostly about things you didn't train.
        if (_isContrast && trained.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _Legend(muscleIds: trained),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(
            _captionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Muscles with any volume at all, in a stable order so the legend doesn't
  /// reshuffle between rebuilds.
  List<String> get _trainedMuscles {
    final data = widget.intensities.value ?? const <String, double>{};
    return colouredMuscles
        .where((id) => (data[id] ?? 0) > 0)
        .toList();
  }

  String get _captionText {
    final data = widget.intensities.value;
    if (data == null || data.isEmpty) return widget.emptyMessage;
    if (_isContrast) return widget.contrastCaption;
    return widget.caption ?? '';
  }
}

/// Names the colours currently on the diagram.
class _Legend extends StatelessWidget {
  const _Legend({required this.muscleIds});

  final List<String> muscleIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final muscleId in muscleIds)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: muscleColor(muscleId),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(muscleLabel(muscleId), style: theme.textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}
