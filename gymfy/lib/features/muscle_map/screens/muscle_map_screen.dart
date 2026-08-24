import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/muscle_fatigue_repository.dart';
import '../data/muscle_volume_repository.dart';
import '../widgets/muscle_map_view.dart';

/// What the map is colouring.
enum MapReading {
  /// Work done over the last 7 days — a record of what you trained.
  volume,

  /// Work still weighing on each muscle right now — a guess at what is ready.
  fatigue,
}

/// The Muscles tab. Two readings of the same body diagram: what you *have*
/// trained (volume) and what is *still recovering* (fatigue).
///
/// One screen rather than two tabs, because they answer questions you ask in
/// the same breath — "did I hit back this week?" and "can I hit back today?" —
/// and reading one right after the other is the point.
class MuscleMapScreen extends ConsumerStatefulWidget {
  const MuscleMapScreen({super.key});

  @override
  ConsumerState<MuscleMapScreen> createState() => _MuscleMapScreenState();
}

class _MuscleMapScreenState extends ConsumerState<MuscleMapScreen> {
  /// View state, not a stored preference — same reasoning as the front/back
  /// toggle inside the map itself.
  MapReading _reading = MapReading.volume;

  bool get _isFatigue => _reading == MapReading.fatigue;

  @override
  Widget build(BuildContext context) {
    final data = _isFatigue
        ? ref.watch(muscleFatigueProvider)
        : ref.watch(weeklyMuscleIntensitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isFatigue ? 'Fatigue' : 'Muscle map')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SegmentedButton<MapReading>(
                segments: const [
                  ButtonSegment(
                    value: MapReading.volume,
                    icon: Icon(Icons.local_fire_department_outlined),
                    label: Text('Volume'),
                  ),
                  ButtonSegment(
                    value: MapReading.fatigue,
                    icon: Icon(Icons.battery_charging_full),
                    label: Text('Fatigue'),
                  ),
                ],
                selected: {_reading},
                onSelectionChanged: (selection) =>
                    setState(() => _reading = selection.first),
              ),
            ),
            Expanded(
              child: MuscleMapView(
                intensities: data,
                emptyMessage: _isFatigue
                    ? 'Everything is recovered — nothing you have trained '
                          'recently is still weighing on you.'
                    : 'No training logged in the last 7 days — finish a '
                          'workout to light up your muscle map.',
                caption: _isFatigue
                    ? 'How much recent work each muscle is still carrying. '
                          'Brighter = less recovered. Halves every two days.'
                    : 'Training volume over the last 7 days. Brighter = more '
                          'volume.',
                contrastCaption: _isFatigue
                    ? 'Each muscle has its own colour. Brighter still means '
                          'less recovered.'
                    : 'Each muscle has its own colour. Brighter still means '
                          'more volume.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
