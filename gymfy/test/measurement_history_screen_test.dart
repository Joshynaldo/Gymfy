// Renders the measurement history screen against a stubbed history: the chart
// must lay out, the summary must show the latest value and total change, and
// switching body part must swap the series.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/progress/screens/measurement_history_screen.dart';
import 'package:gymfy/features/progress/widgets/measurement_timeline_chart.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  BodyMeasurement row(int day, {double? weight, double? waist}) {
    return BodyMeasurement(
      id: day,
      date: DateTime(2026, 7, day),
      weightKg: weight,
      waistCm: waist,
      updatedAt: DateTime(2026, 7, day),
    );
  }

  // Newest first, as the repository streams it.
  final history = [
    row(24, weight: 82.5),
    row(17, waist: 86),
    row(10, weight: 84),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          defaultAccentOverride,
          defaultWeightUnitOverride,
          measurementHistoryProvider.overrideWith(
            (ref) => Stream.value(history),
          ),
        ],
        child: const MaterialApp(home: MeasurementHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the weight timeline with its total change', (tester) async {
    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(MeasurementTimelineChart), findsOneWidget);
    expect(find.text('82.5'), findsOneWidget); // latest weight
    expect(find.text('−1.5 kg'), findsOneWidget); // 84 → 82.5
    expect(find.text('2 measurements over 14 days'), findsOneWidget);
  });

  testWidgets('a body part with one measurement explains itself instead of '
      'drawing a chart', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Waist'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MeasurementTimelineChart), findsNothing);
    expect(find.text('Only one waist measurement so far'), findsOneWidget);
  });

  testWidgets('a body part never measured shows an empty state', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Hips'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No hips measurements yet'), findsOneWidget);
  });
}
