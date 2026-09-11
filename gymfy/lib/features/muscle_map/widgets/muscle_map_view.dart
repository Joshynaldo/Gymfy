import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/exercise_display.dart';
import '../../../shared/widgets/app_segmented.dart';
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
    this.heatColor,
    this.leadingControl,
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

  /// Overrides the accent as the colour muscles heat toward.
  ///
  /// The fatigue reading passes a fixed red, so the two readings of this one
  /// diagram are told apart by colour rather than only by their captions.
  final Color? heatColor;

  /// A control the caller owns, laid out beside the front/back switch.
  ///
  /// The screen above knows what the colours *mean* — volume or fatigue — and
  /// this widget knows which way the body is facing. Passing one in rather than
  /// stacking two rows of switches is what keeps them on one line, as the
  /// design draws them.
  final Widget? leadingControl;

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
        // One row of switches across the top of the card: what the colour
        // means on the left, which way the body faces on the right. They were
        // two different controls in two different places — a segmented button
        // with a tick in it here, a pill there — which is two languages for
        // "pick one of these", on the same card.
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
          child: Row(
            children: [
              if (widget.leadingControl != null) ...[
                Expanded(child: widget.leadingControl!),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 128,
                child: AppSegmented<BodySide>(
                  selected: _side,
                  onChanged: (value) => setState(() => _side = value),
                  segments: const [
                    (value: BodySide.front, label: 'Front', leading: null),
                    (value: BodySide.back, label: 'Back', leading: null),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isContrast ? Icons.palette : Icons.palette_outlined,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
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
                heatColor: widget.heatColor,
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
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _captionText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // The ramp, beside the sentence that explains it. Without it
              // "brighter = more" is a claim the reader has to take on trust;
              // with it, the scale is on the card next to the body it applies
              // to. Only in heatmap mode — in per-muscle colours, brightness
              // is not the variable and the legend above names the colours.
              if (!_isContrast) ...[
                const SizedBox(width: 12),
                _HeatRamp(
                  colour: widget.heatColor ?? theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Muscles with any volume at all, in a stable order so the legend doesn't
  /// reshuffle between rebuilds.
  List<String> get _trainedMuscles {
    final data = widget.intensities.value ?? const <String, double>{};
    return colouredMuscles.where((id) => (data[id] ?? 0) > 0).toList();
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

/// Five squares from unworked to worked hardest, with a word at each end.
///
/// The steps are the same ones the diagram uses, so a muscle on the body can be
/// matched to a square by eye rather than by reading a number off it.
class _HeatRamp extends StatelessWidget {
  const _HeatRamp({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelSmall?.copyWith(letterSpacing: 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Less', style: label),
        const SizedBox(width: 6),
        for (final alpha in [0.08, 0.28, 0.5, 0.74, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                // The lowest step is the *surface*, not the colour at 8%: an
                // untrained muscle is drawn unlit, and the ramp has to start
                // where the body starts or it promises a shade nothing wears.
                color: alpha == 0.08
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : colour.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 3),
        Text('More', style: label),
      ],
    );
  }
}
