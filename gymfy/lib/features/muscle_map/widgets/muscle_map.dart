import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/theme/accent_color.dart';
import '../data/muscle_colors.dart';

export '../data/muscle_colors.dart' show MuscleMapMode;

part 'muscle_map.g.dart';

/// Which body diagram to show.
enum BodySide {
  front('assets/svg/body_front.svg'),
  back('assets/svg/body_back.svg');

  const BodySide(this.asset);

  /// The bundled SVG for this side.
  final String asset;
}

/// The neutral colour every muscle uses at intensity 0 — must match the
/// placeholder `fill` authored into the SVG files.
const _restColor = Color(0xFF4C5361);

/// Matches a muscle path's tag so we can rewrite just its fill, e.g.
/// `data-muscle="chest" fill="#4C5361"`. A single path may carry more than one
/// space-separated id (e.g. `front_deltoid side_deltoid`) when one anatomical
/// region on the diagram stands in for several app muscles.
final _muscleFill = RegExp(r'data-muscle="([a-z_ ]+)" fill="#[0-9A-Fa-f]{6}"');

/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.
@riverpod
Future<String> bodySvgTemplate(Ref ref, BodySide side) {
  return rootBundle.loadString(side.asset);
}

/// A body diagram whose muscles are tinted by how hard they've been worked.
///
/// [intensities] maps a `MuscleId` to a 0.0–1.0 value. Each muscle is blended
/// from the neutral rest colour (0) toward a target colour (1) — the accent in
/// [MuscleMapMode.heatmap], the muscle's own colour in
/// [MuscleMapMode.contrast]. Muscles absent from the map (or set to 0) stay
/// neutral in both, so "what have I not trained" reads the same either way.
class MuscleMap extends ConsumerWidget {
  const MuscleMap({
    super.key,
    required this.side,
    required this.intensities,
    this.mode = MuscleMapMode.heatmap,
  });

  final BodySide side;
  final Map<String, double> intensities;
  final MuscleMapMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(bodySvgTemplateProvider(side));
    final accent = ref.watch(accentColorProvider);

    return AspectRatio(
      aspectRatio: 248.333 / 557.994,
      child: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Could not load the body map.\n$error',
              textAlign: TextAlign.center),
        ),
        data: (template) {
          final svg = tintMuscles(
            svg: template,
            intensities: intensities,
            accent: accent,
            mode: mode,
          );
          return SvgPicture.string(svg, fit: BoxFit.contain);
        },
      ),
    );
  }
}

/// Rewrites each muscle group's fill in [svg] to reflect its intensity.
///
/// Public so it can be tested without rendering: the interesting behaviour is
/// which hex ends up in the string, not what the picture looks like.
String tintMuscles({
  required String svg,
  required Map<String, double> intensities,
  required Color accent,
  MuscleMapMode mode = MuscleMapMode.heatmap,
}) {
  return svg.replaceAllMapped(_muscleFill, (match) {
    final ids = match.group(1)!.split(' ');
    // A region tagged with several ids glows as hard as its most-worked muscle,
    // and — in contrast mode — takes that muscle's colour. Picking the loudest
    // one keeps the region's colour and its brightness telling the same story.
    var t = 0.0;
    var strongest = ids.first;
    for (final id in ids) {
      final v = (intensities[id] ?? 0).clamp(0.0, 1.0);
      if (v > t) {
        t = v;
        strongest = id;
      }
    }
    final target = switch (mode) {
      MuscleMapMode.heatmap => accent,
      MuscleMapMode.contrast => muscleColor(strongest),
    };
    final color = Color.lerp(_restColor, target, t)!;
    return 'data-muscle="${match.group(1)}" fill="${_toHex(color)}"';
  });
}

/// Formats a colour as an SVG `#RRGGBB` string (alpha dropped).
String _toHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
