// The real Home and Progress screens, on invented data, with no database.
//
//   flutter build web -t lib/preview_screens.dart --output=build/screens
//
// Not part of the app; nothing imports it and it ships in no build. It exists
// because the design harness next door can show controls but not *screens* —
// every screen in this app reads from Drift, Drift is native-only, and the one
// renderer that can be looked at from here is the web one. So the screens were
// being judged from their source, which is not judging them at all.
//
// The widgets are the real ones. Only the providers underneath are faked, and
// they are faked at the leaves — the same ones the widget tests override — so
// what renders is the screen the app builds, not a lookalike assembled here.

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/scaffold_with_nav_bar.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/glass.dart';
import 'app/theme/hyper_backdrop.dart';
import 'features/calculator/data/ranked_lifts.dart';
import 'features/home/data/activity_repository.dart';
import 'features/home/data/recap.dart';
import 'features/home/data/recap_repository.dart';
import 'features/home/screens/home_screen.dart';
import 'features/muscle_map/data/muscle_fatigue_repository.dart';
import 'features/muscle_map/data/muscle_volume_repository.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/progress/data/measurements_repository.dart';
import 'features/progress/data/progress_repository.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/workout/data/session_repository.dart';
import 'features/exercises/data/exercise_repository.dart';
import 'features/exercises/screens/exercise_library_screen.dart';
import 'features/workout/data/workout_repository.dart';
import 'features/workout/screens/workout_screen.dart';
import 'shared/database/app_database.dart';
import 'shared/utils/units.dart';
import 'shared/widgets/glass_nav_bar.dart';

void main() => runApp(const _ScreensPreview());

// ---------------------------------------------------------------------------
// The invented week. A push/pull/legs split, four sessions logged, and a year
// of activity behind it — enough that every card has something to say, because
// a screen full of empty states tells you nothing about the design.
// ---------------------------------------------------------------------------

final _split = Split(
  id: 1,
  name: 'Push · Pull · Legs',
  position: 0,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
);

final _pushDay = WorkoutDay(id: 10, splitId: 1, name: 'Push day', position: 0);
final _pullDay = WorkoutDay(id: 11, splitId: 1, name: 'Pull day', position: 1);

Exercise _exercise(String id, String name, List<String> muscles) => Exercise(
  id: id,
  name: name,
  muscleIds: muscles,
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
);

typedef _Plan = ({
  String id,
  String name,
  List<String> muscles,
  int sets,
  int reps,
  int? repsMax,
});

const _plans = <_Plan>[
  (
    id: 'barbell_bench_press',
    name: 'Barbell bench press',
    muscles: ['chest', 'triceps'],
    sets: 4,
    reps: 6,
    repsMax: 8,
  ),
  (
    id: 'incline_press',
    name: 'Incline dumbbell press',
    muscles: ['chest'],
    sets: 3,
    reps: 8,
    repsMax: 10,
  ),
  (
    id: 'shoulder_press',
    name: 'Dumbbell shoulder press',
    muscles: ['front_deltoid'],
    sets: 3,
    reps: 10,
    repsMax: null,
  ),
  (
    id: 'cable_fly',
    name: 'Cable fly',
    muscles: ['chest'],
    sets: 3,
    reps: 12,
    repsMax: 15,
  ),
  (
    id: 'triceps_pushdown',
    name: 'Rope triceps pushdown',
    muscles: ['triceps'],
    sets: 3,
    reps: 12,
    repsMax: null,
  ),
];

final _planned = [
  for (final (index, plan) in _plans.indexed)
    PlannedExercise(
      entry: WorkoutExercise(
        id: index + 1,
        dayId: _pushDay.id,
        exerciseId: plan.id,
        position: index,
        defaultSets: plan.sets,
        defaultReps: plan.reps,
        defaultRepsMax: plan.repsMax,
        warmupSets: index == 0 ? 2 : 0,
      ),
      exercise: _exercise(plan.id, plan.name, plan.muscles),
    ),
];

final _lastSession = WorkoutSession(
  id: 99,
  dayId: _pullDay.id,
  name: 'Pull day',
  startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
  completedAt: DateTime.now().subtract(const Duration(days: 2)),
);

final _lastSets = [
  for (var i = 0; i < 22; i++)
    LoggedSet(
      id: i,
      sessionId: 99,
      exerciseId: 'barbell_row',
      setNumber: (i % 4) + 1,
      weight: 80 + (i % 4) * 5,
      reps: 8,
      isWarmup: false,
    ),
];

/// Five weeks of training, three days a week, so the week bars and the year
/// grid both have a shape rather than a single spike.
final _recapSets = <RecapSet>[
  for (var week = 0; week < 5; week++)
    for (final offset in [0, 2, 4])
      for (var set = 0; set < 18; set++)
        (
          date: DateTime.now().subtract(Duration(days: week * 7 + offset)),
          sessionId: week * 3 + offset,
          exerciseId: 'barbell_bench_press',
          weight: 90 + (week * 2.5) + (set % 3) * 5,
          reps: 8,
          muscleIds: const ['chest', 'triceps', 'front_deltoid'],
        ),
];

final _activity = <DateTime, int>{
  for (var week = 0; week < 40; week++)
    for (final offset in [0, 2, 4])
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).subtract(Duration(days: week * 7 + offset)): 55 + (week % 4) * 12,
};

const _volume = <String, double>{
  'chest': 0.95,
  'front_deltoid': 0.82,
  'triceps': 0.74,
  'lats': 0.62,
  'biceps': 0.55,
  'quads': 0.40,
  'side_deltoid': 0.34,
  'glutes': 0.28,
  'trapezius': 0.22,
  'abs': 0.18,
};

const _fatigue = <String, double>{
  'chest': 1,
  'front_deltoid': 1,
  'triceps': 0.92,
  'side_deltoid': 0.42,
  'lats': 0.38,
  'biceps': 0.33,
};

final _fakeData = [
  storedAccentProvider.overrideWith((ref) => Stream.value(_accent)),
  storedWeightUnitProvider.overrideWith((ref) => Stream.value(null)),
  userNameProvider.overrideWith((ref) => Stream.value('Joshua')),
  activeSplitProvider.overrideWith((ref) => Stream.value(_split)),
  dayForWeekdayProvider.overrideWith((ref, weekday) => Stream.value(_pushDay)),
  dayExercisesProvider.overrideWith((ref, dayId) => Stream.value(_planned)),
  nextDayProvider.overrideWith(
    (ref, weekday) => Stream.value(
      UpcomingDay(day: _pullDay, weekday: weekday + 1, daysAway: 1),
    ),
  ),
  inProgressSessionProvider.overrideWith((ref) => Stream.value(null)),
  lastCompletedSessionProvider.overrideWith(
    (ref) => Stream.value(_lastSession),
  ),
  sessionSetsProvider.overrideWith((ref, id) => Stream.value(_lastSets)),
  sessionMuscleIntensitiesProvider.overrideWith(
    (ref, id) => Stream.value(_volume),
  ),
  workoutStreakProvider.overrideWith((ref) => Stream.value(4)),
  recapSetsProvider.overrideWith((ref) => Stream.value(_recapSets)),
  activityMinutesProvider.overrideWith((ref) => Stream.value(_activity)),
  weeklyMuscleIntensitiesProvider.overrideWith((ref) => Stream.value(_volume)),
  muscleFatigueProvider.overrideWith((ref) => Stream.value(_fatigue)),
  measurementHistoryProvider.overrideWith(
    (ref) => Stream.value(const <BodyMeasurement>[]),
  ),
  exercisesWithHistoryProvider.overrideWith(
    (ref) => Stream.value([
      for (final planned in _planned.take(3)) planned.exercise,
    ]),
  ),
  splitListProvider.overrideWith((ref) => Stream.value([_split])),
  scheduledDaysProvider.overrideWith(
    (ref, splitId) => Stream.value([
      ScheduledDay(day: _pushDay, weekdays: const [1, 4]),
      ScheduledDay(day: _pullDay, weekdays: const [2, 5]),
    ]),
  ),
  exerciseListProvider.overrideWith(
    (ref) => Stream.value([for (final p in _planned) p.exercise]),
  ),
  rankedLiftsProvider.overrideWithValue((
    ranked: const <RankedLift>[],
    unlogged: const <String>[],
  )),
];

Color _accent = const Color(0xFF7C6BFF);

class _ScreensPreview extends StatefulWidget {
  const _ScreensPreview();

  @override
  State<_ScreensPreview> createState() => _ScreensPreviewState();
}

class _ScreensPreviewState extends State<_ScreensPreview> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _fakeData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(AppTheme.hyper, _accent),
        // The same faked phone insets the control gallery uses: without them
        // the app bar comes out ~44px shorter than on any real device, and the
        // bar is one of the things being judged.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 44, bottom: 24),
            viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
          ),
          child: HyperBackdrop(child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            extendBody: glassOf(context).enabled,
            body: switch (_tab) {
              0 => const HomeScreen(),
              1 => const WorkoutScreen(),
              2 => const ExerciseLibraryScreen(),
              _ => const ProgressScreen(),
            },
            bottomNavigationBar: GlassNavBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) =>
                  setState(() => _tab = index.clamp(0, 3)),
              destinations: mainDestinations,
            ),
          ),
        ),
      ),
    );
  }
}
