// The activity heatmap: how sessions become per-day minutes, how minutes
// become shades, and how the year-long grid is laid out.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/widgets/activity_heatmap.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

// A Monday, so the grid maths is easy to reason about by hand.
final _today = DateTime(2026, 8, 24, 18);

void main() {
  group('minutesByDay', () {
    test('nothing trained is an empty map, not a map of zeroes', () {
      expect(minutesByDay(const []), isEmpty);
    });

    test('a session lands on the day it finished', () {
      final result = minutesByDay([
        (endedAt: DateTime(2026, 8, 24, 19, 30), length: const Duration(minutes: 75)),
      ]);

      expect(result, {DateTime(2026, 8, 24): 75});
    });

    test('two sessions on one day add up', () {
      final result = minutesByDay([
        (endedAt: DateTime(2026, 8, 24, 9), length: const Duration(minutes: 30)),
        (endedAt: DateTime(2026, 8, 24, 18), length: const Duration(minutes: 45)),
      ]);

      // Training twice is one busier day — the grid has one cell to say so.
      expect(result, {DateTime(2026, 8, 24): 75});
    });

    test('a session that ran past midnight counts on the day it ended', () {
      final result = minutesByDay([
        (endedAt: DateTime(2026, 8, 25, 0, 20), length: const Duration(minutes: 50)),
      ]);

      // Matches how the streak and the recap date a workout.
      expect(result.keys.single, DateTime(2026, 8, 25));
    });

    test('even an instant session counts as a minute', () {
      final result = minutesByDay([
        (endedAt: _today, length: Duration.zero),
      ]);

      // "Completed means trained" is the rule the streak already uses. Having
      // the grid disagree — a day the streak counts but the heatmap leaves
      // blank — would be worse than either answer being wrong.
      expect(result, {DateTime(2026, 8, 24): 1});
    });

    test('a workout finished inside a minute still counts', () {
      // The bug that made the grid stay empty on a fresh install: set up a
      // split, log one set, hit Finish — the whole thing takes forty seconds,
      // `inMinutes` truncates that to 0, and the day was thrown away as if it
      // had never happened.
      final result = minutesByDay([
        (endedAt: _today, length: const Duration(seconds: 40)),
      ]);

      expect(result, {DateTime(2026, 8, 24): 1});
    });

    test('a negative length is dropped rather than subtracted', () {
      final result = minutesByDay([
        (endedAt: _today, length: const Duration(minutes: 60)),
        (endedAt: _today, length: const Duration(minutes: -30)),
      ]);

      expect(result, {DateTime(2026, 8, 24): 60});
    });
  });

  group('activityLevel', () {
    test('an untrained day is the empty shade', () {
      expect(activityLevel(0), 0);
    });

    test('any training at all clears the empty shade', () {
      // "I turned up" is the distinction the grid is asked to make most often,
      // so a ten-minute session must not look identical to a rest day.
      expect(activityLevel(1), 1);
      expect(activityLevel(29), 1);
    });

    test('the thresholds step the shade up', () {
      expect(activityLevel(30), 2);
      expect(activityLevel(59), 2);
      expect(activityLevel(60), 3);
      expect(activityLevel(89), 3);
      expect(activityLevel(90), 4);
    });

    test('a marathon session tops out instead of overflowing', () {
      // An index past the palette would throw at paint time.
      expect(activityLevel(600), activityShades - 1);
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
      await db.into(db.workoutSessions).insert(
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
      expect(result[DateTime(2026, 8, 24)], 75);
    });

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
      required Map<DateTime, int> minutes,
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
            activityMinutesProvider.overrideWith((ref) => Stream.value(minutes)),
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
      await pump(tester, minutes: {
        DateTime(2026, 8, 24): 60,
        DateTime(2026, 8, 22): 45,
      });

      expect(find.text('Activity'), findsOneWidget);
      expect(find.textContaining('2 days'), findsOneWidget);
      expect(find.textContaining('1 h 45 min this year'), findsOneWidget);
    });

    testWidgets('one day is not "1 days"', (tester) async {
      await pump(tester, minutes: {DateTime(2026, 8, 24): 60});

      expect(find.textContaining('1 day •'), findsOneWidget);
    });

    testWidgets('the legend runs from less to more', (tester) async {
      await pump(tester, minutes: {DateTime(2026, 8, 24): 60});

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('tapping a trained day names it and its length', (
      tester,
    ) async {
      await pump(tester, minutes: {DateTime(2026, 8, 24): 75});

      // Today is a Monday, so it's the last column's top row.
      await tester.tapAt(
        tester.getTopLeft(find.byKey(activityGridKey)) +
            activityCellCentre(week: activityWeeks - 1, weekdayRow: 0),
      );
      await tester.pump();

      expect(find.textContaining('Today'), findsOneWidget);
      expect(find.textContaining('1 h 15 min trained'), findsOneWidget);
    });

    testWidgets('tapping an untrained day says rest day', (tester) async {
      await pump(tester, minutes: {DateTime(2026, 8, 24): 75});

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
      await pump(tester, minutes: {DateTime(2026, 8, 24): 75});

      final cell = tester.getTopLeft(find.byKey(activityGridKey)) +
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
