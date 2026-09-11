// Basic smoke test: the app boots and shows its bottom navigation.

// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/router/app_router.dart';
import 'package:gymfy/features/onboarding/data/onboarding_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/main.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

/// The labels the bottom bar actually offers.
///
/// Read off the destinations rather than searched for as text: Home also
/// carries a "Progress" link now, so `find.text('Progress')` passes whether or
/// not the tab exists — which is exactly how this test kept passing after the
/// tab was removed.
List<String> _tabLabels(WidgetTester tester) {
  return tester
      .widget<NavigationBar>(find.byType(NavigationBar))
      .destinations
      .cast<NavigationDestination>()
      .map((d) => d.label)
      .toList();
}

void main() {
  testWidgets('Gymfy boots and shows the four main tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          // The app root shows onboarding until this says otherwise, so a
          // returning user has to be stated explicitly.
          onboardingCompleteProvider.overrideWith((ref) => Stream.value(true)),
          // The default (Workout) tab reads splits from the database; feed it
          // an empty list so the test doesn't touch a real database and the
          // loading spinner (which never settles) is skipped.
          splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
        ],
        child: const GymfyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(_tabLabels(tester), ['Home', 'Workout', 'Progress', 'More']);
  });

  testWidgets('the library and the muscle map are not tabs', (tester) async {
    // Every tab you add takes width from every other one. These two are the
    // ones that gave: the library is a reference you reach from wherever you
    // happen to be, and the muscle map answers the same question as the charts
    // do. Both live under More, and both keep their paths.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          onboardingCompleteProvider.overrideWith((ref) => Stream.value(true)),
          splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
        ],
        child: const GymfyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(_tabLabels(tester), isNot(contains('Exercises')));
    expect(_tabLabels(tester), isNot(contains('Stats')));
    expect(_tabLabels(tester), hasLength(4));
  });

  testWidgets('every tab opens its own screen', (tester) async {
    // Tapped, not read off the route table. A branch with no stated initial
    // location starts at whichever route happens to be declared first in it —
    // and once the exercise library moved into More's branch and was written
    // above `/more`, the More tab opened the library instead. The config was
    // valid, every route resolved, and the hub was simply unreachable.
    final container = ProviderContainer(
      overrides: [
        defaultAccentOverride,
        onboardingCompleteProvider.overrideWith((ref) => Stream.value(true)),
        splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const GymfyApp()),
    );
    await tester.pumpAndSettle();

    for (final (label, location) in const [
      ('Workout', '/workout'),
      ('Progress', '/progress'),
      ('More', '/more'),
      ('Home', '/home'),
    ]) {
      await tester.tap(find.text(label));
      // Timed pumps, not pumpAndSettle: most of these screens read providers
      // backed by a database this test does not give them, so they sit on a
      // spinner that never settles. Where the router *went* is the question,
      // and that is answered whether or not the screen has its data yet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        container.read(goRouterProvider).state.matchedLocation,
        location,
        reason: 'the $label tab should land on $location',
      );
    }
  });
}
