// Personal records as they happen: the live check on each logged set, the list
// on the workout summary, and the celebration pane.
//
// The rules are the strength filter's: warm-ups and drop sets are never a
// record and never part of the bar one has to clear; failure sets count.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/widgets/record_celebration.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

var _nextId = 1;

LoggedSet _set({
  double weight = 100,
  int reps = 5,
  SetType type = SetType.normal,
  int? seconds,
  int sessionId = 1,
  String exerciseId = 'bench',
}) => LoggedSet(
  id: _nextId++,
  sessionId: sessionId,
  exerciseId: exerciseId,
  setNumber: 1,
  weight: weight,
  reps: reps,
  setType: type.name,
  seconds: seconds,
);

List<BrokenRecord> _check(
  RecordBaseline before, {
  double weight = 100,
  int reps = 5,
  SetType type = SetType.normal,
  int? seconds,
}) => recordsSetBy(
  type: type,
  weightKg: weight,
  reps: reps,
  seconds: seconds,
  before: before,
);

void main() {
  group('the baseline', () {
    test('ignores warm-ups and drop sets', () {
      final baseline = RecordBaseline.of([
        _set(weight: 100),
        _set(weight: 140, type: SetType.warmup),
        _set(weight: 120, type: SetType.drop),
      ]);

      expect(baseline.weightKg, 100);
    });

    test('counts failure sets', () {
      final baseline = RecordBaseline.of([
        _set(weight: 100),
        _set(weight: 110, reps: 3, type: SetType.failure),
      ]);

      expect(baseline.weightKg, 110);
    });

    test('keeps holds and bodyweight reps apart from weights', () {
      final baseline = RecordBaseline.of([
        _set(weight: 0, reps: 0, seconds: 60),
        _set(weight: 0, reps: 12),
      ]);

      expect(baseline.weightKg, isNull);
      expect(baseline.holdSeconds, 60);
      expect(baseline.bodyweightReps, 12);
    });

    test('volume is the best single session', () {
      final baseline = RecordBaseline.of([
        _set(weight: 100, reps: 5, sessionId: 1),
        _set(weight: 100, reps: 5, sessionId: 1),
        _set(weight: 100, reps: 8, sessionId: 2),
      ]);

      expect(baseline.volumeKg, 1000);
    });
  });

  group('a set as it is logged', () {
    final before = RecordBaseline.of([_set(weight: 100, reps: 5)]);

    test('a heavier set is a weight record', () {
      final broken = _check(before, weight: 102.5, reps: 5);

      expect(broken.map((r) => r.kind), contains(RecordKind.weight));
      final weight = broken.firstWhere((r) => r.kind == RecordKind.weight);
      expect(weight.value, 102.5);
      expect(weight.previous, 100);
    });

    test('more reps at the same weight is an estimated-1RM record', () {
      final broken = _check(before, weight: 100, reps: 8);

      expect(broken.map((r) => r.kind), [RecordKind.oneRm]);
    });

    test('matching your best is not a new one', () {
      expect(_check(before, weight: 100, reps: 5), isEmpty);
    });

    test('a lighter set is not a record', () {
      expect(_check(before, weight: 90, reps: 5), isEmpty);
    });

    test('never on the first set ever logged', () {
      expect(_check(const RecordBaseline(), weight: 200), isEmpty);
    });

    test('a warm-up or drop set never is, however heavy', () {
      expect(_check(before, weight: 150, type: SetType.warmup), isEmpty);
      expect(_check(before, weight: 150, type: SetType.drop), isEmpty);
    });

    test('a failure set can be', () {
      expect(_check(before, weight: 105, type: SetType.failure), isNotEmpty);
    });

    test('a hold is measured against holds', () {
      final holds = RecordBaseline.of([_set(weight: 0, reps: 0, seconds: 60)]);

      final broken = _check(holds, weight: 0, reps: 0, seconds: 75);

      expect(broken.single.kind, RecordKind.hold);
      expect(broken.single.value, 75);
    });

    test('a bodyweight set is measured by its reps', () {
      final chins = RecordBaseline.of([_set(weight: 0, reps: 10)]);

      final broken = _check(chins, weight: 0, reps: 11);

      expect(broken.single.kind, RecordKind.reps);
    });

    test('volume is never celebrated mid-session', () {
      final broken = _check(before, weight: 102.5, reps: 20);

      expect(broken.map((r) => r.kind), isNot(contains(RecordKind.volume)));
    });
  });

  group('a session’s records', () {
    test('compares the session’s bests with what came before', () {
      final records = sessionRecordsFrom(
        sessionSets: [
          _set(weight: 60, type: SetType.warmup, sessionId: 9),
          _set(weight: 105, reps: 5, sessionId: 9),
          _set(weight: 105, reps: 5, sessionId: 9),
        ],
        earlierSets: [
          _set(weight: 100, reps: 5, sessionId: 1),
          _set(weight: 100, reps: 5, sessionId: 1),
        ],
      );

      final kinds = records.single.records.map((r) => r.kind);
      expect(kinds, containsAll([RecordKind.weight, RecordKind.volume]));
    });

    test('an exercise with no history sets no records', () {
      final records = sessionRecordsFrom(
        sessionSets: [_set(weight: 100, exerciseId: 'new')],
        earlierSets: const [],
      );

      expect(records, isEmpty);
    });

    test('earlier warm-ups do not lower the bar', () {
      final records = sessionRecordsFrom(
        sessionSets: [_set(weight: 100, sessionId: 9)],
        earlierSets: [
          _set(weight: 100, sessionId: 1),
          _set(weight: 140, type: SetType.warmup, sessionId: 1),
        ],
      );

      expect(records, isEmpty, reason: '100 only matches the best, 100');
    });
  });

  group('against the database', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late PersonalRecordsRepository records;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      records = PersonalRecordsRepository(db);
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'bench',
              name: 'Bench',
              muscleIds: const ['chest'],
            ),
          );
    });
    tearDown(() => db.close());

    Future<int> session(DateTime startedAt) {
      return db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Push',
              startedAt: Value(startedAt),
              completedAt: Value(startedAt.add(const Duration(hours: 1))),
            ),
          );
    }

    Future<void> log(int sessionId, double weight, {SetType? type}) {
      return sessions.logSet(
        sessionId: sessionId,
        exerciseId: 'bench',
        setNumber: 1,
        weight: weight,
        reps: 5,
        setType: type ?? SetType.normal,
      );
    }

    test('the live baseline skips warm-ups and drop sets', () async {
      final id = await session(DateTime(2026, 9, 1));
      await log(id, 100);
      await log(id, 130, type: SetType.warmup);
      await log(id, 120, type: SetType.drop);

      final baseline = await records.baselineFor('bench');

      expect(baseline.weightKg, 100);
    });

    test(
      'a session is compared only with sessions started before it',
      () async {
        final older = await session(DateTime(2026, 9, 1));
        await log(older, 100);
        final today = await session(DateTime(2026, 9, 8));
        await log(today, 105);
        // Started later, so it is not part of today's bar — even though it is
        // heavier and is already in the database.
        final later = await session(DateTime(2026, 9, 15));
        await log(later, 120);

        final found = await records.recordsForSession(today);

        final weight = found.single.records.firstWhere(
          (r) => r.kind == RecordKind.weight,
        );
        expect(weight.value, 105);
        expect(weight.previous, 100);
      },
    );

    test('a session with nothing logged has no records', () async {
      final id = await session(DateTime(2026, 9, 1));

      expect(await records.recordsForSession(id), isEmpty);
    });
  });

  group('on screen', () {
    Widget host(Widget child, {bool reduceMotion = false}) => ProviderScope(
      overrides: [...defaultDisplayOverrides],
      child: MaterialApp(
        theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );

    const broken = [
      BrokenRecord(kind: RecordKind.weight, value: 102.5, previous: 100),
    ];

    testWidgets('the celebration says what was beaten', (tester) async {
      await tester.pumpWidget(
        host(const RecordCelebration(exerciseName: 'Bench', records: broken)),
      );
      await tester.pumpAndSettle();

      expect(find.text('New personal record'), findsOneWidget);
      expect(find.text('Bench'), findsOneWidget);
      expect(
        find.text('Heaviest weight · 102.5 kg, was 100 kg'),
        findsOneWidget,
      );
    });

    testWidgets('it springs in when motion is allowed', (tester) async {
      await tester.pumpWidget(
        host(const RecordCelebration(exerciseName: 'Bench', records: broken)),
      );
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(RecordCelebration),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, lessThan(1));
    });

    testWidgets('and simply appears with reduced motion', (tester) async {
      await tester.pumpWidget(
        host(
          const RecordCelebration(exerciseName: 'Bench', records: broken),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(RecordCelebration),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('tapping it dismisses it', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        host(
          RecordCelebration(
            exerciseName: 'Bench',
            records: broken,
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New personal record'));
      expect(dismissed, isTrue);
    });

    testWidgets('the summary lists records per exercise', (tester) async {
      await tester.pumpWidget(
        host(
          const SessionRecordsList(
            records: [
              ExerciseRecords(
                exerciseId: 'bench',
                records: [
                  BrokenRecord(
                    kind: RecordKind.weight,
                    value: 102.5,
                    previous: 100,
                  ),
                  BrokenRecord(
                    kind: RecordKind.volume,
                    value: 1500,
                    previous: 1200,
                  ),
                ],
              ),
              ExerciseRecords(
                exerciseId: 'plank',
                records: [
                  BrokenRecord(kind: RecordKind.hold, value: 75, previous: 60),
                ],
              ),
            ],
            nameById: {'bench': 'Bench press'},
          ),
        ),
      );

      expect(find.text('3 personal records'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      // No name on file: the id rather than a blank row.
      expect(find.text('plank'), findsOneWidget);
      expect(find.text('Longest hold · 1:15, was 1:00'), findsOneWidget);
    });

    testWidgets('and shows nothing on a session that set none', (tester) async {
      await tester.pumpWidget(
        host(const SessionRecordsList(records: [], nameById: {})),
      );

      expect(find.textContaining('personal record'), findsNothing);
    });
  });

  test('record values read in the display unit', () {
    expect(
      formatRecordValue(RecordKind.weight, 100, WeightUnit.lbs),
      contains('lbs'),
    );
    expect(formatRecordValue(RecordKind.reps, 12, WeightUnit.kg), '12 reps');
  });
}
