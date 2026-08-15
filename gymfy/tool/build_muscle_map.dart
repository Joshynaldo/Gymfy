// Preprocesses the licensed anatomical muscle-map SVG pack (dropped into
// assets/musclemap/) into the two lean body diagrams the app actually ships:
// assets/svg/body_front.svg and assets/svg/body_back.svg.
//
// Why a build step instead of using the pack directly?
//   * The pack colours each muscle with a per-muscle <linearGradient> and drives
//     hover state through a <style> block. The app instead needs to recolour
//     each muscle at runtime by intensity, so every muscle path must carry a
//     `data-muscle="<MuscleId>"` tag and a flat placeholder fill — exactly the
//     convention MuscleMap._tintMuscles already understands.
//   * The pack's anatomical group ids (pectoralis_major, latissimus_dorsi, ...)
//     don't match the app's canonical MuscleId strings. This tool is the single
//     place that mapping lives, documented and re-runnable.
//
// Run it from the package root after (re)placing the pack:
//   dart run tool/build_muscle_map.dart
//
// It is a dev tool, not part of the app; nothing imports it.

import 'dart:io';

/// Placeholder fill every muscle rests at (intensity 0). MUST match
/// `_restColor` in features/muscle_map/widgets/muscle_map.dart.
const _muscleRest = '#4C5361';

/// The body silhouette behind the muscles (dark, reads on the app's surfaces).
const _baseFill = '#2E3440';

/// A flat replacement for the pack's teal gradient outline.
const _baseStroke = '#232833';

/// Maps each pack muscle-group id to one or more canonical app MuscleId
/// strings. Space-separated when a single anatomical region stands in for more
/// than one app muscle (e.g. the pack draws one deltoid cap; the app tracks
/// front/side/rear separately). Runtime tinting takes the max intensity across
/// the listed ids.
const _frontMap = <String, String>{
  'pectoralis_major': 'chest',
  'deltoid': 'front_deltoid side_deltoid',
  'biceps': 'biceps',
  'brachioradialis': 'forearms',
  'finger_flexors': 'forearms',
  'abdominals': 'abs',
  'external_oblique': 'obliques',
  'quadriceps': 'quads',
  'sartorius_abductors': 'adductors',
  'sternocleidomastoid': 'neck',
  'trapezius': 'trapezius',
  'triceps': 'triceps',
  'gastrocnemius': 'calves',
  'peroneus_longus': 'calves',
  'tibialis_anterior': 'calves',
  'tensor_fasciae_latae': 'glutes',
};

const _backMap = <String, String>{
  'deltoid': 'rear_deltoid side_deltoid',
  'infraspinatus_teres_major': 'rear_deltoid',
  'trapezius_lower': 'trapezius',
  'latissimus_dorsi': 'lats',
  'external_oblique': 'obliques',
  'gluteus_maximus': 'glutes',
  'gluteus_medius2': 'glutes',
  'abductors': 'glutes',
  'tensor_fasciae_latae': 'glutes',
  'hamstrings': 'hamstrings',
  'gastrocnemius': 'calves',
  'soleus': 'calves',
  'triceps': 'triceps',
  'brachioradialis': 'forearms',
  'finger_flexors': 'forearms',
  'finger_extensors': 'forearms',
};

/// The pack has no lumbar / erector-spinae region, but the app tracks
/// `lower_back` (deadlifts, rows, RDLs). Draw a pair of erector strips flanking
/// the lower spine, between the lats and the glutes, so that volume lights up.
const _lowerBackGroup =
    '<g id="lower_back"><path data-muscle="lower_back" fill="$_muscleRest" '
    'd="M112,207 a5,5 0 0 1 10,0 v34 a5,5 0 0 1 -10,0 z '
    'M126,207 a5,5 0 0 1 10,0 v34 a5,5 0 0 1 -10,0 z"/></g>';

void main() {
  final root = Directory.current.path;
  _build(
    source: '$root/assets/musclemap/source/with_tooltip_and_colours/man-front.svg',
    dest: '$root/assets/svg/body_front.svg',
    map: _frontMap,
    extraGroups: '',
  );
  _build(
    source: '$root/assets/musclemap/source/with_tooltip_and_colours/man-back.svg',
    dest: '$root/assets/svg/body_back.svg',
    map: _backMap,
    extraGroups: _lowerBackGroup,
  );
  stdout.writeln('Done. Wrote body_front.svg and body_back.svg.');
}

void _build({
  required String source,
  required String dest,
  required Map<String, String> map,
  required String extraGroups,
}) {
  final src = File(source);
  if (!src.existsSync()) {
    stderr.writeln('Missing source SVG: $source');
    exitCode = 1;
    return;
  }
  var svg = src.readAsStringSync();

  // 1. Drop the interactive scaffolding the app doesn't use and flutter_svg
  //    can't style: the CSS <style> block and the hidden tooltip group.
  svg = svg.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
  svg = svg.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
  svg = svg.replaceAll(
    RegExp(r'<g id="tooltip"[^>]*>.*?</g>', dotAll: true),
    '',
  );

  // 2. Rewrite each muscle group: tag EVERY path in it with the app
  //    MuscleId(s) and flatten its gradient fill to the neutral rest colour.
  //    A group may hold several paths — the front draws both sides in one path,
  //    but the back draws left and right as separate paths, so we must tag them
  //    all or half the muscle stays untinted (and renders grey).
  final group = RegExp(r'<g id="([A-Za-z0-9_]+)" class="muscle">(.*?)</g>',
      dotAll: true);
  final unmapped = <String>{};
  svg = svg.replaceAllMapped(group, (m) {
    final packId = m.group(1)!;
    final ids = map[packId];
    if (ids == null) {
      unmapped.add(packId);
      return m.group(0)!; // Leave anything we don't recognise untouched.
    }
    // Rebuild each path so it opens with `data-muscle="ids" fill="#rest"`,
    // exactly the shape the runtime tinting regex looks for, regardless of the
    // source path's original attribute order.
    final cleaned = m.group(2)!.replaceAllMapped(RegExp(r'<path([^>]*)>'), (p) {
      final attrs = p
          .group(1)!
          .replaceAll(RegExp(r'\s*class="[^"]*"'), '')
          .replaceAll(RegExp(r'\s*data-tooltip-text="[^"]*"'), '')
          .replaceAll(RegExp(r'\s*fill="[^"]*"'), '');
      return '<path data-muscle="$ids" fill="$_muscleRest"$attrs>';
    });
    return '<g id="$packId">$cleaned</g>';
  });

  // 3. Neutralise the base silhouette: flat dark fill + flat stroke.
  svg = svg
      .replaceAll('#FFFFFF', _baseFill)
      .replaceAll('#ffffff', _baseFill)
      .replaceAll('url(#SVGID_1_)', _baseStroke);

  // 4. Inject any hand-drawn regions the pack lacks, just before </svg>.
  if (extraGroups.isNotEmpty) {
    svg = svg.replaceFirst('</svg>', '$extraGroups</svg>');
  }

  File(dest).writeAsStringSync(svg);
  final kb = (svg.length / 1024).toStringAsFixed(1);
  stdout.writeln('Wrote $dest (${kb}KB).');
  if (unmapped.isNotEmpty) {
    stdout.writeln('  Note: unmapped pack groups left as-is: $unmapped');
  }
}
