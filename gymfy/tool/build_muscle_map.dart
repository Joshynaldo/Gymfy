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

/// The female front view.
///
/// Not a reshaped copy of the male one — the pack draws a different set of
/// groups, so this needs its own table rather than the same source with a
/// different filename.
///
/// Two app muscles have nowhere to go here, and are deliberately left dark
/// rather than faked onto a neighbouring region:
///   * `neck` — the female front has no `sternocleidomastoid`.
///   * there is no `finger_flexors`, but `brachioradialis` already carries
///     `forearms`, so forearm volume still lights up.
///
/// `iliopsoas_hip_flexors` stands in for `adductors`. It isn't the same muscle,
/// but it occupies the same upper inner-thigh region the male map covers with
/// `sartorius_abductors` — which is an equally loose fit already shipping.
const _frontMapFemale = <String, String>{
  'pectoralis_major': 'chest',
  'deltoid': 'front_deltoid side_deltoid',
  'biceps': 'biceps',
  'brachioradialis': 'forearms',
  'abdominals': 'abs',
  'external_oblique': 'obliques',
  'quadriceps': 'quads',
  'iliopsoas_hip_flexors': 'adductors',
  'trapezius': 'trapezius',
  'triceps': 'triceps',
  'gastrocnemius': 'calves',
  'peroneus_longus': 'calves',
  'tibialis_anterior': 'calves',
  'tensor_fasciae_latae': 'glutes',
};

/// The female back view. Same regions as the male one under different pack
/// ids — `trapezius` not `trapezius_lower`, `hamstrings2` not `hamstrings`,
/// `gluteus_medius` not `gluteus_medius2`.
const _backMapFemale = <String, String>{
  'deltoid': 'rear_deltoid side_deltoid',
  'infraspinatus_teres_major': 'rear_deltoid',
  'trapezius': 'trapezius',
  'latissimus_dorsi': 'lats',
  'external_oblique': 'obliques',
  'gluteus_maximus': 'glutes',
  'gluteus_medius': 'glutes',
  'abductors': 'glutes',
  'tensor_fasciae_latae': 'glutes',
  'hamstrings2': 'hamstrings',
  'gastrocnemius': 'calves',
  'soleus': 'calves',
  'triceps': 'triceps',
  'brachioradialis': 'forearms',
  'finger_flexors': 'forearms',
  'finger_extensors': 'forearms',
};

/// Pack groups that are anatomy but not trained muscles the app tracks.
///
/// Flattened to the base silhouette fill and left untagged. Without this they
/// would keep the pack's own coloured gradient and glow permanently on the map
/// as if you had just trained them.
const _notMuscles = {'breasts', 'subclavius'};

void main() {
  final root = Directory.current.path;
  const pack = 'assets/musclemap/source/with_tooltip_and_colours';

  _build(
    source: '$root/$pack/man-front.svg',
    dest: '$root/assets/svg/body_front.svg',
    map: _frontMap,
    drawLowerBack: false,
  );
  _build(
    source: '$root/$pack/man-back.svg',
    dest: '$root/assets/svg/body_back.svg',
    map: _backMap,
    drawLowerBack: true,
  );
  _build(
    source: '$root/$pack/woman-front.svg',
    dest: '$root/assets/svg/body_front_female.svg',
    map: _frontMapFemale,
    drawLowerBack: false,
  );
  _build(
    source: '$root/$pack/woman-back.svg',
    dest: '$root/assets/svg/body_back_female.svg',
    map: _backMapFemale,
    drawLowerBack: true,
  );
  stdout.writeln('Done. Wrote 4 body diagrams.');
}

void _build({
  required String source,
  required String dest,
  required Map<String, String> map,
  required bool drawLowerBack,
}) {
  final src = File(source);
  if (!src.existsSync()) {
    stderr.writeln('Missing source SVG: $source');
    exitCode = 1;
    return;
  }
  var svg = src.readAsStringSync();

  // 0. Measure the lumbar gap before anything is rewritten, while the pack's
  //    own group ids are still intact.
  final extraGroups = drawLowerBack ? _lowerBackGroup(svg) : '';

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
      // Anatomy the app doesn't track. Flattened to the silhouette so it can't
      // sit there wearing the pack's own bright gradient, which would read as
      // a permanently-trained muscle.
      if (_notMuscles.contains(packId)) {
        return '<g id="$packId">${_flatten(m.group(2)!, _baseFill)}</g>';
      }
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
  //
  // Matched by pattern rather than by the one id the male sheets happen to
  // use: the female sheets call their outline gradient
  // `SVGID_body_outline_front`, so a literal `url(#SVGID_1_)` swap left them
  // pointing at the pack's teal gradient.
  svg = svg
      .replaceAll('#FFFFFF', _baseFill)
      .replaceAll('#ffffff', _baseFill)
      .replaceAll(RegExp(r'url\(#SVGID[^)]*\)'), _baseStroke);

  // Nothing refers to the pack's gradients any more, so the definitions are
  // dead weight shipped in the APK — 70 of them on the female front sheet,
  // nearly half its size.
  svg = svg.replaceAll(
    RegExp(r'<linearGradient[^>]*>.*?</linearGradient>', dotAll: true),
    '',
  );
  final dangling = RegExp(r'url\(#[^)]*\)').firstMatch(svg);
  if (dangling != null) {
    stderr.writeln('  Warning: unresolved paint ${dangling.group(0)}');
  }

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

/// Strips a group's paths of pack styling and gives them one flat [fill].
String _flatten(String groupBody, String fill) {
  return groupBody.replaceAllMapped(RegExp(r'<path([^>]*)>'), (p) {
    final attrs = p
        .group(1)!
        .replaceAll(RegExp(r'\s*class="[^"]*"'), '')
        .replaceAll(RegExp(r'\s*data-tooltip-text="[^"]*"'), '')
        .replaceAll(RegExp(r'\s*fill="[^"]*"'), '');
    return '<path fill="$fill"$attrs>';
  });
}

/// A pair of erector-spinae strips flanking the lower spine.
///
/// The pack has no lumbar region at all, but the app tracks `lower_back`
/// (deadlifts, rows, RDLs), so without this that volume would have nowhere to
/// show. Drawn rather than sourced, which means its position has to come from
/// somewhere.
///
/// Measured off the body it is being drawn onto instead of hardcoded: the male
/// and female sheets have different viewBoxes (248×558 vs 154×539) and the
/// figures sit at different scales within them, so one set of coordinates
/// cannot serve both — the male numbers land off the body entirely on the
/// female sheet. The lumbar sits below the obliques and above the glutes,
/// centred on the torso, which the pack does draw and can therefore be read.
String _lowerBackGroup(String svg) {
  final obliques = _groupBox(svg, 'external_oblique');
  final glutes = _groupBox(svg, 'gluteus_maximus');
  final lats = _groupBox(svg, 'latissimus_dorsi');
  if (obliques == null || glutes == null || lats == null) {
    stderr.writeln('  Cannot place lower_back: a landmark group is missing.');
    return '';
  }

  final centre = (lats.x0 + lats.x1) / 2;
  final top = obliques.y0;
  final height = glutes.y0 - top;
  // Proportions carried over from the hand-tuned male version, expressed
  // against torso width so they hold at either scale.
  final width = (lats.x1 - lats.x0) * 0.107;
  final gap = width * 0.4;
  final r = width / 2;

  String strip(double x) =>
      'M${_n(x)},${_n(top)} a${_n(r)},${_n(r)} 0 0 1 ${_n(width)},0 '
      'v${_n(height)} a${_n(r)},${_n(r)} 0 0 1 -${_n(width)},0 z';

  final left = centre - gap / 2 - width;
  final right = centre + gap / 2;
  return '<g id="lower_back"><path data-muscle="lower_back" '
      'fill="$_muscleRest" d="${strip(left)} ${strip(right)}"/></g>';
}

String _n(double v) => v.toStringAsFixed(1);

/// The bounding box of one pack muscle group, in user units.
({double x0, double y0, double x1, double y1})? _groupBox(
  String svg,
  String id,
) {
  final g = RegExp(
    '<g id="$id" class="muscle">(.*?)</g>',
    dotAll: true,
  ).firstMatch(svg);
  if (g == null) return null;

  var x0 = double.infinity, y0 = double.infinity;
  var x1 = double.negativeInfinity, y1 = double.negativeInfinity;
  var any = false;
  for (final d in RegExp(r'\sd="([^"]*)"').allMatches(g.group(1)!)) {
    for (final p in _pathPoints(d.group(1)!)) {
      any = true;
      if (p.x < x0) x0 = p.x;
      if (p.y < y0) y0 = p.y;
      if (p.x > x1) x1 = p.x;
      if (p.y > y1) y1 = p.y;
    }
  }
  return any ? (x0: x0, y0: y0, x1: x1, y1: y1) : null;
}

/// Every on-curve point an SVG path visits.
///
/// Enough for a bounding box, and only that: control points are skipped, so a
/// curve that bulges past its endpoints is under-measured by a hair. That
/// doesn't matter for locating a region, and it avoids carrying a full path
/// parser in a build script. Relative commands are the reason this exists at
/// all — the pack's path data is almost entirely relative, so reading the raw
/// numbers gives nonsense.
List<({double x, double y})> _pathPoints(String d) {
  final out = <({double x, double y})>[];
  var cmd = 'M';
  final nums = <double>[];
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;

  void flush() {
    if (nums.isEmpty) return;
    final rel = cmd.toLowerCase() == cmd;
    var i = 0;
    // How many numbers each command consumes, and which pair of those is the
    // point it ends on.
    switch (cmd.toUpperCase()) {
      case 'M':
      case 'L':
      case 'T':
        while (i + 1 < nums.length) {
          x = rel ? x + nums[i] : nums[i];
          y = rel ? y + nums[i + 1] : nums[i + 1];
          if (cmd.toUpperCase() == 'M' && i == 0) {
            startX = x;
            startY = y;
          }
          out.add((x: x, y: y));
          i += 2;
        }
      case 'H':
        while (i < nums.length) {
          x = rel ? x + nums[i] : nums[i];
          out.add((x: x, y: y));
          i++;
        }
      case 'V':
        while (i < nums.length) {
          y = rel ? y + nums[i] : nums[i];
          out.add((x: x, y: y));
          i++;
        }
      case 'C':
        while (i + 5 < nums.length) {
          x = rel ? x + nums[i + 4] : nums[i + 4];
          y = rel ? y + nums[i + 5] : nums[i + 5];
          out.add((x: x, y: y));
          i += 6;
        }
      case 'S':
      case 'Q':
        while (i + 3 < nums.length) {
          x = rel ? x + nums[i + 2] : nums[i + 2];
          y = rel ? y + nums[i + 3] : nums[i + 3];
          out.add((x: x, y: y));
          i += 4;
        }
      case 'A':
        while (i + 6 < nums.length) {
          x = rel ? x + nums[i + 5] : nums[i + 5];
          y = rel ? y + nums[i + 6] : nums[i + 6];
          out.add((x: x, y: y));
          i += 7;
        }
    }
    nums.clear();
  }

  for (final t in RegExp(
    r'([MmLlHhVvCcSsQqTtAaZz])|(-?\d*\.?\d+(?:[eE]-?\d+)?)',
  ).allMatches(d)) {
    final letter = t.group(1);
    if (letter != null) {
      flush();
      cmd = letter;
      if (cmd.toUpperCase() == 'Z') {
        x = startX;
        y = startY;
      }
    } else {
      nums.add(double.parse(t.group(2)!));
    }
  }
  flush();
  return out;
}
