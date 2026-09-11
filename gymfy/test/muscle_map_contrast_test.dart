// Contrast mode: a distinct colour per muscle instead of one accent hue.
//
// The tinting is tested by reading the hex it writes into the SVG string rather
// than by rendering — what matters is which colour each region ends up with.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/muscle_map/data/muscle_colors.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  /// A stand-in for the real SVG: the tinting only cares about these tags.
  String svgWith(List<String> regions) {
    return regions
        .map((r) => '<path data-muscle="$r" fill="#4C5361"/>')
        .join();
  }

  /// The fills the tinter wrote, in document order.
  List<String> fillsOf(String svg) {
    return RegExp(r'fill="(#[0-9A-F]{6})"')
        .allMatches(svg)
        .map((m) => m.group(1)!)
        .toList();
  }

  String tint(
    List<String> regions,
    Map<String, double> intensities, {
    MuscleMapMode mode = MuscleMapMode.contrast,
  }) {
    return tintMuscles(
      svg: svgWith(regions),
      intensities: intensities,
      heatColor: AccentPalette.blue,
      mode: mode,
    );
  }

  String hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  group('the palette', () {
    test('covers every muscle on the map', () {
      // A muscle with no colour would be an unexplained grey patch sitting in
      // the middle of a coloured diagram.
      for (final muscleId in MuscleId.all) {
        expect(colouredMuscles, contains(muscleId), reason: muscleId);
      }
    });

    test('every colour is distinct', () {
      final colors = colouredMuscles.map(muscleColor).toList();
      expect(colors.toSet(), hasLength(colors.length));
    });

    test('no two colours are near-identical', () {
      // Distinctness alone isn't enough: two greens one shade apart are two
      // different values and still indistinguishable on a small diagram.
      //
      // Every offending pair is collected before failing, so one run names all
      // of them instead of sending you round the loop once per clash.
      final tooClose = <String>[];
      for (var i = 0; i < colouredMuscles.length; i++) {
        for (var j = i + 1; j < colouredMuscles.length; j++) {
          final a = muscleColor(colouredMuscles[i]);
          final b = muscleColor(colouredMuscles[j]);
          final distance =
              (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
          if (distance <= 0.25) {
            tooClose.add(
              '${colouredMuscles[i]} vs ${colouredMuscles[j]} '
              '(${distance.toStringAsFixed(2)})',
            );
          }
        }
      }
      expect(tooClose, isEmpty);
    });

    test('an unknown muscle gets a neutral colour rather than crashing', () {
      // A new id should be an unremarkable grey region, not a broken tab.
      expect(muscleColor('wingspan'), const Color(0xFF9AA5B1));
    });

    test('the deltoids are told apart, since they sit next to each other', () {
      final front = muscleColor(MuscleId.frontDeltoid);
      final side = muscleColor(MuscleId.sideDeltoid);
      final rear = muscleColor(MuscleId.rearDeltoid);

      expect({front, side, rear}, hasLength(3));
    });
  });

  group('tinting in contrast mode', () {
    test('a fully worked muscle takes its own colour, not the accent', () {
      final svg = tint([MuscleId.chest], {MuscleId.chest: 1});

      expect(fillsOf(svg).single, hex(muscleColor(MuscleId.chest)));
    });

    test('two muscles at the same intensity look different', () {
      // The exact failing case of a single-hue heatmap: chest and front delt at
      // similar volume are the same shade and blur into one region.
      final svg = tint(
        [MuscleId.chest, MuscleId.frontDeltoid],
        {MuscleId.chest: 0.8, MuscleId.frontDeltoid: 0.8},
      );

      final fills = fillsOf(svg);
      expect(fills.first, isNot(fills.last));
    });

    test('an untrained muscle stays neutral, exactly as in heatmap mode', () {
      // So "what have I not trained" reads the same in both modes.
      final contrast = tint([MuscleId.chest], const {});
      final heatmap = tint(
        [MuscleId.chest],
        const {},
        mode: MuscleMapMode.heatmap,
      );

      expect(fillsOf(contrast).single, '#4C5361');
      expect(fillsOf(contrast), fillsOf(heatmap));
    });

    test('intensity still dims the colour', () {
      final full = fillsOf(tint([MuscleId.chest], {MuscleId.chest: 1})).single;
      final half = fillsOf(tint([MuscleId.chest], {MuscleId.chest: 0.5})).single;

      // Same data as the heatmap, just readable — half volume must not look
      // like full volume.
      expect(half, isNot(full));
      expect(half, isNot('#4C5361'));
    });

    test('a region tagged with several muscles takes the loudest one', () {
      // Its colour and its brightness then tell the same story, instead of
      // showing one muscle's hue at another's intensity.
      final svg = tint(
        ['${MuscleId.frontDeltoid} ${MuscleId.sideDeltoid}'],
        {MuscleId.frontDeltoid: 0.2, MuscleId.sideDeltoid: 1},
      );

      expect(fillsOf(svg).single, hex(muscleColor(MuscleId.sideDeltoid)));
    });
  });

  group('tinting in heatmap mode', () {
    test('every worked muscle uses the accent', () {
      final svg = tint(
        [MuscleId.chest, MuscleId.quads],
        {MuscleId.chest: 1, MuscleId.quads: 1},
        mode: MuscleMapMode.heatmap,
      );

      final fills = fillsOf(svg);
      expect(fills.first, hex(AccentPalette.blue));
      expect(fills.last, hex(AccentPalette.blue));
    });

    test('the muscle palette is ignored entirely', () {
      final svg = tint(
        [MuscleId.chest],
        {MuscleId.chest: 1},
        mode: MuscleMapMode.heatmap,
      );

      expect(fillsOf(svg).single, isNot(hex(muscleColor(MuscleId.chest))));
    });
  });
}
