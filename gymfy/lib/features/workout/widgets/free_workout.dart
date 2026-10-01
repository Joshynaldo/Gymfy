import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/session_repository.dart';

/// The name a free workout is saved under. It follows no planned day, so there
/// is no day name to snapshot; history and the summary show this instead.
const freeWorkoutName = 'Free workout';

/// Starts a free workout — no planned day, an empty running order — and opens
/// it. Exercises are added from the workout screen as you go.
///
/// If a workout is already running, that one is opened instead of starting a
/// second: two live sessions would split one workout's sets across both,
/// which is the same reason Home offers Resume rather than Start.
///
/// Shared by the Workout tab and Home so both entry points behave the same.
Future<void> startFreeWorkout(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final sessions = ref.read(sessionRepositoryProvider);

  final running = await sessions.watchInProgressSession().first;
  final id =
      running?.id ?? await sessions.startFreeSession(name: freeWorkoutName);
  router.go('/workout/session/$id');
}
