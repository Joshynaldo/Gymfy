// The review screen, and sharing it as a picture.
//
// Sharing crosses into Kotlin, which no test here can run. What can be pinned
// is everything either side of the boundary: the card renders to a PNG, a
// share that cannot happen falls back to saving, and the channel name, the
// FileProvider authority and its folder agree between Dart, Kotlin and the
// manifest — a mismatch in any of those fails silently on the phone.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_names.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/reviews/data/image_share.dart';
import 'package:gymfy/features/reviews/data/review.dart';
import 'package:gymfy/features/reviews/screens/review_screen.dart';
import 'package:gymfy/features/reviews/widgets/review_links.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';

import 'support/default_accent.dart';
import 'package:gymfy/shared/widgets/lucide_icons.dart';

RecapSet _set(DateTime date, int session, {double weight = 100}) => (
  date: date,
  sessionId: session,
  exerciseId: 'barbell_bench_press',
  weight: weight,
  reps: 5,
  muscleIds: const ['chest'],
);

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

List<Override> get _overrides => [
  ...defaultDisplayOverrides,
  recapSetsProvider.overrideWith((ref) => Stream.value(_sets)),
  allTrainingByDayProvider.overrideWith((ref) => Stream.value(_days)),
  recordsByDayProvider.overrideWith(
    (ref) => Stream.value({DateTime(2026, 9, 15): 2}),
  ),
  exerciseNamesProvider.overrideWithValue({
    'barbell_bench_press': 'Bench Press',
  }),
];

void main() {
  group('the screen', () {
    Future<void> pump(WidgetTester tester, ReviewPeriod period) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: ReviewScreen(initial: period, today: DateTime(2026, 10, 1)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sums up the month against the one before', (tester) async {
      await pump(tester, ReviewPeriod.month(2026, 9));

      expect(find.text('Monthly review'), findsWidgets);
      expect(find.text('September 2026'), findsWidgets);
      // Three workouts, two more than August's one — and two records against
      // August's none.
      expect(find.text('workouts'), findsOneWidget);
      expect(find.text('+2 vs August'), findsNWidgets(2));
      // 500 + 500 + 550 kg.
      expect(find.text('1,550 kg'), findsWidgets);
      // An imported session with no length: counted, not timed.
      expect(find.text('trained, 1 not timed'), findsOneWidget);
      expect(find.text('1 h 45 min'), findsOneWidget);
      expect(find.text('personal records'), findsOneWidget);
      expect(find.text('Bench Press'), findsWidgets);
      expect(find.byTooltip('Share as image'), findsOneWidget);
    });

    testWidgets('steps back a month, and not past the present', (tester) async {
      await pump(tester, ReviewPeriod.month(2026, 9));

      await tester.tap(find.byTooltip('Earlier'));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsWidgets);
      // One workout, so the label is singular — and July had none, so there
      // is nothing to compare it with.
      expect(find.text('workout'), findsOneWidget);
      expect(find.textContaining('vs July'), findsNothing);

      await tester.tap(find.byTooltip('Earlier'));
      await tester.pumpAndSettle();
      expect(find.text('No workouts in July 2026.'), findsOneWidget);
      // Nothing to share.
      expect(find.byTooltip('Share as image'), findsNothing);
    });

    testWidgets('the current month is marked as unfinished', (tester) async {
      await pump(tester, ReviewPeriod.year(2026));

      expect(find.text('Year in training'), findsWidgets);
      expect(find.textContaining('not over yet'), findsOneWidget);
      final later = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(LucideIcons.chevronRight),
          matching: find.byType(IconButton),
        ),
      );
      expect(later.onPressed, isNull);
    });
  });

  group('the way in', () {
    testWidgets('opens on the month that just ended on the 1st', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: MaterialApp(
            home: Scaffold(body: ReviewLinks(today: DateTime(2026, 10, 1))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('September 2026 — and how it compares'), findsOneWidget);
      expect(find.text('2026, start to finish'), findsOneWidget);
    });
  });

  group('sharing', () {
    final png = Uint8List.fromList([137, 80, 78, 71]);

    test('opens the share sheet when it can', () async {
      var saved = false;
      final outcome = await shareOrSaveImage(
        png,
        fileName: 'gymfy-review-2026-09.png',
        title: 'Share',
        writeTemp: (bytes, name) async => '/cache/share/$name',
        share: (path, title) async {
          expect(path, '/cache/share/gymfy-review-2026-09.png');
          return true;
        },
        save: (bytes, name) async => saved = true,
      );

      expect(outcome, ShareOutcome.shared);
      expect(saved, isFalse);
    });

    test('falls back to saving when the sheet cannot open', () async {
      Uint8List? savedBytes;
      final outcome = await shareOrSaveImage(
        png,
        fileName: 'gymfy-review-2026.png',
        title: 'Share',
        writeTemp: (bytes, name) async => '/cache/share/$name',
        share: (path, title) async => false,
        save: (bytes, name) async {
          savedBytes = bytes;
          return true;
        },
      );

      expect(outcome, ShareOutcome.saved);
      expect(savedBytes, png);
    });

    test('and when the cache cannot be written at all', () async {
      final outcome = await shareOrSaveImage(
        png,
        fileName: 'x.png',
        title: 'Share',
        writeTemp: (bytes, name) async => throw const FileSystemException(),
        share: (path, title) async => fail('nothing to share'),
        save: (bytes, name) async => false,
      );

      // The save dialog was dismissed: nothing happened, and nothing failed.
      expect(outcome, ShareOutcome.cancelled);
    });

    test('the bridge says no off Android instead of throwing', () async {
      // Tests run on the host, where there is no Kotlin side at all.
      expect(
        await const ImageShareBridge().sharePng('/x.png', title: 't'),
        isFalse,
      );
    });

    testWidgets('the card renders to a PNG', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 40,
              height: 20,
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      );

      final bytes = await tester.runAsync(
        () => capturePng(
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary,
          pixelRatio: 2,
        ),
      );

      // The PNG signature.
      expect(bytes!.take(4), [137, 80, 78, 71]);
    });
  });

  group('the Android half agrees with this one', () {
    String read(String path) => File(path).readAsStringSync();
    final kotlin = read(
      'android/app/src/main/kotlin/de/kopten/gymfy/ShareBridge.kt',
    );
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    test('on the channel name', () {
      final channel = RegExp(r'CHANNEL\s*=\s*"([^"]+)"').firstMatch(kotlin);
      expect(channel?.group(1), ImageShareBridge.channel.name);
    });

    test('on the provider authority', () {
      final suffix = RegExp(
        r'AUTHORITY_SUFFIX\s*=\s*"([^"]+)"',
      ).firstMatch(kotlin)?.group(1);
      expect(suffix, isNotNull);
      expect(
        manifest,
        contains('android:authorities="\${applicationId}$suffix"'),
      );
      expect(manifest, contains('android:name=".ShareFileProvider"'));
      expect(manifest, contains('@xml/share_paths'));
    });

    test('on the one folder it may hand out', () {
      final paths = read('android/app/src/main/res/xml/share_paths.xml');
      expect(
        RegExp(r'<cache-path [^>]*path="([^"]+)"').firstMatch(paths)?.group(1),
        '${ImageShareBridge.cacheFolder}/',
      );
      // Nothing else in the app's storage is reachable through it.
      expect(RegExp(r'<(files|external|root)-path').hasMatch(paths), isFalse);
    });

    test('and none of it needs the network', () {
      // The app has no INTERNET permission and must never gain one. The debug
      // and profile manifests carry it for the Flutter tool only.
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      final pubspec = read('pubspec.yaml');
      for (final package in ['share_plus', 'http:', 'dio:']) {
        expect(pubspec, isNot(contains('\n  $package')), reason: package);
      }
    });
  });
}
