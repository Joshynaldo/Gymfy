/// What a movement needs to be performed.
///
/// Stored as the enum's [name] so the database keeps a readable slug rather
/// than an index — an index would silently re-point every exercise the first
/// time somebody reorders this list.
///
/// Deliberately six, and coarse. The question this answers is "can I do this
/// today, in this gym", and at that grain a hotel with dumbbells is one
/// answer and a rack is another. A finer list — EZ bar apart from barbell,
/// Smith machine apart from machine — would split that question into
/// distinctions nobody filters on, and every extra chip costs width on a bar
/// meant to be read at a glance.
/// These deliberately carry no icon. The first version gave each one a
/// Material glyph and the result was worse than nothing: there is no barbell
/// icon in the set, so `fitness_center` — which is a *dumbbell* — ended up
/// labelled "Barbell", with the actual dumbbell getting a gymnast and the
/// machine getting a robot arm. A picture that contradicts the word beside it
/// is read before the word is. They are six short words; the words are enough.
enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  machine('Machine'),
  cable('Cable'),
  bodyweight('Bodyweight'),

  /// Kettlebells, an ab wheel, a band — the things a gym either has in a
  /// corner or does not. One bucket rather than four entries that would each
  /// match one or two exercises.
  other('Other');

  const Equipment(this.label);

  final String label;

  /// Reads a stored slug, falling back to [Equipment.other].
  ///
  /// Never throws: an unreadable value is a row written by a newer build or
  /// by hand, and dropping an exercise out of the library over it would be a
  /// worse outcome than filing it under "other".
  static Equipment parse(String? raw) {
    return Equipment.values.firstWhere(
      (equipment) => equipment.name == raw,
      orElse: () => Equipment.other,
    );
  }
}
