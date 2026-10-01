// The programme browser: the list, a programme's detail, and adding one as a
// split — including the case where the name is already taken.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/programs/data/program_catalog.dart';
import 'package:gymfy/features/programs/screens/programs_screen.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

/// Read from disk rather than the asset bundle: the bundle answers over a
/// platform channel, which a widget test's fake clock never lets finish.
PlanDocument _fromDisk(String id) {
  final program = bundledPrograms.firstWhere((p) => p.id == id);
  return PlanDocument.decode(File(program.assetPath).readAsStringSync());
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ...defaultDisplayOverrides,
        bundledProgramProvider.overrideWith((ref, id) async => _fromDisk(id)),
      ],
    );
    await db.batch((batch) => batch.insertAll(db.exercises, exerciseSeedData));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/workout/programs',
          builder: (context, state) => const ProgramsScreen(),
          routes: [
            GoRoute(
              path: ':programId',
              builder: (context, state) => ProgramDetailScreen(
                programId: state.pathParameters['programId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/workout/split/:splitId',
          builder: (context, state) =>
              Text('split ${state.pathParameters['splitId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets real database work finish; drift's cleanup timer means
  /// `pumpAndSettle` alone never would.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('lists every bundled programme with its facts', (tester) async {
    await pumpAt(tester, '/workout/programs');

    for (final program in bundledPrograms) {
      expect(find.text(program.name), findsOneWidget);
    }
    expect(find.textContaining('3 days a week · Beginner'), findsWidgets);
  });

  testWidgets('a programme shows its description and every day', (
    tester,
  ) async {
    await pumpAt(tester, '/workout/programs/percentage_strength');

    final program = bundledPrograms.firstWhere(
      (p) => p.id == 'percentage_strength',
    );
    expect(find.text(program.description), findsOneWidget);
    for (final day in _fromDisk(program.id).splits.single.days) {
      // findsWidgets: "Deadlift" is both a day and the lift on it.
      expect(find.text(day.name), findsWidgets);
    }
    // The percentage is part of the target, the way a programme sheet says it.
    expect(find.text('5 × 5 @ 75%'), findsWidgets);
  });

  testWidgets('adding a programme imports it and opens the new split', (
    tester,
  ) async {
    await pumpAt(tester, '/workout/programs/full_body_5x5');

    await tester.tap(find.text('Add to my splits'));
    await settle(tester);

    final splits = (await tester.runAsync(() => db.select(db.splits).get()))!;
    expect(splits.single.name, 'Full Body 5×5');
    expect(find.text('split ${splits.single.id}'), findsOneWidget);
  });

  testWidgets('a name clash asks for a new name and keeps yours', (
    tester,
  ) async {
    await tester.runAsync(
      () => WorkoutRepository(db).createSplit('Full Body 5×5'),
    );
    await pumpAt(tester, '/workout/programs/full_body_5x5');

    await tester.tap(find.text('Add to my splits'));
    await settle(tester);

    expect(find.text('Name already used'), findsOneWidget);
    await tester.tap(find.text('Import'));
    await settle(tester);

    final names = (await tester.runAsync(
      () => db.select(db.splits).get(),
    ))!.map((s) => s.name);
    expect(names, containsAll(['Full Body 5×5', 'Full Body 5×5 (2)']));
  });
}
