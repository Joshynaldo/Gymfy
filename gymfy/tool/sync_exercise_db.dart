// Builds the exercise library from JahelCuadrado/ExerciseGymGifsDB and
// downloads one animated preview per exercise into assets/exercises/.
//
//   dart run tool/sync_exercise_db.dart              # catalogue + previews
//   dart run tool/sync_exercise_db.dart --no-media   # catalogue only
//   dart run tool/sync_exercise_db.dart --force      # re-download previews
//
// It is a dev tool, not part of the app; nothing imports it. Its output is
// `lib/features/exercises/data/exercise_catalog_data.dart`, which is checked
// in, so the app never needs the network.
//
// ---------------------------------------------------------------------------
// WHAT IT PRODUCES
//
// The 78 hand-written exercises in `exercise_seed_data.dart` stay as they are:
// their ids are what existing workout history points at, and their muscles,
// equipment and flags were set by hand. [_curated] maps each of them to its
// upstream entry, so that entry is not imported a second time and its preview
// is saved under the curated id.
//
// Everything else upstream becomes a generated entry, except stretches. The
// upstream data is mapped onto the app's model by rules, not by hand:
//
//   * muscles — the upstream primary muscle, then its secondary muscles, each
//     translated to a [MuscleId]. `delts` is split into front, side and rear
//     by the exercise name; `abs` becomes obliques for twists and side work.
//   * equipment — onto the app's six slugs; ez-bar is a barbell, lever, sled
//     and smith are machines, everything else is `other`.
//   * plate-loaded — straight barbell strength lifts only, the same rule the
//     curated list follows (a sled's starting weight is unknown).
//   * timed — cardio, and holds: planks, hangs, wall sits, carries.
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
// the author. If that ever arrives, the fix is bounded: buy the Gym Visual
// pack, drop the files in under the same names. Nothing else in the app knows
// where these came from.
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

/// jsDelivr mirror of the upstream repository.
const _base =
    'https://cdn.jsdelivr.net/gh/JahelCuadrado/ExerciseGymGifsDB@main';

const _dest = 'assets/exercises';
const _output = 'lib/features/exercises/data/exercise_catalog_data.dart';

/// Curated exercise id -> upstream id (`<muscle folder>/<slug>`).
///
/// Written out by hand rather than matched by name. The two naming schemes
/// genuinely disagree — our `barbell_row` is their `barbell-bent-over-row`,
/// our `pec_deck` is their `lever-seated-fly` — and a wrong demonstration is
/// worse than none, because it looks correct.
///
/// Entries in [_substitutes] are the nearest movement upstream has, not the
/// same exercise, so the upstream entry is still imported on its own.
const _curated = <String, String>{
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
  'overhead_triceps_extension':
      'triceps/barbell-standing-overhead-triceps-extension',
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

/// Curated ids whose upstream animation is a stand-in movement: hip thrust
/// shown as a glute bridge, split squat without the rear foot raised, face
/// pull as a rope rear-delt row, plank as a weighted plank, glute bridge as a
/// glute bridge march. The upstream exercise is real in its own right, so it
/// is imported as well.
const _substitutes = {
  'barbell_hip_thrust',
  'bulgarian_split_squat',
  'face_pull',
  'plank',
  'glute_bridge',
};

/// Upstream muscle -> app muscle ids, for every muscle except the ones that
/// need the exercise name to decide (`delts`, `abs`, `cardio`).
const _muscleMap = <String, List<String>>{
  'pectorals': ['chest'],
  'lats': ['lats'],
  'upper-back': ['lats', 'trapezius'],
  'traps': ['trapezius'],
  'spine': ['lower_back'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'forearms': ['forearms'],
  'quads': ['quads'],
  'hamstrings': ['hamstrings'],
  'glutes': ['glutes'],
  // Hip abduction is gluteus medius work; the map has no separate abductors.
  'abductors': ['glutes'],
  'adductors': ['adductors'],
  'calves': ['calves'],
  'levator-scapulae': ['neck'],
  // No serratus on the map. Its exercises are presses and scapular push-ups,
  // so they land on the chest.
  'serratus-anterior': ['chest'],
};

/// Muscle ids for one upstream muscle name, in the context of [name].
List<String> _muscles(String muscle, String name, {required bool primary}) {
  final lower = name.toLowerCase();
  switch (muscle) {
    case 'delts':
      if (RegExp(
        r'rear|reverse fly|face pull|reverse cable|posterior',
      ).hasMatch(lower)) {
        return ['rear_deltoid'];
      }
      if (RegExp(
        r'lateral|side raise|upright|\by raise|lu raise',
      ).hasMatch(lower)) {
        return ['side_deltoid'];
      }
      return ['front_deltoid'];
    case 'abs':
      if (RegExp(
        r'oblique|twist|side|woodchop|wood chop|windmill|rotation|'
        r'bicycle|heel touch|pallof',
      ).hasMatch(lower)) {
        return ['obliques', 'abs'];
      }
      return ['abs'];
    case 'cardio':
      return primary ? ['quads', 'calves'] : const [];
    default:
      return _muscleMap[muscle] ?? const [];
  }
}

/// Upstream equipment -> the app's [Equipment] slug.
String _equipment(String raw) => switch (raw) {
  'barbell' || 'ez-bar' => 'barbell',
  'dumbbell' => 'dumbbell',
  'cable' => 'cable',
  'bodyweight' => 'bodyweight',
  'machine' || 'lever' || 'sled' || 'smith' => 'machine',
  _ => 'other',
};

/// Holds, as opposed to movements that happen to share a word with one: a
/// plank is held, "push up to side plank" and "hang clean" are counted.
final _timedName = RegExp(
  r'(?<!to side )plank$|\bhold\b|isometric(?! wipers)|static|dead hang|\bhang$|wall sit|'
  r'farmer|carry|suitcase walk',
);

/// The same rule as `slugifyExerciseName` in the app, without its prefix.
String _slug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp("['’]"), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// Tidies an upstream display name: "Jump Squat v2" -> "Jump Squat
/// (Variant 2)", and a trailing " Male" is dropped — upstream tags a handful
/// of animations by the model's sex, which says nothing about the exercise.
String _cleanName(String raw) {
  var name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  name = name.replaceAll(RegExp(r' (Male|Female)$'), '');
  name = name.replaceAll('Sitted', 'Seated');
  name = name.replaceAllMapped(
    RegExp(r' [vV](\d+)$'),
    (m) => ' (Variant ${m[1]})',
  );
  return name;
}

class _Entry {
  _Entry({
    required this.id,
    required this.name,
    required this.equipment,
    required this.muscles,
    required this.upstream,
    required this.plateLoaded,
    required this.timed,
  });

  final String id;
  final String name;
  final String equipment;
  final List<String> muscles;
  final String upstream;
  final bool plateLoaded;
  final bool timed;
}

/// Names the curated list already uses, read from its source so the two
/// files cannot drift apart.
Set<String> _curatedNames() {
  final source = File(
    'lib/features/exercises/data/exercise_seed_data.dart',
  ).readAsStringSync();
  return RegExp(
    r"name: Value\('([^']+)'\)",
  ).allMatches(source).map((m) => m[1]!).toSet();
}

const _dartMuscle = {
  'chest': 'MuscleId.chest',
  'front_deltoid': 'MuscleId.frontDeltoid',
  'side_deltoid': 'MuscleId.sideDeltoid',
  'biceps': 'MuscleId.biceps',
  'forearms': 'MuscleId.forearms',
  'abs': 'MuscleId.abs',
  'obliques': 'MuscleId.obliques',
  'quads': 'MuscleId.quads',
  'adductors': 'MuscleId.adductors',
  'trapezius': 'MuscleId.trapezius',
  'rear_deltoid': 'MuscleId.rearDeltoid',
  'lats': 'MuscleId.lats',
  'lower_back': 'MuscleId.lowerBack',
  'triceps': 'MuscleId.triceps',
  'glutes': 'MuscleId.glutes',
  'hamstrings': 'MuscleId.hamstrings',
  'calves': 'MuscleId.calves',
  'neck': 'MuscleId.neck',
};

String _dartString(String s) =>
    "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

Future<void> main(List<String> args) async {
  final noMedia = args.contains('--no-media');
  final force = args.contains('--force');

  if (!Directory(_dest).existsSync()) {
    stderr.writeln('No $_dest directory — run this from the package root.');
    exitCode = 1;
    return;
  }

  final client = HttpClient();
  stdout.writeln('Fetching the catalogue…');
  final catalogue =
      jsonDecode(
            utf8.decode(await _get(client, '$_base/api/en/exercises.json')),
          )
          as Map<String, dynamic>;
  final upstream = (catalogue['exercises'] as List)
      .cast<Map<String, dynamic>>();

  final taken = <String>{..._curated.keys};
  final usedNames = _curatedNames();
  final claimed = {
    for (final e in _curated.entries)
      if (!_substitutes.contains(e.key)) e.value,
  };

  final entries = <_Entry>[];
  final seenEquipment = <String, String>{};
  var skippedStretches = 0, skippedDuplicates = 0;

  for (final row in upstream) {
    final upstreamId = row['id'] as String;
    if (row['category'] == 'stretching') {
      skippedStretches++;
      continue;
    }
    if (claimed.contains(upstreamId)) continue;

    var name = _cleanName(row['name'] as String);
    final equipment = _equipment(row['equipment'] as String);
    // Two upstream entries can clean to the same name. With the same
    // equipment it is the same exercise filmed on a second model, and is
    // dropped; otherwise the second one gets its equipment appended.
    if (usedNames.contains(name) || taken.contains(_slug(name))) {
      final raw = row['equipment'] as String;
      if (seenEquipment[name] == raw) {
        skippedDuplicates++;
        continue;
      }
      final label = raw[0].toUpperCase() + raw.substring(1);
      name = '$name ($label)';
      if (usedNames.contains(name) || taken.contains(_slug(name))) {
        skippedDuplicates++;
        continue;
      }
    }
    final id = _slug(name);

    final muscle = row['muscle'] as String;
    final muscles = <String>[];
    void add(Iterable<String> ids) {
      for (final id in ids) {
        if (!muscles.contains(id)) muscles.add(id);
      }
    }

    add(_muscles(muscle, name, primary: true));
    for (final secondary in (row['secondaryMuscles'] as List).cast<String>()) {
      if (secondary == 'delts') {
        // A pull brings the rear delt in; everything else the front one.
        final pull = const {
          'lats',
          'upper-back',
          'traps',
          'biceps',
        }.contains(muscle);
        add([pull ? 'rear_deltoid' : 'front_deltoid']);
      } else {
        add(_muscles(secondary, name, primary: false));
      }
    }
    if (muscles.isEmpty) add(['quads', 'calves']);

    final lower = name.toLowerCase();
    entries.add(
      _Entry(
        id: id,
        name: name,
        equipment: equipment,
        muscles: muscles,
        upstream: upstreamId,
        plateLoaded:
            row['equipment'] == 'barbell' &&
            row['category'] == 'strength' &&
            !_timedName.hasMatch(lower),
        timed: row['category'] == 'cardio' || _timedName.hasMatch(lower),
      ),
    );
    taken.add(id);
    usedNames.add(name);
    seenEquipment[_cleanName(row['name'] as String)] ??=
        row['equipment'] as String;
  }

  entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  _writeCatalog(entries);
  stdout.writeln(
    'Wrote ${entries.length} exercises to $_output '
    '($skippedStretches stretches and $skippedDuplicates duplicates left out).',
  );

  if (!noMedia) {
    final sources = <String, String>{
      ..._curated,
      for (final e in entries) e.id: e.upstream,
    };
    await _downloadPreviews(client, sources, force: force);
  }
  client.close();
}

void _writeCatalog(List<_Entry> entries) {
  final out = StringBuffer()
    ..writeln(
      '// GENERATED by tool/sync_exercise_db.dart — do not edit by hand.',
    )
    ..writeln('// Re-run the tool to change it; see the notes at its top for')
    ..writeln('// how upstream data is mapped onto the app.')
    ..writeln('//')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'package:drift/drift.dart';")
    ..writeln()
    ..writeln("import '../../../shared/database/app_database.dart';")
    ..writeln("import '../../../shared/models/muscle_ids.dart';")
    ..writeln()
    ..writeln('/// The imported part of the built-in library, sorted by name.')
    ..writeln('///')
    ..writeln('/// Joined with the hand-written entries in [exerciseSeedData].')
    ..writeln('const List<ExercisesCompanion> exerciseCatalogData = [');
  for (final e in entries) {
    final muscles = e.muscles.map((m) => _dartMuscle[m]!).join(', ');
    out
      ..writeln('  ExercisesCompanion(')
      ..writeln('    id: Value(${_dartString(e.id)}),')
      ..writeln('    equipment: Value(${_dartString(e.equipment)}),')
      ..writeln('    name: Value(${_dartString(e.name)}),')
      ..writeln('    muscleIds: Value([$muscles]),')
      ..writeln("    gifPath: Value('assets/exercises/${e.id}.gif'),");
    if (e.plateLoaded) out.writeln('    isPlateLoaded: Value(true),');
    if (e.timed) out.writeln('    isTimed: Value(true),');
    out.writeln('  ),');
  }
  out.writeln('];');
  File(_output).writeAsStringSync(out.toString());
}

/// Saves each upstream 128px animated WebP as `<id>.webp`, and removes an
/// older `<id>.gif` so only one file per exercise ships.
Future<void> _downloadPreviews(
  HttpClient client,
  Map<String, String> sources, {
  required bool force,
}) async {
  var written = 0, skipped = 0, failed = 0, bytes = 0;
  final pending = sources.entries.toList();

  Future<void> worker() async {
    while (pending.isNotEmpty) {
      final entry = pending.removeLast();
      final target = File('$_dest/${entry.key}.webp');
      final oldGif = File('$_dest/${entry.key}.gif');
      if (target.existsSync() && !force) {
        if (oldGif.existsSync()) oldGif.deleteSync();
        skipped++;
        continue;
      }
      try {
        final data = await _get(client, '$_base/${entry.value}.thumb.webp');
        // Written only once the whole body has arrived: a half-downloaded
        // file would be skipped as "already present" on the next run.
        target.writeAsBytesSync(data);
        if (oldGif.existsSync()) oldGif.deleteSync();
        bytes += data.length;
        written++;
        stdout.write('\r  ${written + skipped} / ${sources.length}   ');
      } catch (error) {
        stderr.writeln('\n  failed  ${entry.key}: $error');
        failed++;
      }
    }
  }

  await Future.wait(List.generate(8, (_) => worker()));

  // Previews for ids that no longer exist would ship as dead weight.
  final valid = sources.keys.toSet();
  var removed = 0;
  for (final file in Directory(_dest).listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || name == 'README.md') continue;
    if (!valid.contains(name.substring(0, dot))) {
      file.deleteSync();
      removed++;
    }
  }

  stdout.writeln(
    '\n$written downloaded (${(bytes / 1048576).toStringAsFixed(1)}MB), '
    '$skipped already present, $failed failed, $removed stale files removed.',
  );
  if (failed > 0) exitCode = 1;
}

Future<List<int>> _get(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != 200) {
    await response.drain<void>();
    throw HttpException('${response.statusCode} for $url');
  }
  return response.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
}
