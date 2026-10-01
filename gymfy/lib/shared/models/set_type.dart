/// What kind of set a logged set was.
///
/// Stored on `logged_sets.set_type` as the enum's [name], like `Equipment` —
/// a readable slug survives somebody reordering this list, an index would not.
///
/// Replaces the old warm-up boolean (schema v26). The divide that boolean drew
/// still exists, it just has more than two sides now:
///
/// - [warmup] and [drop] are real work — they count toward session volume, the
///   muscle map and the recap charts — but they are not evidence of strength.
///   A ramp-up single is lighter than you can lift on purpose, and a drop set
///   is lighter because you are already exhausted. Neither belongs on the
///   estimated-1RM chart, in the PR list, or in the overload suggestion.
/// - [normal] and [failure] are working sets. A set taken to failure is the
///   most honest strength data there is, so it counts like any other.
enum SetType {
  warmup('Warm-up'),
  normal('Working'),
  drop('Drop set'),
  failure('Failure');

  const SetType(this.label);

  final String label;

  /// Whether a set of this type may feed estimated 1RM, personal records,
  /// progress charts and overload suggestions.
  ///
  /// The single answer to that question — `isWorkingSet` in
  /// session_repository.dart and every SQL filter go through it (see
  /// [strengthExcludedSetTypes]).
  bool get countsTowardStrength => !strengthExcludedSetTypes.contains(name);

  /// Whether this set is numbered with the ramp-up sets rather than the
  /// working ones. Only warm-ups are: a drop set or a failure set follows a
  /// working set and is counted after it.
  bool get isWarmupPhase => this == SetType.warmup;

  /// The types worth offering for an exercise.
  ///
  /// A held exercise — a plank, a hang, a carry — is either a warm-up or the
  /// real thing. There is no lighter weight to drop to, and "to failure" or a
  /// rep in reserve describes counting reps, which a hold doesn't do.
  static List<SetType> optionsFor({required bool timed}) =>
      timed ? const [SetType.warmup, SetType.normal] : SetType.values;

  /// Reads a stored slug, falling back to [SetType.normal].
  ///
  /// Never throws: an unknown value was written by a newer build or by hand,
  /// and treating it as an ordinary working set loses nothing — matching the
  /// SQL filter, which excludes only the slugs it knows to exclude.
  static SetType parse(String? raw) => SetType.values.firstWhere(
    (type) => type.name == raw,
    orElse: () => SetType.normal,
  );
}

/// The stored slugs that never count as evidence of strength.
///
/// For SQL: `loggedSets.setType.isNotIn(strengthExcludedSetTypes)`. Written as
/// an exclusion list on purpose, so an unknown slug behaves like [SetType.parse]
/// says it should — as a working set.
const strengthExcludedSetTypes = <String>['warmup', 'drop'];
