// The card look shared by Exercises, Progress and More.
//
// Worth pinning down because three screens now depend on it: a change that only
// looked right on one of them would otherwise ship unnoticed on the other two.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/shared/widgets/app_card.dart';

import 'support/default_accent.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [defaultAccentOverride],
      child: MaterialApp(
        // The app's real theme, not Flutter's default: the card reads its
        // surface and outline straight off `cardTheme`, and the stock theme
        // leaves those null — which would make these tests pass against
        // nothing.
        theme: buildAppTheme(AppTheme.darkDefault, AccentPalette.blue),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The border the card is currently drawing.
BorderSide _borderOf(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(AppCard),
      matching: find.byType(AnimatedContainer),
    ).first,
  );
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.border! as Border).top;
}

void main() {
  group('AppCard', () {
    testWidgets('takes its surface from the theme, like a Home tab card', (
      tester,
    ) async {
      await _pump(tester, const AppCard(child: Text('hi')));

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final cardTheme = Theme.of(
        tester.element(find.byType(AppCard)),
      ).cardTheme;

      // Same colour the Home tab's cards use — that's the whole point of
      // reading it off `cardTheme` rather than picking a surface by hand.
      expect(decoration.color, cardTheme.color);
    });

    testWidgets('wears whatever outline the theme gives its cards', (
      tester,
    ) async {
      await _pump(tester, const AppCard(child: Text('hi')));

      final shape =
          Theme.of(tester.element(find.byType(AppCard))).cardTheme.shape
              as RoundedRectangleBorder;

      // Passed through rather than invented. The theme decides per palette
      // whether cards need an outline at all — near-black surfaces do, lifted
      // ones don't — and this has no business overruling that.
      expect(_borderOf(tester).color, shape.side.color);
    });

    testWidgets('outlines itself in the accent when selected', (tester) async {
      await _pump(tester, const AppCard(selected: true, child: Text('hi')));
      await tester.pumpAndSettle();

      final picked = _borderOf(tester);

      // Visible, and the only border most themes ever draw — so when it shows
      // up it means "this is the one you picked" rather than being decoration.
      expect(picked.color.a, greaterThan(0.9));
      expect(picked.width, greaterThan(1));
    });

    testWidgets('is tappable and long-pressable', (tester) async {
      var taps = 0;
      var holds = 0;

      await _pump(
        tester,
        AppCard(
          onTap: () => taps++,
          onLongPress: () => holds++,
          child: const Text('hi'),
        ),
      );

      await tester.tap(find.text('hi'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('hi'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(holds, 1);
    });
  });

  group('AppTile', () {
    testWidgets('shows its icon, title and subtitle', (tester) async {
      await _pump(
        tester,
        const AppTile(
          icon: Icons.fitness_center,
          title: 'Barbell Bench Press',
          subtitle: 'Chest · Triceps',
        ),
      );

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Chest · Triceps'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('a one-line tile renders without a subtitle', (tester) async {
      await _pump(
        tester,
        const AppTile(icon: Icons.show_chart, title: 'Squat'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Squat'), findsOneWidget);
    });

    testWidgets('the glyph becomes a tick when selected', (tester) async {
      await _pump(
        tester,
        const AppTile(
          icon: Icons.fitness_center,
          title: 'Squat',
          selected: true,
        ),
      );

      // The icon is replaced rather than decorated, so a picked row reads as
      // picked at a glance rather than needing the border to be noticed.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsNothing);
    });

    testWidgets('carries a badge next to the title', (tester) async {
      await _pump(
        tester,
        const AppTile(
          icon: Icons.fitness_center,
          title: 'Cable Fly',
          titleTrailing: Text('Custom'),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('the trailing icon can be replaced', (tester) async {
      await _pump(
        tester,
        const AppTile(
          icon: Icons.fitness_center,
          title: 'Squat',
          trailing: Icon(Icons.show_chart),
        ),
      );

      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('the glyph can be replaced entirely', (tester) async {
      // The exercise library puts a still of the movement here instead of the
      // same dumbbell symbol on every row.
      await _pump(
        tester,
        const AppTile(
          icon: Icons.fitness_center,
          title: 'Barbell Bench Press',
          leading: SizedBox.square(dimension: 42, child: Placeholder()),
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(AppGlyph), findsNothing);
      expect(find.byIcon(Icons.fitness_center), findsNothing);
    });
  });

  group('AppPanel', () {
    testWidgets('draws its heading above its content', (tester) async {
      await _pump(
        tester,
        const AppPanel(
          icon: Icons.table_chart_outlined,
          title: 'Spreadsheet',
          subtitle: 'One row per set',
          child: Text('body'),
        ),
      );

      expect(find.text('Spreadsheet'), findsOneWidget);
      expect(find.text('One row per set'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Spreadsheet')).dy,
        lessThan(tester.getTopLeft(find.text('body')).dy),
      );
    });

    testWidgets('a panel with no heading is just a surface', (tester) async {
      await _pump(tester, const AppPanel(child: Text('body')));

      expect(find.text('body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('takes its surface from the theme, like every other card', (
      tester,
    ) async {
      // The whole reason this widget exists: five screens had each grown a
      // `Container` with `surfaceContainerHighest` and a hand-picked radius,
      // which is a card that ignores the theme. Going through AppCard is what
      // stops that drifting again.
      await _pump(tester, const AppPanel(child: Text('body')));

      expect(find.byType(AppCard), findsOneWidget);
    });
  });

  group('AppSectionHeader', () {
    testWidgets('shows its title and count', (tester) async {
      await _pump(tester, const AppSectionHeader(title: 'Chest', count: 10));

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('the count is optional', (tester) async {
      await _pump(tester, const AppSectionHeader(title: 'Chest'));

      expect(find.text('Chest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
