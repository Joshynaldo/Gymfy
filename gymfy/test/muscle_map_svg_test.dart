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
}
