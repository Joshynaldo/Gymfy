// Your own note on an exercise: seat height, pin position, which machine.
//
// The feature is mostly about one thing surviving: the launch upsert rewrites
// every built-in row on every app start. A note on the leg press — and the leg
// press is exactly the case this exists for — has to live on a column the seed
// companions never mention, or it would be silently erased overnight and the
// user would conclude the app forgets things.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/widgets/exercise_note.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  group('storing a note', () {
    late AppDatabase db;
    late ExerciseRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseRepository(db);
      await repo.seed();
    });

    tearDown(() async => db.close());

    Future<String?> noteOf(String id) async {
      final row = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(id))).getSingle();
      return row.notes;
    }

    test('starts unwritten', () async {
      expect(await noteOf('leg_press'), isNull);
    });

    test('is kept verbatim', () async {
      await repo.setNotes('leg_press', 'Seat 4, back pad 2');

      expect(await noteOf('leg_press'), 'Seat 4, back pad 2');
    });

    test('works on built-in exercises, which is the whole point', () async {
      // Editing a built-in exercise's *name* is refused, because the seed
      // would revert it on the next launch. A note is the exception, and it
      // has to be: nobody invented the leg press, and the seat height is not
      // knowable from code.
      final legPress = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals('leg_press'))).getSingle();
      expect(legPress.isCustom, isFalse);

      await repo.setNotes('leg_press', 'Seat 4');
      expect(await noteOf('leg_press'), 'Seat 4');
    });

    test('survives the seed upsert that runs on every launch', () async {
      // The reason `notes` is deliberately absent from the seed companions.
      // `insertAllOnConflictUpdate` rewrites every built-in row at startup but
      // only the columns those companions carry. Same guard as the per-
      // exercise bar weight, and the same silent failure if it ever breaks:
      // you would come back the next morning to a blank note.
      await repo.setNotes('leg_press', 'Seat 4, back pad 2');
      await repo.setNotes('barbell_bench_press', 'Bench 2, feet tucked');

      await repo.seed();
      await repo.seed();

      expect(await noteOf('leg_press'), 'Seat 4, back pad 2');
      expect(await noteOf('barbell_bench_press'), 'Bench 2, feet tucked');
    });

    test('blank input clears the note rather than storing ""', () async {
      // They look identical on screen and are not the same thing: the empty
      // state is drawn from `null`, so an empty string would put a note
      // heading over nothing at all.
      await repo.setNotes('leg_press', 'Seat 4');

      await repo.setNotes('leg_press', '   ');
      expect(await noteOf('leg_press'), isNull);

      await repo.setNotes('leg_press', 'Seat 4');
      await repo.setNotes('leg_press', null);
      expect(await noteOf('leg_press'), isNull);
    });

    test('surrounding whitespace is trimmed', () async {
      await repo.setNotes('leg_press', '  Seat 4  ');

      expect(await noteOf('leg_press'), 'Seat 4');
    });

    test('one exercise at a time', () async {
      await repo.setNotes('leg_press', 'Seat 4');

      expect(await noteOf('barbell_bench_press'), isNull);
    });
  });

  group('the tile', () {
    late AppDatabase db;
    late ExerciseRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseRepository(db);
      await repo.seed();
    });

    tearDown(() async => db.close());

    Future<Exercise> exerciseRow(String id) => (db.select(
      db.exercises,
    )..where((t) => t.id.equals(id))).getSingle();

    Future<void> pump(WidgetTester tester, Exercise exercise) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            defaultAccentOverride,
          ],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: Scaffold(body: ExerciseNoteTile(exercise: exercise)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an empty note says what to write, not "none"', (tester) async {
      // A labelled blank is something to wonder about; an example is an
      // instruction.
      await pump(tester, await exerciseRow('leg_press'));

      expect(find.textContaining('seat height'), findsOneWidget);
    });

    testWidgets('a written note is shown as written', (tester) async {
      await repo.setNotes('leg_press', 'Seat 4, back pad 2');

      await pump(tester, await exerciseRow('leg_press'));

      expect(find.text('Seat 4, back pad 2'), findsOneWidget);
    });

    testWidgets('tapping it opens the editor, prefilled', (tester) async {
      await repo.setNotes('leg_press', 'Seat 4');

      await pump(tester, await exerciseRow('leg_press'));
      await tester.tap(find.byType(ExerciseNoteTile));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Seat 4'), findsOneWidget);
      // Clear is only offered when there is something to clear.
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('no Clear button when there is nothing to clear', (
      tester,
    ) async {
      await pump(tester, await exerciseRow('leg_press'));
      await tester.tap(find.byType(ExerciseNoteTile));
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('cancelling leaves the note alone', (tester) async {
      // The one that matters. `showNamePromptDialog` returns null for both
      // "cancelled" and "left blank", and reusing that here would mean backing
      // out of a note you opened to read would delete it.
      await repo.setNotes('leg_press', 'Seat 4');

      await pump(tester, await exerciseRow('leg_press'));
      await tester.tap(find.byType(ExerciseNoteTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'something else');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final row = await exerciseRow('leg_press');
      expect(row.notes, 'Seat 4');
    });

    testWidgets('saving writes it through', (tester) async {
      await pump(tester, await exerciseRow('leg_press'));
      await tester.tap(find.byType(ExerciseNoteTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Seat 4, back pad 2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final row = await exerciseRow('leg_press');
      expect(row.notes, 'Seat 4, back pad 2');
    });

    testWidgets('Clear removes it', (tester) async {
      await repo.setNotes('leg_press', 'Seat 4');

      await pump(tester, await exerciseRow('leg_press'));
      await tester.tap(find.byType(ExerciseNoteTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      final row = await exerciseRow('leg_press');
      expect(row.notes, isNull);
    });
  });
}
