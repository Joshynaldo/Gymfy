// The rest timer's progress bar has to actually have pixels.
//
// It did not. The fill measured 150 x 0 — full width, zero height, painting
// nothing — and had never been visible since the bar was written. Nothing
// about the source looks wrong, the widget it lives in is only four pixels
// tall, and no existing test asked about size, so there was nothing to
// notice: the bar simply was not there.
//
// Measured rather than reasoned about. Working out constraint propagation by
// reading it is what cost three wrong attempts on the filter chips.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymfy/features/workout/data/rest_timer_controller.dart';
import 'package:gymfy/features/workout/widgets/rest_timer_bar.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, RestTimerState? state) async {
    await tester.pumpWidget(
      ProviderScope(
        // Keyed on the state so a second pumpWidget actually rebuilds the
        // scope. Without it Flutter reuses the element tree, the override
        // is never re-applied, and both measurements come back identical —
        // which reads exactly like a bar that does not move.
        key: ValueKey(state?.remainingSeconds),
        overrides: [restTimerProvider.overrideWith(() => _FakeTimer(state))],
        child: MaterialApp(
          home: Scaffold(body: Center(child: RestTimerBar())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the progress fill has height, not just width', (tester) async {
    await pumpBar(tester, (
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      totalSeconds: 120,
      remainingSeconds: 60,
    ));

    final size = tester.getSize(find.byKey(restProgressFillKey));
    expect(
      size.height,
      greaterThan(0),
      reason: 'a zero-height fill paints nothing — this is the bug, and it '
          'looks identical to a bar that simply has not started',
    );
    expect(size.width, greaterThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('and it gets narrower as the rest runs down', (tester) async {
    await pumpBar(tester, (
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      totalSeconds: 120,
      remainingSeconds: 120,
    ));
    final full = tester.getSize(find.byKey(restProgressFillKey)).width;

    await pumpBar(tester, (
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      totalSeconds: 120,
      remainingSeconds: 30,
    ));
    // Let the tween land rather than reading it mid-flight.
    await tester.pumpAndSettle();
    final quarter = tester.getSize(find.byKey(restProgressFillKey)).width;

    expect(
      quarter,
      lessThan(full),
      reason: 'the fill must shrink with the remaining time, or it is not a '
          'progress bar',
    );
  });
}

class _FakeTimer extends RestTimer {
  _FakeTimer(this._state);

  final RestTimerState? _state;

  @override
  RestTimerState? build() => _state;
}
