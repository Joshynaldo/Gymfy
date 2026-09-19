// Leaving a tab drops what was open there — except a running workout.
//
// The bug this pins down: open More → Exercises, tap Home, tap More, and the
// exercise library was still sitting there. `StatefulShellRoute` keeps a
// navigation stack per branch, so that was the framework working as designed;
// it just is not what a hub tab should do. You asked for the menu and got a
// screen you were finished with, which reads as a missed tap.
//
// The exception earns a test of its own, because it is the half that a
// well-meaning simplification ("just always reset") would silently delete: a
// session in progress is not a screen left open, it is something still
// happening, and the way back to it has to be one tap.
//
// Providers are overridden rather than pointing at a real database: drift
// keeps a stream-cleanup timer alive that `pumpAndSettle` would wait on
// forever.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/router/app_router.dart';
import 'package:gymfy/features/onboarding/data/onboarding_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/main.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

final _runningSession = WorkoutSession(
  id: 1,
  dayId: 10,
  name: 'Push',
  startedAt: DateTime(2026, 9, 19, 18),
);

/// Boots the real app with just enough overridden to keep it off a database.
///
/// [inProgress] is the session the app should believe is still running, if
/// any — the single input this whole behaviour turns on.
Future<ProviderContainer> _bootApp(
  WidgetTester tester, {
  WorkoutSession? inProgress,
}) async {
  final container = ProviderContainer(
    overrides: [
      defaultAccentOverride,
      // The app root shows onboarding until this says otherwise, so a
      // returning user has to be stated explicitly.
      onboardingCompleteProvider.overrideWith((ref) => Stream.value(true)),
      splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
      inProgressSessionProvider.overrideWith(
        (ref) => Stream.value(inProgress),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GymfyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Taps a tab and gives the switch time to land.
///
/// Timed pumps rather than `pumpAndSettle`: several of these screens read
/// providers backed by a database this test does not give them, so they sit on
/// a spinner that never settles. Where the router *went* is the question, and
/// that is answered whether or not the screen has its data yet.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('leaving More drops the screen it was left on', (tester) async {
    final container = await _bootApp(tester);
    final router = container.read(goRouterProvider);

    // Deep into the More branch, the way a user gets there: More → Exercises.
    router.go('/exercises');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.state.matchedLocation, '/exercises');

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'More');

    expect(
      router.state.matchedLocation,
      '/more',
      reason: 'coming back to More should show the menu, not the library',
    );
  });

  testWidgets('leaving Progress drops the screen it was left on', (
    tester,
  ) async {
    // The same rule, on a second branch — so a fix that happened to special-
    // case More would not pass.
    final container = await _bootApp(tester);
    final router = container.read(goRouterProvider);

    router.go('/progress/measurements');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.state.matchedLocation, '/progress/measurements');

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Progress');

    expect(router.state.matchedLocation, '/progress');
  });

  testWidgets('Workout resets too when no session is running', (tester) async {
    final container = await _bootApp(tester);
    final router = container.read(goRouterProvider);

    router.go('/workout/splits');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.state.matchedLocation, '/workout/splits');

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Workout');

    expect(router.state.matchedLocation, '/workout');
  });

  testWidgets('a running workout survives a trip to another tab', (
    tester,
  ) async {
    // The whole point of the exception: phone down between sets, pick it up to
    // check something, one tap back into the set you were in the middle of.
    final container = await _bootApp(tester, inProgress: _runningSession);
    final router = container.read(goRouterProvider);

    router.go('/workout/splits');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await _tapTab(tester, 'Progress');
    await _tapTab(tester, 'Workout');

    expect(
      router.state.matchedLocation,
      '/workout/splits',
      reason: 'the Workout tab keeps its place while a session is open',
    );
  });

  testWidgets('the exception is only the Workout tab', (tester) async {
    // A session in progress must not turn the reset off everywhere — that
    // would be the easy way to make the test above pass and would quietly put
    // the original bug back.
    final container = await _bootApp(tester, inProgress: _runningSession);
    final router = container.read(goRouterProvider);

    router.go('/exercises');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'More');

    expect(router.state.matchedLocation, '/more');
  });
}
