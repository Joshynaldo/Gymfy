// Building a session's running order for widget tests.
//
// The active workout reads its exercises from the session (session_exercises),
// not from the planned day. Most tests describe a workout as a day's plan,
// so this turns that plan into the running order a session started from it
// would have — one entry per planned exercise, in order, linked to its slot.

import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

/// The running order of a session started from [planned].
List<SessionExerciseEntry> sessionEntriesFor(
  List<PlannedExercise> planned, {
  int sessionId = 1,
}) => [
  for (final (index, p) in planned.indexed)
    SessionExerciseEntry(
      row: SessionExercise(
        id: index + 1,
        sessionId: sessionId,
        exerciseId: p.exercise.id,
        position: index,
        workoutExerciseId: p.entry.id,
      ),
      exercise: p.exercise,
      planned: p.entry,
    ),
];
