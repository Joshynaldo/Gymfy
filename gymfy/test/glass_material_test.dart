// The material itself: four surfaces, and the rules that keep them four
// surfaces rather than one fill used four times.
//
// These are theme assertions rather than screenshots on purpose. "Does it look
// like glass" is not testable, but "is a row dimmer than a card", "does a pane
// with nothing behind it skip the blur" and "do the flat themes still get
// nothing at all" are exactly the things that quietly stop being true.

import 'dart:typed_data' show Uint8List;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/shared/widgets/app_card.dart';

import 'support/default_accent.dart';

GlassStyle _glass(AppTheme theme) =>
    buildAppTheme(theme, AccentPalette.blue).extension<GlassStyle>()!;

void main() {
  _shadowTests();

  group('the four surfaces', () {
    test('a row is dimmer than a card', () {
      // The whole point of the second tier. If a library row carries a card's
      // fill, seventy-eight of them read as seventy-eight competing surfaces
      // and the one card on the screen stops being the thing you look at.
      final glass = _glass(AppTheme.hyper);

      expect(glass.quiet.fill.first.a, lessThan(glass.raised.fill.first.a));
      expect(glass.quiet.topEdge.a, lessThan(glass.raised.topEdge.a));
    });

    test('a card catches more light at its lip than along its sides', () {
      // The specular line is the single detail that most makes a surface read
      // as glass rather than as a grey rectangle. Equal alphas mean a plain
      // outline, which is the look this replaced.
      final glass = _glass(AppTheme.hyper);

      for (final pane in [glass.raised, glass.quiet, glass.bar, glass.sheet]) {
        expect(pane.topEdge.a, greaterThan(pane.edge.a));
      }
    });

    test('a card dips through the middle and recovers at the foot', () {
      // Three stops, not two. A linear fade top to bottom reads as a painted
      // band; the dip and the bounce are what the eye takes as thickness.
      final fill = _glass(AppTheme.hyper).raised.fill;

      expect(fill, hasLength(3));
      expect(fill[1].a, lessThan(fill[0].a));
      expect(fill[2].a, greaterThan(fill[1].a));
    });

    test('only the panes that cover content blur', () {
      // The performance rule, written down. A card lies directly on the
      // backdrop, and blurring a smooth colour field returns the same smooth
      // field — an offscreen pass per card that changes not one pixel. On a
      // forty-row list on older hardware that is the difference between a
      // scroll that holds sixty and one that does not.
      final glass = _glass(AppTheme.hyper);

      expect(glass.raised.blur, 0);
      expect(glass.quiet.blur, 0);
      expect(glass.bar.blur, greaterThan(0));
      expect(glass.sheet.blur, greaterThan(0));
    });

    test('the panes that cover content have a floor to cover it with', () {
      // Blur alone averages the text underneath into a haze that is still,
      // faintly, text. Legibility on the bar and the sheet comes from the
      // opaque fill; the blur only stops the edges being distracting.
      final glass = _glass(AppTheme.hyper);

      expect(glass.bar.base, isNotNull);
      expect(glass.bar.base!.a, greaterThan(0.6));
      for (final stop in glass.sheet.fill) {
        expect(stop.a, greaterThan(0.7));
      }
    });

    test('colour lost to the blur is put back', () {
      // Averaging always moves towards grey, so a blurred backdrop comes out
      // duller than the field it was sampled from. Without this the panes look
      // like frosted plastic over a colourful screen.
      final glass = _glass(AppTheme.hyper);

      expect(glass.saturation, greaterThan(1));
      expect(glass.brightness, greaterThan(1));
    });
  });

  group('the flat themes', () {
    test('get no material at all', () {
      // The compatibility promise: six themes that should come out of the
      // redesign byte-for-byte unchanged.
      for (final theme in AppTheme.values.where((t) => t != AppTheme.hyper)) {
        final glass = _glass(theme);

        expect(glass.enabled, isFalse, reason: theme.name);
        expect(glass.raised.blur, 0, reason: theme.name);
        expect(
          glass.raised.fill.every((c) => c.a == 0),
          isTrue,
          reason: theme.name,
        );
        expect(glass.raised.shadow, isEmpty, reason: theme.name);
      }
    });

    test('keep the card radius they always had', () {
      // Hyper's panes are rounder because a translucent surface is read by its
      // edge. That is a reason to change Hyper, not the other six.
      final flat = buildAppTheme(AppTheme.darkDefault, AccentPalette.blue);
      final hyper = buildAppTheme(AppTheme.hyper, AccentPalette.blue);

      BorderRadius radiusOf(ThemeData theme) =>
          ((theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius
              as BorderRadius);

      expect(radiusOf(flat), BorderRadius.circular(16));
      expect(radiusOf(hyper), BorderRadius.circular(24));
    });
  });

  group('which tier a widget asks for', () {
    Future<GlassSurface> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: Scaffold(body: child),
          ),
        ),
      );
      return tester.widget<GlassSurface>(find.byType(GlassSurface).first);
    }

    testWidgets('a panel is a card', (tester) async {
      final surface = await pump(
        tester,
        const AppPanel(title: 'Volume', child: Text('38,240 kg')),
      );

      expect(surface.tier, GlassTier.raised);
    });

    testWidgets('a tile is a row', (tester) async {
      final surface = await pump(
        tester,
        const AppTile(icon: Icons.menu_book, title: 'Barbell bench press'),
      );

      expect(surface.tier, GlassTier.quiet);
    });

    testWidgets('and a row takes the tighter corner', (tester) async {
      // A row and a card on the same radius makes a list of rows look like a
      // stack of cards that happen to be short.
      final surface = await pump(
        tester,
        const AppTile(icon: Icons.menu_book, title: 'Barbell bench press'),
      );

      expect(surface.borderRadius, BorderRadius.circular(20));
    });
  });

  group('the glyph on a row', () {
    testWidgets('is neutral until it is picked', (tester) async {
      // One accent per screen, on the thing that matters. A column of nine
      // accent squares down the side of the More tab breaks that nine times
      // over, and spends it on the part of the row nobody reads.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [defaultAccentOverride],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: const Scaffold(
              body: Column(
                children: [
                  AppGlyph(icon: Icons.scale),
                  AppGlyph(icon: Icons.scale, selected: true),
                ],
              ),
            ),
          ),
        ),
      );

      final glyphs = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      final resting = (glyphs.first.decoration! as BoxDecoration).color!;
      final picked = (glyphs.last.decoration! as BoxDecoration).color!;

      expect(resting, isNot(AccentPalette.blue));
      expect(picked, AccentPalette.blue);
    });
  });
}

/// A card's shadow must stay outside the card.
///
/// Flutter's `BoxShadow` paints the whole blurred rounded rectangle *behind*
/// the box. CSS clips an outer box-shadow to outside it — so the design's
/// `rgba(0,0,0,0.9)` halo, ported literally, became a near-opaque black card
/// sitting behind a translucent one. Every pane came out charcoal in the middle
/// and lit at the edges, whatever the field behind it was doing.
///
/// Painted rather than inspected: this is a question about pixels, and the
/// widget tree looked perfectly correct the whole time it was wrong.
void _shadowTests() {
  testWidgets('a card does not darken its own interior', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: MaterialApp(
          theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
          home: const Scaffold(
            backgroundColor: Color(0xFF6A5AE0),
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: RepaintBoundary(
                  child: GlassSurface(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Inside runAsync: rasterising is real asynchronous work, and the test
    // binding's fake clock never lets it finish otherwise — the await simply
    // hangs until the test times out.
    final boundary =
        tester.firstRenderObject(find.byType(RepaintBoundary))
            as RenderRepaintBoundary;
    late Uint8List pixels;
    late int width;
    late int height;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ImageByteFormat.rawRgba);
      pixels = data!.buffer.asUint8List();
      width = image.width;
      height = image.height;
      image.dispose();
    });

    // The middle of the card, in the ground colour it is laid over.
    final middle = (width * (height ~/ 2) + width ~/ 2) * 4;
    final red = pixels[middle];
    final blue = pixels[middle + 2];

    expect(
      blue,
      greaterThan(0x50),
      reason:
          'the card reads as #${red.toRadixString(16)}..'
          '${blue.toRadixString(16)} — a translucent pane over a violet ground '
          'cannot be this dark unless something black is painted behind it',
    );
    // Still violet: the ground shows through rather than being replaced.
    expect(blue, greaterThan(red));
  });
}
