// The goals card, the calendar and the review fit a 320-point phone — at the
// reader's text size, not only at mine.
//
// Same approach as overflow_test.dart: lay each one out at a fixed width and
// a text scale, and fail on whatever the framework complains about. 320 is
// the narrowest Android phone still common; 1.3 is larger text switched on,
// which on a gym app is not an edge case. The data is chosen to be awkward —
// long names, five-figure volumes — because that is what overflows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/calendar/data/calendar_repository.dart';
import 'package:gymfy/features/calendar/widgets/training_calendar.dart';
import 'package:gymfy/features/exercises/data/exercise_names.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/goals/data/goal_repository.dart';
import 'package:gymfy/features/goals/widgets/goal_form.dart';
import 'package:gymfy/features/goals/widgets/goals_card.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/reviews/data/review.dart';
import 'package:gymfy/features/reviews/screens/review_screen.dart';
import 'package:gymfy/features/reviews/widgets/review_links.dart';
import 'package:gymfy/features/reviews/widgets/review_share_card.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/data/week_start.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/goal.dart';

import 'support/default_accent.dart';

const _longName = 'Single-Arm Landmine Rotational Press With Pause';

final _today = DateTime(2026, 10, 1, 12);

Goal _goal(int id, GoalKind kind, double target) => Goal(
  id: id,
  kind: kind.name,
  exerciseId: kind == GoalKind.lift ? 'custom_long' : null,
  target: target,
  startValue: kind == GoalKind.frequency ? null : 80,
  deadline: kind == GoalKind.frequency ? null : DateTime(2026, 10, 9),
  createdAt: DateTime(2026, 9, 1),
);

final _statuses = [
  GoalStatus(
    goal: _goal(1, GoalKind.lift, 142.5),
    kind: GoalKind.lift,
    current: 137.5,
    fraction: 0.8,
    reachedAt: null,
    daysLeft: 8,
  ),
  GoalStatus(
    goal: _goal(2, GoalKind.frequency, 5),
    kind: GoalKind.frequency,
    current: 2,
    fraction: 0.4,
    reachedAt: null,
    daysLeft: null,
    weekStreak: 12,
  ),
  GoalStatus(
    goal: _goal(3, GoalKind.bodyweight, 72.5),
    kind: GoalKind.bodyweight,
    current: 76.4,
    fraction: 0.4,
    reachedAt: DateTime(2026, 9, 30),
    daysLeft: 8,
  ),
];

RecapSet _set(DateTime date, int session, String exercise, double weight) => (
  date: date,
  sessionId: session,
  exerciseId: exercise,
  weight: weight,
  reps: 10,
  muscleIds: const ['front_deltoid', 'upper_chest', 'tricep'],
);

/// A heavy month: five-figure volumes and long names in every list.
final _sets = [
  for (var session = 0; session < 24; session++)
    for (final exercise in ['custom_long', 'barbell_back_squat', 'deadlift'])
      for (var set = 0; set < 5; set++)
        _set(
          DateTime(2026, session < 12 ? 8 : 9, 1 + session % 12, 18),
          session,
          exercise,
          182.5,
        ),
];

final _days = {
  for (var day = 1; day <= 12; day++) ...{
    DateTime(2026, 8, day): (minutes: 125, untimed: 0),
    DateTime(2026, 9, day): (minutes: 0, untimed: 1),
  },
};

final _calendar = <CalendarSession>[
  for (final (hour, free) in [(7, true), (19, false)])
    (
      id: hour,
      name: free ? 'Free workout' : 'Upper Body Strength And Hypertrophy A',
      day: DateTime(2026, 10, 1),
      finishedAt: DateTime(2026, 10, 1, hour, 5),
      length: const Duration(minutes: 135),
      sets: 128,
      free: free,
    ),
];

final _review = buildReview(
  period: ReviewPeriod.month(2026, 9),
  allSets: _sets,
  trainingDays: _days,
  recordsByDay: {DateTime(2026, 9, 3): 14},
);

List<Override> get _overrides => [
  ...defaultDisplayOverrides,
  firstWeekdayProvider.overrideWithValue(DateTime.sunday),
  exerciseNamesProvider.overrideWithValue({
    'custom_long': _longName,
    'barbell_back_squat': 'Barbell Back Squat (High Bar, Paused)',
    'deadlift': 'Conventional Deadlift From Deficit',
  }),
  goalStatusesProvider.overrideWithValue(_statuses),
  recapSetsProvider.overrideWith((ref) => Stream.value(_sets)),
  allTrainingByDayProvider.overrideWith((ref) => Stream.value(_days)),
  recordsByDayProvider.overrideWith(
    (ref) => Stream.value({DateTime(2026, 9, 3): 14}),
  ),
  lastCompletedSessionProvider.overrideWith(
    (ref) => Stream.value(
      WorkoutSession(
        id: 19,
        name: 'Upper',
        startedAt: DateTime(2026, 10, 1, 17),
        completedAt: DateTime(2026, 10, 1, 19, 5),
      ),
    ),
  ),
  calendarMonthProvider.overrideWith((ref, month) => Stream.value(_calendar)),
  latestBodyweightProvider.overrideWithValue(null),
];

/// Builds [child] at 320 wide and [scale], and hands back whatever the
/// framework complained about.
Future<Object?> _layout(
  WidgetTester tester,
  Widget child, {
  required double scale,
  required AppTheme theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        theme: buildAppTheme(theme, AccentPalette.blue),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return tester.takeException();
}

void main() {
  for (final theme in [AppTheme.hyper, AppTheme.darkDefault]) {
    for (final scale in [1.0, 1.3]) {
      group('${theme.name} at text scale $scale, 320 wide', () {
        testWidgets('the goals card', (tester) async {
          expect(
            await _layout(
              tester,
              const GoalsCard(),
              scale: scale,
              theme: theme,
            ),
            isNull,
          );
          // The celebration rides along: the third goal is reached and
          // unseen.
          expect(find.text('Goal reached'), findsOneWidget);
        });

        testWidgets('the calendar, with a day open', (tester) async {
          expect(
            await _layout(
              tester,
              TrainingCalendar(today: _today),
              scale: scale,
              theme: theme,
            ),
            isNull,
          );
          await tester.tap(find.text('1'));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('Free workout'), findsOneWidget);
        });

        testWidgets('the review card', (tester) async {
          expect(
            await _layout(
              tester,
              ReviewShareCard(review: _review, today: _today),
              scale: scale,
              theme: theme,
            ),
            isNull,
          );
        });

        testWidgets('the review links', (tester) async {
          expect(
            await _layout(
              tester,
              ReviewLinks(today: _today),
              scale: scale,
              theme: theme,
            ),
            isNull,
          );
        });

        testWidgets('the goal form, every kind', (tester) async {
          expect(
            await _layout(tester, const GoalForm(), scale: scale, theme: theme),
            isNull,
          );
          for (final kind in ['Workouts', 'Bodyweight']) {
            await tester.tap(find.text(kind));
            await tester.pump();
            expect(tester.takeException(), isNull, reason: kind);
          }
        });

        testWidgets('the whole review screen', (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: _overrides,
              child: MaterialApp(
                theme: buildAppTheme(theme, AccentPalette.blue),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: const Size(320, 900),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: ReviewScreen(
                    initial: ReviewPeriod.month(2026, 9),
                    today: _today,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
}
