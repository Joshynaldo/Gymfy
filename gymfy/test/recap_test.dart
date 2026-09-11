// The Home tab's recap: bucketing a training log into week / month / year, and
// counting personal records.
//
// Pure functions, no database — the bucket boundaries and the PR walk are where
// the bugs would hide, and both are easier to pin down with hand-built sets.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/data/recap.dart';

void main() {
  // A Friday, so the weekday labels below are checkable by hand.
  final today = DateTime(2026, 7, 24);

  RecapSet set({
    required DateTime date,
    int session = 1,
    String exercise = 'bench',
    double weight = 100,
    int reps = 10,
    List<String> muscles = const ['chest'],
  }) {
    return (
      date: date,
      sessionId: session,
      exerciseId: exercise,
      weight: weight,
      reps: reps,
      muscleIds: muscles,
    );
  }

  RecapSummary summarise(
    List<RecapSet> sets, {
    RecapPeriod period = RecapPeriod.week,
  }) {
    return summariseRecap(period: period, today: today, allSets: sets);
  }

  group('setVolume', () {
    test('weight times reps for a loaded set', () {
      expect(setVolume(100, 10), 1000);
    });

    test('bodyweight sets count their reps, not zero', () {
      // Otherwise every pull-up would score nothing and vanish from the totals.
      expect(setVolume(0, 12), 12);
    });
  });

  group('bucketStarts', () {
    test('a week is seven days ending today', () {
      final starts = bucketStarts(RecapPeriod.week, today);

      expect(starts, hasLength(7));
      expect(starts.first, DateTime(2026, 7, 18));
      expect(starts.last, DateTime(2026, 7, 24));
    });

    test('a month is five seven-day blocks ending today', () {
      final starts = bucketStarts(RecapPeriod.month, today);

      expect(starts, hasLength(5));
      // The last block covers the last seven days, ending today. Snapping to
      // Mondays instead would make the final bar a stub that looks like a
      // collapse in volume every Monday morning.
      expect(starts.last, DateTime(2026, 7, 18));
      expect(starts.first, DateTime(2026, 6, 20));
    });

    test('a year is twelve calendar months ending this one', () {
      final starts = bucketStarts(RecapPeriod.year, today);

      expect(starts, hasLength(12));
      expect(starts.last, DateTime(2026, 7, 1));
      expect(starts.first, DateTime(2025, 8, 1));
    });
  });

  group('bucketLabel', () {
    test('days are weekday initials', () {
      // 2026-07-24 is a Friday.
      expect(bucketLabel(DateTime(2026, 7, 24), RecapGrain.day), 'F');
      expect(bucketLabel(DateTime(2026, 7, 20), RecapGrain.day), 'M');
    });

    test('weeks are the day they start on', () {
      expect(bucketLabel(DateTime(2026, 7, 18), RecapGrain.week), '18');
    });

    test('months are month initials', () {
      expect(bucketLabel(DateTime(2026, 7, 1), RecapGrain.month), 'J');
      expect(bucketLabel(DateTime(2025, 12, 1), RecapGrain.month), 'D');
    });
  });

  group('bucketing volume', () {
    test('an empty log is an empty recap', () {
      final recap = summarise([]);

      expect(recap.isEmpty, isTrue);
      expect(recap.totalVolumeKg, 0);
      expect(recap.buckets, hasLength(7));
      expect(recap.buckets.every((b) => b.volumeKg == 0), isTrue);
    });

    test("today's sets land in the last bucket", () {
      final recap = summarise([set(date: today)]);

      expect(recap.buckets.last.volumeKg, 1000);
      expect(recap.buckets.first.volumeKg, 0);
    });

    test('the time of day is ignored', () {
      final recap = summarise([set(date: DateTime(2026, 7, 24, 23, 45))]);

      expect(recap.buckets.last.volumeKg, 1000);
    });

    test('sets older than the period are excluded', () {
      final recap = summarise([set(date: DateTime(2026, 7, 1))]);

      expect(recap.totalVolumeKg, 0);
      expect(recap.sessions, 0);
    });

    test('the oldest day of the week still counts', () {
      // An off-by-one here silently drops a day's training every week.
      final recap = summarise([set(date: DateTime(2026, 7, 18))]);

      expect(recap.buckets.first.volumeKg, 1000);
    });

    test('volume sums across sets in a bucket', () {
      final recap = summarise([
        set(date: today),
        set(date: today, weight: 50, reps: 10),
      ]);

      expect(recap.buckets.last.volumeKg, 1500);
      expect(recap.totalVolumeKg, 1500);
    });
  });

  group('counting workouts', () {
    test('counts sessions, not sets', () {
      final recap = summarise([
        set(date: today, session: 1),
        set(date: today, session: 1),
        set(date: today, session: 1),
      ]);

      expect(recap.sessions, 1);
      expect(recap.buckets.last.sessions, 1);
    });

    test('two sessions on one day count twice', () {
      // Unlike the streak, which counts days — this chart is about workouts.
      final recap = summarise([
        set(date: today, session: 1),
        set(date: today, session: 2),
      ]);

      expect(recap.sessions, 2);
    });

    test('a session spanning buckets is counted in each', () {
      final recap = summarise([
        set(date: DateTime(2026, 7, 20), session: 1),
        set(date: DateTime(2026, 7, 24), session: 2),
      ]);

      expect(recap.sessions, 2);
      expect(recap.buckets.map((b) => b.sessions).reduce((a, b) => a + b), 2);
    });
  });

  group('what you trained', () {
    test('counts a set once for every muscle it works', () {
      final recap = summarise([
        set(date: today, muscles: ['chest', 'triceps']),
      ]);

      // A bench press really does work all three; splitting the set between
      // them would need a per-muscle contribution the app doesn't know.
      expect(recap.muscleSets['chest'], 1);
      expect(recap.muscleSets['triceps'], 1);
    });

    test('sums a muscle across exercises', () {
      final recap = summarise([
        set(date: today, exercise: 'bench', muscles: ['chest']),
        set(date: today, exercise: 'fly', weight: 20, muscles: ['chest']),
      ]);

      expect(recap.muscleSets['chest'], 2);
    });

    test('counts sets, not kilograms — so legs cannot swamp arms', () {
      // The whole reason this is sets: one heavy squat set moves five times
      // the weight of a curl set. Ranked by volume, legs would top every chart
      // no matter how the week actually went.
      final recap = summarise([
        set(date: today, exercise: 'squat', weight: 200, muscles: ['quads']),
        set(date: today, exercise: 'curl', weight: 20, muscles: ['biceps']),
        set(date: today, exercise: 'curl', weight: 20, muscles: ['biceps']),
      ]);

      expect(recap.muscleSets['biceps'], 2);
      expect(recap.muscleSets['quads'], 1);
      // Biceps got more work despite a twentieth of the tonnage.
      expect(recap.muscleSets['biceps']! > recap.muscleSets['quads']!, isTrue);
    });

    test('a bodyweight set counts the same as a loaded one', () {
      // Attention, not load — a set of pull-ups is a set.
      final recap = summarise([
        set(date: today, exercise: 'pull_up', weight: 0, muscles: ['lats']),
      ]);

      expect(recap.muscleSets['lats'], 1);
    });

    test('only counts muscles trained inside the period', () {
      final recap = summarise([
        set(date: DateTime(2026, 7, 1), muscles: ['lats']),
      ]);

      expect(recap.muscleSets, isEmpty);
    });
  });

  group('personal records', () {
    test('a heavier set than ever before is a record', () {
      final records = personalRecordDates([
        set(date: DateTime(2026, 7, 20), weight: 100),
        set(date: DateTime(2026, 7, 24), weight: 105),
      ]);

      expect(records[DateTime(2026, 7, 24)], 1);
    });

    test('the first ever set of an exercise is not a record', () {
      // Otherwise trying a new machine would read as a personal best.
      final records = personalRecordDates([set(date: today, weight: 100)]);

      expect(records, isEmpty);
    });

    test('matching your best is not beating it', () {
      final records = personalRecordDates([
        set(date: DateTime(2026, 7, 20), weight: 100),
        set(date: DateTime(2026, 7, 24), weight: 100),
      ]);

      expect(records, isEmpty);
    });

    test('a lighter set afterwards is not a record', () {
      final records = personalRecordDates([
        set(date: DateTime(2026, 7, 20), weight: 100),
        set(date: DateTime(2026, 7, 24), weight: 90),
      ]);

      expect(records, isEmpty);
    });

    test('records are tracked per exercise', () {
      final records = personalRecordDates([
        set(date: DateTime(2026, 7, 20), exercise: 'bench', weight: 100),
        set(date: DateTime(2026, 7, 24), exercise: 'squat', weight: 60),
        set(date: DateTime(2026, 7, 24), exercise: 'squat', weight: 70),
      ]);

      // The squat PR stands even though it's lighter than the bench.
      expect(records[DateTime(2026, 7, 24)], 1);
    });

    test('bodyweight sets set no records', () {
      // There is no weight to beat, so every rep count would look like a PR.
      final records = personalRecordDates([
        set(date: DateTime(2026, 7, 20), weight: 0, reps: 10),
        set(date: DateTime(2026, 7, 24), weight: 0, reps: 15),
      ]);

      expect(records, isEmpty);
    });

    test('the walk covers history outside the period', () {
      // Whether today's 100 kg is a record depends on a lift from months ago,
      // so the window has to be applied after the walk, not in the query.
      final recap = summarise([
        set(date: DateTime(2026, 1, 5), weight: 120),
        set(date: today, weight: 100),
      ]);

      expect(recap.personalRecords, 0);
    });

    test('only records inside the period are counted', () {
      final recap = summarise([
        set(date: DateTime(2026, 1, 5), weight: 100),
        set(date: DateTime(2026, 1, 12), weight: 110), // a PR, but long ago
        set(date: today, weight: 120), // a PR, today
      ]);

      expect(recap.personalRecords, 1);
    });
  });

  group('longer periods', () {
    test('a month spreads sets across its blocks', () {
      final recap = summarise([
        set(date: today), // last block
        set(date: DateTime(2026, 6, 25)), // first block
      ], period: RecapPeriod.month);

      expect(recap.buckets, hasLength(5));
      expect(recap.buckets.last.volumeKg, 1000);
      expect(recap.buckets.first.volumeKg, 1000);
      expect(recap.totalVolumeKg, 2000);
    });

    test('a year spreads sets across its months', () {
      final recap = summarise([
        set(date: today),
        set(date: DateTime(2025, 9, 15), session: 2),
      ], period: RecapPeriod.year);

      expect(recap.buckets, hasLength(12));
      expect(recap.buckets.last.volumeKg, 1000); // July 2026
      expect(recap.buckets[1].volumeKg, 1000); // September 2025
      expect(recap.sessions, 2);
    });

    test('a set from before the year window is excluded', () {
      final recap = summarise([
        set(date: DateTime(2025, 7, 1)),
      ], period: RecapPeriod.year);

      expect(recap.isEmpty, isTrue);
    });
  });
}
