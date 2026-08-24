// The shape of a shared plan file.
//
// Deliberately small and boring: plain JSON, no compression, no binary. A plan
// is a few kilobytes of names and numbers, and a format you can open in a text
// editor is one you can still recover by hand in five years when this app is
// three rewrites away.
//
// **Plans only.** No sessions, no logged sets, no body measurements, no photos.
// Sending someone your programme should not send them your body weight, and the
// only reliable way to guarantee that is for the exporter to have no idea those
// tables exist.

import 'dart:convert';

/// Marks the file as ours, so a wrong file picked by mistake fails with an
/// explanation rather than a type error halfway through the import.
const planFormatTag = 'gymfy.plan';

/// Bumped when the shape changes incompatibly. An importer that meets a version
/// it doesn't know refuses rather than guessing.
const planFormatVersion = 1;

/// File extension for an exported plan.
const planFileExtension = 'gymfy';

/// One planned exercise inside a shared day.
class SharedExercise {
  const SharedExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleIds,
    required this.sets,
    required this.reps,
    this.repsMax,
    this.warmupSets = 0,
  });

  /// The library slug. Built-in exercises share these across installs, so the
  /// recipient's own copy is reused rather than duplicated.
  final String exerciseId;

  /// Carried alongside the id so a custom exercise the recipient has never seen
  /// can still be recreated. Without it, importing someone's programme would
  /// silently drop every lift they invented — the ones most worth sharing.
  final String name;

  /// Same reason as [name]: enough to rebuild the exercise, and what the muscle
  /// map needs to colour it.
  final List<String> muscleIds;

  final int sets;
  final int reps;

  /// Top of the rep range, or null for a fixed target.
  final int? repsMax;

  final int warmupSets;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleIds': muscleIds,
    'sets': sets,
    'reps': reps,
    if (repsMax != null) 'repsMax': repsMax,
    if (warmupSets > 0) 'warmupSets': warmupSets,
  };

  factory SharedExercise.fromJson(Map<String, dynamic> json) {
    return SharedExercise(
      exerciseId: _string(json, 'exerciseId'),
      name: _string(json, 'name'),
      muscleIds: _stringList(json, 'muscleIds'),
      sets: _int(json, 'sets', fallback: 3),
      reps: _int(json, 'reps', fallback: 10),
      repsMax: json['repsMax'] is num ? (json['repsMax'] as num).toInt() : null,
      warmupSets: _int(json, 'warmupSets', fallback: 0),
    );
  }
}

/// One day of a shared split.
class SharedDay {
  const SharedDay({
    required this.name,
    required this.weekdays,
    required this.exercises,
  });

  final String name;

  /// ISO weekdays (1 = Monday). Empty means the day exists but isn't scheduled.
  final List<int> weekdays;

  /// Exercises with a blank id are dropped while reading: the id is the only
  /// thing that connects a planned slot to a real lift, and importing one
  /// without it would put a nameless placeholder in the library that shows up
  /// in every picker from then on.
  final List<SharedExercise> exercises;

  Map<String, dynamic> toJson() => {
    'name': name,
    'weekdays': weekdays,
    'exercises': [for (final e in exercises) e.toJson()],
  };

  factory SharedDay.fromJson(Map<String, dynamic> json) {
    return SharedDay(
      name: _string(json, 'name'),
      // Anything outside 1–7 is dropped rather than imported: a weekday of 9
      // would be invisible in the UI but still occupy the day's slot.
      weekdays: [
        for (final value in _list(json, 'weekdays'))
          if (value is num && value >= 1 && value <= 7) value.toInt(),
      ],
      exercises: [
        for (final value in _list(json, 'exercises'))
          if (value is Map<String, dynamic>)
            SharedExercise.fromJson(value),
      ].where((e) => e.exerciseId.isNotEmpty).toList(),
    );
  }
}

/// One shared split: a name and its days.
class SharedSplit {
  const SharedSplit({required this.name, required this.days});

  final String name;
  final List<SharedDay> days;

  Map<String, dynamic> toJson() => {
    'name': name,
    'days': [for (final d in days) d.toJson()],
  };

  factory SharedSplit.fromJson(Map<String, dynamic> json) {
    return SharedSplit(
      name: _string(json, 'name'),
      days: [
        for (final value in _list(json, 'days'))
          if (value is Map<String, dynamic>) SharedDay.fromJson(value),
      ],
    );
  }
}

/// A whole shared plan file.
class PlanDocument {
  const PlanDocument({required this.splits, this.exportedAt});

  final List<SharedSplit> splits;

  /// Informational only — shown when importing so you can tell two versions of
  /// the same programme apart. Nothing branches on it.
  final DateTime? exportedAt;

  /// Encodes to pretty-printed JSON. Pretty because the file is meant to be
  /// human-readable, and a plan is small enough that the extra bytes are free.
  String encode() {
    return const JsonEncoder.withIndent('  ').convert({
      'format': planFormatTag,
      'version': planFormatVersion,
      if (exportedAt != null) 'exportedAt': exportedAt!.toIso8601String(),
      'splits': [for (final split in splits) split.toJson()],
    });
  }

  /// Parses a plan file, or throws [PlanFormatException] with something worth
  /// showing the user.
  static PlanDocument decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      throw const PlanFormatException(
        "That file isn't a Gymfy plan — it isn't even JSON.",
      );
    }

    if (raw is! Map<String, dynamic>) {
      throw const PlanFormatException("That file isn't a Gymfy plan.");
    }
    if (raw['format'] != planFormatTag) {
      throw const PlanFormatException(
        "That file isn't a Gymfy plan. Look for a file ending in "
        '.$planFileExtension.',
      );
    }

    final version = raw['version'];
    if (version is! num || version > planFormatVersion) {
      // Refusing beats guessing: a newer file may describe things this build
      // has no column for, and a half-imported plan is worse than none.
      throw const PlanFormatException(
        'That plan was made by a newer version of Gymfy. Update the app and '
        'try again.',
      );
    }

    final splits = [
      for (final value in _list(raw, 'splits'))
        if (value is Map<String, dynamic>) SharedSplit.fromJson(value),
    ];

    if (splits.isEmpty) {
      throw const PlanFormatException("That plan file doesn't contain a split.");
    }

    return PlanDocument(
      splits: splits,
      exportedAt: DateTime.tryParse(raw['exportedAt'] as String? ?? ''),
    );
  }
}

/// A plan file that can't be read, carrying a message meant for the user.
class PlanFormatException implements Exception {
  const PlanFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Suggests a filename like `push-pull-legs.gymfy`.
///
/// Named after the plan rather than timestamped, because the file usually
/// arrives in someone's chat app where the name is all they see.
String planFileName(PlanDocument document) {
  final base = document.splits.length == 1
      ? document.splits.single.name
      : 'gymfy-plans';
  final slug = base
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'plan' : slug}.$planFileExtension';
}

// --- Lenient readers ---------------------------------------------------------
//
// A plan file usually arrives over a chat app from someone running a different
// build. These read what's there and fall back rather than throwing on a
// missing optional field — the format check in `decode` has already established
// that this *is* a plan file, and past that point salvaging what we can beats
// refusing the whole import over one absent key.

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : '';
}

List<Object?> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is List ? value : const [];
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  return [
    for (final value in _list(json, key))
      if (value is String) value,
  ];
}

int _int(Map<String, dynamic> json, String key, {required int fallback}) {
  final value = json[key];
  return value is num ? value.toInt() : fallback;
}
