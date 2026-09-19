// Filtering the library by what the movement needs.
//
// Most of this file is about one rule: every chip on screen has results
// behind it. That is easy to state and easy to get subtly wrong — the obvious
// implementation computes both bars from the fully filtered set, which looks
// right until you try to pick a second muscle and find every other chip has
// vanished.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/equipment.dart';
import 'package:gymfy/features/exercises/widgets/equipment_filter_sheet.dart';
import 'package:gymfy/shared/utils/exercise_search.dart';

import 'support/default_accent.dart';

Exercise _exercise(
  String id,
  String name, {
  required List<String> muscles,
  required Equipment equipment,
}) => Exercise(
  id: id,
  name: name,
  muscleIds: muscles,
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: equipment.name,
);

final _library = [
  _exercise(
    'bench',
    'Barbell Bench Press',
    muscles: ['chest'],
    equipment: Equipment.barbell,
  ),
  _exercise(
    'fly',
    'Cable Fly',
    muscles: ['chest'],
    equipment: Equipment.cable,
  ),
  _exercise(
    'pushup',
    'Push-Up',
    muscles: ['chest'],
    equipment: Equipment.bodyweight,
  ),
  _exercise(
    'legpress',
    'Leg Press',
    muscles: ['quads'],
    equipment: Equipment.machine,
  ),
  _exercise(
    'curl',
    'Dumbbell Curl',
    muscles: ['biceps'],
    equipment: Equipment.dumbbell,
  ),
];

void main() {
  group('Equipment.parse', () {
    test('reads back what it stores', () {
      for (final equipment in Equipment.values) {
        expect(Equipment.parse(equipment.name), equipment);
      }
    });

    test('an unreadable value files under other rather than throwing', () {
      // A row from a newer build, or one written by hand. Dropping an
      // exercise out of the library over it would be worse than "other".
      expect(Equipment.parse('trebuchet'), Equipment.other);
      expect(Equipment.parse(null), Equipment.other);
      expect(Equipment.parse(''), Equipment.other);
    });
  });

  group('matching', () {
    bool matches(Exercise e, Set<Equipment> equipment) => matchesExerciseSearch(
      e,
      query: '',
      muscleFilters: const {},
      equipmentFilters: equipment,
    );

    test('no filter means no restriction', () {
      expect(_library.where((e) => matches(e, {})), hasLength(5));
    });

    test('several kinds combine with OR', () {
      // "What can I do in a hotel room" is a real question, and it is this
      // one.
      final hotel = _library.where(
        (e) => matches(e, {Equipment.dumbbell, Equipment.bodyweight}),
      );

      expect(hotel.map((e) => e.id), containsAll(['pushup', 'curl']));
      expect(hotel, hasLength(2));
    });

    test('it ANDs against the muscle filter', () {
      // "Dumbbell chest work" is a search within a filtered set, not a union.
      final result = _library.where(
        (e) => matchesExerciseSearch(
          e,
          query: '',
          muscleFilters: {'chest'},
          equipmentFilters: {Equipment.cable},
        ),
      );

      expect(result.map((e) => e.id), ['fly']);
    });

    test('it ANDs against the search box too', () {
      final result = _library.where(
        (e) => matchesExerciseSearch(
          e,
          query: 'press',
          muscleFilters: const {},
          equipmentFilters: {Equipment.machine},
        ),
      );

      expect(result.map((e) => e.id), ['legpress']);
    });
  });

  group('equipmentIn', () {
    test('offers only what is present', () {
      expect(equipmentIn(_library), [
        Equipment.barbell,
        Equipment.dumbbell,
        Equipment.machine,
        Equipment.cable,
        Equipment.bodyweight,
      ]);
    });

    test('keeps enum order, so chips do not move as the list narrows', () {
      final reversed = _library.reversed.toList();

      expect(equipmentIn(reversed), equipmentIn(_library));
    });
  });

  group('the options each bar offers', () {
    ({List<String> muscles, List<Equipment> equipment}) optionsWith({
      String query = '',
      Set<String> muscles = const {},
      Set<Equipment> equipment = const {},
    }) => filterOptionsFor(
      _library,
      query: query,
      muscleFilters: muscles,
      equipmentFilters: equipment,
    );

    test('with nothing picked, everything present is offered', () {
      final options = optionsWith();

      expect(options.muscles, ['biceps', 'chest', 'quads']);
      expect(options.equipment, hasLength(5));
    });

    test('picking equipment narrows the muscles to what it can train', () {
      // The promise in the feature's name: tap Cable and the muscles with no
      // cable work go, so there is no combination you can reach that shows
      // an empty list.
      final options = optionsWith(equipment: {Equipment.cable});

      expect(options.muscles, ['chest']);
    });

    test('picking a muscle narrows the equipment to what it needs', () {
      final options = optionsWith(muscles: {'quads'});

      expect(options.equipment, [Equipment.machine]);
    });

    test('a facet does not narrow itself', () {
      // The one that matters, and the one the obvious implementation gets
      // wrong. Muscle filters OR together, so computing the muscle chips
      // from the fully filtered set would leave only the muscle you just
      // picked — and you could never pick a second.
      final options = optionsWith(muscles: {'chest'});

      expect(
        options.muscles,
        ['biceps', 'chest', 'quads'],
        reason: 'the other muscles must stay pickable',
      );
    });

    test('the same holds for equipment', () {
      final options = optionsWith(equipment: {Equipment.cable});

      expect(options.equipment, hasLength(5));
    });

    test('a picked option never disappears from its own bar', () {
      // Otherwise the chip you just tapped could vanish under your finger,
      // leaving a filter that is still applied and no longer visible
      // anywhere — nothing left to tap to undo it.
      //
      // Quads are machine-only, so picking Cable would otherwise take the
      // Quads chip away while the Quads filter was still on.
      final options = optionsWith(
        muscles: {'quads'},
        equipment: {Equipment.cable},
      );

      expect(options.muscles, contains('quads'));
      expect(options.equipment, contains(Equipment.cable));
    });

    test('the search box narrows both bars', () {
      final options = optionsWith(query: 'press');

      expect(options.muscles, ['chest', 'quads']);
      expect(options.equipment, [Equipment.barbell, Equipment.machine]);
    });
  });

  group('the sheet', () {
    // Behind a button rather than a second chip bar. Stacked under the muscle
    // bar it put two identical "All" chips directly above each other, meaning
    // different things — which reads as a rendering fault, not a control.
    late Set<Equipment> applied;

    Future<void> pump(WidgetTester tester) async {
      applied = <Equipment>{};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showEquipmentFilterSheet(
                      context: context,
                      available: const [
                        Equipment.barbell,
                        Equipment.dumbbell,
                        Equipment.cable,
                      ],
                      selected: applied,
                      onToggle: (equipment) {
                        if (!applied.remove(equipment)) applied.add(equipment);
                      },
                      onClear: applied.clear,
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

    testWidgets('offers only the equipment it was given', (tester) async {
      await pump(tester);

      expect(find.text('Barbell'), findsOneWidget);
      expect(find.text('Dumbbell'), findsOneWidget);
      expect(find.text('Cable'), findsOneWidget);
      expect(find.text('Machine'), findsNothing);
    });

    testWidgets('a tap applies immediately', (tester) async {
      // No Apply button: a sheet you can dismiss with a swipe must not hold
      // changes that the swipe would throw away.
      await pump(tester);

      await tester.tap(find.text('Dumbbell'));
      await tester.pumpAndSettle();

      expect(applied, {Equipment.dumbbell});
    });

    testWidgets('several can be on at once', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Dumbbell'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbell'));
      await tester.pumpAndSettle();

      expect(applied, {Equipment.dumbbell, Equipment.barbell});
    });

    testWidgets('tapping a picked one turns it off again', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Cable'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cable'));
      await tester.pumpAndSettle();

      expect(applied, isEmpty);
    });

    testWidgets('the tick follows the tap without closing the sheet', (
      tester,
    ) async {
      // The sheet keeps its own copy of the selection: the parent rebuilding
      // does not rebuild a route already on the stack, so reading the
      // caller's set would leave the ticks stale.
      await pump(tester);
      expect(find.byIcon(Icons.check), findsOneWidget); // "All equipment"

      await tester.tap(find.text('Dumbbell'));
      await tester.pumpAndSettle();

      expect(find.text('Dumbbell'), findsOneWidget, reason: 'still open');
      expect(find.byIcon(Icons.check), findsOneWidget); // moved to Dumbbell
    });

    testWidgets('"All equipment" clears the lot', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Dumbbell'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All equipment'));
      await tester.pumpAndSettle();

      expect(applied, isEmpty);
    });
  });

  group('the button', () {
    Future<void> pumpButton(WidgetTester tester, int count) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            home: Scaffold(
              body: EquipmentFilterButton(count: count, onPressed: () {}),
            ),
          ),
        ),
      );
    }

    testWidgets('says nothing when no filter is on', (tester) async {
      await pumpButton(tester, 0);

      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('counts the filters that are on', (tester) async {
      // A filter you cannot see is one you forget you set, and then the list
      // looks broken. The badge is what explains a short list.
      await pumpButton(tester, 2);

      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    });
  });

  group('the seeded library', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await ExerciseRepository(db).seed();
    });

    tearDown(() async => db.close());

    test('every built-in exercise says what it needs', () async {
      // A chip that matches nothing is a chip nobody can use, and an
      // exercise filed under "other" by accident is one its owner will not
      // find behind the chip they expect.
      final all = await db.select(db.exercises).get();
      final unclassified = all
          .where((e) => Equipment.parse(e.equipment) == Equipment.other)
          .map((e) => e.name)
          .toList();

      expect(all, hasLength(78));
      expect(
        unclassified,
        // The ab wheel and the kettlebell swing, which is what the bucket is
        // for. Anything else appearing here is an exercise that was missed.
        hasLength(2),
        reason: 'unexpectedly unclassified: $unclassified',
      );
    });

    test('the obvious ones landed where they should', () async {
      Future<Equipment> of(String id) async => Equipment.parse(
        (await (db.select(
          db.exercises,
        )..where((t) => t.id.equals(id))).getSingle()).equipment,
      );

      expect(await of('barbell_bench_press'), Equipment.barbell);
      expect(await of('dumbbell_row'), Equipment.dumbbell);
      expect(await of('leg_press'), Equipment.machine);
      expect(await of('cable_fly'), Equipment.cable);
      expect(await of('pull_up'), Equipment.bodyweight);
    });

    test('all six kinds are represented', () async {
      // So no chip in the bar is dead on a fresh install.
      final all = await db.select(db.exercises).get();

      expect(equipmentIn(all), hasLength(Equipment.values.length));
    });

    test('the seed keeps asserting it on every launch', () async {
      // Carried by the seed companions, unlike notes and bar weight: a bench
      // press needs a barbell whoever is holding it.
      await (db.update(db.exercises)
            ..where((t) => t.id.equals('barbell_bench_press')))
          .write(const ExercisesCompanion(equipment: Value('other')));

      await ExerciseRepository(db).seed();

      final bench = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals('barbell_bench_press'))).getSingle();
      expect(Equipment.parse(bench.equipment), Equipment.barbell);
    });
  });
}
