// The shared picker: the closed field, and the sheet it opens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/app_picker.dart';
import 'package:gymfy/shared/widgets/number_wheel.dart';

import 'support/default_accent.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    // Taller than the default 800×600: the number sheet is a headline value, a
    // 180px drum and a Done button, and on the default surface Done sits below
    // the fold — the tap silently misses rather than failing loudly.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppPickerField', () {
    testWidgets('shows what is being asked and the current answer', (
      tester,
    ) async {
      await pump(
        tester,
        AppPickerField(label: 'Height', value: '183 cm', onTap: () {}),
      );

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('183 cm'), findsOneWidget);
    });

    testWidgets('a disabled field does not fire', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppPickerField(
          label: 'Height',
          value: '183 cm',
          enabled: false,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byType(AppPickerField));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });

  group('showNumberPicker', () {
    /// A button that opens the picker and records what came back.
    Widget opener(List<int?> results, {int initial = 30}) {
      return Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            results.add(
              await showNumberPicker(
                context: context,
                title: 'How old are you?',
                min: 13,
                max: 100,
                initial: initial,
              ),
            );
          },
          child: const Text('open'),
        ),
      );
    }

    testWidgets('opens on the value it was given', (tester) async {
      await pump(tester, opener([]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Shown twice on purpose: once large above the drum as the sheet's
      // answer, once inside the drum among its neighbours.
      expect(find.text('30'), findsNWidgets(2));
    });

    testWidgets('uses the one shared wheel', (tester) async {
      // Not its own drum: a picker that scrolls differently from the sets and
      // reps wheels is a second control wearing the same costume.
      await pump(tester, opener([]));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(NumberWheel), findsOneWidget);
    });

    testWidgets('Done returns the value', (tester) async {
      final results = <int?>[];
      await pump(tester, opener(results));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results.single, 30);
    });

    testWidgets('dismissing returns null rather than the initial value', (
      tester,
    ) async {
      // "Cancelled" and "chose what was already there" have to stay different
      // answers, or dismissing would silently write a value nobody picked.
      final results = <int?>[];
      await pump(tester, opener(results));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.text('Done'))).pop();
      await tester.pumpAndSettle();

      expect(results.single, isNull);
    });

    testWidgets('an out-of-range initial value is pulled into range', (
      tester,
    ) async {
      // A stored figure from a hand-edited database shouldn't crash the wheel
      // by asking it to open past its own last item.
      await pump(tester, opener([], initial: 5000));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('100'), findsWidgets);
    });
  });

  group('showOptionPicker', () {
    testWidgets('ticks only the chosen row', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showOptionPicker<int>(
              context: context,
              title: 'Bar',
              selected: 20,
              options: const [
                (value: 20, label: '20 kg', subtitle: null),
                (value: 15, label: '15 kg', subtitle: null),
                (value: 0, label: 'None', subtitle: null),
              ],
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The question is "which is it", not "here are three switches".
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
