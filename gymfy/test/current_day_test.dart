// Today's date, for what changes with the calendar and not with the data —
// and the resume that moves it on when Gymfy comes back on a new day.

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/data/current_day.dart';

/// Takes the app to the background and back, through every state between,
/// the order Android reports them in.
void backgroundAndBack(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  test('is today, at midnight', () {
    withClock(Clock.fixed(DateTime(2026, 9, 27, 20, 15)), () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentDayProvider), DateTime(2026, 9, 27));
    });
  });

  testWidgets('coming back on a new day moves it on', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    withClock(Clock.fixed(DateTime(2026, 9, 27, 23, 50)), () {
      container.read(currentDayWatcherProvider);
      expect(container.read(currentDayProvider), DateTime(2026, 9, 27));
    });

    // Left in the background overnight.
    withClock(
      Clock.fixed(DateTime(2026, 9, 28, 7)),
      () => backgroundAndBack(tester),
    );

    expect(container.read(currentDayProvider), DateTime(2026, 9, 28));
  });

  testWidgets('and coming back on the same day tells no one', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final day = DateTime(2026, 9, 27, 18);
    var heard = 0;
    withClock(Clock.fixed(day), () {
      container.read(currentDayWatcherProvider);
      container.listen(currentDayProvider, (_, _) => heard++);
    });

    // Phone down, phone up, between sets.
    withClock(
      Clock.fixed(day.add(const Duration(minutes: 3))),
      () => backgroundAndBack(tester),
    );

    expect(heard, 0);
  });
}
