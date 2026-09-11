// The app bar earns its weight: nothing at rest, a scrim once there is
// something beneath it.
//
// Written after the bar was reported as "too big, hiding content". The insets
// were right — the bar was simply a hundred pixels of permanent brightness
// across the top of every screen, spent whether or not it was separating the
// title from anything.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/shared/widgets/glass_app_bar.dart';
import 'package:gymfy/shared/widgets/glass_scaffold.dart';

import 'support/default_accent.dart';

/// A glass screen with a list long enough to scroll.
Future<void> _pumpScreen(
  WidgetTester tester, {
  AppTheme theme = AppTheme.hyper,
  bool reduceMotion = false,
}) async {
  Widget app = ProviderScope(
    overrides: [defaultAccentOverride],
    child: MaterialApp(
      theme: buildAppTheme(theme, AccentPalette.blue),
      home: Builder(
        builder: (_) => GlassScaffold(
          appBar: const GlassAppBar(title: Text('Exercises')),
          // Read inside the scaffold, which is the only place the app bar's
          // own height is in the padding at all.
          body: (context) => ListView(
            padding: barInsets(context),
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('row $i')),
            ],
          ),
        ),
      ),
    ),
  );

  if (reduceMotion) {
    app = MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: app,
    );
  }

  await tester.pumpWidget(app);
  await tester.pump();
}

/// Whether the bar is currently painting a filter over what is behind it.
bool _barIsDrawn(WidgetTester tester) => find
    .descendant(of: find.byType(AppBar), matching: find.byType(BackdropFilter))
    .evaluate()
    .isNotEmpty;

void main() {
  group('the app bar at rest', () {
    testWidgets('paints nothing at the top of a list', (tester) async {
      // A hundred-pixel scrim over a title with nothing beneath it is a sixth
      // of a phone spent on decoration. At rest the title simply floats over
      // the drifting field.
      await _pumpScreen(tester);

      expect(_barIsDrawn(tester), isFalse);
      expect(find.text('Exercises'), findsOneWidget);
    });

    testWidgets('costs no blur pass either', (tester) async {
      // The same assertion, read the other way: with nothing under the bar
      // there is nothing to filter, and an offscreen pass that changes no
      // pixels is the exact cost this app cannot afford on older hardware.
      await _pumpScreen(tester);

      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('the app bar once content is under it', () {
    testWidgets('fades a scrim in', (tester) async {
      await _pumpScreen(tester);
      expect(_barIsDrawn(tester), isFalse);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(_barIsDrawn(tester), isTrue);
    });

    testWidgets('and takes it away again at the top', (tester) async {
      // Scrolling back to the top has to put the bar away, or the scrim is just
      // a permanent bar that took one gesture to arrive.
      await _pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_barIsDrawn(tester), isTrue);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(_barIsDrawn(tester), isFalse);
    });

    testWidgets('arrives immediately under reduced motion', (tester) async {
      await _pumpScreen(tester, reduceMotion: true);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      expect(_barIsDrawn(tester), isTrue);
    });
  });

  testWidgets('a flat theme keeps its solid bar throughout', (tester) async {
    // The compatibility promise again: no pane, no scrim, no scroll listening.
    await _pumpScreen(tester, theme: AppTheme.darkDefault);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      isNull,
      reason: 'a flat theme should keep the palette bar colour',
    );
  });
}
