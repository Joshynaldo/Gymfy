// The still-frame thumbnail shown beside each exercise in the library.
//
// The decode is the part worth testing. Flutter has no way to ask
// `Image.asset` for a still frame of a GIF — handed one, it plays it — so this
// widget decodes frame one itself through `dart:ui`. That is a fair amount of
// machinery standing between an asset and a picture, and every failure in it
// looks the same on screen: the fallback icon, which is also what a perfectly
// healthy exercise-with-no-animation looks like. Nothing would report it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/exercise_thumbnail.dart';

import 'support/default_accent.dart';

const _realAsset = 'assets/exercises/barbell_bench_press.gif';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirstFrame', () {
    test('decodes a real bundled animation', () async {
      const provider = FirstFrame(_realAsset, pixelWidth: 126);
      final info = await provider.decodeForTest();
      addTearDown(info.dispose);

      expect(info.image.width, 126, reason: 'not decoded at the asked size');
      // Square source, so the height follows. Asserted rather than assumed:
      // the decoder is only told the width, on purpose, so a non-square asset
      // is letterboxed rather than stretched.
      expect(info.image.height, 126);
    });

    test('downsamples rather than decoding at full size', () async {
      // The whole reason targetWidth is passed into the decoder instead of
      // scaling afterwards. The source is 360×360; 78 rows of that in RGBA
      // would be about 40MB of image cache.
      const provider = FirstFrame(_realAsset, pixelWidth: 64);
      final info = await provider.decodeForTest();
      addTearDown(info.dispose);

      expect(info.image.width, lessThan(360));
      expect(info.image.width, 64);
    });

    test('finds a webp where the declared path says gif', () async {
      // Seed data declares `.gif` for every exercise; what ships may be either.
      // The provider resolves through previewCandidates, so asking for the gif
      // spelling has to work whichever format is actually bundled.
      const provider = FirstFrame(_realAsset, pixelWidth: 32);
      final info = await provider.decodeForTest();
      addTearDown(info.dispose);

      expect(info.image.width, 32);
    });

    test('a missing asset fails rather than hanging', () async {
      const provider = FirstFrame(
        'assets/exercises/not_a_real_exercise.gif',
        pixelWidth: 64,
      );

      await expectLater(provider.decodeForTest(), throwsA(isA<StateError>()));
    });

    test('two rows asking for the same still share one cache entry', () {
      // Equality is what lets Flutter's ImageCache de-duplicate and evict.
      // Without it every rebuild decodes again.
      const a = FirstFrame(_realAsset, pixelWidth: 126);
      const b = FirstFrame(_realAsset, pixelWidth: 126);
      const differentSize = FirstFrame(_realAsset, pixelWidth: 64);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(differentSize));
    });
  });

  group('ExerciseThumbnail', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
      await tester.pump();
    }

    testWidgets('an exercise with no animation keeps the icon', (tester) async {
      await pump(tester, const ExerciseThumbnail(gifPath: null));

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a custom exercise keeps the icon too', (tester) async {
      // Its image is a file the user picked, not a bundled asset, and this
      // widget only reads the bundle.
      await pump(
        tester,
        const ExerciseThumbnail(gifPath: '/data/user/0/files/mine.jpg'),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('selection replaces the still with a tick', (tester) async {
      // The row has to say "picked" more loudly than it says which exercise it
      // is, so the picture gets out of the way entirely.
      await pump(
        tester,
        const ExerciseThumbnail(gifPath: _realAsset, selected: true),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('an unselected bundled exercise draws a still', (tester) async {
      await pump(tester, const ExerciseThumbnail(gifPath: _realAsset));

      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<FirstFrame>());
    });
  });
}
