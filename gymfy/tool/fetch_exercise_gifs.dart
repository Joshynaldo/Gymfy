// Downloads one exercise animation per seeded exercise from
// JahelCuadrado/ExerciseGymGifsDB into assets/exercises/.
//
//   dart run tool/fetch_exercise_gifs.dart          # animated WebP (small)
//   dart run tool/fetch_exercise_gifs.dart --gif    # GIF (large, sharper)
//
// It is a dev tool, not part of the app; nothing imports it. Re-runnable —
// files already present are skipped unless --force is passed.
//
// ---------------------------------------------------------------------------
// PROVENANCE — read before changing the source
//
// The upstream repository has no LICENSE file, and its README states plainly
// that the author does not hold copyright in these images:
//
//     "No poseo los derechos de autor sobre esas imágenes"
//     "Los GIFs pertenecen a sus respectivos autores"
//
// The author gave the developer written permission by email, and that is the
// basis on which these ship. Note what that permission can and cannot do: it
// covers what the author is able to grant, which by his own account is the
// organisation layer rather than the images. Comparable datasets trace their
// media to Gym Visual (gymvisual.com), who sell a licence expressly covering
// Android and iOS apps.
//
// So the standing risk is a takedown from the actual rights holder, not from
// the author. If that ever arrives, the fix is bounded and already sketched:
// buy the Gym Visual pack, drop the files in under the same names, delete this
// tool. Nothing else in the app knows where these came from.
// ---------------------------------------------------------------------------

import 'dart:io';

/// Raw file host for the upstream repository.
const _base =
    'https://raw.githubusercontent.com/JahelCuadrado/ExerciseGymGifsDB/main';

/// Where the app expects them, named by exercise id.
const _dest = 'assets/exercises';

/// Our exercise id -> the upstream path, without extension.
///
/// Written out by hand rather than matched by name at runtime. The two naming
/// schemes genuinely disagree — our `barbell_row` is their
/// `barbell-bent-over-row`, our `pec_deck` is their `lever-seated-fly` — and a
/// fuzzy matcher that is right eighty times out of a hundred silently puts the
/// wrong animation on twenty exercises. A wrong demonstration is worse than
/// the "Preview coming soon" placeholder, because it looks correct.
///
/// Entries marked SUBSTITUTE are the nearest movement the dataset has, not the
/// same exercise. They are listed so the compromise is reviewable rather than
/// buried:
///
///   * `barbell_hip_thrust` -> barbell glute bridge. The dataset has no
///     barbell hip thrust at all; the glute bridge is the floor version of the
///     same movement, shoulders down instead of on a bench.
///   * `bulgarian_split_squat` -> single-leg split squat. Same movement
///     without the rear foot elevated.
///   * `face_pull` -> cable rear-delt row with rope. Same rope, same target,
///     pulled to the chest rather than the face.
///   * `plank` -> weighted front plank, the only plain front plank on offer.
const _sources = <String, String>{
  'barbell_bench_press': 'pectorals/barbell-bench-press',
  'dumbbell_bench_press': 'pectorals/dumbbell-bench-press',
  'incline_barbell_press': 'pectorals/barbell-incline-bench-press',
  'incline_dumbbell_press': 'pectorals/dumbbell-incline-bench-press',
  'decline_barbell_press': 'pectorals/barbell-decline-bench-press',
  'push_up': 'pectorals/push-up',
  'chest_dip': 'pectorals/chest-dip',
  'cable_fly': 'pectorals/cable-middle-fly',
  'dumbbell_fly': 'pectorals/dumbbell-fly',
  'pec_deck': 'pectorals/lever-seated-fly',
  'pull_up': 'lats/pull-up',
  'chin_up': 'lats/chin-up',
  'lat_pulldown': 'lats/cable-lat-pulldown-full-range-of-motion',
  'straight_arm_pulldown': 'lats/cable-straight-arm-pulldown',
  'barbell_row': 'upper-back/barbell-bent-over-row',
  'dumbbell_row': 'upper-back/dumbbell-bent-over-row',
  't_bar_row': 'upper-back/lever-t-bar-row',
  'seated_cable_row': 'upper-back/cable-seated-row',
  'inverted_row': 'upper-back/inverted-row',
  'lat_pullover': 'pectorals/dumbbell-pullover',
  'barbell_shrug': 'traps/barbell-shrug',
  'deadlift': 'glutes/barbell-deadlift',
  'good_morning': 'hamstrings/barbell-good-morning',
  'back_extension': 'spine/lever-back-extension',
  'overhead_barbell_press': 'delts/barbell-seated-overhead-press',
  'dumbbell_shoulder_press': 'delts/dumbbell-seated-shoulder-press',
  'machine_shoulder_press': 'delts/lever-shoulder-press',
  'arnold_press': 'delts/dumbbell-arnold-press',
  'dumbbell_lateral_raise': 'delts/dumbbell-lateral-raise',
  'cable_lateral_raise': 'delts/cable-lateral-raise',
  'front_raise': 'delts/dumbbell-front-raise',
  'rear_delt_fly': 'delts/dumbbell-reverse-fly',
  'face_pull': 'delts/cable-rear-delt-row-with-rope',
  'upright_row': 'delts/barbell-upright-row',
  'barbell_biceps_curl': 'biceps/barbell-curl',
  'dumbbell_hammer_curl': 'biceps/dumbbell-hammer-curl',
  'incline_dumbbell_curl': 'biceps/dumbbell-incline-curl',
  'preacher_curl': 'biceps/barbell-preacher-curl',
  'cable_curl': 'biceps/cable-curl',
  'concentration_curl': 'biceps/dumbbell-concentration-curl',
  'reverse_curl': 'biceps/barbell-reverse-curl',
  'wrist_curl': 'forearms/barbell-wrist-curl',
  'triceps_pushdown': 'triceps/cable-pushdown',
  'overhead_triceps_extension': 'triceps/barbell-standing-overhead-triceps-extension',
  'skull_crusher': 'triceps/barbell-lying-triceps-extension-skull-crusher',
  'close_grip_bench_press': 'triceps/barbell-close-grip-bench-press',
  'bench_dip': 'triceps/bench-dip-on-floor',
  'barbell_back_squat': 'glutes/barbell-full-squat',
  'front_squat': 'glutes/barbell-front-squat',
  'goblet_squat': 'quads/dumbbell-goblet-squat',
  'hack_squat': 'glutes/sled-hack-squat',
  'leg_press': 'glutes/sled-45-leg-press',
  'sumo_deadlift': 'glutes/barbell-sumo-deadlift',
  'romanian_deadlift': 'glutes/barbell-romanian-deadlift',
  'walking_lunge': 'glutes/walking-lunge',
  'bulgarian_split_squat': 'quads/dumbbell-single-leg-split-squat',
  'step_up': 'glutes/dumbbell-step-up',
  'leg_extension': 'quads/lever-leg-extension',
  'lying_leg_curl': 'hamstrings/lever-lying-leg-curl',
  'seated_leg_curl': 'hamstrings/lever-seated-leg-curl',
  'barbell_hip_thrust': 'glutes/barbell-glute-bridge',
  'glute_bridge': 'glutes/glute-bridge-march',
  'hip_adduction': 'adductors/lever-seated-hip-adduction',
  'standing_calf_raise': 'calves/lever-standing-calf-raise',
  'seated_calf_raise': 'calves/lever-seated-calf-raise',
  'plank': 'abs/weighted-front-plank',
  'side_plank': 'abs/bodyweight-incline-side-plank',
  'crunch': 'abs/decline-crunch',
  'cable_crunch': 'abs/cable-kneeling-crunch',
  'hanging_leg_raise': 'abs/hanging-leg-raise',
  'ab_wheel_rollout': 'abs/wheel-rollerout',
  'russian_twist': 'abs/russian-twist',
  'bicycle_crunch': 'abs/band-bicycle-crunch',
  'mountain_climber': 'cardio/mountain-climber',
  'power_clean': 'hamstrings/power-clean',
  'push_press': 'delts/dumbbell-push-press',
  'kettlebell_swing': 'glutes/kettlebell-swing',
  'farmers_walk': 'quads/farmers-walk',
};

Future<void> main(List<String> args) async {
  // WebP by default. Upstream ships a 360px GIF and a 128px animated WebP of
  // the same loop; across these 78 that is 22.5MB against 1.4MB. All of it
  // lands in the download, because a local-first app has no server to stream
  // from.
  final wantGif = args.contains('--gif');
  final force = args.contains('--force');
  final extension = wantGif ? 'gif' : 'webp';
  final suffix = wantGif ? '.gif' : '.thumb.webp';

  final dir = Directory(_dest);
  if (!dir.existsSync()) {
    stderr.writeln('No $_dest directory — run this from the package root.');
    exitCode = 1;
    return;
  }

  final client = HttpClient();
  var written = 0, skipped = 0, failed = 0, bytes = 0;

  for (final entry in _sources.entries) {
    final target = File('$_dest/${entry.key}.$extension');
    if (target.existsSync() && !force) {
      skipped++;
      continue;
    }

    final url = '$_base/${entry.value}$suffix';
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('  ${response.statusCode}  ${entry.key}  <- $url');
        failed++;
        continue;
      }
      final data = await response.fold<List<int>>(
        <int>[],
        (all, chunk) => all..addAll(chunk),
      );
      // Written only once the whole body has arrived: a half-downloaded file
      // left on disk would be skipped as "already present" on the next run and
      // render as a broken image forever.
      target.writeAsBytesSync(data);
      bytes += data.length;
      written++;
      stdout.write('\r  ${written + skipped} / ${_sources.length}   ');
    } catch (error) {
      stderr.writeln('  failed  ${entry.key}: $error');
      failed++;
    }
  }
  client.close();

  stdout.writeln(
    '\n$written downloaded (${(bytes / 1048576).toStringAsFixed(1)}MB), '
    '$skipped already present, $failed failed.',
  );
  if (failed > 0) {
    stdout.writeln('Re-run to retry the failures; existing files are skipped.');
    exitCode = 1;
  }
  stdout.writeln('Now run: dart run tool/check_exercise_gifs.dart');
}
