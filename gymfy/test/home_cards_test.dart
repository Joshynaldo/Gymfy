// The two supporting cards on Home: what's coming next, and what you last did.
//
// Both stay silent when they have nothing to say, so a fresh install shows one
// card rather than three, two of which are empty.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/widgets/last_workout_card.dart';
import 'package:gymfy/features/home/widgets/next_up_card.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  const monday = 1;
  const wednesday = 3;
  const thursday = 4;
  // A real Monday, so "today" is fixed rather than whenever the suite runs.
  final mondayDate = DateTime(2026, 8, 17);

  group('relativeDayLabel', () {
    test('tomorrow is named, not counted', () {
      expect(relativeDayLabel(1, thursday), 'Tomorrow');
    });

    test('within the week it is just the weekday', () {
      // "In 3 days" is arithmetic the reader has to do; "Thursday" is the
      // answer.
      expect(relativeDayLabel(3, thursday), 'Thursday');
      expect(relativeDayLabel(6, wednesday), 'Wednesday');
    });

    test('a full week out is qualified', () {
      // Seven days away is the same weekday as today, so the bare name would
      // read as "today" at a glance.
      expect(relativeDayLabel(7, monday), 'Next Monday');
    });
  });

  group('NextUpCard', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ...defaultDisplayOverrides,
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: NextUpCard(today: mondayDate)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows nothing when nothing is scheduled', (tester) async {
      await pump(tester);

      // The today card already explains this case; repeating it would be noise.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('names the next training day', (tester) async {
      final splitId = await repo.createSplit('PPL');
      final push = await repo.createDay(splitId, 'Push');
      final pull = await repo.createDay(splitId, 'Pull');
      await repo.assignWeekday(dayId: push, weekday: monday);
      await repo.assignWeekday(dayId: pull, weekday: thursday);

      await pump(tester);

      expect(find.text('Pull'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
    });

    testWidgets('skips today and finds the nearest day after it', (
      tester,
    ) async {
      final splitId = await repo.createSplit('PPL');
      final push = await repo.createDay(splitId, 'Push');
      final legs = await repo.createDay(splitId, 'Legs');
      final pull = await repo.createDay(splitId, 'Pull');
      await repo.assignWeekday(dayId: push, weekday: monday);
      await repo.assignWeekday(dayId: legs, weekday: thursday);
      await repo.assignWeekday(dayId: pull, weekday: 2); // Tuesday

      await pump(tester);

      // Today is Monday and Push is on it, but "next" means after today.
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Pull'), findsOneWidget);
      expect(find.text('Push'), findsNothing);
    });

    testWidgets('a once-weekly programme points at next week', (tester) async {
      final splitId = await repo.createSplit('Full Body');
      final day = await repo.createDay(splitId, 'Full Body A');
      await repo.assignWeekday(dayId: day, weekday: monday);

      await pump(tester);

      // The only training day is today's — so the next one is a week out, not
      // "nothing scheduled".
      expect(find.text('Next Monday'), findsOneWidget);
    });

    testWidgets('ignores splits that are not active', (tester) async {
      final ppl = await repo.createSplit('PPL');
      final push = await repo.createDay(ppl, 'Push');
      await repo.assignWeekday(dayId: push, weekday: thursday);

      final other = await repo.createSplit('Upper/Lower');
      final upper = await repo.createDay(other, 'Upper');
      await repo.assignWeekday(dayId: upper, weekday: wednesday);
      await repo.setActiveSplit(other);

      await pump(tester);

      expect(find.text('Upper'), findsOneWidget);
      expect(find.text('Push'), findsNothing);
    });
  });

  group('LastWorkoutCard', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ...defaultDisplayOverrides,
          // A stub body map. The real one loads an SVG asset and shows a
          // spinner meanwhile — and a spinner animates forever, so
          // `pumpAndSettle` would never return. What this card is *about* is
          // the text, and muscle_map_widget_test.dart already covers the real
          // SVG.
          bodySvgTemplateProvider(BodySide.front).overrideWith(
            (ref) => '<svg xmlns="http://www.w3.org/2000/svg" '
                'viewBox="0 0 248 558"></svg>',
          ),
        ],
      );
      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          id: 'barbell_bench_press',
          name: 'Barbell Bench Press',
          muscleIds: const ['chest'],
        ),
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: LastWorkoutCard())),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// A finished session with [sets] identical sets of 100 kg × 10.
    Future<int> completedSession({String name = 'Push', int sets = 2}) async {
      final id = await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(name: name),
      );
      for (var i = 1; i <= sets; i++) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: i,
          weight: 100,
          reps: 10,
        );
      }
      await sessions.completeSession(id);
      return id;
    }

    testWidgets('shows nothing before the first workout', (tester) async {
      await pump(tester);

      // A card reading "no workouts yet" on a new install adds nothing the
      // empty app doesn't already say.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('an unfinished workout is not the last one', (tester) async {
      await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(name: 'Push'),
      );

      await pump(tester);

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows the name, set count and total volume', (tester) async {
      await completedSession(sets: 3);

      await pump(tester);

      expect(find.text('Push'), findsOneWidget);
      // 3 × 100 kg × 10 reps.
      expect(find.textContaining('3 sets'), findsOneWidget);
      expect(find.textContaining('3000 kg'), findsOneWidget);
    });

    testWidgets('one set is not "1 sets"', (tester) async {
      await completedSession(sets: 1);

      await pump(tester);

      expect(find.textContaining('1 set •'), findsOneWidget);
    });

    testWidgets('the most recent finished session wins', (tester) async {
      await completedSession(name: 'Push');
      await completedSession(name: 'Pull');

      await pump(tester);

      expect(find.text('Pull'), findsOneWidget);
      expect(find.text('Push'), findsNothing);
    });
  });
}
