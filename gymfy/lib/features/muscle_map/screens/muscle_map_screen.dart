import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/muscle_volume_repository.dart';
import '../widgets/muscle_map_view.dart';

/// The Muscle map tab: a heatmap of the muscles you've trained over the last 7
/// days, driven by your logged workout volume.
class MuscleMapScreen extends ConsumerWidget {
  const MuscleMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensitiesAsync = ref.watch(weeklyMuscleIntensitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Muscle map')),
      body: SafeArea(
        child: MuscleMapView(
          intensities: intensitiesAsync,
          emptyMessage:
              'No training logged in the last 7 days — finish a workout to '
              'light up your muscle map.',
          caption: 'Training volume over the last 7 days. Brighter = more '
              'volume.',
        ),
      ),
    );
  }
}
