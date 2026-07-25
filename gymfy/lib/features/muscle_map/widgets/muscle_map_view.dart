import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  /// The intensities to display (loading / error / data).
  final AsyncValue<Map<String, double>> intensities;

  /// Shown under the map when there's no training data to display.
  final String emptyMessage;

  /// Shown under the map when there IS data. Omit to show nothing.
  final String? caption;

  @override
  State<MuscleMapView> createState() => _MuscleMapViewState();
}

class _MuscleMapViewState extends State<MuscleMapView> {
  BodySide _side = BodySide.front;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SegmentedButton<BodySide>(
            segments: const [
              ButtonSegment(value: BodySide.front, label: Text('Front')),
              ButtonSegment(value: BodySide.back, label: Text('Back')),
            ],
            selected: {_side},
            onSelectionChanged: (selection) =>
                setState(() => _side = selection.first),
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
              child: MuscleMap(side: _side, intensities: intensities),
            ),
          ),
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

  String get _captionText {
    final data = widget.intensities.value;
    if (data == null || data.isEmpty) return widget.emptyMessage;
    return widget.caption ?? '';
  }
}
