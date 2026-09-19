// Exercises measured in time: planks, hangs, wall sits, loaded carries.
//
// The thing that makes these worth building rather than letting people type a
// number is the work timer — nobody counts a plank accurately while holding
// one, and the phone is already propped in front of them. So the tests here
// are mostly about the timer producing a real number and that number
// surviving all the way to the screen it is read back on.

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/widgets/log_set_sheet.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/format.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

final _plank = Exercise(
  id: 'plank',
  name: 'Plank',
  muscleIds: const ['abs'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: true,
  equipment: 'other',
);

final _bench = Exercise(
  id: 'barbell_bench_press',
  name: 'Barbell Bench Press',
  muscleIds: const ['chest'],
  isPlateLoaded: true,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

void main() {
  group('formatSetDuration', () {
    test('reads as minutes and seconds', () {
      expect(formatSetDuration(45), '0:45');
      expect(formatSetDuration(90), '1:30');
      expect(formatSetDuration(725), '12:05');
    });

    test('a short hold is not rounded away', () {
      // `formatDuration` rounds to whole minutes for session lengths, which
      // would show a 45-second plank as "0 min" — the seconds are the entire
      // content of a timed set.
      expect(formatSetDuration(45), isNot(contains('min')));
    });
  });

  group('formatLoggedSet', () {
    test('a counted set reads as weight by reps', () {
      expect(
        formatLoggedSet(
          weightKg: 80,
          reps: 8,
          seconds: null,
          unit: WeightUnit.kg,
        ),
        '80 kg × 8 reps',
      );
    });

    test('a held set reads as a duration, not as zero reps', () {
      expect(
        formatLoggedSet(weightKg: 0, reps: 0, seconds: 90, unit: WeightUnit.kg),
        '1:30',
      );
    });

    test('a loaded carry keeps its weight', () {
      expect(
        formatLoggedSet(
          weightKg: 20,
          reps: 0,
          seconds: 45,
          unit: WeightUnit.kg,
        ),
        '20 kg × 0:45',
      );
    });

    test('an unloaded hold does not say "0 kg"', () {
      // Which would invite the question of where the weight went, when the
      // answer is that a plank never had one.
      final line = formatLoggedSet(
        weightKg: 0,
        reps: 0,
        seconds: 60,
        unit: WeightUnit.kg,
      );
      expect(line, isNot(contains('0 kg')));
    });
  });

  group('the muscle map', () {
    test('a hold registers rather than leaving the body grey', () {
      // Counting a held set as zero effort is what the ladder used to do, and
      // it meant a core session showed an untouched body after you plainly
      // trained.
      final result = muscleIntensities(const [
        (weight: 0.0, reps: 0, seconds: 60, muscleIds: ['abs']),
      ]);

      expect(result['abs'], 1.0);
    });

    test('a minute of plank does not outweigh sixty crunches', () {
      // The reason time is converted to rep-equivalents rather than counted
      // second for second: raw seconds would wash the whole map out.
      final result = muscleIntensities(const [
        (weight: 0.0, reps: 0, seconds: 60, muscleIds: ['abs']),
        (weight: 0.0, reps: 60, seconds: null, muscleIds: ['obliques']),
      ]);

      expect(result['obliques'], 1.0);
      expect(result['abs']! < result['obliques']!, isTrue);
    });

    test('a loaded carry counts its weight', () {
      final light = muscleIntensities(const [
        (weight: 0.0, reps: 0, seconds: 60, muscleIds: ['forearms']),
      ]);
      final heavy = muscleIntensities(const [
        (weight: 40.0, reps: 0, seconds: 60, muscleIds: ['forearms']),
        (weight: 0.0, reps: 0, seconds: 60, muscleIds: ['abs']),
      ]);

      expect(light['forearms'], 1.0);
      // With a weight in play the carry dominates the unloaded hold.
      expect(heavy['forearms'], 1.0);
      expect(heavy['abs']! < 1.0, isTrue);
    });
  });

  group('the log sheet', () {
    late AppDatabase db;
    late List<LoggedSetInput?> results;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      results = [];
    });

    tearDown(() async => db.close());

    Future<void> open(WidgetTester tester, Exercise exercise) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ...defaultDisplayOverrides,
          ],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async => results.add(
                      await showLogSetSheet(
                        context: context,
                        exercise: exercise,
                        isWarmup: false,
                        initialWeight: 0,
                        initialReps: 8,
                        unit: WeightUnit.kg,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> tapText(WidgetTester tester, String label) async {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    /// What the clock reads, as `m:ss`.
    ///
    /// Read from the two halves by key rather than by text: the keypad has a
    /// "0" on it at the same time as the clock does, so a plain text finder
    /// would match either.
    String clockReads(WidgetTester tester) {
      final minutes = tester
          .widget<Text>(find.byKey(const ValueKey('time-minutes')))
          .data!;
      final seconds = tester
          .widget<Text>(find.byKey(const ValueKey('time-seconds')))
          .data!;
      return '$minutes:$seconds';
    }

    testWidgets('asks for time, not reps, on a timed exercise', (tester) async {
      await open(tester, _plank);
      await tapText(tester, 'Next: time');

      expect(find.text('STEP 2 — TIME'), findsOneWidget);
      expect(find.text('STEP 2 — REPS'), findsNothing);
    });

    testWidgets('still asks for reps on an ordinary exercise', (tester) async {
      // The other half: adding a third step must not change the two that
      // every other lift in the app uses.
      await open(tester, _bench);
      // A weight, because a lift counted in reps still has to state one.
      await tapText(tester, '8');
      await tapText(tester, 'Next: reps');

      expect(find.text('STEP 2 — REPS'), findsOneWidget);
      expect(find.text('STEP 2 — TIME'), findsNothing);
    });

    testWidgets('minutes and seconds are typed into separately', (
      tester,
    ) async {
      // The whole reason this is two fields: entering the total in raw
      // seconds made "three and a half minutes" 210 — arithmetic in your
      // head, at the end of a hard set.
      await open(tester, _plank);
      await tapText(tester, 'Next: time');

      await tapText(tester, 'MIN');
      await tapText(tester, '3');
      await tapText(tester, 'SEC');
      await tapText(tester, '3');
      await tapText(tester, '0');

      expect(clockReads(tester), '3:30');

      await tapText(tester, 'Save set');
      expect(results.single!.seconds, 210);
    });

    testWidgets('minutes are the field you land on', (tester) async {
      // So the common case — pick a field, type — reads left to right with
      // no tap wasted on selecting the first one.
      await open(tester, _plank);
      await tapText(tester, 'Next: time');

      await tapText(tester, '2');

      expect(clockReads(tester), '2:00');
    });

    testWidgets('seconds refuse to overflow into minutes', (tester) async {
      // Sixty-one seconds silently becoming 1:01 would be a number the user
      // never typed, and on a field this small the mistake is invisible.
      await open(tester, _plank);
      await tapText(tester, 'Next: time');
      await tapText(tester, 'SEC');

      await tapText(tester, '5');
      await tapText(tester, '9');
      expect(clockReads(tester), '0:59');

      // A sixth digit would make 599; refused rather than wrapped.
      await tapText(tester, '9');
      expect(clockReads(tester), '0:59');
    });

    testWidgets('backspace clears the field you are in', (tester) async {
      await open(tester, _plank);
      await tapText(tester, 'Next: time');
      await tapText(tester, 'SEC');
      await tapText(tester, '4');
      await tapText(tester, '5');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      expect(clockReads(tester), '0:04');
    });

    testWidgets('the work timer counts the hold and saves it', (tester) async {
      // The feature's whole reason to exist.
      //
      // The hold is measured against the wall clock rather than counted in
      // ticks, so that a dropped frame or a sleeping screen cannot quietly
      // shorten it. That is correct and untestable at the same time —
      // `tester.pump` moves Flutter's timers but not `DateTime.now` — so the
      // sheet reads `package:clock`, and here the clock is the thing being
      // moved.
      var now = DateTime(2026, 9, 19, 18);
      await withClock(Clock(() => now), () async {
        await open(tester, _plank);
        await tapText(tester, 'Next: time');
        await tapText(tester, 'Start timer');

        now = now.add(const Duration(seconds: 45));
        await tester.pump(const Duration(seconds: 45));

        expect(clockReads(tester), '0:45');
        await tapText(tester, 'Stop');
        expect(clockReads(tester), '0:45');

        await tapText(tester, 'Save set');
      });

      expect(results.single, isNotNull);
      expect(results.single!.seconds, 45);
      expect(
        results.single!.reps,
        0,
        reason: 'a set is counted or held, never both',
      );
    });

    testWidgets('a dropped tick does not shorten the hold', (tester) async {
      // Why the elapsed time is derived from the start rather than counted:
      // the ticker will miss beats the moment the screen sleeps, and a hold
      // that silently came out short would be worse than no timer at all.
      var now = DateTime(2026, 9, 19, 18);
      await withClock(Clock(() => now), () async {
        await open(tester, _plank);
        await tapText(tester, 'Next: time');
        await tapText(tester, 'Start timer');

        // A minute of wall time passes with only one frame drawn in it.
        now = now.add(const Duration(seconds: 60));
        await tester.pump(const Duration(seconds: 1));

        await tapText(tester, 'Stop');
        expect(clockReads(tester), '1:00');
        await tapText(tester, 'Save set');
      });

      expect(results.single!.seconds, 60);
    });

    testWidgets('saving mid-hold keeps the time on screen', (tester) async {
      // Ending the plank and reaching straight for Save is the natural move;
      // refusing it until Stop was also tapped would be a second dead end of
      // exactly the kind the plate stacker had.
      var now = DateTime(2026, 9, 19, 18);
      await withClock(Clock(() => now), () async {
        await open(tester, _plank);
        await tapText(tester, 'Next: time');
        await tapText(tester, 'Start timer');

        now = now.add(const Duration(seconds: 30));
        await tester.pump(const Duration(seconds: 30));

        await tapText(tester, 'Save set');
      });

      expect(results.single!.seconds, 30);
    });

    testWidgets('a counted set still carries no duration', (tester) async {
      await open(tester, _bench);
      // A weight, because a lift counted in reps still has to state one.
      await tapText(tester, '8');
      await tapText(tester, 'Next: reps');
      await tapText(tester, '8');
      await tapText(tester, 'Save set');

      expect(results.single!.seconds, isNull);
      expect(results.single!.reps, 8);
    });
  });

  group('storing it', () {
    late AppDatabase db;
    late SessionRepository sessions;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      await ExerciseRepository(db).seed();
    });

    tearDown(() async => db.close());

    test('a held set round-trips', () async {
      final id = await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Core'));

      await sessions.logSet(
        sessionId: id,
        exerciseId: 'plank',
        setNumber: 1,
        weight: 0,
        reps: 0,
        seconds: 75,
      );

      final set = (await db.select(db.loggedSets).get()).single;
      expect(set.seconds, 75);
      expect(set.reps, 0);
    });

    test('an ordinary set stores no duration', () async {
      final id = await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));

      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 80,
        reps: 8,
      );

      expect((await db.select(db.loggedSets).get()).single.seconds, isNull);
    });

    test('the seeded holds are marked as timed', () async {
      Future<bool> timed(String id) async => (await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(id))).getSingle()).isTimed;

      expect(await timed('plank'), isTrue);
      expect(await timed('side_plank'), isTrue);
      expect(await timed('farmers_walk'), isTrue);
      // And nothing counted in reps got swept up.
      expect(await timed('barbell_bench_press'), isFalse);
      expect(await timed('crunch'), isFalse);
    });

    test('the seed keeps saying so on every launch', () async {
      // Unlike notes and bar weight, this one IS carried by the seed
      // companions: it is a fact about the movement, not a user choice, so
      // the built-in library should keep asserting it.
      await (db.update(db.exercises)..where((t) => t.id.equals('plank'))).write(
        const ExercisesCompanion(isTimed: Value(false)),
      );

      await ExerciseRepository(db).seed();

      final plank = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals('plank'))).getSingle();
      expect(plank.isTimed, isTrue);
    });
  });
}
