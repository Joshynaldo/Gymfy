// Health Connect: the decisions, and the seams between languages.
//
// The decisions — which workouts to write, which weigh-ins become a
// bodyweight — are pure functions and tested as such; they carry the two
// promises the privacy policy makes (a typed weight is never overwritten, a
// record is never imported twice). The rest guards things that fail silently
// across the Dart/Kotlin/manifest boundary: a permission spelled differently
// in two places is not a crash, it is a switch that never works.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';
import 'package:gymfy/features/health_connect/data/health_connect_sync.dart';
import 'package:gymfy/features/health_connect/widgets/health_connect_settings_panel.dart';
import 'package:gymfy/shared/database/app_database.dart';

WorkoutSession _session(
  int id, {
  required DateTime start,
  Duration? length = const Duration(minutes: 60),
  String name = 'Push A',
  bool finished = true,
}) => WorkoutSession(
  id: id,
  name: name,
  startedAt: start,
  completedAt: finished ? start.add(length ?? Duration.zero) : null,
);

HealthConnectWeighIn _weighIn(
  String id,
  DateTime time,
  double kg, {
  int? offsetSeconds,
}) => (id: id, time: time, offsetSeconds: offsetSeconds, kg: kg);

void main() {
  group('the record id', () {
    test('is the same every time for the same workout', () {
      // The whole idempotency story: writing twice must replace, not add.
      final session = _session(7, start: DateTime(2026, 9, 1, 18));
      expect(clientRecordIdFor(session), clientRecordIdFor(session));
      expect(clientRecordIdFor(session), startsWith('gymfy-session-7-'));
    });

    test('differs when an id is reused for a different workout', () {
      // A reinstall starts ids at 1 again, and Health Connect keeps what the
      // old install wrote. Same id, different start: must not collide.
      final old = _session(1, start: DateTime(2025, 1, 5, 18));
      final fresh = _session(1, start: DateTime(2026, 9, 1, 18));
      expect(clientRecordIdFor(old), isNot(clientRecordIdFor(fresh)));
    });
  });

  group('a workout as Health Connect sees it', () {
    test('carries the name, start and end', () {
      final session = _session(3, start: DateTime(2026, 9, 1, 18));
      final record = healthConnectSessionFor(session)!;
      expect(record.title, 'Push A');
      expect(record.start, DateTime(2026, 9, 1, 18));
      expect(record.end, DateTime(2026, 9, 1, 19));
      expect(record.clientRecordId, clientRecordIdFor(session));
    });

    test('is not written when its length is unknown', () {
      // An import with no usable end time stores end == start. Writing it
      // would mean inventing a duration for someone's health data.
      final untimed = _session(
        4,
        start: DateTime(2026, 9, 1, 18),
        length: Duration.zero,
      );
      expect(healthConnectSessionFor(untimed), isNull);
    });

    test('nor when the clock ran backwards, nor while it is running', () {
      final backwards = WorkoutSession(
        id: 5,
        name: 'Pull',
        startedAt: DateTime(2026, 9, 1, 18),
        completedAt: DateTime(2026, 9, 1, 17),
      );
      final running = _session(
        6,
        start: DateTime(2026, 9, 1, 18),
        finished: false,
      );
      expect(healthConnectSessionFor(backwards), isNull);
      expect(healthConnectSessionFor(running), isNull);
    });
  });

  group('planWorkoutSync', () {
    final since = DateTime(2026, 9, 10);
    final before = _session(1, start: DateTime(2026, 9, 5, 18));
    final after = _session(2, start: DateTime(2026, 9, 12, 18));
    final later = _session(3, start: DateTime(2026, 9, 14, 18));

    test('writes workouts finished after it was switched on, only', () {
      final plan = planWorkoutSync(
        sessions: [before, after, later],
        written: const {},
        writeSince: since,
      );
      expect([for (final w in plan.write) w.sessionId], [2, 3]);
      expect(plan.delete, isEmpty);
    });

    test('never writes the same workout twice', () {
      final plan = planWorkoutSync(
        sessions: [after, later],
        written: {2: clientRecordIdFor(after)},
        writeSince: since,
      );
      expect([for (final w in plan.write) w.sessionId], [3]);
    });

    test('the backfill writes the old ones too, oldest first', () {
      final plan = planWorkoutSync(
        sessions: [later, before, after],
        written: {3: clientRecordIdFor(later)},
        writeSince: since,
        backfill: true,
      );
      expect([for (final w in plan.write) w.sessionId], [1, 2]);
    });

    test('without a start date nothing is written by itself', () {
      final plan = planWorkoutSync(
        sessions: [before, after],
        written: const {},
        writeSince: null,
      );
      expect(plan.write, isEmpty);
    });

    test('counts and skips workouts with no known length', () {
      final untimed = _session(
        9,
        start: DateTime(2026, 9, 12, 7),
        length: Duration.zero,
      );
      final plan = planWorkoutSync(
        sessions: [untimed, after],
        written: const {},
        writeSince: since,
      );
      expect([for (final w in plan.write) w.sessionId], [2]);
      expect(plan.untimed, 1);
    });

    test('ignores a workout still running', () {
      final running = _session(
        4,
        start: DateTime(2026, 9, 15, 18),
        finished: false,
      );
      final plan = planWorkoutSync(
        sessions: [running],
        written: const {},
        writeSince: since,
        backfill: true,
      );
      expect(plan.write, isEmpty);
      expect(plan.untimed, 0);
    });

    test('deletes the record of a workout that is gone', () {
      final plan = planWorkoutSync(
        sessions: [later],
        written: {2: 'gymfy-session-2-1757692800', 3: clientRecordIdFor(later)},
        writeSince: since,
      );
      expect(plan.delete, {2: 'gymfy-session-2-1757692800'});
      expect(plan.write, isEmpty);
    });

    test('replaces a record whose id now belongs to another workout', () {
      // A restored backup can put a different workout under an id that was
      // written before. The old record describes nothing any more.
      final plan = planWorkoutSync(
        sessions: [after],
        written: {2: 'gymfy-session-2-1600000000'},
        writeSince: since,
      );
      expect(plan.delete, {2: 'gymfy-session-2-1600000000'});
      expect([for (final w in plan.write) w.sessionId], [2]);
    });
  });

  group('the written-workouts ledger', () {
    test('round-trips', () {
      final ledger = {1: 'gymfy-session-1-100', 22: 'gymfy-session-22-200'};
      expect(decodeWrittenSessions(encodeWrittenSessions(ledger)), ledger);
    });

    test('junk reads as empty rather than throwing', () {
      for (final raw in [null, '', 'nope', '[1,2]', '{"x": 3}']) {
        expect(decodeWrittenSessions(raw), isEmpty, reason: '$raw');
      }
    });
  });

  group('weighInDay', () {
    test('is the day where the scale stood, when the offset is known', () {
      // 23:30 UTC is already tomorrow in Berlin summer time.
      final record = _weighIn(
        'a',
        DateTime.utc(2026, 9, 30, 23, 30),
        80,
        offsetSeconds: 2 * 3600,
      );
      expect(weighInDay(record), DateTime(2026, 10, 1));
    });

    test("is the phone's own day otherwise", () {
      final local = DateTime(2026, 9, 30, 7, 15);
      expect(weighInDay(_weighIn('a', local, 80)), DateTime(2026, 9, 30));
    });
  });

  group('weighInWindowStart', () {
    final now = DateTime(2026, 10, 1, 12);

    test('reads thirty days the first time', () {
      expect(
        weighInWindowStart(now: now),
        now.subtract(const Duration(days: 30)),
      );
    });

    test('still thirty days after a recent check — scales sync late', () {
      expect(
        weighInWindowStart(now: now, lastChecked: DateTime(2026, 9, 30)),
        now.subtract(const Duration(days: 30)),
      );
    });

    test('reaches back past a long absence instead of leaving a gap', () {
      expect(
        weighInWindowStart(now: now, lastChecked: DateTime(2026, 7, 1)),
        DateTime(2026, 6, 29),
      );
    });
  });

  group('planWeightImport', () {
    final monday = DateTime(2026, 9, 28);
    final morning = DateTime(2026, 9, 28, 7);
    final evening = DateTime(2026, 9, 28, 21);

    test('fills an empty day with its first weigh-in', () {
      final plan = planWeightImport(
        records: [
          _weighIn('late', evening, 81.2),
          _weighIn('early', morning, 80.4),
        ],
        current: const {},
        imported: const {},
      );
      expect(plan, hasLength(1));
      expect(plan.single.day, monday);
      expect(plan.single.kg, 80.4);
      expect(plan.single.recordId, 'early');
      expect(plan.single.replaces, isNull);
    });

    test('never overwrites a weight typed by hand', () {
      final plan = planWeightImport(
        records: [_weighIn('early', morning, 80.4)],
        current: {monday: 82.0},
        imported: const {},
      );
      expect(plan, isEmpty);
    });

    test('never imports the same record twice', () {
      final plan = planWeightImport(
        records: [_weighIn('early', morning, 80.4)],
        current: {monday: 80.4},
        imported: {'2026-09-28': (id: 'early', kg: 80.4)},
      );
      expect(plan, isEmpty);
    });

    test('nor again after the imported value was cleared by hand', () {
      // Clearing the day is a decision. Filling it back in on the next app
      // start would undo it.
      final plan = planWeightImport(
        records: [_weighIn('early', morning, 80.4)],
        current: const {},
        imported: {'2026-09-28': (id: 'early', kg: 80.4)},
      );
      expect(plan, isEmpty);
    });

    test('an imported value changed by hand is left alone for good', () {
      final plan = planWeightImport(
        records: [_weighIn('earlier', DateTime(2026, 9, 28, 6), 79.9)],
        current: {monday: 81.0},
        imported: {'2026-09-28': (id: 'early', kg: 80.4)},
      );
      expect(plan, isEmpty);
    });

    test('an untouched import follows a new first weigh-in of the day', () {
      // The morning record was deleted in Health Connect, or an earlier one
      // synced late. The day is still ours, so it follows.
      final plan = planWeightImport(
        records: [_weighIn('earlier', DateTime(2026, 9, 28, 6), 79.9)],
        current: {monday: 80.4},
        imported: {'2026-09-28': (id: 'early', kg: 80.4)},
      );
      expect(plan.single.recordId, 'earlier');
      expect(plan.single.replaces, 80.4);
    });

    test('drops nonsense and rounds away float noise', () {
      final plan = planWeightImport(
        records: [
          _weighIn('zero', morning, 0),
          _weighIn('pounds', DateTime(2026, 9, 29, 7), 80.01361),
        ],
        current: const {},
        imported: const {},
      );
      expect(plan.single.recordId, 'pounds');
      expect(plan.single.kg, 80.01);
    });

    test('one entry per day, in day order', () {
      final plan = planWeightImport(
        records: [
          _weighIn('tue', DateTime(2026, 9, 29, 7), 80.1),
          _weighIn('mon', morning, 80.4),
          _weighIn('mon-late', evening, 80.9),
        ],
        current: const {},
        imported: const {},
      );
      expect([for (final p in plan) p.recordId], ['mon', 'tue']);
    });
  });

  group('the weigh-in ledger', () {
    test('round-trips', () {
      final ledger = {
        '2026-09-28': (id: 'a', kg: 80.4),
        '2026-09-29': (id: 'b', kg: 80.1),
      };
      expect(decodeWeightImports(encodeWeightImports(ledger)), ledger);
    });

    test('junk reads as empty', () {
      for (final raw in [null, '', '{', '[]', '{"2026-09-28": 3}']) {
        expect(decodeWeightImports(raw), isEmpty, reason: '$raw');
      }
    });
  });

  group('describeBackfill', () {
    test('says what happened, including what was left out', () {
      expect(
        describeBackfill((written: 12, deleted: 0, untimed: 3, error: null)),
        'Wrote 12 workouts to Health Connect. 3 without a recorded length '
        'were left out.',
      );
      expect(
        describeBackfill((written: 0, deleted: 0, untimed: 0, error: null)),
        'No workouts needed writing.',
      );
      expect(
        describeBackfill((written: 1, deleted: 0, untimed: 0, error: 'busy')),
        'Wrote 1 workout to Health Connect. Then it stopped: busy',
      );
    });
  });

  group('the bridge', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const bridge = HealthConnectBridge(HealthConnectBridge.channel);
    final calls = <MethodCall>[];

    void answer(Object? Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(HealthConnectBridge.channel, (call) async {
            calls.add(call);
            return handler(call);
          });
    }

    tearDown(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(HealthConnectBridge.channel, null);
    });

    test('reads availability, and anything unknown as unsupported', () async {
      answer((_) => 'needsUpdate');
      expect(
        await bridge.availability(),
        HealthConnectAvailability.needsUpdate,
      );
      answer((_) => 'somethingNew');
      expect(
        await bridge.availability(),
        HealthConnectAvailability.unsupported,
      );
      answer((_) => throw PlatformException(code: 'boom'));
      expect(
        await bridge.availability(),
        HealthConnectAvailability.unsupported,
      );
    });

    test('with no channel at all it is simply unsupported', () async {
      // A test, or a platform without the Kotlin side.
      expect(
        await bridge.availability(),
        HealthConnectAvailability.unsupported,
      );
      expect(await bridge.grantedPermissions(), isEmpty);
    });

    test('is never even asked on a platform without Health Connect', () async {
      answer((_) => 'available');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        expect(
          await bridge.availability(),
          HealthConnectAvailability.unsupported,
        );
        expect(await bridge.openStore(), isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      expect(calls, isEmpty);
    });

    test('sends a workout as plain values, in epoch milliseconds', () async {
      answer((_) => null);
      final start = DateTime(2026, 9, 1, 18);
      await bridge.writeSessions([
        (
          clientRecordId: 'gymfy-session-1-1',
          title: 'Push A',
          start: start,
          end: start.add(const Duration(hours: 1)),
        ),
      ]);
      expect(calls.single.method, 'writeSessions');
      expect(calls.single.arguments, [
        {
          'clientRecordId': 'gymfy-session-1-1',
          'title': 'Push A',
          'startMs': start.millisecondsSinceEpoch,
          'endMs': start.millisecondsSinceEpoch + 3600000,
        },
      ]);
    });

    test('a refused write is an error, not silence', () async {
      answer((_) => throw PlatformException(code: 'failed', message: 'nope'));
      await expectLater(
        bridge.deleteSessions(['x']),
        throwsA(isA<HealthConnectException>()),
      );
    });

    test('reads weigh-ins, skipping any it cannot place', () async {
      answer(
        (_) => [
          {
            'id': 'a',
            'timeMs': 1759300000000,
            'offsetSeconds': 7200,
            'kg': 80.4,
          },
          {'id': 'b', 'timeMs': 1759300000000, 'offsetSeconds': null, 'kg': 81},
          {'id': 'c', 'kg': 80.0},
          'not a map',
        ],
      );
      final records = await bridge.readWeights(
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 10, 1),
      );
      expect([for (final r in records) r.id], ['a', 'b']);
      expect(records.first.offsetSeconds, 7200);
      expect(records.last.offsetSeconds, isNull);
      expect(records.last.kg, 81.0);
      expect(calls.single.arguments, {
        'startMs': DateTime(2026, 9, 1).millisecondsSinceEpoch,
        'endMs': DateTime(2026, 10, 1).millisecondsSinceEpoch,
      });
    });
  });

  group('across the language boundary', () {
    final kotlinDir = 'android/app/src/main/kotlin/de/kopten/gymfy';
    late String bridgeKt;
    late String opsKt;
    late String manifest;

    setUpAll(() {
      bridgeKt = File('$kotlinDir/HealthConnectBridge.kt').readAsStringSync();
      opsKt = File('$kotlinDir/HealthConnectOps.kt').readAsStringSync();
      manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
    });

    test('both sides use the same channel', () {
      expect(bridgeKt, contains('"${HealthConnectBridge.channel.name}"'));
    });

    test('every method Dart calls is one Kotlin answers', () {
      final dart = File(
        'lib/features/health_connect/data/health_connect_bridge.dart',
      ).readAsStringSync();
      final called = RegExp(
        r"""invoke(?:List)?Method<[^>]*>\(\s*'(\w+)'|_call\('(\w+)'|_open\('(\w+)'""",
      ).allMatches(dart).map((m) => m[1] ?? m[2] ?? m[3]).toSet();
      expect(called, isNotEmpty);
      for (final method in called) {
        expect(bridgeKt, contains('"$method"'), reason: method);
      }
    });

    test('the manifest declares exactly the permissions Dart asks for', () {
      // Each health permission needs its own Play Console declaration, so an
      // extra one here is a store problem, and a missing one is a switch
      // that can never be turned on.
      final declared = RegExp(
        r'uses-permission android:name="(android\.permission\.health\.[A-Z_]+)"',
      ).allMatches(manifest).map((m) => m[1]).toSet();
      expect(declared, {writeExercisePermission, readWeightPermission});
    });

    test('and Kotlin builds the same two from the library', () {
      expect(
        opsKt,
        contains('getWritePermission(ExerciseSessionRecord::class)'),
      );
      expect(opsKt, contains('getReadPermission(WeightRecord::class)'));
    });

    test('Health Connect can find the screen explaining them', () {
      // Without these Health Connect refuses to offer the permissions at
      // all, and nothing anywhere says why.
      expect(
        manifest,
        contains('androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE'),
      );
      expect(manifest, contains('android.intent.action.VIEW_PERMISSION_USAGE'));
      expect(manifest, contains('android.intent.category.HEALTH_PERMISSIONS'));
      expect(
        manifest,
        contains(
          'android:permission="android.permission.START_VIEW_PERMISSION_USAGE"',
        ),
      );
      expect(
        manifest,
        contains('<package android:name="com.google.android.apps.healthdata"'),
      );
    });

    test('the library is only allowed below its minSdk behind a gate', () {
      expect(
        manifest,
        contains('tools:overrideLibrary="androidx.health.connect.client"'),
      );
      // The gate itself: Android 8 (O, API 26) before anything else.
      expect(
        bridgeKt,
        contains('Build.VERSION.SDK_INT >= Build.VERSION_CODES.O'),
      );
      // Every channel call other than the version-safe ones checks it, and
      // nothing touches the library before that check.
      final handle = bridgeKt.substring(
        bridgeKt.indexOf('private fun handle('),
        bridgeKt.indexOf('when (call.method) {'),
      );
      expect(handle, contains('if (!supported ||'));
      expect(handle, isNot(contains('ops.')));
      // The client itself is created lazily, so it is never built early.
      expect(bridgeKt, contains('private val ops by lazy'));
    });

    test('and the app still has no internet permission', () {
      expect(manifest, isNot(contains('android.permission.INTERNET')));
    });

    test(
      'the rationale screen and the policy describe the same two things',
      () {
        final strings = File(
          'android/app/src/main/res/values/strings.xml',
        ).readAsStringSync();
        final policy = File('store/privacy-policy.md').readAsStringSync();
        for (final text in [strings, policy]) {
          expect(text, contains('Write workouts'));
          expect(text, contains('Read bodyweight'));
          expect(text, contains('write exercise'));
          expect(text, contains('read weight'));
        }
      },
    );
  });
}
