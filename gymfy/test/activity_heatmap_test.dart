// The activity heatmap: how sessions become per-day minutes, how minutes
// become shades, and how the year-long grid is laid out.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/progress/widgets/activity_heatmap.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

// A Monday, so the grid maths is easy to reason about by hand.
final _today = DateTime(2026, 8, 24, 18);

void main() {
  group('trainingByDay', () {
    /// A day with known minutes and nothing unrecorded.
    DayTraining timed(int minutes) => (minutes: minutes, untimed: 0);

    test('nothing trained is an empty map, not a map of zeroes', () {
      expect(trainingByDay(const []), isEmpty);
    });

    test('a session lands on the day it finished', () {
      final result = trainingByDay([
        (
          endedAt: DateTime(2026, 8, 24, 19, 30),
          length: const Duration(minutes: 75),
        ),
      ]);

      expect(result, {DateTime(2026, 8, 24): timed(75)});
    });

    test('two sessions on one day add up', () {
      final result = trainingByDay([
        (
          endedAt: DateTime(2026, 8, 24, 9),
          length: const Duration(minutes: 30),
        ),
        (
          endedAt: DateTime(2026, 8, 24, 18),
          length: const Duration(minutes: 45),
        ),
      ]);

      // Training twice is one busier day — the grid has one cell to say so.
      expect(result, {DateTime(2026, 8, 24): timed(75)});
    });

    test('a session that ran past midnight counts on the day it ended', () {
      final result = trainingByDay([
        (
          endedAt: DateTime(2026, 8, 25, 0, 20),
          length: const Duration(minutes: 50),
        ),
      ]);

      // Matches how the streak and the recap date a workout.
      expect(result.keys.single, DateTime(2026, 8, 25));
    });

    test('even an instant session counts as a minute', () {
      final result = trainingByDay([(endedAt: _today, length: Duration.zero)]);

      // "Completed means trained" is the rule the streak already uses. Having
      // the grid disagree — a day the streak counts but the heatmap leaves
      // blank — would be worse than either answer being wrong.
      expect(result, {DateTime(2026, 8, 24): timed(1)});
    });

    test('a workout finished inside a minute still counts', () {
      // The bug that made the grid stay empty on a fresh install: set up a
      // split, log one set, hit Finish — the whole thing takes forty seconds,
      // `inMinutes` truncates that to 0, and the day was thrown away as if it
      // had never happened.
      final result = trainingByDay([
        (endedAt: _today, length: const Duration(seconds: 40)),
      ]);

      expect(result, {DateTime(2026, 8, 24): timed(1)});
    });

    test('a session with no recorded length is counted, not timed', () {
      // What an imported workout looks like when the file it came from
      // recorded no usable end. It trained; how long is not known, and a
      // minute invented for it would sit in the year's total as fact.
      final result = trainingByDay([(endedAt: _today, length: null)]);

      expect(result, {DateTime(2026, 8, 24): (minutes: 0, untimed: 1)});
    });

    test('a timed and an untimed session on one day are both kept', () {
      final result = trainingByDay([
        (endedAt: _today, length: const Duration(minutes: 60)),
        (endedAt: _today, length: null),
      ]);

      expect(result, {DateTime(2026, 8, 24): (minutes: 60, untimed: 1)});
    });

    test('a negative length is not subtracted, and not invented either', () {
      // The clock moved. The session still happened, so it is kept as one
      // whose length is unknown rather than dropped — dropping it alone would
      // leave a day the streak counts and the grid does not.
      final result = trainingByDay([
        (endedAt: _today, length: const Duration(minutes: 60)),
        (endedAt: _today, length: const Duration(minutes: -30)),
      ]);

      expect(result, {DateTime(2026, 8, 24): (minutes: 60, untimed: 1)});
    });
  });

  group('activityLevel', () {
    DayTraining timed(int minutes) => (minutes: minutes, untimed: 0);

    test('an untrained day is the empty shade', () {
      expect(activityLevel(timed(0)), 0);
    });

    test('any training at all clears the empty shade', () {
      // "I turned up" is the distinction the grid is asked to make most often,
      // so a ten-minute session must not look identical to a rest day.
      expect(activityLevel(timed(1)), 1);
      expect(activityLevel(timed(29)), 1);
    });

    test('a day whose length was never recorded is still a trained day', () {
      // Otherwise importing a history would leave the squares blank for days
      // that plainly hold eighteen logged sets.
      expect(activityLevel((minutes: 0, untimed: 1)), 1);
    });

    test('the thresholds step the shade up', () {
      expect(activityLevel(timed(30)), 2);
      expect(activityLevel(timed(59)), 2);
      expect(activityLevel(timed(60)), 3);
      expect(activityLevel(timed(89)), 3);
      expect(activityLevel(timed(90)), 4);
    });

    test('an untimed session does not raise the shade of a timed day', () {
      // The shade means minutes. One with no number behind it cannot move it.
      expect(activityLevel((minutes: 30, untimed: 3)), 2);
    });

    test('a marathon session tops out instead of overflowing', () {
      // An index past the palette would throw at paint time.
      expect(activityLevel(timed(600)), activityShades - 1);
    });

    test('the palette has a colour for every level', () {
      final palette = activityPalette(
        const Color(0xFF00FF00),
        ColorScheme.fromSeed(seedColor: const Color(0xFF00FF00)),
      );

      expect(palette, hasLength(activityShades));
    });
  });

  group('grid layout', () {
    test('starts on a Monday', () {
      // Every column has to be a whole week or the weekday rows stop lining up.
      for (var offset = 0; offset < 7; offset++) {
        final day = _today.add(Duration(days: offset));
        expect(activityGridStart(day).weekday, DateTime.monday);
      }
    });

    test('still starts on a Monday across the clock changes', () {
      // `Duration`-based date arithmetic slips an hour when it crosses a DST
      // boundary, which would land the grid a day out and put every weekday in
      // the wrong row. Germany moves the clocks on 29 Mar and 25 Oct 2026.
      for (final around in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
        for (var offset = -7; offset <= 7; offset++) {
          final day = DateTime(around.year, around.month, around.day + offset);
          final start = activityGridStart(day);
          expect(start.weekday, DateTime.monday, reason: 'from $day');
          expect(start.hour, 0, reason: 'from $day');
        }
      }
    });

    test('covers a full year', () {
      final start = activityGridStart(_today);

      expect(_today.difference(start).inDays, greaterThanOrEqualTo(364));
    });

    test('is midnight, so day keys compare equal', () {
      final start = activityGridStart(_today);

      expect(start.hour, 0);
      expect(start.minute, 0);
    });

    test('the grid ends in the week containing today', () {
      final start = activityGridStart(_today);
      final lastColumnStart = start.add(
        const Duration(days: (activityWeeks - 1) * 7),
      );

      expect(lastColumnStart, DateTime(2026, 8, 24));
    });
  });

  group('through the database', () {
    late AppDatabase db;
    late ActivityRepository activity;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      activity = ActivityRepository(db);
    });

    tearDown(() => db.close());

    Future<void> session({
      required DateTime startedAt,
      DateTime? completedAt,
    }) async {
      await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Push',
              startedAt: Value(startedAt),
              completedAt: Value(completedAt),
            ),
          );
    }

    test('a finished session shows its length', () async {
      await session(
        startedAt: DateTime(2026, 8, 24, 17),
        completedAt: DateTime(2026, 8, 24, 18, 15),
      );

      final result = await activity.watchMinutesByDay(_today).first;
      expect(result[DateTime(2026, 8, 24)], (minutes: 75, untimed: 0));
    });

    test(
      'an imported session with no recorded end is trained, not timed',
      () async {
        // The importer writes `completedAt == startedAt` when the file it read
        // gave no usable end — a StrengthLog export does this for thirteen of
        // thirty workouts. The day still has to shade, and the minutes have to
        // stay out of the year's total.
        await session(
          startedAt: DateTime(2026, 8, 24, 17),
          completedAt: DateTime(2026, 8, 24, 17),
        );

        final result = await activity.watchMinutesByDay(_today).first;
        expect(result[DateTime(2026, 8, 24)], (minutes: 0, untimed: 1));
        expect(activityLevel(result[DateTime(2026, 8, 24)]!), 1);
      },
    );

    test('a workout still in progress is not on the grid', () async {
      await session(startedAt: DateTime(2026, 8, 24, 17));

      // It has no length yet, and shading a day you are still mid-way through
      // would keep changing under you.
      expect(await activity.watchMinutesByDay(_today).first, isEmpty);
    });

    test('sessions older than the grid are not read', () async {
      await session(
        startedAt: DateTime(2024, 1, 1, 10),
        completedAt: DateTime(2024, 1, 1, 11),
      );

      expect(await activity.watchMinutesByDay(_today).first, isEmpty);
    });
  });

  group('on screen', () {
    Future<void> pump(
      WidgetTester tester, {
      required Map<DateTime, DayTraining> minutes,
    }) async {
      // A year of squares is far wider than the default 800px test surface —
      // the grid scrolls and the right-hand columns land outside the viewport,
      // where taps are clipped and never reach the painter. A surface wide
      // enough for the whole year makes a square's position just its offset
      // from the grid's top-left. Sized off the real geometry so growing the
      // cells doesn't silently push today's column back out of view.
      tester.view.physicalSize = Size(activityGridWidth + 200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            defaultAccentOverride,
            activityMinutesProvider.overrideWith(
              (ref) => Stream.value(minutes),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ActivityHeatmap(today: _today),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('renders nothing until something has been logged', (
      tester,
    ) async {
      await pump(tester, minutes: const {});

      // A new install shouldn't show a year of empty grey squares.
      expect(find.text('Activity'), findsNothing);
    });

    testWidgets('summarises the year under the grid', (tester) async {
      await pump(
        tester,
        minutes: {
          DateTime(2026, 8, 24): (minutes: 60, untimed: 0),
          DateTime(2026, 8, 22): (minutes: 45, untimed: 0),
        },
      );

      expect(find.text('Activity'), findsOneWidget);
      expect(find.textContaining('2 days'), findsOneWidget);
      expect(find.textContaining('1 h 45 min this year'), findsOneWidget);
    });

    testWidgets('one day is not "1 days"', (tester) async {
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 60, untimed: 0)},
      );

      expect(find.textContaining('1 day •'), findsOneWidget);
    });

    testWidgets('the legend runs from less to more', (tester) async {
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 60, untimed: 0)},
      );

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('tapping a trained day names it and its length', (
      tester,
    ) async {
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 75, untimed: 0)},
      );

      // Today is a Monday, so it's the last column's top row.
      await tester.tapAt(
        tester.getTopLeft(find.byKey(activityGridKey)) +
            activityCellCentre(week: activityWeeks - 1, weekdayRow: 0),
      );
      await tester.pump();

      expect(find.textContaining('Today'), findsOneWidget);
      expect(find.textContaining('1 h 15 min trained'), findsOneWidget);
    });

    testWidgets('a day with no recorded length says so, not "1 min"', (
      tester,
    ) async {
      // An imported workout whose file recorded no usable end. The square is
      // shaded — it trained — but there is no honest number to put in the
      // caption, and a made-up minute would sit there looking like a fact.
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 0, untimed: 1)},
      );

      await tester.tapAt(
        tester.getTopLeft(find.byKey(activityGridKey)) +
            activityCellCentre(week: activityWeeks - 1, weekdayRow: 0),
      );
      await tester.pump();

      expect(find.textContaining('length not recorded'), findsOneWidget);
      expect(find.textContaining('1 min trained'), findsNothing);
    });

    testWidgets('the year total leaves out what was never recorded', (
      tester,
    ) async {
      await pump(
        tester,
        minutes: {
          DateTime(2026, 8, 24): (minutes: 60, untimed: 0),
          DateTime(2026, 8, 22): (minutes: 0, untimed: 2),
        },
      );

      // Both days trained, only one of them timed. Understating is the honest
      // direction: the alternative is inventing minutes.
      expect(find.textContaining('2 days'), findsOneWidget);
      expect(find.textContaining('1 h 00 min this year'), findsOneWidget);
    });

    testWidgets('tapping an untrained day says rest day', (tester) async {
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 75, untimed: 0)},
      );

      // Yesterday: same column as today only because today is a Monday, so
      // step back a column and down to Sunday.
      await tester.tapAt(
        tester.getTopLeft(find.byKey(activityGridKey)) +
            activityCellCentre(week: activityWeeks - 2, weekdayRow: 6),
      );
      await tester.pump();

      expect(find.textContaining('Yesterday'), findsOneWidget);
      expect(find.textContaining('rest day'), findsOneWidget);
    });

    testWidgets('tapping the same day again clears the selection', (
      tester,
    ) async {
      await pump(
        tester,
        minutes: {DateTime(2026, 8, 24): (minutes: 75, untimed: 0)},
      );

      final cell =
          tester.getTopLeft(find.byKey(activityGridKey)) +
          activityCellCentre(week: activityWeeks - 1, weekdayRow: 0);
      await tester.tapAt(cell);
      await tester.pump();
      await tester.tapAt(cell);
      await tester.pump();

      // Back to the year summary rather than stuck on one day.
      expect(find.textContaining('Today'), findsNothing);
      expect(find.textContaining('this year'), findsOneWidget);
    });
  });
}
