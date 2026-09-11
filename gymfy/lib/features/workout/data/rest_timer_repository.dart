import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/settings_repository.dart';
import '../../../shared/database/app_database.dart';

part 'rest_timer_repository.g.dart';

/// Setting key for the rest length used by exercises with no override.
const defaultRestSecondsSetting = 'default_rest_seconds';

/// Rest length used until the user says otherwise.
///
/// 90 seconds is the usual middle ground: long enough for a working set of a
/// compound lift, short enough not to stretch an accessory workout out.
const defaultRestSeconds = 90;

/// The shortest and longest rest we'll store.
///
/// The floor is above zero because a rest timer of zero is just "off", which is
/// a different thing and has its own control. The ceiling keeps a fat-fingered
/// entry from scheduling a notification twenty minutes out.
const minRestSeconds = 10;
const maxRestSeconds = 600;

/// Clamps a rest length to something we're willing to store.
int clampRestSeconds(int seconds) {
  return seconds.clamp(minRestSeconds, maxRestSeconds);
}

/// Reads a stored rest length, or null if it isn't a usable number.
int? parseRestSeconds(String? raw) {
  if (raw == null) return null;
  final value = int.tryParse(raw);
  if (value == null) return null;
  return clampRestSeconds(value);
}

/// Formats a rest length as "1:30" — the way a timer reads, not "90 s".
String formatRest(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Database access for per-exercise rest lengths.
class RestTimerRepository {
  RestTimerRepository(this._db);

  final AppDatabase _db;

  /// Streams the override for one exercise, or null if it has none.
  Stream<int?> watchForExercise(String exerciseId) {
    final query = _db.select(_db.restTimers)
      ..where((t) => t.exerciseId.equals(exerciseId));
    return query.watchSingleOrNull().map((row) => row?.seconds);
  }

  /// Sets the override for one exercise.
  Future<void> setForExercise(String exerciseId, int seconds) async {
    await _db
        .into(_db.restTimers)
        .insertOnConflictUpdate(
          RestTimersCompanion.insert(
            exerciseId: exerciseId,
            seconds: clampRestSeconds(seconds),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Removes the override, so the exercise follows the global default again.
  Future<void> clearForExercise(String exerciseId) async {
    await (_db.delete(
      _db.restTimers,
    )..where((t) => t.exerciseId.equals(exerciseId))).go();
  }
}

/// App-wide access to the [RestTimerRepository].
@Riverpod(keepAlive: true)
RestTimerRepository restTimerRepository(Ref ref) {
  return RestTimerRepository(ref.watch(appDatabaseProvider));
}

/// The global default rest length.
final defaultRestProvider = StreamProvider<int>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(defaultRestSecondsSetting)
      .map((raw) => parseRestSeconds(raw) ?? defaultRestSeconds);
});

/// The override for one exercise, or null when it follows the default.
final exerciseRestOverrideProvider = StreamProvider.family<int?, String>((
  ref,
  exerciseId,
) {
  return ref.watch(restTimerRepositoryProvider).watchForExercise(exerciseId);
});

/// The rest length actually used for one exercise: its own if it has one,
/// otherwise the global default.
///
/// Everything that starts a timer reads this rather than combining the two
/// itself, so the number shown in settings and the number counted down can't
/// disagree.
final restForExerciseProvider = Provider.family<int, String>((ref, exerciseId) {
  final override = ref.watch(exerciseRestOverrideProvider(exerciseId)).value;
  if (override != null) return override;
  return ref.watch(defaultRestProvider).value ?? defaultRestSeconds;
});

/// Writes the global default rest length.
Future<void> setDefaultRest(WidgetRef ref, int seconds) {
  return ref
      .read(settingsRepositoryProvider)
      .write(defaultRestSecondsSetting, clampRestSeconds(seconds).toString());
}
