// The progress, rank, goals, review, calorie, backup, export, import and
// Health Connect screens laid out in German at phone width — at the default
// text size and at 130%.
//
// Like german_workout_layout_test.dart, this checks that nothing overflows
// rather than the wording, plus a line or two per screen where the language
// changes what the screen shows: a decimal comma, a German month, a plural.
// The screens chosen are the dense ones — segmented controls with three long
// labels, stat grids, rows with a value pinned to the right.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/backup/screens/backup_screen.dart';
import 'package:gymfy/features/calculator/data/rank_inputs.dart';
import 'package:gymfy/features/calculator/data/ranked_lifts.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/calculator/screens/one_rm_calculator_screen.dart';
import 'package:gymfy/features/calculator/screens/strength_rank_screen.dart';
import 'package:gymfy/features/calories/screens/calorie_log_screen.dart';
import 'package:gymfy/features/data_export/screens/export_screen.dart';
import 'package:gymfy/features/exercises/data/exercise_names.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/goals/data/goal_repository.dart';
import 'package:gymfy/features/goals/screens/goals_screen.dart';
import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';
import 'package:gymfy/features/health_connect/widgets/health_connect_settings_panel.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/import/screens/import_screen.dart';
import 'package:gymfy/features/muscle_map/data/muscle_fatigue_repository.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';
import 'package:gymfy/features/progress/screens/measurements_screen.dart';
import 'package:gymfy/features/reviews/data/review.dart';
import 'package:gymfy/features/reviews/screens/review_screen.dart';
import 'package:gymfy/features/stats/widgets/stats_sections.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/data/week_start.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/goal.dart';

import 'support/default_accent.dart';
import 'support/fake_health_connect.dart';
import 'support/weight_wheel.dart';

RankedLift _lift(String name, StrengthTier tier, {bool tested = false}) => (
  exerciseId: name.toLowerCase().replaceAll(' ', '_'),
  name: name,
  oneRm: 102.5,
  tested: tested,
  rank: (
    tier: tier,
    next: tier.next,
    ratio: 1.24,
    progressToNext: tier.next == null ? null : 0.4,
    weightToNext: tier.next == null ? null : 12.5,
  ),
);

/// The longest tier names, and a lift at the top with nothing above it.
final _lifts = [
  _lift('Romanian Deadlift', StrengthTier.elite, tested: true),
  _lift('Barbell Bench Press', StrengthTier.intermediate),
  _lift('Overhead Barbell Press', StrengthTier.beginner),
];

RecapSet _set(DateTime date, int session, {double weight = 100}) => (
  date: date,
  sessionId: session,
  exerciseId: 'barbell_bench_press',
  weight: weight,
  reps: 5,
  muscleIds: const ['chest', 'triceps'],
);

/// A September against an August, as review_screen_test.dart has them.
final _sets = [
  _set(DateTime(2026, 8, 12, 18), 1),
  _set(DateTime(2026, 9, 1, 18), 2),
  _set(DateTime(2026, 9, 8, 18), 3),
  _set(DateTime(2026, 9, 15, 18), 4, weight: 110),
];

final _days = <DateTime, DayTraining>{
  DateTime(2026, 8, 12): (minutes: 60, untimed: 0),
  DateTime(2026, 9, 1): (minutes: 60, untimed: 0),
  DateTime(2026, 9, 8): (minutes: 45, untimed: 0),
  DateTime(2026, 9, 15): (minutes: 0, untimed: 1),
};

GoalStatus _goal(int id, GoalKind kind, double target, double current) =>
    GoalStatus(
      goal: Goal(
        id: id,
        kind: kind.name,
        exerciseId: kind == GoalKind.lift ? 'barbell_bench_press' : null,
        target: target,
        startValue: kind == GoalKind.frequency ? null : target - 10,
        createdAt: DateTime(2026, 9, 1),
      ),
      kind: kind,
      current: current,
      fraction: 0.5,
      reachedAt: null,
      daysLeft: 12,
      weekStreak: kind == GoalKind.frequency ? 3 : 0,
    );

void main() {
  late AppDatabase db;
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
    double height = 1400,
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
    // clock; then the entrances settle. Plain pumps rather than settling:
    // drift keeps a stream-cleanup timer alive that pumpAndSettle would wait
    // on forever.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 600));
    return tester.takeException();
  }

  final rankOverrides = [
    rankInputsProvider.overrideWithValue((
      sex: LifterSex.female,
      bodyweightKg: 62.5,
      measuredOn: DateTime(2026, 9, 30),
    )),
    rankedLiftsProvider.overrideWithValue((
      ranked: _lifts,
      unlogged: const ['Barbell Hip Thrust', 'Power Clean'],
    )),
  ];

  final reviewOverrides = [
    recapSetsProvider.overrideWith((ref) => Stream.value(_sets)),
    allTrainingByDayProvider.overrideWith((ref) => Stream.value(_days)),
    recordsByDayProvider.overrideWith(
      (ref) => Stream.value({DateTime(2026, 9, 15): 2}),
    ),
    exerciseNamesProvider.overrideWithValue({
      'barbell_bench_press': 'Barbell Bench Press',
    }),
  ];

  for (final scale in [1.0, 1.3]) {
    group('in German at text scale $scale', () {
      testWidgets('the strength rank fits its basis line and lift cards', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const StrengthRankScreen(),
            scale: scale,
            height: 2000,
            overrides: rankOverrides,
          ),
          isNull,
        );

        expect(
          find.text('Standards für Frauen • 62,5 kg Körpergewicht (30. Sept.)'),
          findsOneWidget,
        );
        expect(find.text('Männer nutzen'), findsOneWidget);
        expect(
          find.text('Höchste Stufe – darüber gibt es nichts'),
          findsOneWidget,
        );
        expect(
          find.text('102,5 kg geschätzt • 1,24× Körpergewicht'),
          findsWidgets,
        );
        expect(find.text('12,5 kg bis Erfahren'), findsOneWidget);
      });

      testWidgets('the rank section and all-time totals fit their grid', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const Scaffold(
              body: SingleChildScrollView(
                child: Column(children: [RankSection(), TotalsSection()]),
              ),
            ),
            scale: scale,
            height: 2000,
            overrides: [
              ...rankOverrides,
              recapSetsProvider.overrideWith((ref) => Stream.value(_sets)),
              activityMinutesProvider.overrideWith(
                (ref) => Stream.value(_days),
              ),
              workoutStreakProvider.overrideWith((ref) => Stream.value(1)),
              weeklyMuscleIntensitiesProvider.overrideWith(
                (ref) => Stream.value(const <String, double>{}),
              ),
              muscleFatigueProvider.overrideWith(
                (ref) => Stream.value(const <String, double>{}),
              ),
            ],
          ),
          isNull,
        );

        expect(find.text('Neuling'), findsOneWidget);
        expect(
          find.text(
            'Deine schwächste bewertete Übung. Deine beste liegt auf Stufe '
            'Elite.',
          ),
          findsOneWidget,
        );
        expect(find.text('Insgesamt'), findsOneWidget);
        expect(find.text('Tag in Folge'), findsOneWidget);
        // 2,050 kg lifted: the comparison, with a German decimal comma.
        expect(find.text('Das sind 1,7 Kleinwagen.'), findsOneWidget);
      });

      testWidgets('the 1RM calculator fits its result and tables', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const OneRmCalculatorScreen(),
            scale: scale,
            height: 2600,
          ),
          isNull,
        );
        await pickWeight(tester, whole: 100);
        expect(tester.takeException(), isNull);

        expect(find.text('Geschätztes 1RM'), findsOneWidget);
        expect(find.text('114,5'), findsOneWidget);
        expect(
          find.text('Durchschnitt aus 3 Formeln • Spanne 112,5–116,5 kg'),
          findsOneWidget,
        );
        expect(find.text('10 Wdh.'), findsOneWidget);
        // A no-break space before the sign, as German writes it.
        expect(find.text('100\u00a0%'), findsOneWidget);
      });

      testWidgets('the monthly review fits its card', (tester) async {
        expect(
          await pumpGerman(
            tester,
            ReviewScreen(
              initial: ReviewPeriod.month(2026, 9),
              today: DateTime(2026, 10, 1),
            ),
            scale: scale,
            height: 2000,
            overrides: reviewOverrides,
          ),
          isNull,
        );

        expect(find.text('Monatsrückblick'), findsOneWidget);
        expect(find.text('DEIN TRAININGSMONAT'), findsOneWidget);
        expect(find.text('+2 vs. August'), findsNWidgets(2));
        expect(find.text('1.550 kg'), findsWidgets);
        expect(find.text('trainiert, 1 ohne Zeit'), findsOneWidget);
      });

      testWidgets('the goals list and the form fit their controls', (
        tester,
      ) async {
        expect(
          await pumpGerman(
            tester,
            const GoalsScreen(),
            scale: scale,
            height: 1400,
            overrides: [
              firstWeekdayProvider.overrideWithValue(DateTime.monday),
              exerciseNamesProvider.overrideWithValue({
                'barbell_bench_press': 'Barbell Bench Press',
              }),
              goalStatusesProvider.overrideWithValue([
                _goal(1, GoalKind.lift, 102.5, 95),
                _goal(2, GoalKind.frequency, 4, 1),
                _goal(3, GoalKind.bodyweight, 78, 80),
              ]),
            ],
          ),
          isNull,
        );

        expect(find.text('In Arbeit'), findsOneWidget);
        expect(
          find.text('Noch 3 diese Woche · 3 Wochen in Folge'),
          findsOneWidget,
        );
        expect(find.text('Barbell Bench Press · 102,5 kg'), findsOneWidget);
        expect(find.text('Schwerster Arbeitssatz'), findsOneWidget);

        await tester.tap(find.byTooltip('Neues Ziel'));
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(() => pumpEventQueue());
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);
        expect(find.text('Körpergewicht'), findsOneWidget);
        expect(find.text('Ohne Frist'), findsOneWidget);
      });

      testWidgets('backup fits its three-way automatic switch', (tester) async {
        expect(
          await pumpGerman(
            tester,
            const BackupScreen(),
            scale: scale,
            height: 1800,
          ),
          isNull,
        );

        expect(find.text('Nach dem Training'), findsOneWidget);
        expect(find.text('Wöchentlich'), findsOneWidget);
        expect(find.text('Kein Ordner gewählt'), findsOneWidget);
      });

      testWidgets('the export fits its two formats', (tester) async {
        expect(
          await pumpGerman(tester, const ExportScreen(), scale: scale),
          isNull,
        );

        expect(find.text('CSV speichern'), findsOneWidget);
        expect(find.text('Das ist eine Kopie, kein Backup'), findsOneWidget);
      });

      testWidgets('the import explains itself before a file is picked', (
        tester,
      ) async {
        expect(
          await pumpGerman(tester, const ImportScreen(), scale: scale),
          isNull,
        );

        expect(find.text('Nimm deinen Verlauf mit'), findsOneWidget);
        expect(find.text('Datei auswählen'), findsOneWidget);
      });

      testWidgets('the calorie log fits its summary and macros', (
        tester,
      ) async {
        expect(
          await pumpGerman(tester, const CalorieLogScreen(), scale: scale),
          isNull,
        );

        expect(find.text('Heute'), findsOneWidget);
        expect(find.text('Makros'), findsOneWidget);
        expect(find.text('Mahlzeit hinzufügen'), findsOneWidget);
      });

      testWidgets('the measurements fit their rows', (tester) async {
        expect(
          await pumpGerman(tester, const MeasurementsScreen(), scale: scale),
          isNull,
        );

        expect(find.text('Körpermaße'), findsOneWidget);
        expect(find.text('Taille'), findsOneWidget);
      });

      testWidgets('the Health Connect section fits its switches', (
        tester,
      ) async {
        final health = FakeHealthConnect()..granted = {readWeightPermission};
        expect(
          await pumpGerman(
            tester,
            const Scaffold(
              body: SingleChildScrollView(child: HealthConnectSettingsPanel()),
            ),
            scale: scale,
            overrides: [healthConnectBridgeProvider.overrideWithValue(health)],
          ),
          isNull,
        );

        expect(find.text('Verfügbar'), findsOneWidget);
        expect(find.text('Trainings eintragen'), findsOneWidget);
        expect(
          find.text('Trainings: nicht erlaubt · Gewicht: erlaubt'),
          findsOneWidget,
        );
      });
    });
  }
}
