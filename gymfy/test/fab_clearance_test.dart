// A floating action button has to clear the navigation pill.
//
// The pill belongs to the *shell's* Scaffold; a screen's FAB belongs to its
// own. Neither knows about the other, so the screen places its button at the
// bottom of the screen and the pill floats down on top of it — "Add exercises"
// on the day builder was completely covered, and every other FAB in the app
// sits in the same place.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/router/scaffold_with_nav_bar.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/glass.dart';
import 'package:gymfy/shared/widgets/glass_app_bar.dart';
import 'package:gymfy/shared/widgets/glass_nav_bar.dart';
import 'package:gymfy/shared/widgets/glass_scaffold.dart';

import 'support/default_accent.dart';

/// The app's actual arrangement: the shell owns the pill, the screen inside it
/// owns the FAB.
Future<void> _pumpShell(WidgetTester tester, {required AppTheme theme}) async {
  tester.view.padding = const FakeViewPadding(bottom: 24 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [defaultAccentOverride],
      child: MaterialApp(
        theme: buildAppTheme(theme, AccentPalette.blue),
        home: Builder(
          builder: (context) => Scaffold(
            extendBody: glassOf(context).enabled,
            body: GlassScaffold(
              appBar: const GlassAppBar(title: Text('Push day')),
              body: (context) => ListView(
                padding: barInsets(context),
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 60, child: Text('row $i')),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add exercises'),
              ),
            ),
            bottomNavigationBar: GlassNavBar(
              selectedIndex: 1,
              onDestinationSelected: (_) {},
              destinations: mainDestinations,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the day builder FAB sits above the pill', (tester) async {
    await _pumpShell(tester, theme: AppTheme.hyper);

    final fabBottom = tester
        .getBottomLeft(find.byType(FloatingActionButton))
        .dy;
    final pillTop = tester.getTopLeft(find.byType(NavigationBar)).dy;

    expect(
      fabBottom,
      lessThanOrEqualTo(pillTop),
      reason:
          'the button ends at $fabBottom, under a pill that starts at '
          '$pillTop — it is drawn and covered',
    );
  });

  testWidgets('and the flat themes are untouched', (tester) async {
    // There is no floating pill there: the bar is opaque and welded to the
    // bottom edge, and Scaffold has always placed the FAB above it.
    await _pumpShell(tester, theme: AppTheme.darkDefault);

    expect(
      tester.getBottomLeft(find.byType(FloatingActionButton)).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
    );
  });
}
