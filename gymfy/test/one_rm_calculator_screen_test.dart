// The calculator screen: nothing until there's input, a rounded estimate once
// there is, and a warning when the rep count leaves reliable territory.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/screens/one_rm_calculator_screen.dart';

import 'support/default_accent.dart';
import 'support/weight_wheel.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: defaultDisplayOverrides,
        child: const MaterialApp(home: OneRmCalculatorScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prompts for input before showing an estimate', (tester) async {
    await pump(tester);

    expect(find.text('Estimated 1RM'), findsNothing);
    expect(find.textContaining('the estimate appears here'), findsOneWidget);
  });

  testWidgets('shows the estimate rounded to a loadable weight', (
    tester,
  ) async {
    await pump(tester);

    await pickWeight(tester, whole: 100);

    // Default 5 reps: Epley 116.67, Brzycki 112.5, Lander 113.71 — average
    // 114.29, rounded to the nearest half kilo.
    expect(find.text('Estimated 1RM'), findsOneWidget);
    expect(find.text('114.5'), findsOneWidget);
    expect(find.textContaining('range 112.5–116.5 kg'), findsOneWidget);
  });

  testWidgets('lists every formula, highest first', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 100);

    expect(find.text('Formula comparison'), findsOneWidget);
    expect(find.text('Epley'), findsOneWidget);
    expect(find.text('116.5 kg'), findsOneWidget);
    expect(find.text('Brzycki'), findsOneWidget);
    expect(find.text('112.5 kg'), findsOneWidget);
    expect(find.text('Lander'), findsOneWidget);
    expect(find.text('113.5 kg'), findsOneWidget);

    // Highest first: Epley's value must sit above Brzycki's on screen.
    final epley = tester.getTopLeft(find.text('116.5 kg')).dy;
    final brzycki = tester.getTopLeft(find.text('112.5 kg')).dy;
    expect(epley, lessThan(brzycki));
  });

  testWidgets('a true single needs no estimating', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 140);
    // Drag the reps slider all the way to the left (1 rep).
    await tester.drag(find.byType(Slider), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('already your max'), findsOneWidget);
    // Every formula returns the lifted weight, so there's no range to show.
    expect(find.textContaining('range'), findsNothing);
    // All three formulas return the lifted weight itself.
    expect(find.text('140 kg'), findsAtLeastNWidgets(3));
  });

  testWidgets('warns once the rep count stops being reliable', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 60);
    expect(find.textContaining('rough guess'), findsNothing);

    // Drag the reps slider to the far end (20 reps).
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('rough guess'), findsOneWidget);
  });
}
