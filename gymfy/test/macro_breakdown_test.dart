// Verifies the macro breakdown renders its legend with the right shares, and
// shows a hint when there's nothing to break down.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calories/widgets/macro_breakdown.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ProviderScope(child: MaterialApp(home: Scaffold(body: child))),
  );
}

void main() {
  testWidgets('shows macro legend with grams and percentages', (tester) async {
    // 50g protein (200 kcal) + 50g carbs (200 kcal) + 0g fat = 400 kcal.
    // Protein and carbs are each 50%.
    await _pump(tester, const MacroBreakdown(protein: 50, carbs: 50, fat: 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    // Protein and carbs are each 50% of the 400 kcal total.
    expect(find.text('50g · 50%'), findsNWidgets(2));
    expect(find.text('0g · 0%'), findsOneWidget); // fat share
  });

  testWidgets('shows a hint when there are no macros', (tester) async {
    await _pump(tester, const MacroBreakdown(protein: 0, carbs: 0, fat: 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Add meals'), findsOneWidget);
  });
}
