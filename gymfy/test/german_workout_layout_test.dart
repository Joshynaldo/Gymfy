// The workout, plan, programme, plate and library screens laid out in German
// at phone width — at the default text size and at 130%.
//
// German runs about a third longer than the English these screens were sized
// against, and the densest of them are used one-handed at a rack: the live
// workout card with its two buttons side by side, the log sheet's keypad and
// step label, the day builder's rows of facts. Like german_layout_test.dart,
// this checks that nothing overflows rather than the wording, plus the few
// places where the language changes what a control does or shows: the
// keypad's decimal comma, and a German muscle name finding an exercise.
//
// Providers are overridden rather than pointing at a real database where the
// screen allows it; drift keeps a stream-cleanup timer alive that
// `pumpAndSettle` waits on forever.

import 'dart:io';

import 'package:drift/native.dart';
// Material exports an animation curve also named `Split`.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/screens/exercise_form_screen.dart';
import 'package:gymfy/features/exercises/screens/exercise_library_screen.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/plan_share/screens/share_plan_screen.dart';
import 'package:gymfy/features/plates/screens/plate_calculator_screen.dart';
import 'package:gymfy/features/programs/data/program_catalog.dart';
import 'package:gymfy/features/programs/screens/programs_screen.dart';
import 'package:gymfy/features/programs/widgets/training_block_settings.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/active_workout_screen.dart';
import 'package:gymfy/features/workout/screens/day_builder_screen.dart';
import 'package:gymfy/features/workout/widgets/log_set_sheet.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';
import 'support/session_entries.dart';

const _sessionId = 1;
const _dayId = 10;

Exercise _exercise(
  String id,
  String name,
  List<String> muscles, {
  bool plateLoaded = false,
  bool custom = false,
}) => Exercise(
  id: id,
  name: name,
  muscleIds: muscles,
  isPlateLoaded: plateLoaded,
  isCustom: custom,
  isArchived: false,
  isTimed: false,
  equipment: 'barbell',
);

final _bench = _exercise('barbell_bench_press', 'Barbell Bench Press', [
  'chest',
  'front_deltoid',
  'triceps',
], plateLoaded: true);
final _incline = _exercise('incline_press', 'Incline Dumbbell Press', [
  'chest',
]);
final _row = _exercise('barbell_row', 'Barbell Row', ['lats', 'biceps']);
final _raise = _exercise('custom_lateral_raise', 'Cable Lateral Raise', [
  'side_deltoid',
], custom: true);

PlannedExercise _planned(
  Exercise exercise,
  int position, {
  int warmups = 0,
  int? group,
  int? repsMax,
  double? percent,
}) => PlannedExercise(
  entry: WorkoutExercise(
    id: position + 1,
    dayId: _dayId,
    exerciseId: exercise.id,
    position: position,
    defaultSets: 3,
    defaultReps: 8,
    defaultRepsMax: repsMax,
    warmupSets: warmups,
    supersetGroup: group,
    targetPercent: percent,
  ),
  exercise: exercise,
);

/// The day the live workout and the day builder show: a ramped-up main lift
/// in a superset, a percentage target and a range — every fact a row can
/// carry at once.
final _plan = [
  _planned(_bench, 0, warmups: 2, group: 1, repsMax: 12, percent: 72.5),
  _planned(_incline, 1, group: 1),
  _planned(_row, 2, warmups: 1),
];

LoggedSet _set(
  int id,
  Exercise exercise,
  int number,
  SetType type, {
  double? rpe,
}) => LoggedSet(
  id: id,
  sessionId: _sessionId,
  exerciseId: exercise.id,
  setNumber: number,
  weight: 62.5,
  reps: 8,
  setType: type.name,
  rpe: rpe,
);

final _split = Split(
  id: 1,
  name: 'Push / Pull / Legs',
  position: 0,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  blockWeeks: 4,
  deloadPercent: 60,
  blockStartedAt: DateTime.now().subtract(const Duration(days: 8)),
);

/// Read from disk rather than the asset bundle, which answers over a platform
/// channel a widget test's fake clock never lets finish.
PlanDocument _programFromDisk(String id) {
  final program = bundledPrograms.firstWhere((p) => p.id == id);
  return PlanDocument.decode(File(program.assetPath).readAsStringSync());
}

void main() {
  late AppDatabase db;

  /// Disposed after each test rather than with the widget tree: drift's
  /// stream cleanup timer would otherwise still be pending when the test
  /// checks for timers, the way german_layout_test.dart avoids it too.
  final containers = <ProviderContainer>[];

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async {
    for (final container in containers) {
      container.dispose();
    }
    containers.clear();
    await db.close();
  });

  /// Pumps [home] in German on a 360-wide phone and returns whatever the
  /// layout complained about.
  Future<Object?> pumpGerman(
    WidgetTester tester,
    Widget home, {
    required double scale,
    List overrides = const [],
    double height = 780,
  }) async {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ...defaultDisplayOverrides,
        ...overrides.cast(),
      ],
    );
    containers.add(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.darkDefault, AccentPalette.blue),
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    // Real database work, where a screen does any, finishes outside the fake
    // clock; then the entrances settle.
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return tester.takeException();
  }

  final workoutOverrides = [
    sessionRepositoryProvider.overrideWith((ref) => SessionRepository(db)),
    sessionProvider.overrideWith(
      (ref, id) => Stream.value(
        WorkoutSession(
          id: _sessionId,
          dayId: _dayId,
          name: 'Push',
          startedAt: DateTime(2026, 10, 1, 18),
        ),
      ),
    ),
    sessionSetsProvider.overrideWith(
      (ref, id) => Stream.value([
        _set(1, _bench, 1, SetType.warmup),
        _set(2, _bench, 1, SetType.normal, rpe: 8.5),
        _set(3, _bench, 2, SetType.failure),
      ]),
    ),
    sessionExercisesProvider.overrideWith(
      (ref, id) => Stream.value(sessionEntriesFor(_plan)),
    ),
    // The longest line the card can carry under the exercise's name.
    overloadSuggestionProvider.overrideWith(
      (ref, key) async => const OverloadSuggestion(
        weight: 82.5,
        reason: OverloadReason.atLimit,
      ),
    ),
  ];

  for (final scale in [1.0, 1.3]) {
    group('in German at text scale $scale', () {
      testWidgets('the live workout fits its card and its rows', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const ActiveWorkoutScreen(sessionId: _sessionId),
            scale: scale,
            overrides: workoutOverrides,
            height: 1400,
          ),
          isNull,
        );
        // The suggestion is a future of its own, a frame or two behind the
        // card. Everything here is overridden, so nothing keeps settling
        // from finishing.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.text('Satz 3 loggen'), findsOneWidget);
        expect(find.text('Aufwärmen 2/2'), findsOneWidget);
        expect(find.text('ALS NÄCHSTES'), findsOneWidget);
        expect(find.text('SUPERSATZ'), findsOneWidget);
        expect(
          find.text(
            'Supersatz mit Incline Dumbbell Press – Pause erst nach der '
            'letzten Übung',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Topsatz war letztes Mal am Limit – bleib bei 82,5 kg'),
          findsOneWidget,
        );
        // A half-step rating in the language's decimals, and the badges in
        // its letters: A for Aufwärmsatz, V for Versagen.
        expect(find.text('RPE 8,5'), findsOneWidget);
        expect(find.text('62,5 kg × 8 Wdh.'), findsNWidgets(3));
        expect(find.text('A'), findsOneWidget);
        expect(find.text('V'), findsOneWidget);
      });

      testWidgets('the day builder fits a row of every fact', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const DayBuilderScreen(dayId: _dayId),
            scale: scale,
            overrides: [
              workoutRepositoryProvider.overrideWith(
                (ref) => WorkoutRepository(db),
              ),
              dayProvider.overrideWith(
                (ref, id) => Stream.value(
                  WorkoutDay(id: _dayId, splitId: 1, name: 'Push', position: 0),
                ),
              ),
              dayExercisesProvider.overrideWith(
                (ref, id) => Stream.value(_plan),
              ),
            ],
          ),
          isNull,
        );

        expect(find.text('SUPERSATZ · PAUSE NACH DER LETZTEN'), findsOneWidget);
        expect(
          find.text('3 Sätze × 8–12 Wdh. • 2 Aufwärmsätze • @ 72,5 % 1RM'),
          findsOneWidget,
        );
        expect(find.text('Training starten'), findsOneWidget);
        expect(find.text('Übungen hinzufügen'), findsOneWidget);
      });

      testWidgets('the plate calculator fits the bar choices and the result', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const PlateCalculatorScreen(initialWeight: 102.5),
            scale: scale,
            height: 1200,
          ),
          isNull,
        );

        expect(find.text('Keine'), findsOneWidget);
        expect(find.text('Gesamt'), findsOneWidget);
        expect(tester.widget<Text>(find.byKey(plateTotalKey)).data, '102,5');
        expect(find.text('Stange 20 + Scheiben 82,5 kg'), findsOneWidget);
      });

      testWidgets('the programme list fits its facts', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const ProgramsScreen(),
            scale: scale,
            height: 1600,
          ),
          isNull,
        );

        expect(
          find.textContaining('3 Tage pro Woche · Einsteiger'),
          findsNWidgets(2),
        );
        // The programme's own name stays as it is in the file.
        expect(find.text('Push / Pull / Legs'), findsOneWidget);
      });

      testWidgets('a programme fits its days', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const ProgramDetailScreen(programId: 'percentage_strength'),
            scale: scale,
            height: 2400,
            overrides: [
              bundledProgramProvider.overrideWith(
                (ref, id) async => _programFromDisk(id),
              ),
            ],
          ),
          isNull,
        );

        expect(find.text('Zu meinen Splits hinzufügen'), findsOneWidget);
      });

      testWidgets('the training block sheet fits its week counter', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            Scaffold(body: TrainingBlockSheet(split: _split)),
            scale: scale,
            height: 1000,
          ),
          isNull,
        );

        expect(find.text('Trainingswochen'), findsOneWidget);
        expect(find.text('4 Wochen'), findsOneWidget);
        expect(find.text('60 %'), findsOneWidget);
      });

      testWidgets('sharing a plan fits its two buttons side by side', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const SharePlanScreen(),
            scale: scale,
            overrides: [
              splitListProvider.overrideWith((ref) => Stream.value([_split])),
            ],
          ),
          isNull,
        );

        expect(find.text('Datei speichern'), findsOneWidget);
        expect(find.text('Plan importieren'), findsOneWidget);
      });

      testWidgets('the library fits its sections and chips', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const ExerciseLibraryScreen(),
            scale: scale,
            height: 1200,
            overrides: [
              exerciseListProvider.overrideWith(
                (ref) => Stream.value([_bench, _row, _raise]),
              ),
              allDaysProvider.overrideWith((ref) => Stream.value(const [])),
            ],
          ),
          isNull,
        );

        expect(find.text('Übungen'), findsOneWidget);
        // Section headings and the muscles under each exercise in German;
        // the exercise names stay English.
        expect(find.text('Brust'), findsWidgets);
        expect(find.text('Rücken'), findsWidgets);
        expect(find.text('Barbell Bench Press'), findsOneWidget);
        expect(find.text('Eigene'), findsOneWidget);
      });

      testWidgets('a new exercise fits every muscle chip', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const ExerciseFormScreen(),
            scale: scale,
            height: 1600,
          ),
          isNull,
        );

        expect(find.text('Neue Übung'), findsOneWidget);
        expect(find.text('Vordere Schulter'), findsOneWidget);
        expect(find.text('Mit Scheiben beladen'), findsOneWidget);
      });
    });
  }

  group('the log sheet in German', () {
    /// A key on the pad, rather than the same digit on a rating chip or in
    /// the readout.
    Finder keypad(String label) =>
        find.descendant(of: find.byType(GridView), matching: find.text(label));

    /// Opens the sheet from a button, the way the workout does.
    Future<List<LoggedSetInput?>> open(
      WidgetTester tester, {
      required double scale,
    }) async {
      final results = <LoggedSetInput?>[];
      final error = await pumpGerman(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => results.add(
                  await showLogSetSheet(
                    context: context,
                    exercise: _bench,
                    initialWeight: 0,
                    initialReps: 8,
                    unit: WeightUnit.kg,
                    phaseLabel: context.l10n.workoutPhaseWorking(1),
                    suggestion: const OverloadSuggestion(
                      weight: 82.5,
                      reason: OverloadReason.percentOfMax,
                      targetPercent: 72.5,
                    ),
                    repeatable: _set(9, _bench, 1, SetType.normal),
                    effortMode: EffortRatingMode.rpe,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        scale: scale,
        height: 900,
      );
      expect(error, isNull);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    for (final scale in [1.0, 1.3]) {
      testWidgets('fits both steps at text scale $scale', (tester) async {
        await open(tester, scale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('SCHRITT 1 – GEWICHT'), findsOneWidget);
        expect(find.text('Satz 1 · Arbeitssatz'), findsOneWidget);
        expect(find.text('Scheiben stapeln'), findsOneWidget);
        expect(
          find.text('Geplant mit 72,5 % deines 1RM – 82,5 kg.'),
          findsOneWidget,
        );

        await tester.tap(keypad('1'));
        await tester.pump();
        await tester.tap(find.text('Weiter: Wdh.'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('SCHRITT 2 – WIEDERHOLUNGEN'), findsOneWidget);
        expect(find.text('WIE SCHWER · RPE'), findsOneWidget);
        expect(find.text('8,5'), findsOneWidget);
        expect(find.text('Satz speichern'), findsOneWidget);
      });
    }

    testWidgets('the decimal key shows a comma and still means a point', (
      tester,
    ) async {
      final results = await open(tester, scale: 1);

      // No "." anywhere on the pad: German writes a weight with a comma.
      expect(find.text('.'), findsNothing);
      for (final key in ['1', '0', '2', ',', '5']) {
        await tester.tap(keypad(key));
        await tester.pump();
      }
      expect(find.text('102,5'), findsOneWidget);

      await tester.tap(find.text('Weiter: Wdh.'));
      await tester.pumpAndSettle();
      await tester.tap(keypad('8'));
      await tester.pump();
      await tester.tap(find.text('Satz speichern'));
      await tester.pumpAndSettle();

      expect(results.single?.weight, 102.5);
      expect(results.single?.reps, 8);
    });
  });

  testWidgets('a German muscle name finds the exercise, and keeps its chips', (
    tester,
  ) async {
    await pumpGerman(
      tester,
      const ExerciseLibraryScreen(),
      scale: 1,
      overrides: [
        exerciseListProvider.overrideWith(
          (ref) => Stream.value([_bench, _row, _raise]),
        ),
        allDaysProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );

    await tester.enterText(find.byType(TextField), 'Trizeps');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Barbell Row'), findsNothing);
    // The filter chips are worked out from the same German-aware search, so
    // the bench press's muscles are still on offer rather than an empty bar.
    expect(find.text('Trizeps'), findsOneWidget);
  });
}
