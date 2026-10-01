// Training block settings on a split, and the line saying which week it is.

import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/programs/widgets/training_block_settings.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/dates.dart';
import 'package:gymfy/shared/widgets/glass_sheet.dart';

import 'support/default_accent.dart';

/// A split whose block began [daysAgo] days ago — relative to the real today,
/// because the banner asks the clock what week it is.
Split _split({int? blockWeeks, int daysAgo = 0, double? deloadPercent}) {
  final today = dateOnly(DateTime.now());
  return Split(
    id: 1,
    name: 'Strength',
    position: 0,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    blockWeeks: blockWeeks,
    deloadPercent: deloadPercent,
    blockStartedAt: blockWeeks == null
        ? null
        : DateTime(today.year, today.month, today.day - daysAgo),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(420, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...defaultDisplayOverrides],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the banner', () {
    testWidgets('says nothing for a split without a block', (tester) async {
      await _pump(tester, TrainingBlockBanner(split: _split()));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows the week of the block and when the deload is', (
      tester,
    ) async {
      await _pump(
        tester,
        TrainingBlockBanner(split: _split(blockWeeks: 4, daysAgo: 7)),
      );
      expect(find.text('Week 2 of 4'), findsOneWidget);
      expect(find.textContaining('Deload at 90% in 3 weeks'), findsOneWidget);
    });

    testWidgets('says when the deload is next week', (tester) async {
      await _pump(
        tester,
        TrainingBlockBanner(split: _split(blockWeeks: 4, daysAgo: 21)),
      );
      expect(find.text('Week 4 of 4'), findsOneWidget);
      expect(find.textContaining('next week'), findsOneWidget);
    });

    testWidgets('marks the deload week with its load', (tester) async {
      await _pump(
        tester,
        TrainingBlockBanner(
          split: _split(blockWeeks: 4, daysAgo: 28, deloadPercent: 60),
        ),
      );
      expect(find.text('Deload week'), findsOneWidget);
      expect(find.textContaining('Suggested weights at 60%'), findsOneWidget);
    });
  });

  group('the sheet', () {
    /// Opens the sheet for [split] and returns a holder for its answer.
    Future<List<TrainingBlockChoice?>> open(
      WidgetTester tester,
      Split split,
    ) async {
      final results = <TrainingBlockChoice?>[];
      await _pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async => results.add(
                await showGlassSheet<TrainingBlockChoice>(
                  context: context,
                  child: TrainingBlockSheet(split: split),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('sets up a block from today', (tester) async {
      final results = await open(tester, _split());

      await tester.tap(find.text('Run in training blocks'));
      await tester.pumpAndSettle();
      // Three weeks is where a new block starts.
      expect(find.text('3 weeks'), findsOneWidget);

      await tester.tap(find.byTooltip('More weeks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('70%'));
      await tester.pumpAndSettle();
      expect(find.text('Today: Week 1 of 4'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final choice = results.single!;
      expect(choice.isOff, isFalse);
      expect(choice.blockWeeks, 4);
      expect(choice.deloadPercent, 70);
      expect(choice.startedAt, dateOnly(DateTime.now()));
    });

    testWidgets('keeps a stored deload load it has no chip for', (
      tester,
    ) async {
      // Opening the sheet must not quietly snap 65 % to a neighbour.
      final results = await open(
        tester,
        _split(blockWeeks: 3, daysAgo: 0, deloadPercent: 65),
      );
      expect(find.text('65%'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(results.single!.deloadPercent, 65);
    });

    testWidgets('turning it off hands back "no block"', (tester) async {
      final results = await open(tester, _split(blockWeeks: 3, daysAgo: 10));

      await tester.tap(find.text('Run in training blocks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(results.single!.isOff, isTrue);
    });

    testWidgets('cancel hands back nothing', (tester) async {
      final results = await open(tester, _split(blockWeeks: 3));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results.single, isNull);
    });
  });
}
