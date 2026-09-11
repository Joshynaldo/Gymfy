import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/theme/accent_color.dart';
import '../../../shared/data/lifter_sex.dart';
import '../data/muscle_colors.dart';
import '../../../app/theme/glass.dart';

export '../data/muscle_colors.dart' show MuscleMapMode;

part 'muscle_map.g.dart';

/// Which way round the body is drawn.
enum BodySide { front, back }

/// Which figure the diagram uses.
///
/// Two separate sheets from the licensed pack, not one silhouette reshaped:
/// the pack draws a genuinely different set of muscle groups per figure, and
/// each sheet has its own viewBox.
enum BodyFigure { male, female }

/// One bundled diagram: the asset, and the shape it has to be drawn at.
///
/// The aspect ratio travels with the asset because it is *not* shared. The male
/// sheets are 248×558 for both sides; the female ones are 172×546 and 154×539.
/// A single hardcoded ratio — which is what this used to be — squashes the
/// female figures noticeably.
typedef BodyDiagram = ({String asset, double aspectRatio});

const _diagrams = <BodyFigure, Map<BodySide, BodyDiagram>>{
  BodyFigure.male: {
    BodySide.front: (
      asset: 'assets/svg/body_front.svg',
      aspectRatio: 248.333 / 557.994,
    ),
    BodySide.back: (
      asset: 'assets/svg/body_back.svg',
      aspectRatio: 248.333 / 557.994,
    ),
  },
  BodyFigure.female: {
    BodySide.front: (
      asset: 'assets/svg/body_front_female.svg',
      aspectRatio: 171.852 / 546.3,
    ),
    BodySide.back: (
      asset: 'assets/svg/body_back_female.svg',
      aspectRatio: 154.342 / 539.348,
    ),
  },
};

/// The diagram for one figure and side.
BodyDiagram bodyDiagram(BodyFigure figure, BodySide side) =>
    _diagrams[figure]![side]!;

/// Which figure to draw for this user.
///
/// Falls back to [BodyFigure.male] when the setting is unset — which is what
/// every install created before onboarding asked the question looks like.
/// A fallback is unavoidable here: unlike a strength rank, a body map cannot
/// show "not enough information", it has to draw something. Settings has the
/// control to change it.
final bodyFigureProvider = Provider<BodyFigure>((ref) {
  return switch (ref.watch(lifterSexProvider).value) {
    LifterSex.female => BodyFigure.female,
    LifterSex.male || null => BodyFigure.male,
  };
});

/// The neutral colour every muscle uses at intensity 0 — must match the
/// placeholder `fill` authored into the SVG files.
const _restColor = Color(0xFF4C5361);

/// The silhouette the muscles are laid on, as authored. Never tinted: it is
/// the body, not a muscle group, and it has no volume to report.
const _bodyColor = Color(0xFF2E3440);

/// The silhouette on the glass theme: dark, and violet rather than slate.
///
/// Darker than the flat themes' version, not lighter — which is the opposite of
/// where this started. The figure does not read as glass because it is dimmed;
/// it reads as glass because it is made of the same colour as everything else
/// on the screen. Against a body carrying the field's own hue, a dark head and
/// dark hands are the shadow that gives the muscles somewhere to stand.
const _bodyColorGlass = Color(0xFF3A3360);

/// What an untrained muscle is painted in [MuscleMapMode.contrast] on glass.
///
/// Contrast mode gives every worked muscle its own hue, so the unworked ones
/// have to stay out of the argument — a violet rest would be one more colour
/// competing with the ones carrying meaning. Dark and barely tinted.
const _restColorGlass = Color(0xFF575080);

/// What an untrained muscle is painted in [MuscleMapMode.heatmap] on glass.
///
/// Partway to the colour the map is tinting toward, rather than a neutral grey.
/// This is the change that finally made the figure look like part of the pane:
/// a grey body on a violet screen is a grey body no matter what its alpha is,
/// because neutral is the one hue the field never supplies. Tinted, it reads as
/// light coming through the glass rather than as a shape laid on top of it.
///
/// Derived from the colour being tinted toward, so it follows the accent — and
/// follows the fatigue reading's red, which would look muddy lerping out of a
/// violet.
///
/// Two fifths of the way, not half. Tinting the resting body costs the heatmap
/// range — it starts the scale part-lit — and this is the dial that sets how
/// much. Far enough that the body still reads as glass the field shines
/// through; short enough that a worked muscle is obviously a worked muscle,
/// which is the one thing the picture is for.
Color _restColorGlassFor(Color heat) =>
    Color.lerp(_bodyColorGlass, _heatColorGlassFor(heat), 0.4)!;

/// The colour a fully-worked muscle is tinted to on the glass theme.
///
/// The accent with some white in it. Lifting the *lit* end is what lets the
/// whole figure get lighter without the diagram losing its point: raising only
/// the unworked end would close the gap between a trained muscle and an
/// untrained one, which is the one distinction the picture exists to draw. Both
/// ends move, so the body brightens and the range stays open.
Color _heatColorGlassFor(Color heat) => Color.lerp(heat, Colors.white, 0.18)!;

/// How solid the figure is on the glass theme.
///
/// Enough off that the card's own gradient is legible through the body — on a
/// screen where every other surface admits light, a fully opaque figure is the
/// one thing that doesn't. Not much more than that, though: the tint is what
/// does the work here, and past about a quarter off the difference between a
/// worked muscle and an unworked one starts going with it.
const _glassOpacity = 0.70;

/// Matches a muscle path's tag so we can rewrite just its fill, e.g.
/// `data-muscle="chest" fill="#4C5361"`. A single path may carry more than one
/// space-separated id (e.g. `front_deltoid side_deltoid`) when one anatomical
/// region on the diagram stands in for several app muscles.
final _muscleFill = RegExp(r'data-muscle="([a-z_ ]+)" fill="#[0-9A-Fa-f]{6}"');

/// Loads (and caches) the raw SVG text for a body side. Kept in a provider so
/// the file is read once, not on every rebuild / accent change.
@riverpod
Future<String> bodySvgTemplate(Ref ref, BodyFigure figure, BodySide side) {
  return rootBundle.loadString(bodyDiagram(figure, side).asset);
}

/// A body diagram whose muscles are tinted by how hard they've been worked.
///
/// [intensities] maps a `MuscleId` to a 0.0–1.0 value. Each muscle is blended
/// from the neutral rest colour (0) toward a target colour (1) — [heatColor] in
/// [MuscleMapMode.heatmap], the muscle's own colour in
/// [MuscleMapMode.contrast]. Muscles absent from the map (or set to 0) stay
/// neutral in both, so "what have I not trained" reads the same either way.
class MuscleMap extends ConsumerWidget {
  const MuscleMap({
    super.key,
    required this.side,
    required this.intensities,
    this.mode = MuscleMapMode.heatmap,
    this.figure,
    this.heatColor,
  });

  final BodySide side;
  final Map<String, double> intensities;
  final MuscleMapMode mode;

  /// The colour muscles are tinted toward in [MuscleMapMode.heatmap].
  ///
  /// Defaults to the accent. The fatigue reading overrides it with a fixed red:
  /// volume and fatigue share this diagram, so colour is what tells them apart
  /// at a glance. Ignored in contrast mode, where each muscle brings its own.
  final Color? heatColor;

  /// Which figure to draw. Defaults to whatever the user told us during
  /// onboarding — see [bodyFigureProvider].
  final BodyFigure? figure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BodyFigure drawn = figure ?? ref.watch(bodyFigureProvider);
    final diagram = bodyDiagram(drawn, side);
    final templateAsync = ref.watch(bodySvgTemplateProvider(drawn, side));
    final accent = ref.watch(accentColorProvider);

    return AspectRatio(
      aspectRatio: diagram.aspectRatio,
      child: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load the body map.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
        data: (template) {
          final glass = glassOf(context).enabled;
          final heat = heatColor ?? accent;
          final svg = tintMuscles(
            svg: template,
            intensities: intensities,
            heatColor: glass ? _heatColorGlassFor(heat) : heat,
            mode: mode,
            restColor: switch ((glass, mode)) {
              (false, _) => _restColor,
              (true, MuscleMapMode.heatmap) => _restColorGlassFor(heat),
              (true, MuscleMapMode.contrast) => _restColorGlass,
            },
            bodyColor: glass ? _bodyColorGlass : _bodyColor,
          );
          final picture = SvgPicture.string(svg, fit: BoxFit.contain);
          // The flat themes get the figure as drawn: it sits on an opaque card
          // there, so there is nothing behind it for it to be translucent *to*,
          // and dimming it would only make it harder to read.
          if (!glass) return picture;
          return Opacity(opacity: _glassOpacity, child: picture);
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

  /// What a fully-worked muscle is tinted to in [MuscleMapMode.heatmap].
  ///
  /// Named for what it does rather than where it usually comes from: it was
  /// `accent`, which stopped being true once the fatigue reading started
  /// passing a fixed red.
  required Color heatColor,
  MuscleMapMode mode = MuscleMapMode.heatmap,

  /// What a muscle at intensity 0 is painted, and the colour every tint starts
  /// from. Defaults to the value authored into the files.
  Color restColor = _restColor,

  /// What the silhouette under the muscles is painted.
  Color bodyColor = _bodyColor,
}) {
  // The silhouette first, by its literal authored fill: the muscle pass below
  // can produce any colour at all, and rewriting the body afterwards could
  // catch a muscle that happened to land on the same hex.
  final ground = svg.replaceAll(
    'fill="${_toHex(_bodyColor)}"',
    'fill="${_toHex(bodyColor)}"',
  );

  return ground.replaceAllMapped(_muscleFill, (match) {
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
      MuscleMapMode.heatmap => heatColor,
      MuscleMapMode.contrast => muscleColor(strongest),
    };
    final color = Color.lerp(restColor, target, t)!;
    return 'data-muscle="${match.group(1)}" fill="${_toHex(color)}"';
  });
}

/// Formats a colour as an SVG `#RRGGBB` string (alpha dropped).
String _toHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
