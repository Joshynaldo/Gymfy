// Which body the muscle map draws, and whether the female sheets are usable.
//
// The female diagrams are not a reshaped copy of the male ones — the licensed
// pack draws a different set of muscle groups under different ids, on a
// different viewBox. Every one of those differences is a way for the build
// tool's mapping to silently produce a body with dead regions on it, which
// looks exactly like "I haven't trained that yet".

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/widgets/muscle_map.dart';
import 'package:gymfy/shared/data/lifter_sex.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

/// Muscles the female sheets genuinely cannot show, because the pack didn't
/// draw them. Listed explicitly rather than skipped silently: if a future pack
/// adds them, this list should shrink, and the test says so.
const _missingOnFemale = {
  // The female front has no `sternocleidomastoid`.
  'neck',
};

void main() {
  String read(BodyFigure figure, BodySide side) =>
      File(bodyDiagram(figure, side).asset).readAsStringSync();

  Set<String> taggedIds(BodyFigure figure) {
    final ids = <String>{};
    for (final side in BodySide.values) {
      for (final m in RegExp(
        r'data-muscle="([^"]+)"',
      ).allMatches(read(figure, side))) {
        ids.addAll(m.group(1)!.split(' '));
      }
    }
    return ids;
  }

  group('the female diagrams', () {
    test('exist and are well-formed', () {
      for (final side in BodySide.values) {
        final svg = read(BodyFigure.female, side);
        expect(svg.trimLeft(), startsWith('<svg'));
        expect(svg.trimRight(), endsWith('</svg>'));
      }
    });

    test('cover every muscle the male ones do, bar the documented gaps', () {
      final male = taggedIds(BodyFigure.male);
      final female = taggedIds(BodyFigure.female);

      expect(
        male.difference(female),
        _missingOnFemale,
        reason: 'female sheets lost a muscle the male ones show',
      );
    });

    test('tag no muscle the app does not know about', () {
      for (final id in taggedIds(BodyFigure.female)) {
        expect(MuscleId.all, contains(id), reason: '"$id" is not a MuscleId');
      }
    });

    test('carry the hand-drawn lower back', () {
      // The pack has no lumbar region on either sheet, so the build tool draws
      // it — and it has to be measured off each body, since one set of
      // coordinates lands off the figure entirely on the other viewBox.
      expect(
        read(BodyFigure.female, BodySide.back),
        contains('id="lower_back"'),
      );
    });

    test('ship no leftover pack gradients', () {
      // The female sheets name their outline gradient differently from the
      // male ones, so the original literal swap left them pointing at paint
      // that the build then stripped — a dangling `url(#...)` renders black.
      for (final figure in BodyFigure.values) {
        for (final side in BodySide.values) {
          final svg = read(figure, side);
          expect(svg, isNot(contains('url(#')), reason: '${figure.name} $side');
          expect(svg, isNot(contains('<linearGradient')));
        }
      }
    });
  });

  group('picking a figure', () {
    Future<BodyFigure> figureFor(LifterSex? sex) async {
      final container = ProviderContainer(
        overrides: [lifterSexProvider.overrideWith((ref) => Stream.value(sex))],
      );
      addTearDown(container.dispose);
      // Subscribe, then let the microtask queue drain so the stream's single
      // value has actually landed. Reading straight away would see the loading
      // state and prove nothing.
      final sub = container.listen(lifterSexProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      addTearDown(sub.close);
      return container.read(bodyFigureProvider);
    }

    test('female is drawn for a female lifter', () async {
      expect(await figureFor(LifterSex.female), BodyFigure.female);
    });

    test('male is drawn for a male lifter', () async {
      expect(await figureFor(LifterSex.male), BodyFigure.male);
    });

    test('unset falls back to male rather than drawing nothing', () async {
      // Unlike a strength rank, a body map has no "not enough information"
      // state — it has to draw something. Every install made before onboarding
      // asked the question looks like this.
      expect(await figureFor(null), BodyFigure.male);
    });
  });

  group('the two figures are drawn at their own proportions', () {
    test('each side has its own aspect ratio', () {
      // The male sheets are square-ish at 248×558 both sides; the female ones
      // are 172×546 and 154×539. Reusing one ratio visibly squashed them.
      final femaleFront = bodyDiagram(BodyFigure.female, BodySide.front);
      final femaleBack = bodyDiagram(BodyFigure.female, BodySide.back);
      expect(femaleFront.aspectRatio, isNot(femaleBack.aspectRatio));
      expect(
        femaleFront.aspectRatio,
        isNot(bodyDiagram(BodyFigure.male, BodySide.front).aspectRatio),
      );
    });

    test('the declared ratio matches the file it names', () {
      // A ratio that drifts from its asset stretches the drawing, and nothing
      // else in the app would notice.
      for (final figure in BodyFigure.values) {
        for (final side in BodySide.values) {
          final diagram = bodyDiagram(figure, side);
          final box = RegExp(
            r'viewBox="0 0 ([\d.]+) ([\d.]+)"',
          ).firstMatch(File(diagram.asset).readAsStringSync())!;
          final actual =
              double.parse(box.group(1)!) / double.parse(box.group(2)!);
          expect(
            diagram.aspectRatio,
            closeTo(actual, 0.001),
            reason: '${figure.name} ${side.name}',
          );
        }
      }
    });
  });
}
