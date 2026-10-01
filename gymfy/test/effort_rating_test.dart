// Rating how hard a set was (RPE or RIR), and what the overload suggestion
// does with it.
//
// The rule under test: if every planned set hit the top of the range but a set
// at the top weight was rated RPE 9.5+ (or RIR 0), the weight holds instead of
// going up. A rating only ever holds an increase back; it never invents one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/features/workout/widgets/log_set_sheet.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/set_type.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

LoggedSet _set({
  int id = 1,
  double weight = 100,
  int reps = 8,
  double? rpe,
  int? rir,
  SetType type = SetType.normal,
}) => LoggedSet(
  id: id,
  sessionId: 1,
  exerciseId: 'barbell_bench_press',
  setNumber: id,
  weight: weight,
  reps: reps,
  setType: type.name,
  rpe: rpe,
  rir: rir,
);

/// Three sets of 8 at 100 kg — every planned set at the target — with
/// [ratings] applied to the sets in order.
List<LoggedSet> _earnedSession({List<({double? rpe, int? rir})>? ratings}) => [
  for (var i = 0; i < 3; i++)
    _set(
      id: i + 1,
      rpe: ratings != null && i < ratings.length ? ratings[i].rpe : null,
      rir: ratings != null && i < ratings.length ? ratings[i].rir : null,
    ),
];

OverloadSuggestion _suggest(List<LoggedSet> lastSets) => suggestNextWeight(
  lastSets: lastSets,
  plannedSets: 3,
  targetReps: 8,
  incrementKg: 2.5,
);

void main() {
  group('the setting', () {
    test('is off unless it says otherwise', () {
      expect(EffortRatingMode.parse(null), EffortRatingMode.off);
      expect(EffortRatingMode.parse('junk'), EffortRatingMode.off);
      expect(EffortRatingMode.parse('rpe'), EffortRatingMode.rpe);
      expect(EffortRatingMode.parse('rir'), EffortRatingMode.rir);
    });

    test('offers RPE in half steps from 6 to 10', () {
      expect(rpeOptions.first, 6);
      expect(rpeOptions.last, 10);
      for (var i = 1; i < rpeOptions.length; i++) {
        expect(rpeOptions[i] - rpeOptions[i - 1], 0.5);
      }
    });
  });

  group('overload with ratings', () {
    test('unrated sets progress as before', () {
      final suggestion = _suggest(_earnedSession());

      expect(suggestion.reason, OverloadReason.earned);
      expect(suggestion.weight, 102.5);
    });

    test('a top set at RPE 9.5 holds the weight', () {
      final suggestion = _suggest(
        _earnedSession(
          ratings: [
            (rpe: 8, rir: null),
            (rpe: 9, rir: null),
            (rpe: 9.5, rir: null),
          ],
        ),
      );

      expect(suggestion.reason, OverloadReason.atLimit);
      expect(suggestion.weight, 100);
      expect(suggestion.isIncrease, isFalse);
    });

    test('so does RPE 10', () {
      final suggestion = _suggest(
        _earnedSession(ratings: [(rpe: 10, rir: null)]),
      );

      expect(suggestion.reason, OverloadReason.atLimit);
    });

    test('and RIR 0 — the same claim on the other scale', () {
      final suggestion = _suggest(
        _earnedSession(ratings: [(rpe: null, rir: 2), (rpe: null, rir: 0)]),
      );

      expect(suggestion.reason, OverloadReason.atLimit);
    });

    test('RPE 9 still goes up — one rep was left', () {
      final suggestion = _suggest(
        _earnedSession(
          ratings: [
            (rpe: 9, rir: null),
            (rpe: 9, rir: null),
            (rpe: 9, rir: null),
          ],
        ),
      );

      expect(suggestion.reason, OverloadReason.earned);
    });

    test('an unrated set tagged Failure holds the weight like RIR 0', () {
      // Rating mode off: the only way to say "that was everything" is the
      // set type. Taken to failure is RIR 0 by definition, so it must not
      // earn the increase the same set rated RIR 0 would hold back.
      final sets = _earnedSession();
      sets[2] = _set(id: 3, type: SetType.failure);

      final suggestion = _suggest(sets);

      expect(topSetAtLimit(sets), isTrue);
      expect(suggestion.reason, OverloadReason.atLimit);
      expect(suggestion.weight, 100);
    });

    test('a failure set below the top weight does not count', () {
      final sets = [
        _set(id: 1, weight: 100),
        _set(id: 2, weight: 100),
        _set(id: 3, weight: 100),
        _set(id: 4, weight: 90, type: SetType.failure),
      ];

      expect(topSetAtLimit(sets), isFalse);
    });

    test('a limit effort below the top weight does not count', () {
      // The grinder was a lighter back-off set, not the top set.
      final sets = [
        _set(id: 1, weight: 100),
        _set(id: 2, weight: 100),
        _set(id: 3, weight: 100),
        _set(id: 4, weight: 90, rpe: 10),
      ];

      expect(topSetAtLimit(sets), isFalse);
      expect(_suggest(sets).reason, OverloadReason.earned);
    });

    test('a rating never turns a missed session into an increase', () {
      final missed = [
        _set(id: 1, reps: 8, rpe: 6),
        _set(id: 2, reps: 6, rpe: 6),
        _set(id: 3, reps: 5, rpe: 6),
      ];

      expect(_suggest(missed).reason, OverloadReason.repeat);
    });

    test('a limit effort still loses to a due deload', () {
      final suggestion = suggestNextWeight(
        lastSets: _earnedSession(ratings: [(rpe: 10, rir: null)]),
        plannedSets: 3,
        targetReps: 8,
        incrementKg: 2.5,
        increasesInARow: 4,
        deloadAfterWeeks: 4,
      );

      expect(suggestion.reason, OverloadReason.deload);
    });
  });

  group('the log sheet', () {
    Future<List<LoggedSetInput?>> open(
      WidgetTester tester, {
      EffortRatingMode mode = EffortRatingMode.rpe,
      SetType setType = SetType.normal,
    }) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final results = <LoggedSetInput?>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...defaultDisplayOverrides],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async => results.add(
                      await showLogSetSheet(
                        context: context,
                        exercise: Exercise(
                          id: 'barbell_bench_press',
                          name: 'Barbell bench press',
                          muscleIds: const ['chest'],
                          isPlateLoaded: false,
                          isCustom: false,
                          isArchived: false,
                          isTimed: false,
                          equipment: 'other',
                        ),
                        setType: setType,
                        initialWeight: 100,
                        initialReps: 8,
                        unit: WeightUnit.kg,
                        effortMode: mode,
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
      return results;
    }

    Future<void> toReps(WidgetTester tester) async {
      await tester.tap(find.text('Next: reps'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Center, '8').last);
      await tester.pump();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks nothing when rating is off', (tester) async {
      await open(tester, mode: EffortRatingMode.off);
      await toReps(tester);

      expect(find.textContaining('RPE'), findsNothing);
      expect(find.textContaining('RIR'), findsNothing);
    });

    testWidgets('waits until the reps step to ask', (tester) async {
      await open(tester);

      expect(find.text('HOW HARD · RPE'), findsNothing);
      await toReps(tester);
      expect(find.text('HOW HARD · RPE'), findsOneWidget);
    });

    testWidgets('an RPE is saved as RPE and nothing else', (tester) async {
      final results = await open(tester);
      await toReps(tester);

      await tester.tap(find.byKey(const ValueKey('effort-8.5')));
      await tester.pump();
      await save(tester);

      expect(results.single?.rpe, 8.5);
      expect(results.single?.rir, isNull);
    });

    testWidgets('an RIR is saved as RIR and nothing else', (tester) async {
      final results = await open(tester, mode: EffortRatingMode.rir);
      await toReps(tester);

      expect(find.text('REPS LEFT · RIR'), findsOneWidget);
      expect(find.text('5+'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('effort-2')));
      await tester.pump();
      await save(tester);

      expect(results.single?.rir, 2);
      expect(results.single?.rpe, isNull);
    });

    testWidgets('skipping the rating saves an unrated set', (tester) async {
      final results = await open(tester);
      await toReps(tester);
      await save(tester);

      expect(results.single?.rpe, isNull);
      expect(results.single?.rir, isNull);
    });

    testWidgets('tapping the picked rating again clears it', (tester) async {
      final results = await open(tester);
      await toReps(tester);

      await tester.tap(find.byKey(const ValueKey('effort-9')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('effort-9')));
      await tester.pump();
      await save(tester);

      expect(results.single?.rpe, isNull);
    });

    testWidgets('a warm-up is never rated', (tester) async {
      final results = await open(tester, setType: SetType.warmup);
      await toReps(tester);

      expect(find.text('HOW HARD · RPE'), findsNothing);
      await save(tester);
      expect(results.single?.rpe, isNull);
    });
  });
}
