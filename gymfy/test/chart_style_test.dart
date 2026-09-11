// The charts read as one system rather than three charts.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/chart_style.dart';

void main() {
  group('dots', () {
    test('are shown while you can still count them', () {
      // Dots say "these are the readings, everything between is drawn in".
      expect(chartShowsDots(2), isTrue);
      expect(chartShowsDots(12), isTrue);
    });

    test('are dropped once they would merge into the line', () {
      // Past a dozen they stop being marks and become a thick, lumpy line that
      // says nothing — which is the state a year of logged sessions reaches.
      expect(chartShowsDots(13), isFalse);
      expect(chartShowsDots(200), isFalse);
    });
  });

  group('the shared look', () {
    testWidgets('grid lines are dashed, so they recede behind the data', (
      tester,
    ) async {
      late FlLineProbe probe;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final line = chartGridLine(context);
              probe = (dashArray: line.dashArray, alpha: line.color!.a);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(probe.dashArray, isNotNull);
      // Faint enough to read past. A grid exists to be measured against, not
      // looked at.
      expect(probe.alpha, lessThan(0.15));
    });

    testWidgets('axis labels are tabular', (tester) async {
      // Proportional digits change width as numbers tick over, so a y-axis of
      // 100/110/120 sits at three slightly different indents and the column
      // looks crooked without anyone being able to say why.
      late TextStyle? style;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = chartLabelStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('the area fill fades rather than sitting flat', () {
      // A flat fill reads as a solid shape competing with the line; a gradient
      // reads as the line casting light downward.
      final fill = chartAreaFill(const Color(0xFF7C6BFF));

      expect(fill.gradient, isNotNull);
      expect(fill.color, isNull);
    });

    test('every chart in the app draws from it', () {
      // The point of the file. Three charts had each grown their own gridline
      // colour and their own idea of how strongly to shade under a line — none
      // of it wrong, all of it slightly different, one screen apart.
      final charts = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('FlGridData('));

      expect(charts, isNotEmpty, reason: 'no charts found — check the probe');

      for (final chart in charts) {
        expect(
          chart.readAsStringSync(),
          contains('chartGridLine('),
          reason: '${chart.path} styles its own grid',
        );
      }
    });
  });
}

/// The couple of fields worth reading off a grid line.
typedef FlLineProbe = ({List<int>? dashArray, double alpha});
