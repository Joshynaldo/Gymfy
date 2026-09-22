// Reading a training plan back out of an imported history.
//
// The arithmetic is the whole feature, so it is tested on its own, away from
// the database: given these sessions, is this the split the person actually
// trains? The two rules worth being sure of are that a one-off exercise does
// not end up in the plan, and that a day trained forty times reflects what it
// is now rather than the average of two years.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/import/data/import_format.dart';
import 'package:gymfy/features/import/data/import_plan.dart';

/// A session, written the short way so a test can say what it is about.
ImportedSession _session(
  String name,
  DateTime start,
  List<(String exercise, int reps)> sets, {
  Set<String> warmups = const {},
}) {
  return ImportedSession(
    name: name,
    start: start,
    end: start.add(const Duration(hours: 1)),
    sets: [
      for (final (exercise, reps) in sets)
        ImportedSet(
          exerciseName: exercise,
          weightKg: 60,
          reps: reps,
          isWarmup: warmups.contains(exercise),
          seconds: null,
        ),
    ],
  );
}

/// One day trained three times, always the same two lifts.
List<ImportedSession> _threeTimes(String name) => [
  for (var week = 0; week < 3; week++)
    _session(name, DateTime(2026, 1, 5 + week * 7, 18), const [
      ('Barbell Bench Press', 8),
      ('Barbell Bench Press', 8),
      ('Barbell Bench Press', 7),
      ('Cable Fly', 12),
      ('Cable Fly', 12),
    ]),
];

void main() {
  group('the days of the split', () {
    test('one per workout name in the file', () {
      final plan = planFromSessions([
        ..._threeTimes('Push'),
        ..._threeTimes('Pull'),
      ]);

      expect(plan.map((d) => d.name), unorderedEquals(['Push', 'Pull']));
      expect(plan.every((d) => d.sessionCount == 3), isTrue);
    });

    test('the most recently trained day comes first', () {
      // So the day you did yesterday is at the top of the split rather than
      // buried under one you dropped in the spring.
      final plan = planFromSessions([
        _session('Old', DateTime(2026, 1, 5), const [('Squat', 5)]),
        _session('Recent', DateTime(2026, 6, 5), const [('Deadlift', 5)]),
      ]);

      expect(plan.map((d) => d.name), ['Recent', 'Old']);
    });

    test('one name however it is capitalised', () {
      // "Push " and "push" out of one file are one day; splitting them gives
      // the user two half-populated ones.
      final plan = planFromSessions([
        _session('Push', DateTime(2026, 1, 5), const [('Squat', 5)]),
        _session(' push ', DateTime(2026, 1, 12), const [('Squat', 5)]),
      ]);

      expect(plan, hasLength(1));
      expect(plan.single.name, 'Push', reason: 'the spelling used longest');
      expect(plan.single.sessionCount, 2);
    });

    test('a file with no workout names makes no plan at all', () {
      // Rather than one day called nothing, holding everything ever logged.
      final plan = planFromSessions([
        _session('', DateTime(2026, 1, 5), const [('Squat', 5)]),
      ]);

      expect(plan, isEmpty);
    });

    test('a name too long for the column is cut, not rejected', () {
      // Splits.name and WorkoutDays.name are `withLength(min: 1, max: 60)`,
      // and drift throws rather than truncating. A workout called something
      // long is still that workout; refusing the whole import over a title is
      // not a trade anyone would choose.
      final long =
          'Wednesday Afternoon: ${'Chest, Shoulders and Triceps ' * 3}';
      final plan = planFromSessions([
        _session(long, DateTime(2026, 1, 5), const [('Squat', 5)]),
      ]);

      expect(plan.single.name.length, lessThanOrEqualTo(planNameLimit));
      expect(plan.single.name, endsWith('…'));
    });

    test('the cut never lands inside a character', () {
      // Dart counts UTF-16 units and an emoji is two of them. Cutting between
      // the halves leaves a lone surrogate, which renders as a box.
      final name = '${'A' * 58}🔥 and more besides';
      final plan = planFromSessions([
        _session(name, DateTime(2026, 1, 5), const [('Squat', 5)]),
      ]);

      final fitted = plan.single.name;
      expect(fitted.length, lessThanOrEqualTo(planNameLimit));
      for (var i = 0; i < fitted.length; i++) {
        final unit = fitted.codeUnitAt(i);
        final isHigh = unit >= 0xd800 && unit <= 0xdbff;
        if (!isHigh) continue;
        // A high surrogate must be followed by its low one.
        expect(i + 1, lessThan(fitted.length));
        expect(fitted.codeUnitAt(i + 1), inInclusiveRange(0xdc00, 0xdfff));
      }
    });
  });

  group('the exercises of a day', () {
    test('are the ones actually trained on it, in the order trained', () {
      final plan = planFromSessions(_threeTimes('Push'));

      expect(plan.single.exercises.map((e) => e.exerciseName), [
        'Barbell Bench Press',
        'Cable Fly',
      ]);
    });

    test('a one-off substitution does not join the programme', () {
      // The machine you used once because your bench was taken is not part of
      // your split, and a plan that accumulates every improvisation is one
      // the user has to prune by hand.
      final sessions = [
        ..._threeTimes('Push'),
        _session('Push', DateTime(2026, 2, 2, 18), const [
          ('Barbell Bench Press', 8),
          ('Smith Machine Press', 8),
        ]),
      ];

      final names = planFromSessions(
        sessions,
      ).single.exercises.map((e) => e.exerciseName);

      expect(names, contains('Barbell Bench Press'));
      expect(names, isNot(contains('Smith Machine Press')));
    });

    test('a single session puts everything in', () {
      // Half of one is still one, so somebody importing a month of training
      // gets a usable day rather than an empty one.
      final plan = planFromSessions([
        _session('Push', DateTime(2026, 1, 5), const [
          ('Barbell Bench Press', 8),
          ('Cable Fly', 12),
        ]),
      ]);

      expect(plan.single.exercises, hasLength(2));
    });

    test('only the recent sessions are read', () {
      // A day trained for two years has almost certainly changed. What it was
      // built on last spring should not still be in the plan.
      final sessions = [
        for (var week = 0; week < 10; week++)
          _session('Push', DateTime(2026, 1, 5 + week * 7, 18), const [
            ('Dropped Lift', 8),
          ]),
        for (var week = 0; week < 10; week++)
          _session('Push', DateTime(2026, 6, 1 + week * 7, 18), const [
            ('Current Lift', 8),
          ]),
      ];

      final names = planFromSessions(
        sessions,
        recentSessions: 8,
      ).single.exercises.map((e) => e.exerciseName);

      expect(names, ['Current Lift']);
    });
  });

  group('the targets of a planned exercise', () {
    test('are the sets and reps that were actually done', () {
      final plan = planFromSessions(_threeTimes('Push'));
      final bench = plan.single.exercises.first;

      expect(bench.sets, 3);
      expect(bench.reps, 8, reason: 'the middle of 8, 8, 7');
      expect(bench.warmupSets, 0);
    });

    test('a short session does not drag the target down', () {
      // A median rather than a mean: one day you were short of time and did
      // two sets instead of four is not a reason to plan three forever.
      final sessions = [
        for (var week = 0; week < 3; week++)
          _session('Push', DateTime(2026, 1, 5 + week * 7, 18), const [
            ('Squat', 5),
            ('Squat', 5),
            ('Squat', 5),
            ('Squat', 5),
          ]),
        _session('Push', DateTime(2026, 2, 2, 18), const [('Squat', 5)]),
      ];

      expect(planFromSessions(sessions).single.exercises.single.sets, 4);
    });

    test('ramp-up sets are counted as ramp-ups, not as working sets', () {
      final sessions = [
        for (var week = 0; week < 3; week++)
          _session(
            'Push',
            DateTime(2026, 1, 5 + week * 7, 18),
            const [
              ('Barbell Bench Press', 10),
              ('Barbell Bench Press', 8),
              ('Barbell Bench Press', 8),
            ],
            warmups: const {'Barbell Bench Press'},
          ),
      ];

      // Every set of it was a warm-up in this fixture, so the working count
      // floors at one rather than planning zero sets of something.
      final bench = planFromSessions(sessions).single.exercises.single;
      expect(bench.warmupSets, 3);
      expect(bench.sets, 1);
    });

    test('an exercise logged only by time still gets a target', () {
      // A plank has no reps to take a middle of. Ten is the app's own
      // default, and the day screen can change it.
      final plan = planFromSessions([
        ImportedSession(
          name: 'Core',
          start: DateTime(2026, 1, 5),
          end: null,
          sets: const [
            ImportedSet(
              exerciseName: 'Plank',
              weightKg: 0,
              reps: 0,
              isWarmup: false,
              seconds: 45,
            ),
          ],
        ),
      ]);

      expect(plan.single.exercises.single.reps, 10);
      expect(plan.single.exercises.single.sets, 1);
    });
  });

  group('the weekdays a day is trained on', () {
    test('are read off the history', () {
      // Without these the split is active and invisible: nothing is scheduled,
      // so Home answers "Rest day — nothing scheduled" every day of the week,
      // with no button on it. The history knows — the real export trains
      // "Upper Day (Freitags)" on a Friday eight times out of eight.
      final plan = planFromSessions([
        for (var week = 0; week < 4; week++)
          _session('Upper', DateTime(2026, 1, 2 + week * 7, 18), const [
            ('Squat', 5),
          ]),
      ]);

      expect(plan.single.weekdays, [DateTime.friday]);
    });

    test('a day trained twice a week keeps both', () {
      // What a six-day split does: Push on Monday and Thursday. Storing one
      // would force two identical days, splitting their logged history.
      final plan = planFromSessions([
        for (var week = 0; week < 3; week++) ...[
          _session('Push', DateTime(2026, 1, 5 + week * 7, 18), const [
            ('Squat', 5),
          ]),
          _session('Push', DateTime(2026, 1, 8 + week * 7, 18), const [
            ('Squat', 5),
          ]),
        ],
      ]);

      expect(plan.single.weekdays, [DateTime.monday, DateTime.thursday]);
    });

    test('a stray session does not put the day on that weekday', () {
      // One workout moved to a Sunday because of a holiday is not a schedule.
      final plan = planFromSessions([
        for (var week = 0; week < 5; week++)
          _session('Push', DateTime(2026, 1, 5 + week * 7, 18), const [
            ('Squat', 5),
          ]),
        _session('Push', DateTime(2026, 2, 15, 18), const [('Squat', 5)]),
      ]);

      expect(plan.single.weekdays, [DateTime.monday]);
    });

    test('a history that never settled schedules nothing', () {
      // Six sessions on six different weekdays. Claiming all of them would
      // bury every other day of the split.
      final plan = planFromSessions([
        for (var day = 5; day < 11; day++)
          _session('Whenever', DateTime(2026, 1, day, 18), const [
            ('Squat', 5),
          ]),
      ]);

      expect(plan.single.weekdays, isEmpty);
    });
  });

  group('what the split is called', () {
    test('names the app it came from, when the file said', () {
      expect(defaultSplitName('Hevy'), 'Hevy import');
      expect(defaultSplitName('StrengthLog'), 'StrengthLog import');
    });

    test('and says something useful when it did not', () {
      expect(defaultSplitName(null), 'Imported split');
    });
  });
}
