// Nothing lays itself out past its own box — at the reader's text size, not
// only at mine.
//
// Written after "BOTTOM OVERFLOWED BY 2 PIXELS" turned up on Home. The cause
// was a hard-coded total: the week card's bar area was 76, which was the sum of
// a 56px bar, an 8px gap and a label at one particular size. The label is not a
// fixed size — it is whatever the phone's font scale makes it — so the sum was
// only ever right on the device it was measured on.
//
// Two pixels at 100%, six at 130%. Both are the same bug, and the fix is to
// stop adding the pieces up by hand.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/router/scaffold_with_nav_bar.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/home/data/recap_repository.dart';
import 'package:gymfy/features/home/widgets/week_card.dart';
import 'package:gymfy/shared/widgets/app_button.dart';
import 'package:gymfy/shared/widgets/app_segmented.dart';
import 'package:gymfy/shared/widgets/glass_nav_bar.dart';

import 'support/default_accent.dart';

/// A week's worth of logged sets, so the card has bars to draw.
final _sets = <RecapSet>[
  for (var day = 0; day < 5; day++)
    (
      date: DateTime(2026, 9, 7 + day),
      sessionId: day,
      exerciseId: 'barbell_bench_press',
      weight: 100.0 + day * 10,
      reps: 8,
      muscleIds: const ['chest'],
    ),
];

/// Builds [child] at [scale] and hands back whatever the framework complained
/// about — an overflow is reported as an exception, so this catches it.
Future<Object?> _layout(
  WidgetTester tester,
  Widget child, {
  required double scale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...defaultDisplayOverrides,
        recapSetsProvider.overrideWith((ref) => Stream.value(_sets)),
      ],
      child: MaterialApp(
        theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Center(child: SizedBox(width: 375, child: child)),
          ),
        ),
      ),
    ),
  );
  // Plain pumps: some of these animate on arrival and none of them settle on
  // their own inside a test with no clock advancing the providers.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return tester.takeException();
}

void main() {
  // 1.0 is the default; 1.3 is a phone with larger text turned on, which is
  // common enough on a gym app that it is not an edge case.
  for (final scale in [1.0, 1.3]) {
    group('at text scale $scale', () {
      testWidgets('the week card fits its bars and their labels', (
        tester,
      ) async {
        expect(await _layout(tester, const WeekCard(), scale: scale), isNull);
      });

      testWidgets('the navigation pill fits its labels', (tester) async {
        expect(
          await _layout(
            tester,
            GlassNavBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: mainDestinations,
            ),
            scale: scale,
          ),
          isNull,
        );
      });

      testWidgets('a primary button fits its label', (tester) async {
        expect(
          await _layout(
            tester,
            AppButton(
              label: 'Start workout',
              icon: Icons.play_arrow,
              onPressed: () {},
            ),
            scale: scale,
          ),
          isNull,
        );
      });

      testWidgets('the segmented control fits three labels', (tester) async {
        expect(
          await _layout(
            tester,
            AppSegmented<int>(
              selected: 0,
              onChanged: (_) {},
              segments: const [
                (value: 0, label: 'Trends', leading: null),
                (value: 1, label: 'All-time', leading: null),
                (value: 2, label: 'Body', leading: null),
              ],
            ),
            scale: scale,
          ),
          isNull,
        );
      });
    });
  }
}
