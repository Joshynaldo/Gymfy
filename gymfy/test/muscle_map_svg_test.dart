// Verifies the muscle-map SVG assets are well-formed and that every muscle id
// in MuscleId is represented by a tagged path across the front/back diagrams.
// This guards the sync requirement called out in muscle_ids.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('every muscle id appears as a data-muscle group somewhere', () {
    final combined = '$front\n$back';
    for (final id in MuscleId.all) {
      expect(
        combined,
        contains('data-muscle="$id"'),
        reason: 'No path tagged for muscle "$id" in the body SVGs.',
      );
    }
  });

  test('no data-muscle tag references an unknown muscle id', () {
    final tag = RegExp(r'data-muscle="([^"]+)"');
    for (final svg in [front, back]) {
      for (final match in tag.allMatches(svg)) {
        final id = match.group(1)!;
        expect(
          MuscleId.all,
          contains(id),
          reason: '"$id" is tagged in an SVG but is not a known MuscleId.',
        );
      }
    }
  });
}
