// The fatigue reading is red, not the accent.
//
// Volume and fatigue share one body diagram. Before this, both tinted toward
// the accent — the same picture twice, and a glance could not tell "I trained
// this hard" from "this is not recovered". The captions said which, but nobody
// reads a caption to interpret a colour.
//
// Worth a test because it fails invisibly: an accent-coloured fatigue map looks
// perfectly fine on its own. It is only wrong next to the volume one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/muscle_map/data/muscle_colors.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map_view.dart';

import 'support/default_accent.dart';

/// A stand-in body with one taggable muscle.
const _svg =
    '<svg><path data-muscle="chest" fill="#4C5361"/></svg>';

String _fillOf(String svg) =>
    RegExp(r'fill="(#[0-9A-F]{6})"').firstMatch(svg)!.group(1)!;

String _hex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

void main() {
  group('the fatigue colour', () {
    test('is red, and not one of the accents', () {
      // The point of the change: it has to be distinguishable from whichever
      // accent the user picked, so it cannot be one of them.
      expect(AccentPalette.options, isNot(contains(fatigueColor)));

      // Red in the plain sense — dominant red channel, by a clear margin.
      expect(fatigueColor.r, greaterThan(fatigueColor.g));
      expect(fatigueColor.r, greaterThan(fatigueColor.b));
      expect(fatigueColor.g, closeTo(fatigueColor.b, 0.06));
    });

    test('a fully fatigued muscle is drawn in it', () {
      final svg = tintMuscles(
        svg: _svg,
        intensities: const {'chest': 1},
        heatColor: fatigueColor,
      );

      expect(_fillOf(svg), _hex(fatigueColor));
    });

    test('a recovered muscle stays neutral, same as an untrained one', () {
      // Zero has to mean the same thing in both readings, or "what have I not
      // trained" and "what is ready" would look like different questions.
      final fatigued = tintMuscles(
        svg: _svg,
        intensities: const {'chest': 0},
        heatColor: fatigueColor,
      );
      final volume = tintMuscles(
        svg: _svg,
        intensities: const {'chest': 0},
        heatColor: AccentPalette.blue,
      );

      expect(_fillOf(fatigued), _fillOf(volume));
    });

    test('volume and fatigue never draw the same colour at full strength', () {
      // Across every accent a user can choose.
      for (final accent in AccentPalette.options) {
        final volume = tintMuscles(
          svg: _svg,
          intensities: const {'chest': 1},
          heatColor: accent,
        );
        final fatigue = tintMuscles(
          svg: _svg,
          intensities: const {'chest': 1},
          heatColor: fatigueColor,
        );

        expect(_fillOf(volume), isNot(_fillOf(fatigue)), reason: '$accent');
      }
    });

    test('contrast mode ignores it — each muscle keeps its own colour', () {
      // Per-muscle colours are the whole point of that mode; overriding them
      // with red would collapse it back into a heatmap.
      final svg = tintMuscles(
        svg: _svg,
        intensities: const {'chest': 1},
        heatColor: fatigueColor,
        mode: MuscleMapMode.contrast,
      );

      expect(_fillOf(svg), _hex(muscleColor('chest')));
    });
  });

  group('MuscleMapView', () {
    testWidgets('passes the heat colour down to the diagram', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...defaultDisplayOverrides],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: MuscleMapView(
                  intensities: AsyncData({'chest': 1.0}),
                  emptyMessage: 'nothing',
                  heatColor: fatigueColor,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final map = tester.widget<MuscleMap>(find.byType(MuscleMap));
      expect(map.heatColor, fatigueColor);
    });

    testWidgets('defaults to the accent when none is given', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...defaultDisplayOverrides],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 600,
                child: MuscleMapView(
                  intensities: AsyncData({'chest': 1.0}),
                  emptyMessage: 'nothing',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Null rather than the accent itself: the map resolves the default, so
      // the volume reading keeps following whatever accent is chosen.
      expect(tester.widget<MuscleMap>(find.byType(MuscleMap)).heatColor, isNull);
    });
  });
}
