// Verifies the muscle-map SVG assets are well-formed and that every muscle id
// in MuscleId is represented by a tagged path across the front/back diagrams.
// This guards the sync requirement called out in muscle_ids.dart.

import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  final front = File('assets/svg/body_front.svg').readAsStringSync();
  final back = File('assets/svg/body_back.svg').readAsStringSync();

  test('both SVGs look well-formed', () {
    for (final svg in [front, back]) {
      expect(svg.trimLeft(), startsWith('<svg'));
      expect(svg.trimRight(), endsWith('</svg>'));
    }
  });

  // Collects every id token across both diagrams. A single path may carry
  // several space-separated ids (one region standing in for several muscles).
  Set<String> taggedIds() {
    final tag = RegExp(r'data-muscle="([^"]+)"');
    final ids = <String>{};
    for (final svg in [front, back]) {
      for (final match in tag.allMatches(svg)) {
        ids.addAll(match.group(1)!.split(' '));
      }
    }
    return ids;
  }

  test('every muscle id appears as a data-muscle token somewhere', () {
    final tagged = taggedIds();
    for (final id in MuscleId.all) {
      expect(
        tagged,
        contains(id),
        reason: 'No path tagged for muscle "$id" in the body SVGs.',
      );
    }
  });

  test('no data-muscle tag references an unknown muscle id', () {
    for (final id in taggedIds()) {
      expect(
        MuscleId.all,
        contains(id),
        reason: '"$id" is tagged in an SVG but is not a known MuscleId.',
      );
    }
  });

  // The figure is drawn over two different things depending on the theme: a
  // near-black card on the flat ones, a bright moving field on Hyper. The slate
  // the sheets are authored in reads as "muscle I haven't trained" on the first
  // and as a hole cut in the screen on the second, so the palette travels in
  // rather than being fixed in the files. Making it merely translucent was not
  // enough — 86% of a very dark colour is still a very dark colour.
  group('the figure takes the palette it is given', () {
    test('an untrained muscle is painted the rest colour it was passed', () {
      final tinted = tintMuscles(
        svg: front,
        intensities: const {},
        heatColor: const Color(0xFF7C6BFF),
        restColor: const Color(0xFF9BA3B6),
      );

      expect(tinted, contains('fill="#9BA3B6"'));
      expect(
        tinted,
        isNot(contains('data-muscle="chest" fill="#4C5361"')),
        reason: 'the authored rest colour survived the tint',
      );
    });

    test('the silhouette is repainted too, not just the muscles', () {
      // It carries its own fill and no data-muscle tag, so the tinting pass
      // walks straight past it — which left a black head, hands and feet on a
      // body whose muscles had been lifted.
      expect(front, contains('fill="#2E3440"'));

      final tinted = tintMuscles(
        svg: front,
        intensities: const {},
        heatColor: const Color(0xFF7C6BFF),
        bodyColor: const Color(0xFF666F82),
      );

      expect(tinted, contains('fill="#666F82"'));
      expect(tinted, isNot(contains('fill="#2E3440"')));
    });

    test('and by default the sheets are left exactly as authored', () {
      // The six flat themes are meant to come out of the redesign unchanged.
      final tinted = tintMuscles(
        svg: front,
        intensities: const {},
        heatColor: const Color(0xFF7C6BFF),
      );

      expect(tinted, contains('fill="#2E3440"'));
      expect(tinted, contains('fill="#4C5361"'));
    });
  });
}
