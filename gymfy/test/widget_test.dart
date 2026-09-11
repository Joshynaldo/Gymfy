// Basic smoke test: the app boots and shows its bottom navigation.

// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means our Drift row class.
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('Gymfy boots and shows the five main tabs', (tester) async {
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
    expect(_tabLabels(tester), [
      'Home',
      'Workout',
      'Exercises',
      'Stats',
      'More',
    ]);
  });

  testWidgets('Progress is not a tab any more', (tester) async {
    // Six destinations crowded the bar into unreadable labels. Progress was
    // the one to go: it is consulted after training rather than reached for
    // during it. It lives under More, with a link from Home.
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

    expect(_tabLabels(tester), isNot(contains('Progress')));
    expect(_tabLabels(tester), hasLength(5));
  });
}
