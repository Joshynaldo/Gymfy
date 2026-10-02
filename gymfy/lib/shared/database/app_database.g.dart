// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> muscleIds =
      GeneratedColumn<String>(
        'muscle_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ExercisesTable.$convertermuscleIds);
  static const VerificationMeta _gifPathMeta = const VerificationMeta(
    'gifPath',
  );
  @override
  late final GeneratedColumn<String> gifPath = GeneratedColumn<String>(
    'gif_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPlateLoadedMeta = const VerificationMeta(
    'isPlateLoaded',
  );
  @override
  late final GeneratedColumn<bool> isPlateLoaded = GeneratedColumn<bool>(
    'is_plate_loaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plate_loaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _barWeightKgMeta = const VerificationMeta(
    'barWeightKg',
  );
  @override
  late final GeneratedColumn<double> barWeightKg = GeneratedColumn<double>(
    'bar_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _isTimedMeta = const VerificationMeta(
    'isTimed',
  );
  @override
  late final GeneratedColumn<bool> isTimed = GeneratedColumn<bool>(
    'is_timed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_timed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    muscleIds,
    gifPath,
    isPlateLoaded,
    barWeightKg,
    isCustom,
    isArchived,
    equipment,
    isTimed,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gif_path')) {
      context.handle(
        _gifPathMeta,
        gifPath.isAcceptableOrUnknown(data['gif_path']!, _gifPathMeta),
      );
    }
    if (data.containsKey('is_plate_loaded')) {
      context.handle(
        _isPlateLoadedMeta,
        isPlateLoaded.isAcceptableOrUnknown(
          data['is_plate_loaded']!,
          _isPlateLoadedMeta,
        ),
      );
    }
    if (data.containsKey('bar_weight_kg')) {
      context.handle(
        _barWeightKgMeta,
        barWeightKg.isAcceptableOrUnknown(
          data['bar_weight_kg']!,
          _barWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('is_timed')) {
      context.handle(
        _isTimedMeta,
        isTimed.isAcceptableOrUnknown(data['is_timed']!, _isTimedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      muscleIds: $ExercisesTable.$convertermuscleIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}muscle_ids'],
        )!,
      ),
      gifPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gif_path'],
      ),
      isPlateLoaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_plate_loaded'],
      )!,
      barWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bar_weight_kg'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      isTimed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_timed'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermuscleIds =
      const MuscleIdsConverter();
}

class Exercise extends DataClass implements Insertable<Exercise> {
  /// Stable slug id, e.g. "barbell_bench_press". We assign these ourselves in
  /// the seed data, so it's a text primary key (not an autoincrement int).
  final String id;

  /// Display name, e.g. "Barbell Bench Press".
  final String name;

  /// Muscles this exercise trains. Values must come from `MuscleId`
  /// (muscle_ids.dart); stored as a JSON array. Drives the muscle-map heatmap.
  final List<String> muscleIds;

  /// Where the preview image lives. Two shapes, told apart by the prefix:
  ///
  /// - `assets/exercises/<id>.gif` — a built-in GIF bundled with the app.
  /// - an absolute file path — a picture the user chose for a custom exercise,
  ///   copied into the app's own directory (see `ExerciseRepository.saveImage`).
  ///
  /// Nullable: most exercises have no image, which is a normal state and not an
  /// error. Use `isBundledAsset` to decide how to load it.
  final String? gifPath;

  /// True for exercises loaded by putting plates on a bar.
  ///
  /// Barbell and EZ-bar movements only. Plate-loaded *machines* (leg press,
  /// hack squat) are deliberately excluded: their sleds have an unlisted
  /// starting weight and a varying number of pegs, so "bar + 2 × plates" would
  /// quietly report a wrong number rather than a useful one.
  ///
  /// Drives how the log-set dialog opens — stacking plates for these, typing a
  /// number for everything else.
  final bool isPlateLoaded;

  /// What the empty bar or carriage weighs, in kilograms, or null to use the
  /// gym-wide default for the unit.
  ///
  /// Per exercise because "plate-loaded" does not mean "on a barbell". A
  /// T-bar row, a hack squat, a leg press: plates go on, but there is no 20 kg
  /// bar in the equation, and the calculator's total was wrong by exactly one
  /// bar every time. Zero is a legitimate value here and means what it says —
  /// nothing to add.
  ///
  /// Deliberately *not* set by [exerciseSeedData]. The seed upsert rewrites
  /// every built-in row on launch, but only the columns its companions carry,
  /// so leaving this one absent is what lets a value the user chose survive.
  /// `exercise_bar_test.dart` re-seeds and checks exactly that.
  final double? barWeightKg;

  /// True for exercises the user created themselves.
  ///
  /// This is what gates editing and deleting: the built-in library is upserted
  /// from [exerciseSeedData] on every launch, so "editing" a seed exercise would
  /// silently revert on the next start. Rather than let that happen, the UI only
  /// offers those actions on custom rows.
  final bool isCustom;

  /// True once the user has deleted a custom exercise that already has history.
  ///
  /// Archived exercises vanish from the library and from every picker, but the
  /// row stays so past workouts keep their sets and their exercise *name*.
  /// Deleting a custom exercise that was never logged removes it outright — no
  /// history to protect, so no tombstone to leave behind.
  final bool isArchived;

  /// What the movement needs: barbell, dumbbell, machine, cable, bodyweight
  /// or other. Stored as the [Equipment] slug.
  ///
  /// Carried by the seed companions, like [isTimed] and unlike [notes]: a
  /// bench press needs a barbell whoever is holding it, so the built-in
  /// library should keep asserting that on every launch.
  ///
  /// Defaults to `other` rather than being nullable. "Unclassified" and
  /// "something else" would show up identically on a filter bar, and a second
  /// state that renders the same as the first is a state nobody can act on.
  final String equipment;

  /// True for movements measured in time rather than reps — planks, hangs,
  /// wall sits, loaded carries, and cardio.
  ///
  /// On the exercise rather than on the set, because it is a fact about the
  /// movement: a plank is never counted in reps, on any day, in any
  /// programme. It decides which of the two the log sheet asks for, so a
  /// per-set flag would let you log a plank in reps by accident.
  ///
  /// Carried by the seed companions, unlike [notes] and [barWeightKg] — this
  /// is a property of the movement itself, not something the user chose, so
  /// the built-in library should keep telling the truth about it on every
  /// launch even if a past version got one wrong.
  final bool isTimed;

  /// The user's own note about this exercise — seat height, pin position, grip
  /// width, which machine in the gym, a cue that makes the lift click.
  ///
  /// On the *exercise*, not on the planned entry or the session. A seat height
  /// is a fact about the machine, so it is the same on push day and pull day
  /// and in a programme written next year. Hanging it off the plan would mean
  /// retyping it for every day the lift appears in, and losing it when the
  /// plan is rewritten.
  ///
  /// Null means "never written", which is not the same as an empty note — an
  /// empty string would still draw a heading with nothing under it. Clearing
  /// the text stores null again.
  ///
  /// Available on built-in exercises too, and that is the main case: the leg
  /// press is not something you invented. Like [barWeightKg] this is
  /// deliberately absent from [exerciseSeedData], so the launch upsert — which
  /// rewrites every built-in row but only the columns its companions carry —
  /// cannot wipe what you wrote. `exercise_notes_test.dart` re-seeds and
  /// checks exactly that.
  final String? notes;
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleIds,
    this.gifPath,
    required this.isPlateLoaded,
    this.barWeightKg,
    required this.isCustom,
    required this.isArchived,
    required this.equipment,
    required this.isTimed,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['muscle_ids'] = Variable<String>(
        $ExercisesTable.$convertermuscleIds.toSql(muscleIds),
      );
    }
    if (!nullToAbsent || gifPath != null) {
      map['gif_path'] = Variable<String>(gifPath);
    }
    map['is_plate_loaded'] = Variable<bool>(isPlateLoaded);
    if (!nullToAbsent || barWeightKg != null) {
      map['bar_weight_kg'] = Variable<double>(barWeightKg);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['is_archived'] = Variable<bool>(isArchived);
    map['equipment'] = Variable<String>(equipment);
    map['is_timed'] = Variable<bool>(isTimed);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleIds: Value(muscleIds),
      gifPath: gifPath == null && nullToAbsent
          ? const Value.absent()
          : Value(gifPath),
      isPlateLoaded: Value(isPlateLoaded),
      barWeightKg: barWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(barWeightKg),
      isCustom: Value(isCustom),
      isArchived: Value(isArchived),
      equipment: Value(equipment),
      isTimed: Value(isTimed),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleIds: serializer.fromJson<List<String>>(json['muscleIds']),
      gifPath: serializer.fromJson<String?>(json['gifPath']),
      isPlateLoaded: serializer.fromJson<bool>(json['isPlateLoaded']),
      barWeightKg: serializer.fromJson<double?>(json['barWeightKg']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      equipment: serializer.fromJson<String>(json['equipment']),
      isTimed: serializer.fromJson<bool>(json['isTimed']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'muscleIds': serializer.toJson<List<String>>(muscleIds),
      'gifPath': serializer.toJson<String?>(gifPath),
      'isPlateLoaded': serializer.toJson<bool>(isPlateLoaded),
      'barWeightKg': serializer.toJson<double?>(barWeightKg),
      'isCustom': serializer.toJson<bool>(isCustom),
      'isArchived': serializer.toJson<bool>(isArchived),
      'equipment': serializer.toJson<String>(equipment),
      'isTimed': serializer.toJson<bool>(isTimed),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    List<String>? muscleIds,
    Value<String?> gifPath = const Value.absent(),
    bool? isPlateLoaded,
    Value<double?> barWeightKg = const Value.absent(),
    bool? isCustom,
    bool? isArchived,
    String? equipment,
    bool? isTimed,
    Value<String?> notes = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    muscleIds: muscleIds ?? this.muscleIds,
    gifPath: gifPath.present ? gifPath.value : this.gifPath,
    isPlateLoaded: isPlateLoaded ?? this.isPlateLoaded,
    barWeightKg: barWeightKg.present ? barWeightKg.value : this.barWeightKg,
    isCustom: isCustom ?? this.isCustom,
    isArchived: isArchived ?? this.isArchived,
    equipment: equipment ?? this.equipment,
    isTimed: isTimed ?? this.isTimed,
    notes: notes.present ? notes.value : this.notes,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleIds: data.muscleIds.present ? data.muscleIds.value : this.muscleIds,
      gifPath: data.gifPath.present ? data.gifPath.value : this.gifPath,
      isPlateLoaded: data.isPlateLoaded.present
          ? data.isPlateLoaded.value
          : this.isPlateLoaded,
      barWeightKg: data.barWeightKg.present
          ? data.barWeightKg.value
          : this.barWeightKg,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      isTimed: data.isTimed.present ? data.isTimed.value : this.isTimed,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleIds: $muscleIds, ')
          ..write('gifPath: $gifPath, ')
          ..write('isPlateLoaded: $isPlateLoaded, ')
          ..write('barWeightKg: $barWeightKg, ')
          ..write('isCustom: $isCustom, ')
          ..write('isArchived: $isArchived, ')
          ..write('equipment: $equipment, ')
          ..write('isTimed: $isTimed, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    muscleIds,
    gifPath,
    isPlateLoaded,
    barWeightKg,
    isCustom,
    isArchived,
    equipment,
    isTimed,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleIds == this.muscleIds &&
          other.gifPath == this.gifPath &&
          other.isPlateLoaded == this.isPlateLoaded &&
          other.barWeightKg == this.barWeightKg &&
          other.isCustom == this.isCustom &&
          other.isArchived == this.isArchived &&
          other.equipment == this.equipment &&
          other.isTimed == this.isTimed &&
          other.notes == this.notes);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<List<String>> muscleIds;
  final Value<String?> gifPath;
  final Value<bool> isPlateLoaded;
  final Value<double?> barWeightKg;
  final Value<bool> isCustom;
  final Value<bool> isArchived;
  final Value<String> equipment;
  final Value<bool> isTimed;
  final Value<String?> notes;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleIds = const Value.absent(),
    this.gifPath = const Value.absent(),
    this.isPlateLoaded = const Value.absent(),
    this.barWeightKg = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.equipment = const Value.absent(),
    this.isTimed = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required List<String> muscleIds,
    this.gifPath = const Value.absent(),
    this.isPlateLoaded = const Value.absent(),
    this.barWeightKg = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.equipment = const Value.absent(),
    this.isTimed = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       muscleIds = Value(muscleIds);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? muscleIds,
    Expression<String>? gifPath,
    Expression<bool>? isPlateLoaded,
    Expression<double>? barWeightKg,
    Expression<bool>? isCustom,
    Expression<bool>? isArchived,
    Expression<String>? equipment,
    Expression<bool>? isTimed,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleIds != null) 'muscle_ids': muscleIds,
      if (gifPath != null) 'gif_path': gifPath,
      if (isPlateLoaded != null) 'is_plate_loaded': isPlateLoaded,
      if (barWeightKg != null) 'bar_weight_kg': barWeightKg,
      if (isCustom != null) 'is_custom': isCustom,
      if (isArchived != null) 'is_archived': isArchived,
      if (equipment != null) 'equipment': equipment,
      if (isTimed != null) 'is_timed': isTimed,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<List<String>>? muscleIds,
    Value<String?>? gifPath,
    Value<bool>? isPlateLoaded,
    Value<double?>? barWeightKg,
    Value<bool>? isCustom,
    Value<bool>? isArchived,
    Value<String>? equipment,
    Value<bool>? isTimed,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleIds: muscleIds ?? this.muscleIds,
      gifPath: gifPath ?? this.gifPath,
      isPlateLoaded: isPlateLoaded ?? this.isPlateLoaded,
      barWeightKg: barWeightKg ?? this.barWeightKg,
      isCustom: isCustom ?? this.isCustom,
      isArchived: isArchived ?? this.isArchived,
      equipment: equipment ?? this.equipment,
      isTimed: isTimed ?? this.isTimed,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (muscleIds.present) {
      map['muscle_ids'] = Variable<String>(
        $ExercisesTable.$convertermuscleIds.toSql(muscleIds.value),
      );
    }
    if (gifPath.present) {
      map['gif_path'] = Variable<String>(gifPath.value);
    }
    if (isPlateLoaded.present) {
      map['is_plate_loaded'] = Variable<bool>(isPlateLoaded.value);
    }
    if (barWeightKg.present) {
      map['bar_weight_kg'] = Variable<double>(barWeightKg.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (isTimed.present) {
      map['is_timed'] = Variable<bool>(isTimed.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleIds: $muscleIds, ')
          ..write('gifPath: $gifPath, ')
          ..write('isPlateLoaded: $isPlateLoaded, ')
          ..write('barWeightKg: $barWeightKg, ')
          ..write('isCustom: $isCustom, ')
          ..write('isArchived: $isArchived, ')
          ..write('equipment: $equipment, ')
          ..write('isTimed: $isTimed, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _blockWeeksMeta = const VerificationMeta(
    'blockWeeks',
  );
  @override
  late final GeneratedColumn<int> blockWeeks = GeneratedColumn<int>(
    'block_weeks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deloadPercentMeta = const VerificationMeta(
    'deloadPercent',
  );
  @override
  late final GeneratedColumn<double> deloadPercent = GeneratedColumn<double>(
    'deload_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockStartedAtMeta = const VerificationMeta(
    'blockStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> blockStartedAt =
      GeneratedColumn<DateTime>(
        'block_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    isActive,
    createdAt,
    blockWeeks,
    deloadPercent,
    blockStartedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Split> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('block_weeks')) {
      context.handle(
        _blockWeeksMeta,
        blockWeeks.isAcceptableOrUnknown(data['block_weeks']!, _blockWeeksMeta),
      );
    }
    if (data.containsKey('deload_percent')) {
      context.handle(
        _deloadPercentMeta,
        deloadPercent.isAcceptableOrUnknown(
          data['deload_percent']!,
          _deloadPercentMeta,
        ),
      );
    }
    if (data.containsKey('block_started_at')) {
      context.handle(
        _blockStartedAtMeta,
        blockStartedAt.isAcceptableOrUnknown(
          data['block_started_at']!,
          _blockStartedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      blockWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_weeks'],
      ),
      deloadPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deload_percent'],
      ),
      blockStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}block_started_at'],
      ),
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }
}

class Split extends DataClass implements Insertable<Split> {
  /// App-generated integer id (these are created at runtime by the user, so
  /// unlike exercises they use an autoincrementing key rather than a slug).
  final int id;

  /// Display name, e.g. "Push / Pull / Legs".
  final String name;

  /// Sort order of this split in the split list (lower = higher up).
  final int position;

  /// Whether this is the programme currently being followed.
  ///
  /// At most one split is active at a time (enforced in the repository, not by
  /// the schema — SQLite has no "only one row may be true" constraint). Only the
  /// active split's [WorkoutDaySchedules] decide what today is, so an old split
  /// kept around for reference can't fight the current one over Mondays.
  final bool isActive;

  /// When it was created — handy for a default "newest first" ordering.
  final DateTime createdAt;

  /// Training weeks per block, before the deload week. Null means no blocks.
  final int? blockWeeks;

  /// The deload week's load as a percentage of the working weights, e.g. 60
  /// for "60 %". Same 0–100 scale as the overload percentage setting. Null
  /// falls back to the conventional 10 % off (90) the overload deload uses.
  final double? deloadPercent;

  /// When week 1 of the current block began. Null until a block is set up.
  final DateTime? blockStartedAt;
  const Split({
    required this.id,
    required this.name,
    required this.position,
    required this.isActive,
    required this.createdAt,
    this.blockWeeks,
    this.deloadPercent,
    this.blockStartedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || blockWeeks != null) {
      map['block_weeks'] = Variable<int>(blockWeeks);
    }
    if (!nullToAbsent || deloadPercent != null) {
      map['deload_percent'] = Variable<double>(deloadPercent);
    }
    if (!nullToAbsent || blockStartedAt != null) {
      map['block_started_at'] = Variable<DateTime>(blockStartedAt);
    }
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      blockWeeks: blockWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(blockWeeks),
      deloadPercent: deloadPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(deloadPercent),
      blockStartedAt: blockStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(blockStartedAt),
    );
  }

  factory Split.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      blockWeeks: serializer.fromJson<int?>(json['blockWeeks']),
      deloadPercent: serializer.fromJson<double?>(json['deloadPercent']),
      blockStartedAt: serializer.fromJson<DateTime?>(json['blockStartedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'blockWeeks': serializer.toJson<int?>(blockWeeks),
      'deloadPercent': serializer.toJson<double?>(deloadPercent),
      'blockStartedAt': serializer.toJson<DateTime?>(blockStartedAt),
    };
  }

  Split copyWith({
    int? id,
    String? name,
    int? position,
    bool? isActive,
    DateTime? createdAt,
    Value<int?> blockWeeks = const Value.absent(),
    Value<double?> deloadPercent = const Value.absent(),
    Value<DateTime?> blockStartedAt = const Value.absent(),
  }) => Split(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    blockWeeks: blockWeeks.present ? blockWeeks.value : this.blockWeeks,
    deloadPercent: deloadPercent.present
        ? deloadPercent.value
        : this.deloadPercent,
    blockStartedAt: blockStartedAt.present
        ? blockStartedAt.value
        : this.blockStartedAt,
  );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      blockWeeks: data.blockWeeks.present
          ? data.blockWeeks.value
          : this.blockWeeks,
      deloadPercent: data.deloadPercent.present
          ? data.deloadPercent.value
          : this.deloadPercent,
      blockStartedAt: data.blockStartedAt.present
          ? data.blockStartedAt.value
          : this.blockStartedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('blockWeeks: $blockWeeks, ')
          ..write('deloadPercent: $deloadPercent, ')
          ..write('blockStartedAt: $blockStartedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    position,
    isActive,
    createdAt,
    blockWeeks,
    deloadPercent,
    blockStartedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.blockWeeks == this.blockWeeks &&
          other.deloadPercent == this.deloadPercent &&
          other.blockStartedAt == this.blockStartedAt);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> position;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int?> blockWeeks;
  final Value<double?> deloadPercent;
  final Value<DateTime?> blockStartedAt;
  const SplitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.blockWeeks = const Value.absent(),
    this.deloadPercent = const Value.absent(),
    this.blockStartedAt = const Value.absent(),
  });
  SplitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.position = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.blockWeeks = const Value.absent(),
    this.deloadPercent = const Value.absent(),
    this.blockStartedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Split> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? blockWeeks,
    Expression<double>? deloadPercent,
    Expression<DateTime>? blockStartedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (blockWeeks != null) 'block_weeks': blockWeeks,
      if (deloadPercent != null) 'deload_percent': deloadPercent,
      if (blockStartedAt != null) 'block_started_at': blockStartedAt,
    });
  }

  SplitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? position,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int?>? blockWeeks,
    Value<double?>? deloadPercent,
    Value<DateTime?>? blockStartedAt,
  }) {
    return SplitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      blockWeeks: blockWeeks ?? this.blockWeeks,
      deloadPercent: deloadPercent ?? this.deloadPercent,
      blockStartedAt: blockStartedAt ?? this.blockStartedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (blockWeeks.present) {
      map['block_weeks'] = Variable<int>(blockWeeks.value);
    }
    if (deloadPercent.present) {
      map['deload_percent'] = Variable<double>(deloadPercent.value);
    }
    if (blockStartedAt.present) {
      map['block_started_at'] = Variable<DateTime>(blockStartedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('blockWeeks: $blockWeeks, ')
          ..write('deloadPercent: $deloadPercent, ')
          ..write('blockStartedAt: $blockStartedAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDaysTable extends WorkoutDays
    with TableInfo<$WorkoutDaysTable, WorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _splitIdMeta = const VerificationMeta(
    'splitId',
  );
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
    'split_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES splits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, splitId, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(
        _splitIdMeta,
        splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_splitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      splitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $WorkoutDaysTable createAlias(String alias) {
    return $WorkoutDaysTable(attachedDatabase, alias);
  }
}

class WorkoutDay extends DataClass implements Insertable<WorkoutDay> {
  final int id;

  /// Owning split. If the split is deleted, its days go with it.
  final int splitId;

  /// Display name, e.g. "Push".
  final String name;

  /// Sort order of this day within its split (lower = earlier in the week).
  final int position;
  const WorkoutDay({
    required this.id,
    required this.splitId,
    required this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_id'] = Variable<int>(splitId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  WorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaysCompanion(
      id: Value(id),
      splitId: Value(splitId),
      name: Value(name),
      position: Value(position),
    );
  }

  factory WorkoutDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDay(
      id: serializer.fromJson<int>(json['id']),
      splitId: serializer.fromJson<int>(json['splitId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitId': serializer.toJson<int>(splitId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  WorkoutDay copyWith({int? id, int? splitId, String? name, int? position}) =>
      WorkoutDay(
        id: id ?? this.id,
        splitId: splitId ?? this.splitId,
        name: name ?? this.name,
        position: position ?? this.position,
      );
  WorkoutDay copyWithCompanion(WorkoutDaysCompanion data) {
    return WorkoutDay(
      id: data.id.present ? data.id.value : this.id,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDay(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, splitId, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDay &&
          other.id == this.id &&
          other.splitId == this.splitId &&
          other.name == this.name &&
          other.position == this.position);
}

class WorkoutDaysCompanion extends UpdateCompanion<WorkoutDay> {
  final Value<int> id;
  final Value<int> splitId;
  final Value<String> name;
  final Value<int> position;
  const WorkoutDaysCompanion({
    this.id = const Value.absent(),
    this.splitId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
  });
  WorkoutDaysCompanion.insert({
    this.id = const Value.absent(),
    required int splitId,
    required String name,
    this.position = const Value.absent(),
  }) : splitId = Value(splitId),
       name = Value(name);
  static Insertable<WorkoutDay> custom({
    Expression<int>? id,
    Expression<int>? splitId,
    Expression<String>? name,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitId != null) 'split_id': splitId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
    });
  }

  WorkoutDaysCompanion copyWith({
    Value<int>? id,
    Value<int>? splitId,
    Value<String>? name,
    Value<int>? position,
  }) {
    return WorkoutDaysCompanion(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaysCompanion(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDaySchedulesTable extends WorkoutDaySchedules
    with TableInfo<$WorkoutDaySchedulesTable, WorkoutDaySchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaySchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dayId, weekday];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_day_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutDaySchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayId, weekday};
  @override
  WorkoutDaySchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDaySchedule(
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
    );
  }

  @override
  $WorkoutDaySchedulesTable createAlias(String alias) {
    return $WorkoutDaySchedulesTable(attachedDatabase, alias);
  }
}

class WorkoutDaySchedule extends DataClass
    implements Insertable<WorkoutDaySchedule> {
  /// The day being scheduled. Removed with it.
  final int dayId;

  /// ISO-8601 weekday: 1 = Monday … 7 = Sunday, matching `DateTime.weekday`
  /// so "is this day today?" needs no conversion.
  final int weekday;
  const WorkoutDaySchedule({required this.dayId, required this.weekday});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_id'] = Variable<int>(dayId);
    map['weekday'] = Variable<int>(weekday);
    return map;
  }

  WorkoutDaySchedulesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaySchedulesCompanion(
      dayId: Value(dayId),
      weekday: Value(weekday),
    );
  }

  factory WorkoutDaySchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDaySchedule(
      dayId: serializer.fromJson<int>(json['dayId']),
      weekday: serializer.fromJson<int>(json['weekday']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayId': serializer.toJson<int>(dayId),
      'weekday': serializer.toJson<int>(weekday),
    };
  }

  WorkoutDaySchedule copyWith({int? dayId, int? weekday}) => WorkoutDaySchedule(
    dayId: dayId ?? this.dayId,
    weekday: weekday ?? this.weekday,
  );
  WorkoutDaySchedule copyWithCompanion(WorkoutDaySchedulesCompanion data) {
    return WorkoutDaySchedule(
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaySchedule(')
          ..write('dayId: $dayId, ')
          ..write('weekday: $weekday')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayId, weekday);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDaySchedule &&
          other.dayId == this.dayId &&
          other.weekday == this.weekday);
}

class WorkoutDaySchedulesCompanion extends UpdateCompanion<WorkoutDaySchedule> {
  final Value<int> dayId;
  final Value<int> weekday;
  final Value<int> rowid;
  const WorkoutDaySchedulesCompanion({
    this.dayId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutDaySchedulesCompanion.insert({
    required int dayId,
    required int weekday,
    this.rowid = const Value.absent(),
  }) : dayId = Value(dayId),
       weekday = Value(weekday);
  static Insertable<WorkoutDaySchedule> custom({
    Expression<int>? dayId,
    Expression<int>? weekday,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dayId != null) 'day_id': dayId,
      if (weekday != null) 'weekday': weekday,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutDaySchedulesCompanion copyWith({
    Value<int>? dayId,
    Value<int>? weekday,
    Value<int>? rowid,
  }) {
    return WorkoutDaySchedulesCompanion(
      dayId: dayId ?? this.dayId,
      weekday: weekday ?? this.weekday,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaySchedulesCompanion(')
          ..write('dayId: $dayId, ')
          ..write('weekday: $weekday, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutExercisesTable extends WorkoutExercises
    with TableInfo<$WorkoutExercisesTable, WorkoutExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _defaultSetsMeta = const VerificationMeta(
    'defaultSets',
  );
  @override
  late final GeneratedColumn<int> defaultSets = GeneratedColumn<int>(
    'default_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _warmupSetsMeta = const VerificationMeta(
    'warmupSets',
  );
  @override
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
    'warmup_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _defaultRepsMeta = const VerificationMeta(
    'defaultReps',
  );
  @override
  late final GeneratedColumn<int> defaultReps = GeneratedColumn<int>(
    'default_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _defaultRepsMaxMeta = const VerificationMeta(
    'defaultRepsMax',
  );
  @override
  late final GeneratedColumn<int> defaultRepsMax = GeneratedColumn<int>(
    'default_reps_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPercentMeta = const VerificationMeta(
    'targetPercent',
  );
  @override
  late final GeneratedColumn<double> targetPercent = GeneratedColumn<double>(
    'target_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayId,
    exerciseId,
    position,
    defaultSets,
    warmupSets,
    defaultReps,
    defaultRepsMax,
    supersetGroup,
    targetPercent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('default_sets')) {
      context.handle(
        _defaultSetsMeta,
        defaultSets.isAcceptableOrUnknown(
          data['default_sets']!,
          _defaultSetsMeta,
        ),
      );
    }
    if (data.containsKey('warmup_sets')) {
      context.handle(
        _warmupSetsMeta,
        warmupSets.isAcceptableOrUnknown(data['warmup_sets']!, _warmupSetsMeta),
      );
    }
    if (data.containsKey('default_reps')) {
      context.handle(
        _defaultRepsMeta,
        defaultReps.isAcceptableOrUnknown(
          data['default_reps']!,
          _defaultRepsMeta,
        ),
      );
    }
    if (data.containsKey('default_reps_max')) {
      context.handle(
        _defaultRepsMaxMeta,
        defaultRepsMax.isAcceptableOrUnknown(
          data['default_reps_max']!,
          _defaultRepsMaxMeta,
        ),
      );
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    if (data.containsKey('target_percent')) {
      context.handle(
        _targetPercentMeta,
        targetPercent.isAcceptableOrUnknown(
          data['target_percent']!,
          _targetPercentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      defaultSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_sets'],
      )!,
      warmupSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warmup_sets'],
      )!,
      defaultReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_reps'],
      )!,
      defaultRepsMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_reps_max'],
      ),
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group'],
      ),
      targetPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_percent'],
      ),
    );
  }

  @override
  $WorkoutExercisesTable createAlias(String alias) {
    return $WorkoutExercisesTable(attachedDatabase, alias);
  }
}

class WorkoutExercise extends DataClass implements Insertable<WorkoutExercise> {
  final int id;

  /// Owning day. If the day is deleted, its planned exercises go with it.
  final int dayId;

  /// Which library exercise this slot is. Text FK because exercise ids are
  /// slugs (see exercise.dart).
  final String exerciseId;

  /// Sort order of this exercise within its day.
  final int position;

  /// Default number of working sets planned for this exercise.
  final int defaultSets;

  /// How many ramp-up sets to plan before the working sets.
  ///
  /// Zero for most exercises — you don't warm up for a cable curl.
  ///
  /// A target, not pre-created rows. The session shows "Warm-up 1 of 3" and
  /// keeps offering the button until you've logged that many; it never inserts
  /// placeholder sets, because a 0 kg row you didn't perform would still count
  /// toward your session volume and your muscle map.
  final int warmupSets;

  /// Default target reps per set — the bottom of the range when there is one.
  final int defaultReps;

  /// Top of the rep range, e.g. 12 in "3 × 8–12". Null means a fixed target
  /// rather than a range.
  ///
  /// Nullable rather than defaulting to the same value as [defaultReps]: a
  /// fixed 10 should read as "10", not "10–10", and storing them identically
  /// would leave no way to tell "no range" from "a range of one number".
  final int? defaultRepsMax;

  /// Superset membership. Planned exercises of the same day that share a
  /// non-null value form one superset, done back to back with rest only after
  /// the last of them. Members must sit next to each other in the day's order;
  /// see `supersetBlocks` in workout/data/supersets.dart, which is how every
  /// screen should read this. Null means a standalone exercise.
  ///
  /// The number itself means nothing beyond "same group" — only equality
  /// within one day matters, so any unused small integer will do.
  final int? supersetGroup;

  /// Working-set target as a percentage of the estimated 1RM, e.g. 75 for
  /// "3 × 5 @ 75 %". Same 0–100 scale as the other percentages in the app.
  /// Null means no percentage target — the weight comes from the overload
  /// suggestion or the last session, as before v26.
  final double? targetPercent;
  const WorkoutExercise({
    required this.id,
    required this.dayId,
    required this.exerciseId,
    required this.position,
    required this.defaultSets,
    required this.warmupSets,
    required this.defaultReps,
    this.defaultRepsMax,
    this.supersetGroup,
    this.targetPercent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['default_sets'] = Variable<int>(defaultSets);
    map['warmup_sets'] = Variable<int>(warmupSets);
    map['default_reps'] = Variable<int>(defaultReps);
    if (!nullToAbsent || defaultRepsMax != null) {
      map['default_reps_max'] = Variable<int>(defaultRepsMax);
    }
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    if (!nullToAbsent || targetPercent != null) {
      map['target_percent'] = Variable<double>(targetPercent);
    }
    return map;
  }

  WorkoutExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutExercisesCompanion(
      id: Value(id),
      dayId: Value(dayId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      defaultSets: Value(defaultSets),
      warmupSets: Value(warmupSets),
      defaultReps: Value(defaultReps),
      defaultRepsMax: defaultRepsMax == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultRepsMax),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
      targetPercent: targetPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPercent),
    );
  }

  factory WorkoutExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutExercise(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      defaultSets: serializer.fromJson<int>(json['defaultSets']),
      warmupSets: serializer.fromJson<int>(json['warmupSets']),
      defaultReps: serializer.fromJson<int>(json['defaultReps']),
      defaultRepsMax: serializer.fromJson<int?>(json['defaultRepsMax']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
      targetPercent: serializer.fromJson<double?>(json['targetPercent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'defaultSets': serializer.toJson<int>(defaultSets),
      'warmupSets': serializer.toJson<int>(warmupSets),
      'defaultReps': serializer.toJson<int>(defaultReps),
      'defaultRepsMax': serializer.toJson<int?>(defaultRepsMax),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
      'targetPercent': serializer.toJson<double?>(targetPercent),
    };
  }

  WorkoutExercise copyWith({
    int? id,
    int? dayId,
    String? exerciseId,
    int? position,
    int? defaultSets,
    int? warmupSets,
    int? defaultReps,
    Value<int?> defaultRepsMax = const Value.absent(),
    Value<int?> supersetGroup = const Value.absent(),
    Value<double?> targetPercent = const Value.absent(),
  }) => WorkoutExercise(
    id: id ?? this.id,
    dayId: dayId ?? this.dayId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    defaultSets: defaultSets ?? this.defaultSets,
    warmupSets: warmupSets ?? this.warmupSets,
    defaultReps: defaultReps ?? this.defaultReps,
    defaultRepsMax: defaultRepsMax.present
        ? defaultRepsMax.value
        : this.defaultRepsMax,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
    targetPercent: targetPercent.present
        ? targetPercent.value
        : this.targetPercent,
  );
  WorkoutExercise copyWithCompanion(WorkoutExercisesCompanion data) {
    return WorkoutExercise(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      defaultSets: data.defaultSets.present
          ? data.defaultSets.value
          : this.defaultSets,
      warmupSets: data.warmupSets.present
          ? data.warmupSets.value
          : this.warmupSets,
      defaultReps: data.defaultReps.present
          ? data.defaultReps.value
          : this.defaultReps,
      defaultRepsMax: data.defaultRepsMax.present
          ? data.defaultRepsMax.value
          : this.defaultRepsMax,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
      targetPercent: data.targetPercent.present
          ? data.targetPercent.value
          : this.targetPercent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercise(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('defaultSets: $defaultSets, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('defaultReps: $defaultReps, ')
          ..write('defaultRepsMax: $defaultRepsMax, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('targetPercent: $targetPercent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayId,
    exerciseId,
    position,
    defaultSets,
    warmupSets,
    defaultReps,
    defaultRepsMax,
    supersetGroup,
    targetPercent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExercise &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.defaultSets == this.defaultSets &&
          other.warmupSets == this.warmupSets &&
          other.defaultReps == this.defaultReps &&
          other.defaultRepsMax == this.defaultRepsMax &&
          other.supersetGroup == this.supersetGroup &&
          other.targetPercent == this.targetPercent);
}

class WorkoutExercisesCompanion extends UpdateCompanion<WorkoutExercise> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> defaultSets;
  final Value<int> warmupSets;
  final Value<int> defaultReps;
  final Value<int?> defaultRepsMax;
  final Value<int?> supersetGroup;
  final Value<double?> targetPercent;
  const WorkoutExercisesCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.defaultSets = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.defaultReps = const Value.absent(),
    this.defaultRepsMax = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.targetPercent = const Value.absent(),
  });
  WorkoutExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required String exerciseId,
    this.position = const Value.absent(),
    this.defaultSets = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.defaultReps = const Value.absent(),
    this.defaultRepsMax = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.targetPercent = const Value.absent(),
  }) : dayId = Value(dayId),
       exerciseId = Value(exerciseId);
  static Insertable<WorkoutExercise> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? defaultSets,
    Expression<int>? warmupSets,
    Expression<int>? defaultReps,
    Expression<int>? defaultRepsMax,
    Expression<int>? supersetGroup,
    Expression<double>? targetPercent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (defaultSets != null) 'default_sets': defaultSets,
      if (warmupSets != null) 'warmup_sets': warmupSets,
      if (defaultReps != null) 'default_reps': defaultReps,
      if (defaultRepsMax != null) 'default_reps_max': defaultRepsMax,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (targetPercent != null) 'target_percent': targetPercent,
    });
  }

  WorkoutExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? defaultSets,
    Value<int>? warmupSets,
    Value<int>? defaultReps,
    Value<int?>? defaultRepsMax,
    Value<int?>? supersetGroup,
    Value<double?>? targetPercent,
  }) {
    return WorkoutExercisesCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      defaultSets: defaultSets ?? this.defaultSets,
      warmupSets: warmupSets ?? this.warmupSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRepsMax: defaultRepsMax ?? this.defaultRepsMax,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      targetPercent: targetPercent ?? this.targetPercent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (defaultSets.present) {
      map['default_sets'] = Variable<int>(defaultSets.value);
    }
    if (warmupSets.present) {
      map['warmup_sets'] = Variable<int>(warmupSets.value);
    }
    if (defaultReps.present) {
      map['default_reps'] = Variable<int>(defaultReps.value);
    }
    if (defaultRepsMax.present) {
      map['default_reps_max'] = Variable<int>(defaultRepsMax.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    if (targetPercent.present) {
      map['target_percent'] = Variable<double>(targetPercent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('defaultSets: $defaultSets, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('defaultReps: $defaultReps, ')
          ..write('defaultRepsMax: $defaultRepsMax, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('targetPercent: $targetPercent')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_days (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayId,
    name,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;

  /// The planned day this session was started from, if any. Nullable and set
  /// to null (not cascaded) if that day is deleted, so past sessions survive.
  /// Null from the start for a free workout, which follows no plan at all.
  final int? dayId;

  /// A readable label for the session, snapshotted from the day name at start
  /// time (e.g. "Push"). Kept on the row so history doesn't depend on the plan.
  final String name;

  /// When the session was started.
  final DateTime startedAt;

  /// When the session was finished. Null while it's still in progress.
  final DateTime? completedAt;
  const WorkoutSession({
    required this.id,
    this.dayId,
    required this.name,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      dayId: dayId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayId),
      name: Value(name),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int?>(json['dayId']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int?>(dayId),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  WorkoutSession copyWith({
    int? id,
    Value<int?> dayId = const Value.absent(),
    String? name,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => WorkoutSession(
    id: id ?? this.id,
    dayId: dayId.present ? dayId.value : this.dayId,
    name: name ?? this.name,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, name, startedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<int?> dayId;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    required String name,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? dayId,
    Value<String>? name,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $LoggedSetsTable extends LoggedSets
    with TableInfo<$LoggedSetsTable, LoggedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoggedSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setTypeMeta = const VerificationMeta(
    'setType',
  );
  @override
  late final GeneratedColumn<String> setType = GeneratedColumn<String>(
    'set_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    setNumber,
    weight,
    reps,
    seconds,
    setType,
    rpe,
    rir,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logged_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoggedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    }
    if (data.containsKey('set_type')) {
      context.handle(
        _setTypeMeta,
        setType.isAcceptableOrUnknown(data['set_type']!, _setTypeMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoggedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoggedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      ),
      setType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_type'],
      )!,
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
    );
  }

  @override
  $LoggedSetsTable createAlias(String alias) {
    return $LoggedSetsTable(attachedDatabase, alias);
  }
}

class LoggedSet extends DataClass implements Insertable<LoggedSet> {
  final int id;

  /// Owning session. If the session is deleted, its sets go with it.
  final int sessionId;

  /// Which library exercise this set is for (text FK — exercise ids are slugs).
  final String exerciseId;

  /// 1-based position of this set within its exercise for this session
  /// (set 1, set 2, …).
  final int setNumber;

  /// Weight lifted. A real number so half-kilo / half-pound plates work.
  final double weight;

  /// Reps completed for this set. Zero on a set logged by time.
  final int reps;

  /// How long the set was held, in seconds — planks, hangs, wall sits, loaded
  /// carries. Null on an ordinary set counted in reps.
  ///
  /// Null rather than zero, because the two say different things: zero would
  /// be a set that lasted no time, and every screen deciding how to render a
  /// set reads exactly this distinction. A set has one or the other, never
  /// both — a plank has no rep count and a bench press has no useful duration.
  ///
  /// [weight] still applies: a loaded carry and a weighted plank both have
  /// one, and a set of 45 seconds with 20 kg is a different set from 45
  /// seconds with nothing.
  final int? seconds;

  /// What kind of set this was — `warmup`, `normal`, `drop` or `failure` —
  /// stored as the `SetType` slug (see set_type.dart). Read it through the
  /// `type` getter on `LoggedSet` (session_repository.dart) rather than
  /// comparing strings.
  ///
  /// Replaced the `is_warmup` boolean in v26: old warm-ups became `warmup` and
  /// everything else `normal`.
  ///
  /// Every type is real work you did and is stored like any other set — all of
  /// them count toward session volume, the muscle map and the recap charts,
  /// because they happened. What warm-ups and drop sets must not do is pretend
  /// to be evidence of strength: a 60 kg single on the way to 100 is not a data
  /// point on your bench chart, is not a PR, and must never talk the overload
  /// suggestion down. See `isWorkingSet` in `session_repository.dart` for the
  /// one place that filter is defined.
  ///
  /// Defaults to `normal` rather than being nullable, like the exercise
  /// equipment column: "untyped" and "working" would render identically, and a
  /// state nobody can see is a state nobody can fix.
  final String setType;

  /// Rate of perceived exertion, 1–10 in half steps (8.5 = "maybe two more").
  /// Null when the set wasn't rated — most sets, since rating is optional and
  /// switched on in Settings.
  final double? rpe;

  /// Reps in reserve — how many more reps were left in the tank. The other way
  /// of saying [rpe] (RIR ≈ 10 − RPE); a set normally carries whichever one the
  /// user chose to log, never a guess at the other. Null when unrated.
  final int? rir;
  const LoggedSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.seconds,
    required this.setType,
    this.rpe,
    this.rir,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_number'] = Variable<int>(setNumber);
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || seconds != null) {
      map['seconds'] = Variable<int>(seconds);
    }
    map['set_type'] = Variable<String>(setType);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    return map;
  }

  LoggedSetsCompanion toCompanion(bool nullToAbsent) {
    return LoggedSetsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      setNumber: Value(setNumber),
      weight: Value(weight),
      reps: Value(reps),
      seconds: seconds == null && nullToAbsent
          ? const Value.absent()
          : Value(seconds),
      setType: Value(setType),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
    );
  }

  factory LoggedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoggedSet(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<int>(json['reps']),
      seconds: serializer.fromJson<int?>(json['seconds']),
      setType: serializer.fromJson<String>(json['setType']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      rir: serializer.fromJson<int?>(json['rir']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setNumber': serializer.toJson<int>(setNumber),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<int>(reps),
      'seconds': serializer.toJson<int?>(seconds),
      'setType': serializer.toJson<String>(setType),
      'rpe': serializer.toJson<double?>(rpe),
      'rir': serializer.toJson<int?>(rir),
    };
  }

  LoggedSet copyWith({
    int? id,
    int? sessionId,
    String? exerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    Value<int?> seconds = const Value.absent(),
    String? setType,
    Value<double?> rpe = const Value.absent(),
    Value<int?> rir = const Value.absent(),
  }) => LoggedSet(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    setNumber: setNumber ?? this.setNumber,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    seconds: seconds.present ? seconds.value : this.seconds,
    setType: setType ?? this.setType,
    rpe: rpe.present ? rpe.value : this.rpe,
    rir: rir.present ? rir.value : this.rir,
  );
  LoggedSet copyWithCompanion(LoggedSetsCompanion data) {
    return LoggedSet(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      setType: data.setType.present ? data.setType.value : this.setType,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      rir: data.rir.present ? data.rir.value : this.rir,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoggedSet(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('seconds: $seconds, ')
          ..write('setType: $setType, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    setNumber,
    weight,
    reps,
    seconds,
    setType,
    rpe,
    rir,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggedSet &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.setNumber == this.setNumber &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.seconds == this.seconds &&
          other.setType == this.setType &&
          other.rpe == this.rpe &&
          other.rir == this.rir);
}

class LoggedSetsCompanion extends UpdateCompanion<LoggedSet> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> exerciseId;
  final Value<int> setNumber;
  final Value<double> weight;
  final Value<int> reps;
  final Value<int?> seconds;
  final Value<String> setType;
  final Value<double?> rpe;
  final Value<int?> rir;
  const LoggedSetsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.seconds = const Value.absent(),
    this.setType = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
  });
  LoggedSetsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String exerciseId,
    required int setNumber,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.seconds = const Value.absent(),
    this.setType = const Value.absent(),
    this.rpe = const Value.absent(),
    this.rir = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       setNumber = Value(setNumber);
  static Insertable<LoggedSet> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? setNumber,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? seconds,
    Expression<String>? setType,
    Expression<double>? rpe,
    Expression<int>? rir,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setNumber != null) 'set_number': setNumber,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (seconds != null) 'seconds': seconds,
      if (setType != null) 'set_type': setType,
      if (rpe != null) 'rpe': rpe,
      if (rir != null) 'rir': rir,
    });
  }

  LoggedSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? exerciseId,
    Value<int>? setNumber,
    Value<double>? weight,
    Value<int>? reps,
    Value<int?>? seconds,
    Value<String>? setType,
    Value<double?>? rpe,
    Value<int?>? rir,
  }) {
    return LoggedSetsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      seconds: seconds ?? this.seconds,
      setType: setType ?? this.setType,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(setType.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoggedSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('seconds: $seconds, ')
          ..write('setType: $setType, ')
          ..write('rpe: $rpe, ')
          ..write('rir: $rir')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _workoutExerciseIdMeta = const VerificationMeta(
    'workoutExerciseId',
  );
  @override
  late final GeneratedColumn<int> workoutExerciseId = GeneratedColumn<int>(
    'workout_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_exercises (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    exerciseId,
    position,
    workoutExerciseId,
    supersetGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('workout_exercise_id')) {
      context.handle(
        _workoutExerciseIdMeta,
        workoutExerciseId.isAcceptableOrUnknown(
          data['workout_exercise_id']!,
          _workoutExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      workoutExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_exercise_id'],
      ),
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group'],
      ),
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final int id;

  /// Owning session. If the session is deleted, its running order goes too.
  final int sessionId;

  /// The exercise to do. A swap rewrites this and keeps [workoutExerciseId], so
  /// the plan slot's targets carry over to the replacement.
  final String exerciseId;

  /// Sort order within the session (lower = earlier), ties broken by id.
  final int position;

  /// The plan slot this came from, which supplies the targets (sets, reps,
  /// warm-ups, percent of 1RM). Null for an exercise added during the
  /// session, and set to null if the slot is later deleted — the session
  /// keeps the exercise either way.
  final int? workoutExerciseId;

  /// The superset this entry is done in, like `WorkoutExercises.supersetGroup`
  /// but for this session's own running order. Null when it stands alone.
  ///
  /// The session's, not the plan's (v28). Copied from the plan slot when the
  /// session starts, then edited here: a free workout or an exercise added
  /// mid-workout has no plan slot to carry a group, and pairing two exercises
  /// for one workout is no reason to rewrite the plan.
  final int? supersetGroup;
  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
    this.workoutExerciseId,
    this.supersetGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || workoutExerciseId != null) {
      map['workout_exercise_id'] = Variable<int>(workoutExerciseId);
    }
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      workoutExerciseId: workoutExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutExerciseId),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      workoutExerciseId: serializer.fromJson<int?>(json['workoutExerciseId']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'workoutExerciseId': serializer.toJson<int?>(workoutExerciseId),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
    };
  }

  SessionExercise copyWith({
    int? id,
    int? sessionId,
    String? exerciseId,
    int? position,
    Value<int?> workoutExerciseId = const Value.absent(),
    Value<int?> supersetGroup = const Value.absent(),
  }) => SessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    workoutExerciseId: workoutExerciseId.present
        ? workoutExerciseId.value
        : this.workoutExerciseId,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      workoutExerciseId: data.workoutExerciseId.present
          ? data.workoutExerciseId.value
          : this.workoutExerciseId,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('supersetGroup: $supersetGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    exerciseId,
    position,
    workoutExerciseId,
    supersetGroup,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.workoutExerciseId == this.workoutExerciseId &&
          other.supersetGroup == this.supersetGroup);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int?> workoutExerciseId;
  final Value<int?> supersetGroup;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.workoutExerciseId = const Value.absent(),
    this.supersetGroup = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String exerciseId,
    this.position = const Value.absent(),
    this.workoutExerciseId = const Value.absent(),
    this.supersetGroup = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseId = Value(exerciseId);
  static Insertable<SessionExercise> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? workoutExerciseId,
    Expression<int>? supersetGroup,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (workoutExerciseId != null) 'workout_exercise_id': workoutExerciseId,
      if (supersetGroup != null) 'superset_group': supersetGroup,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int?>? workoutExerciseId,
    Value<int?>? supersetGroup,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      supersetGroup: supersetGroup ?? this.supersetGroup,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (workoutExerciseId.present) {
      map['workout_exercise_id'] = Variable<int>(workoutExerciseId.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('supersetGroup: $supersetGroup')
          ..write(')'))
        .toString();
  }
}

class $CalorieEntriesTable extends CalorieEntries
    with TableInfo<$CalorieEntriesTable, CalorieEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalorieEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    name,
    calories,
    protein,
    carbs,
    fat,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calorie_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalorieEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalorieEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalorieEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CalorieEntriesTable createAlias(String alias) {
    return $CalorieEntriesTable(attachedDatabase, alias);
  }
}

class CalorieEntry extends DataClass implements Insertable<CalorieEntry> {
  final int id;

  /// The calendar day this entry belongs to (stored normalized to midnight by
  /// the repository, so all of a day's entries share the same value).
  final DateTime date;

  /// What was eaten, e.g. "Chicken & rice".
  final String name;

  /// Energy in kilocalories.
  final int calories;

  /// Macronutrients in grams.
  final int protein;
  final int carbs;
  final int fat;

  /// Exact time the entry was logged — used to order items within a day.
  final DateTime createdAt;
  const CalorieEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['name'] = Variable<String>(name);
    map['calories'] = Variable<int>(calories);
    map['protein'] = Variable<int>(protein);
    map['carbs'] = Variable<int>(carbs);
    map['fat'] = Variable<int>(fat);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CalorieEntriesCompanion toCompanion(bool nullToAbsent) {
    return CalorieEntriesCompanion(
      id: Value(id),
      date: Value(date),
      name: Value(name),
      calories: Value(calories),
      protein: Value(protein),
      carbs: Value(carbs),
      fat: Value(fat),
      createdAt: Value(createdAt),
    );
  }

  factory CalorieEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalorieEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<int>(json['calories']),
      protein: serializer.fromJson<int>(json['protein']),
      carbs: serializer.fromJson<int>(json['carbs']),
      fat: serializer.fromJson<int>(json['fat']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<int>(calories),
      'protein': serializer.toJson<int>(protein),
      'carbs': serializer.toJson<int>(carbs),
      'fat': serializer.toJson<int>(fat),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CalorieEntry copyWith({
    int? id,
    DateTime? date,
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? createdAt,
  }) => CalorieEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    name: name ?? this.name,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    createdAt: createdAt ?? this.createdAt,
  );
  CalorieEntry copyWithCompanion(CalorieEntriesCompanion data) {
    return CalorieEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalorieEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, name, calories, protein, carbs, fat, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalorieEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.name == this.name &&
          other.calories == this.calories &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.createdAt == this.createdAt);
}

class CalorieEntriesCompanion extends UpdateCompanion<CalorieEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> name;
  final Value<int> calories;
  final Value<int> protein;
  final Value<int> carbs;
  final Value<int> fat;
  final Value<DateTime> createdAt;
  const CalorieEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CalorieEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String name,
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       name = Value(name);
  static Insertable<CalorieEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? name,
    Expression<int>? calories,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CalorieEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? name,
    Value<int>? calories,
    Value<int>? protein,
    Value<int>? carbs,
    Value<int>? fat,
    Value<DateTime>? createdAt,
  }) {
    return CalorieEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalorieEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipsCmMeta = const VerificationMeta('hipsCm');
  @override
  late final GeneratedColumn<double> hipsCm = GeneratedColumn<double>(
    'hips_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _armsCmMeta = const VerificationMeta('armsCm');
  @override
  late final GeneratedColumn<double> armsCm = GeneratedColumn<double>(
    'arms_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legsCmMeta = const VerificationMeta('legsCm');
  @override
  late final GeneratedColumn<double> legsCm = GeneratedColumn<double>(
    'legs_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    weightKg,
    chestCm,
    waistCm,
    hipsCm,
    armsCm,
    legsCm,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('hips_cm')) {
      context.handle(
        _hipsCmMeta,
        hipsCm.isAcceptableOrUnknown(data['hips_cm']!, _hipsCmMeta),
      );
    }
    if (data.containsKey('arms_cm')) {
      context.handle(
        _armsCmMeta,
        armsCm.isAcceptableOrUnknown(data['arms_cm']!, _armsCmMeta),
      );
    }
    if (data.containsKey('legs_cm')) {
      context.handle(
        _legsCmMeta,
        legsCm.isAcceptableOrUnknown(data['legs_cm']!, _legsCmMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date},
  ];
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      hipsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hips_cm'],
      ),
      armsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}arms_cm'],
      ),
      legsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}legs_cm'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final int id;

  /// The calendar day measured (stored normalized to midnight).
  final DateTime date;

  /// Bodyweight in kilograms.
  final double? weightKg;

  /// Circumferences in centimetres.
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;

  /// Upper arm (flexed), measured on the dominant side.
  final double? armsCm;

  /// Upper thigh, measured on the dominant side.
  final double? legsCm;

  /// When the row was last written — the "auto-timestamp" the input screen
  /// shows so the user knows how fresh the numbers are.
  final DateTime updatedAt;
  const BodyMeasurement({
    required this.id,
    required this.date,
    this.weightKg,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armsCm,
    this.legsCm,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || hipsCm != null) {
      map['hips_cm'] = Variable<double>(hipsCm);
    }
    if (!nullToAbsent || armsCm != null) {
      map['arms_cm'] = Variable<double>(armsCm);
    }
    if (!nullToAbsent || legsCm != null) {
      map['legs_cm'] = Variable<double>(legsCm);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      date: Value(date),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      hipsCm: hipsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipsCm),
      armsCm: armsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(armsCm),
      legsCm: legsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(legsCm),
      updatedAt: Value(updatedAt),
    );
  }

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      hipsCm: serializer.fromJson<double?>(json['hipsCm']),
      armsCm: serializer.fromJson<double?>(json['armsCm']),
      legsCm: serializer.fromJson<double?>(json['legsCm']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'weightKg': serializer.toJson<double?>(weightKg),
      'chestCm': serializer.toJson<double?>(chestCm),
      'waistCm': serializer.toJson<double?>(waistCm),
      'hipsCm': serializer.toJson<double?>(hipsCm),
      'armsCm': serializer.toJson<double?>(armsCm),
      'legsCm': serializer.toJson<double?>(legsCm),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BodyMeasurement copyWith({
    int? id,
    DateTime? date,
    Value<double?> weightKg = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> hipsCm = const Value.absent(),
    Value<double?> armsCm = const Value.absent(),
    Value<double?> legsCm = const Value.absent(),
    DateTime? updatedAt,
  }) => BodyMeasurement(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    hipsCm: hipsCm.present ? hipsCm.value : this.hipsCm,
    armsCm: armsCm.present ? armsCm.value : this.armsCm,
    legsCm: legsCm.present ? legsCm.value : this.legsCm,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      hipsCm: data.hipsCm.present ? data.hipsCm.value : this.hipsCm,
      armsCm: data.armsCm.present ? data.armsCm.value : this.armsCm,
      legsCm: data.legsCm.present ? data.legsCm.value : this.legsCm,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('armsCm: $armsCm, ')
          ..write('legsCm: $legsCm, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    weightKg,
    chestCm,
    waistCm,
    hipsCm,
    armsCm,
    legsCm,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.date == this.date &&
          other.weightKg == this.weightKg &&
          other.chestCm == this.chestCm &&
          other.waistCm == this.waistCm &&
          other.hipsCm == this.hipsCm &&
          other.armsCm == this.armsCm &&
          other.legsCm == this.legsCm &&
          other.updatedAt == this.updatedAt);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double?> weightKg;
  final Value<double?> chestCm;
  final Value<double?> waistCm;
  final Value<double?> hipsCm;
  final Value<double?> armsCm;
  final Value<double?> legsCm;
  final Value<DateTime> updatedAt;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.armsCm = const Value.absent(),
    this.legsCm = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.weightKg = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.armsCm = const Value.absent(),
    this.legsCm = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<BodyMeasurement> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? weightKg,
    Expression<double>? chestCm,
    Expression<double>? waistCm,
    Expression<double>? hipsCm,
    Expression<double>? armsCm,
    Expression<double>? legsCm,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (chestCm != null) 'chest_cm': chestCm,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (armsCm != null) 'arms_cm': armsCm,
      if (legsCm != null) 'legs_cm': legsCm,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double?>? weightKg,
    Value<double?>? chestCm,
    Value<double?>? waistCm,
    Value<double?>? hipsCm,
    Value<double?>? armsCm,
    Value<double?>? legsCm,
    Value<DateTime>? updatedAt,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      armsCm: armsCm ?? this.armsCm,
      legsCm: legsCm ?? this.legsCm,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (hipsCm.present) {
      map['hips_cm'] = Variable<double>(hipsCm.value);
    }
    if (armsCm.present) {
      map['arms_cm'] = Variable<double>(armsCm.value);
    }
    if (legsCm.present) {
      map['legs_cm'] = Variable<double>(legsCm.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('armsCm: $armsCm, ')
          ..write('legsCm: $legsCm, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProgressPhotosTable extends ProgressPhotos
    with TableInfo<$ProgressPhotosTable, ProgressPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, fileName, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProgressPhotosTable createAlias(String alias) {
    return $ProgressPhotosTable(attachedDatabase, alias);
  }
}

class ProgressPhoto extends DataClass implements Insertable<ProgressPhoto> {
  final int id;

  /// The calendar day the photo represents (stored normalized to midnight).
  /// Several photos can share a day — front, back, side.
  final DateTime date;

  /// File name inside the app's progress-photos directory, e.g.
  /// "2026-07-25_1753441200000.jpg".
  final String fileName;

  /// Optional label, e.g. "front relaxed".
  final String? note;
  final DateTime createdAt;
  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.fileName,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProgressPhotosCompanion toCompanion(bool nullToAbsent) {
    return ProgressPhotosCompanion(
      id: Value(id),
      date: Value(date),
      fileName: Value(fileName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ProgressPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressPhoto(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      fileName: serializer.fromJson<String>(json['fileName']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'fileName': serializer.toJson<String>(fileName),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProgressPhoto copyWith({
    int? id,
    DateTime? date,
    String? fileName,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => ProgressPhoto(
    id: id ?? this.id,
    date: date ?? this.date,
    fileName: fileName ?? this.fileName,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  ProgressPhoto copyWithCompanion(ProgressPhotosCompanion data) {
    return ProgressPhoto(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressPhoto(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fileName: $fileName, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, fileName, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressPhoto &&
          other.id == this.id &&
          other.date == this.date &&
          other.fileName == this.fileName &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ProgressPhotosCompanion extends UpdateCompanion<ProgressPhoto> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> fileName;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const ProgressPhotosCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.fileName = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProgressPhotosCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String fileName,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       fileName = Value(fileName);
  static Insertable<ProgressPhoto> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? fileName,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (fileName != null) 'file_name': fileName,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProgressPhotosCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? fileName,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return ProgressPhotosCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      fileName: fileName ?? this.fileName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressPhotosCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fileName: $fileName, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TestedOneRmsTable extends TestedOneRms
    with TableInfo<$TestedOneRmsTable, TestedOneRm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestedOneRmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testedOnMeta = const VerificationMeta(
    'testedOn',
  );
  @override
  late final GeneratedColumn<DateTime> testedOn = GeneratedColumn<DateTime>(
    'tested_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    exerciseId,
    weightKg,
    testedOn,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tested_one_rms';
  @override
  VerificationContext validateIntegrity(
    Insertable<TestedOneRm> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('tested_on')) {
      context.handle(
        _testedOnMeta,
        testedOn.isAcceptableOrUnknown(data['tested_on']!, _testedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_testedOnMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  TestedOneRm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TestedOneRm(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      testedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tested_on'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TestedOneRmsTable createAlias(String alias) {
    return $TestedOneRmsTable(attachedDatabase, alias);
  }
}

class TestedOneRm extends DataClass implements Insertable<TestedOneRm> {
  /// The exercise this max belongs to. Deleting the exercise removes it.
  final String exerciseId;

  /// The tested max in kilograms.
  final double weightKg;

  /// The day it was tested (stored normalized to midnight). Shown next to the
  /// number, since a max from eight months ago is worth doubting.
  final DateTime testedOn;

  /// When the row was last written.
  final DateTime updatedAt;
  const TestedOneRm({
    required this.exerciseId,
    required this.weightKg,
    required this.testedOn,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['weight_kg'] = Variable<double>(weightKg);
    map['tested_on'] = Variable<DateTime>(testedOn);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TestedOneRmsCompanion toCompanion(bool nullToAbsent) {
    return TestedOneRmsCompanion(
      exerciseId: Value(exerciseId),
      weightKg: Value(weightKg),
      testedOn: Value(testedOn),
      updatedAt: Value(updatedAt),
    );
  }

  factory TestedOneRm.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TestedOneRm(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      testedOn: serializer.fromJson<DateTime>(json['testedOn']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'weightKg': serializer.toJson<double>(weightKg),
      'testedOn': serializer.toJson<DateTime>(testedOn),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TestedOneRm copyWith({
    String? exerciseId,
    double? weightKg,
    DateTime? testedOn,
    DateTime? updatedAt,
  }) => TestedOneRm(
    exerciseId: exerciseId ?? this.exerciseId,
    weightKg: weightKg ?? this.weightKg,
    testedOn: testedOn ?? this.testedOn,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TestedOneRm copyWithCompanion(TestedOneRmsCompanion data) {
    return TestedOneRm(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      testedOn: data.testedOn.present ? data.testedOn.value : this.testedOn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TestedOneRm(')
          ..write('exerciseId: $exerciseId, ')
          ..write('weightKg: $weightKg, ')
          ..write('testedOn: $testedOn, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, weightKg, testedOn, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TestedOneRm &&
          other.exerciseId == this.exerciseId &&
          other.weightKg == this.weightKg &&
          other.testedOn == this.testedOn &&
          other.updatedAt == this.updatedAt);
}

class TestedOneRmsCompanion extends UpdateCompanion<TestedOneRm> {
  final Value<String> exerciseId;
  final Value<double> weightKg;
  final Value<DateTime> testedOn;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TestedOneRmsCompanion({
    this.exerciseId = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.testedOn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TestedOneRmsCompanion.insert({
    required String exerciseId,
    required double weightKg,
    required DateTime testedOn,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       weightKg = Value(weightKg),
       testedOn = Value(testedOn);
  static Insertable<TestedOneRm> custom({
    Expression<String>? exerciseId,
    Expression<double>? weightKg,
    Expression<DateTime>? testedOn,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (weightKg != null) 'weight_kg': weightKg,
      if (testedOn != null) 'tested_on': testedOn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TestedOneRmsCompanion copyWith({
    Value<String>? exerciseId,
    Value<double>? weightKg,
    Value<DateTime>? testedOn,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TestedOneRmsCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      weightKg: weightKg ?? this.weightKg,
      testedOn: testedOn ?? this.testedOn,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (testedOn.present) {
      map['tested_on'] = Variable<DateTime>(testedOn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestedOneRmsCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('weightKg: $weightKg, ')
          ..write('testedOn: $testedOn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// The setting's key, e.g. "lifter_sex". Use the constants in the repository
  /// rather than typing these as literals.
  final String name;

  /// The value as text. For enums this is the enum's `name`.
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.name,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      name: Value(name),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? name, String? value, DateTime? updatedAt}) =>
      AppSetting(
        name: name ?? this.name,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.name == this.name &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> name;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String name,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RestTimersTable extends RestTimers
    with TableInfo<$RestTimersTable, RestTimer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestTimersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseId, seconds, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rest_timers';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestTimer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  RestTimer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestTimer(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RestTimersTable createAlias(String alias) {
    return $RestTimersTable(attachedDatabase, alias);
  }
}

class RestTimer extends DataClass implements Insertable<RestTimer> {
  /// The exercise this applies to. Deleting the exercise removes it.
  final String exerciseId;

  /// Rest length in seconds.
  final int seconds;

  /// When the row was last written.
  final DateTime updatedAt;
  const RestTimer({
    required this.exerciseId,
    required this.seconds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['seconds'] = Variable<int>(seconds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RestTimersCompanion toCompanion(bool nullToAbsent) {
    return RestTimersCompanion(
      exerciseId: Value(exerciseId),
      seconds: Value(seconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory RestTimer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestTimer(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      seconds: serializer.fromJson<int>(json['seconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'seconds': serializer.toJson<int>(seconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RestTimer copyWith({String? exerciseId, int? seconds, DateTime? updatedAt}) =>
      RestTimer(
        exerciseId: exerciseId ?? this.exerciseId,
        seconds: seconds ?? this.seconds,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RestTimer copyWithCompanion(RestTimersCompanion data) {
    return RestTimer(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestTimer(')
          ..write('exerciseId: $exerciseId, ')
          ..write('seconds: $seconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, seconds, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestTimer &&
          other.exerciseId == this.exerciseId &&
          other.seconds == this.seconds &&
          other.updatedAt == this.updatedAt);
}

class RestTimersCompanion extends UpdateCompanion<RestTimer> {
  final Value<String> exerciseId;
  final Value<int> seconds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RestTimersCompanion({
    this.exerciseId = const Value.absent(),
    this.seconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestTimersCompanion.insert({
    required String exerciseId,
    required int seconds,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       seconds = Value(seconds);
  static Insertable<RestTimer> custom({
    Expression<String>? exerciseId,
    Expression<int>? seconds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (seconds != null) 'seconds': seconds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestTimersCompanion copyWith({
    Value<String>? exerciseId,
    Value<int>? seconds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RestTimersCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      seconds: seconds ?? this.seconds,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestTimersCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('seconds: $seconds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<double> target = GeneratedColumn<double>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startValueMeta = const VerificationMeta(
    'startValue',
  );
  @override
  late final GeneratedColumn<double> startValue = GeneratedColumn<double>(
    'start_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _celebratedAtMeta = const VerificationMeta(
    'celebratedAt',
  );
  @override
  late final GeneratedColumn<DateTime> celebratedAt = GeneratedColumn<DateTime>(
    'celebrated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    exerciseId,
    target,
    startValue,
    deadline,
    createdAt,
    celebratedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('start_value')) {
      context.handle(
        _startValueMeta,
        startValue.isAcceptableOrUnknown(data['start_value']!, _startValueMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('celebrated_at')) {
      context.handle(
        _celebratedAtMeta,
        celebratedAt.isAcceptableOrUnknown(
          data['celebrated_at']!,
          _celebratedAtMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      ),
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target'],
      )!,
      startValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_value'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      celebratedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}celebrated_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;

  /// What kind of goal this is, as the [GoalKind] slug (`lift`, `frequency`,
  /// `bodyweight`). Read it through [GoalKind.parse] rather than comparing
  /// strings.
  final String kind;

  /// The exercise a `lift` goal is about. Null for the other kinds.
  ///
  /// Deleting the exercise deletes the goal: a target on a lift that no longer
  /// exists has nothing left to measure. (A custom exercise with any history
  /// is archived rather than deleted, so this only fires for one that was
  /// never trained.)
  final String? exerciseId;

  /// The number to reach, in the kind's own unit: kilograms for `lift` and
  /// `bodyweight` (stored canonically, like every weight), workouts per week
  /// for `frequency`.
  final double target;

  /// Where the user stood when the goal was set, in the same unit — the best
  /// working weight on the lift, or the latest bodyweight. Progress is
  /// measured from here, so a 95 → 100 kg goal starts empty rather than at
  /// 95%.
  ///
  /// For a bodyweight goal it also says which way is forward: a target below
  /// it is a cut, above it a gain. Null for `frequency`, which starts from
  /// zero every week, and for a lift never trained before.
  final double? startValue;

  /// The day to reach it by, or null for "whenever". Never set on `frequency`
  /// goals, which repeat every week rather than ending.
  final DateTime? deadline;
  final DateTime createdAt;

  /// When the user saw this goal's celebration. Null until then.
  ///
  /// The one piece of reaching a goal that *is* stored, because it is about
  /// the user rather than the log: the celebration shows once, not every time
  /// Home is opened. For a `frequency` goal it is the last week celebrated —
  /// a new week that meets the target earns a new one.
  final DateTime? celebratedAt;

  /// When the goal was put away. Archived goals leave Home and the active
  /// list but keep their history; null while the goal is live.
  final DateTime? archivedAt;
  const Goal({
    required this.id,
    required this.kind,
    this.exerciseId,
    required this.target,
    this.startValue,
    this.deadline,
    required this.createdAt,
    this.celebratedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    map['target'] = Variable<double>(target);
    if (!nullToAbsent || startValue != null) {
      map['start_value'] = Variable<double>(startValue);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || celebratedAt != null) {
      map['celebrated_at'] = Variable<DateTime>(celebratedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      kind: Value(kind),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      target: Value(target),
      startValue: startValue == null && nullToAbsent
          ? const Value.absent()
          : Value(startValue),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      createdAt: Value(createdAt),
      celebratedAt: celebratedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(celebratedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      target: serializer.fromJson<double>(json['target']),
      startValue: serializer.fromJson<double?>(json['startValue']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      celebratedAt: serializer.fromJson<DateTime?>(json['celebratedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'target': serializer.toJson<double>(target),
      'startValue': serializer.toJson<double?>(startValue),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'celebratedAt': serializer.toJson<DateTime?>(celebratedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Goal copyWith({
    int? id,
    String? kind,
    Value<String?> exerciseId = const Value.absent(),
    double? target,
    Value<double?> startValue = const Value.absent(),
    Value<DateTime?> deadline = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> celebratedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    target: target ?? this.target,
    startValue: startValue.present ? startValue.value : this.startValue,
    deadline: deadline.present ? deadline.value : this.deadline,
    createdAt: createdAt ?? this.createdAt,
    celebratedAt: celebratedAt.present ? celebratedAt.value : this.celebratedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      target: data.target.present ? data.target.value : this.target,
      startValue: data.startValue.present
          ? data.startValue.value
          : this.startValue,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      celebratedAt: data.celebratedAt.present
          ? data.celebratedAt.value
          : this.celebratedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('target: $target, ')
          ..write('startValue: $startValue, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('celebratedAt: $celebratedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    exerciseId,
    target,
    startValue,
    deadline,
    createdAt,
    celebratedAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.exerciseId == this.exerciseId &&
          other.target == this.target &&
          other.startValue == this.startValue &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt &&
          other.celebratedAt == this.celebratedAt &&
          other.archivedAt == this.archivedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String?> exerciseId;
  final Value<double> target;
  final Value<double?> startValue;
  final Value<DateTime?> deadline;
  final Value<DateTime> createdAt;
  final Value<DateTime?> celebratedAt;
  final Value<DateTime?> archivedAt;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.target = const Value.absent(),
    this.startValue = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.celebratedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.exerciseId = const Value.absent(),
    required double target,
    this.startValue = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.celebratedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : kind = Value(kind),
       target = Value(target);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? exerciseId,
    Expression<double>? target,
    Expression<double>? startValue,
    Expression<DateTime>? deadline,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? celebratedAt,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (target != null) 'target': target,
      if (startValue != null) 'start_value': startValue,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (celebratedAt != null) 'celebrated_at': celebratedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String?>? exerciseId,
    Value<double>? target,
    Value<double?>? startValue,
    Value<DateTime?>? deadline,
    Value<DateTime>? createdAt,
    Value<DateTime?>? celebratedAt,
    Value<DateTime?>? archivedAt,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      exerciseId: exerciseId ?? this.exerciseId,
      target: target ?? this.target,
      startValue: startValue ?? this.startValue,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      celebratedAt: celebratedAt ?? this.celebratedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (target.present) {
      map['target'] = Variable<double>(target.value);
    }
    if (startValue.present) {
      map['start_value'] = Variable<double>(startValue.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (celebratedAt.present) {
      map['celebrated_at'] = Variable<DateTime>(celebratedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('target: $target, ')
          ..write('startValue: $startValue, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('celebratedAt: $celebratedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $WorkoutDaysTable workoutDays = $WorkoutDaysTable(this);
  late final $WorkoutDaySchedulesTable workoutDaySchedules =
      $WorkoutDaySchedulesTable(this);
  late final $WorkoutExercisesTable workoutExercises = $WorkoutExercisesTable(
    this,
  );
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $LoggedSetsTable loggedSets = $LoggedSetsTable(this);
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $CalorieEntriesTable calorieEntries = $CalorieEntriesTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final $ProgressPhotosTable progressPhotos = $ProgressPhotosTable(this);
  late final $TestedOneRmsTable testedOneRms = $TestedOneRmsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $RestTimersTable restTimers = $RestTimersTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    splits,
    workoutDays,
    workoutDaySchedules,
    workoutExercises,
    workoutSessions,
    loggedSets,
    sessionExercises,
    calorieEntries,
    bodyMeasurements,
    progressPhotos,
    testedOneRms,
    appSettings,
    restTimers,
    goals,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'splits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_day_schedules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('logged_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exercises', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tested_one_rms', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rest_timers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('goals', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String name,
      required List<String> muscleIds,
      Value<String?> gifPath,
      Value<bool> isPlateLoaded,
      Value<double?> barWeightKg,
      Value<bool> isCustom,
      Value<bool> isArchived,
      Value<String> equipment,
      Value<bool> isTimed,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<List<String>> muscleIds,
      Value<String?> gifPath,
      Value<bool> isPlateLoaded,
      Value<double?> barWeightKg,
      Value<bool> isCustom,
      Value<bool> isArchived,
      Value<String> equipment,
      Value<bool> isTimed,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>>
  _workoutExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutExercises,
    aliasName: 'exercises__id__workout_exercises__exercise_id',
  );

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoggedSetsTable, List<LoggedSet>>
  _loggedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loggedSets,
    aliasName: 'exercises__id__logged_sets__exercise_id',
  );

  $$LoggedSetsTableProcessedTableManager get loggedSetsRefs {
    final manager = $$LoggedSetsTableTableManager(
      $_db,
      $_db.loggedSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loggedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: 'exercises__id__session_exercises__exercise_id',
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TestedOneRmsTable, List<TestedOneRm>>
  _testedOneRmsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.testedOneRms,
    aliasName: 'exercises__id__tested_one_rms__exercise_id',
  );

  $$TestedOneRmsTableProcessedTableManager get testedOneRmsRefs {
    final manager = $$TestedOneRmsTableTableManager(
      $_db,
      $_db.testedOneRms,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_testedOneRmsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RestTimersTable, List<RestTimer>>
  _restTimersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.restTimers,
    aliasName: 'exercises__id__rest_timers__exercise_id',
  );

  $$RestTimersTableProcessedTableManager get restTimersRefs {
    final manager = $$RestTimersTableTableManager(
      $_db,
      $_db.restTimers,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_restTimersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.goals,
    aliasName: 'exercises__id__goals__exercise_id',
  );

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get muscleIds => $composableBuilder(
    column: $table.muscleIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get gifPath => $composableBuilder(
    column: $table.gifPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlateLoaded => $composableBuilder(
    column: $table.isPlateLoaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get barWeightKg => $composableBuilder(
    column: $table.barWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTimed => $composableBuilder(
    column: $table.isTimed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workoutExercisesRefs(
    Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f,
  ) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loggedSetsRefs(
    Expression<bool> Function($$LoggedSetsTableFilterComposer f) f,
  ) {
    final $$LoggedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableFilterComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> testedOneRmsRefs(
    Expression<bool> Function($$TestedOneRmsTableFilterComposer f) f,
  ) {
    final $$TestedOneRmsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.testedOneRms,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestedOneRmsTableFilterComposer(
            $db: $db,
            $table: $db.testedOneRms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> restTimersRefs(
    Expression<bool> Function($$RestTimersTableFilterComposer f) f,
  ) {
    final $$RestTimersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.restTimers,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestTimersTableFilterComposer(
            $db: $db,
            $table: $db.restTimers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalsRefs(
    Expression<bool> Function($$GoalsTableFilterComposer f) f,
  ) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleIds => $composableBuilder(
    column: $table.muscleIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gifPath => $composableBuilder(
    column: $table.gifPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlateLoaded => $composableBuilder(
    column: $table.isPlateLoaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get barWeightKg => $composableBuilder(
    column: $table.barWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTimed => $composableBuilder(
    column: $table.isTimed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get muscleIds =>
      $composableBuilder(column: $table.muscleIds, builder: (column) => column);

  GeneratedColumn<String> get gifPath =>
      $composableBuilder(column: $table.gifPath, builder: (column) => column);

  GeneratedColumn<bool> get isPlateLoaded => $composableBuilder(
    column: $table.isPlateLoaded,
    builder: (column) => column,
  );

  GeneratedColumn<double> get barWeightKg => $composableBuilder(
    column: $table.barWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<bool> get isTimed =>
      $composableBuilder(column: $table.isTimed, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loggedSetsRefs<T extends Object>(
    Expression<T> Function($$LoggedSetsTableAnnotationComposer a) f,
  ) {
    final $$LoggedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> testedOneRmsRefs<T extends Object>(
    Expression<T> Function($$TestedOneRmsTableAnnotationComposer a) f,
  ) {
    final $$TestedOneRmsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.testedOneRms,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestedOneRmsTableAnnotationComposer(
            $db: $db,
            $table: $db.testedOneRms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> restTimersRefs<T extends Object>(
    Expression<T> Function($$RestTimersTableAnnotationComposer a) f,
  ) {
    final $$RestTimersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.restTimers,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestTimersTableAnnotationComposer(
            $db: $db,
            $table: $db.restTimers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
    Expression<T> Function($$GoalsTableAnnotationComposer a) f,
  ) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool workoutExercisesRefs,
            bool loggedSetsRefs,
            bool sessionExercisesRefs,
            bool testedOneRmsRefs,
            bool restTimersRefs,
            bool goalsRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<String>> muscleIds = const Value.absent(),
                Value<String?> gifPath = const Value.absent(),
                Value<bool> isPlateLoaded = const Value.absent(),
                Value<double?> barWeightKg = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<bool> isTimed = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                muscleIds: muscleIds,
                gifPath: gifPath,
                isPlateLoaded: isPlateLoaded,
                barWeightKg: barWeightKg,
                isCustom: isCustom,
                isArchived: isArchived,
                equipment: equipment,
                isTimed: isTimed,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required List<String> muscleIds,
                Value<String?> gifPath = const Value.absent(),
                Value<bool> isPlateLoaded = const Value.absent(),
                Value<double?> barWeightKg = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<bool> isTimed = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                muscleIds: muscleIds,
                gifPath: gifPath,
                isPlateLoaded: isPlateLoaded,
                barWeightKg: barWeightKg,
                isCustom: isCustom,
                isArchived: isArchived,
                equipment: equipment,
                isTimed: isTimed,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workoutExercisesRefs = false,
                loggedSetsRefs = false,
                sessionExercisesRefs = false,
                testedOneRmsRefs = false,
                restTimersRefs = false,
                goalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutExercisesRefs) db.workoutExercises,
                    if (loggedSetsRefs) db.loggedSets,
                    if (sessionExercisesRefs) db.sessionExercises,
                    if (testedOneRmsRefs) db.testedOneRms,
                    if (restTimersRefs) db.restTimers,
                    if (goalsRefs) db.goals,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WorkoutExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loggedSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          LoggedSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._loggedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).loggedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          SessionExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._sessionExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (testedOneRmsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          TestedOneRm
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._testedOneRmsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).testedOneRmsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (restTimersRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          RestTimer
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._restTimersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).restTimersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          Goal
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._goalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).goalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool workoutExercisesRefs,
        bool loggedSetsRefs,
        bool sessionExercisesRefs,
        bool testedOneRmsRefs,
        bool restTimersRefs,
        bool goalsRefs,
      })
    >;
typedef $$SplitsTableCreateCompanionBuilder =
    SplitsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> position,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int?> blockWeeks,
      Value<double?> deloadPercent,
      Value<DateTime?> blockStartedAt,
    });
typedef $$SplitsTableUpdateCompanionBuilder =
    SplitsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> position,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int?> blockWeeks,
      Value<double?> deloadPercent,
      Value<DateTime?> blockStartedAt,
    });

final class $$SplitsTableReferences
    extends BaseReferences<_$AppDatabase, $SplitsTable, Split> {
  $$SplitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutDaysTable, List<WorkoutDay>>
  _workoutDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutDays,
    aliasName: 'splits__id__workout_days__split_id',
  );

  $$WorkoutDaysTableProcessedTableManager get workoutDaysRefs {
    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SplitsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockWeeks => $composableBuilder(
    column: $table.blockWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deloadPercent => $composableBuilder(
    column: $table.deloadPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get blockStartedAt => $composableBuilder(
    column: $table.blockStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workoutDaysRefs(
    Expression<bool> Function($$WorkoutDaysTableFilterComposer f) f,
  ) {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.splitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockWeeks => $composableBuilder(
    column: $table.blockWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deloadPercent => $composableBuilder(
    column: $table.deloadPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get blockStartedAt => $composableBuilder(
    column: $table.blockStartedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get blockWeeks => $composableBuilder(
    column: $table.blockWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deloadPercent => $composableBuilder(
    column: $table.deloadPercent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get blockStartedAt => $composableBuilder(
    column: $table.blockStartedAt,
    builder: (column) => column,
  );

  Expression<T> workoutDaysRefs<T extends Object>(
    Expression<T> Function($$WorkoutDaysTableAnnotationComposer a) f,
  ) {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.splitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SplitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitsTable,
          Split,
          $$SplitsTableFilterComposer,
          $$SplitsTableOrderingComposer,
          $$SplitsTableAnnotationComposer,
          $$SplitsTableCreateCompanionBuilder,
          $$SplitsTableUpdateCompanionBuilder,
          (Split, $$SplitsTableReferences),
          Split,
          PrefetchHooks Function({bool workoutDaysRefs})
        > {
  $$SplitsTableTableManager(_$AppDatabase db, $SplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> blockWeeks = const Value.absent(),
                Value<double?> deloadPercent = const Value.absent(),
                Value<DateTime?> blockStartedAt = const Value.absent(),
              }) => SplitsCompanion(
                id: id,
                name: name,
                position: position,
                isActive: isActive,
                createdAt: createdAt,
                blockWeeks: blockWeeks,
                deloadPercent: deloadPercent,
                blockStartedAt: blockStartedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> position = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> blockWeeks = const Value.absent(),
                Value<double?> deloadPercent = const Value.absent(),
                Value<DateTime?> blockStartedAt = const Value.absent(),
              }) => SplitsCompanion.insert(
                id: id,
                name: name,
                position: position,
                isActive: isActive,
                createdAt: createdAt,
                blockWeeks: blockWeeks,
                deloadPercent: deloadPercent,
                blockStartedAt: blockStartedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SplitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({workoutDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutDaysRefs) db.workoutDays],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutDaysRefs)
                    await $_getPrefetchedData<Split, $SplitsTable, WorkoutDay>(
                      currentTable: table,
                      referencedTable: $$SplitsTableReferences
                          ._workoutDaysRefsTable(db),
                      managerFromTypedResult: (p0) => $$SplitsTableReferences(
                        db,
                        table,
                        p0,
                      ).workoutDaysRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.splitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitsTable,
      Split,
      $$SplitsTableFilterComposer,
      $$SplitsTableOrderingComposer,
      $$SplitsTableAnnotationComposer,
      $$SplitsTableCreateCompanionBuilder,
      $$SplitsTableUpdateCompanionBuilder,
      (Split, $$SplitsTableReferences),
      Split,
      PrefetchHooks Function({bool workoutDaysRefs})
    >;
typedef $$WorkoutDaysTableCreateCompanionBuilder =
    WorkoutDaysCompanion Function({
      Value<int> id,
      required int splitId,
      required String name,
      Value<int> position,
    });
typedef $$WorkoutDaysTableUpdateCompanionBuilder =
    WorkoutDaysCompanion Function({
      Value<int> id,
      Value<int> splitId,
      Value<String> name,
      Value<int> position,
    });

final class $$WorkoutDaysTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutDaysTable, WorkoutDay> {
  $$WorkoutDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SplitsTable _splitIdTable(_$AppDatabase db) =>
      db.splits.createAlias('workout_days__split_id__splits__id');

  $$SplitsTableProcessedTableManager get splitId {
    final $_column = $_itemColumn<int>('split_id')!;

    final manager = $$SplitsTableTableManager(
      $_db,
      $_db.splits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $WorkoutDaySchedulesTable,
    List<WorkoutDaySchedule>
  >
  _workoutDaySchedulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workoutDaySchedules,
        aliasName: 'workout_days__id__workout_day_schedules__day_id',
      );

  $$WorkoutDaySchedulesTableProcessedTableManager get workoutDaySchedulesRefs {
    final manager = $$WorkoutDaySchedulesTableTableManager(
      $_db,
      $_db.workoutDaySchedules,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutDaySchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>>
  _workoutExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutExercises,
    aliasName: 'workout_days__id__workout_exercises__day_id',
  );

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSession>>
  _workoutSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSessions,
    aliasName: 'workout_days__id__workout_sessions__day_id',
  );

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workoutSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutDaysTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SplitsTableFilterComposer get splitId {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitsTableFilterComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutDaySchedulesRefs(
    Expression<bool> Function($$WorkoutDaySchedulesTableFilterComposer f) f,
  ) {
    final $$WorkoutDaySchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutDaySchedules,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaySchedulesTableFilterComposer(
            $db: $db,
            $table: $db.workoutDaySchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutExercisesRefs(
    Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f,
  ) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSessionsRefs(
    Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f,
  ) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SplitsTableOrderingComposer get splitId {
    final $$SplitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitsTableOrderingComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SplitsTableAnnotationComposer get splitId {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: $db.splits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitsTableAnnotationComposer(
            $db: $db,
            $table: $db.splits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutDaySchedulesRefs<T extends Object>(
    Expression<T> Function($$WorkoutDaySchedulesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutDaySchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workoutDaySchedules,
          getReferencedColumn: (t) => t.dayId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkoutDaySchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.workoutDaySchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSessionsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutDaysTable,
          WorkoutDay,
          $$WorkoutDaysTableFilterComposer,
          $$WorkoutDaysTableOrderingComposer,
          $$WorkoutDaysTableAnnotationComposer,
          $$WorkoutDaysTableCreateCompanionBuilder,
          $$WorkoutDaysTableUpdateCompanionBuilder,
          (WorkoutDay, $$WorkoutDaysTableReferences),
          WorkoutDay,
          PrefetchHooks Function({
            bool splitId,
            bool workoutDaySchedulesRefs,
            bool workoutExercisesRefs,
            bool workoutSessionsRefs,
          })
        > {
  $$WorkoutDaysTableTableManager(_$AppDatabase db, $WorkoutDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> splitId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => WorkoutDaysCompanion(
                id: id,
                splitId: splitId,
                name: name,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int splitId,
                required String name,
                Value<int> position = const Value.absent(),
              }) => WorkoutDaysCompanion.insert(
                id: id,
                splitId: splitId,
                name: name,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                splitId = false,
                workoutDaySchedulesRefs = false,
                workoutExercisesRefs = false,
                workoutSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutDaySchedulesRefs) db.workoutDaySchedules,
                    if (workoutExercisesRefs) db.workoutExercises,
                    if (workoutSessionsRefs) db.workoutSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (splitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.splitId,
                                    referencedTable:
                                        $$WorkoutDaysTableReferences
                                            ._splitIdTable(db),
                                    referencedColumn:
                                        $$WorkoutDaysTableReferences
                                            ._splitIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutDaySchedulesRefs)
                        await $_getPrefetchedData<
                          WorkoutDay,
                          $WorkoutDaysTable,
                          WorkoutDaySchedule
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutDaysTableReferences
                              ._workoutDaySchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutDaySchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutExercisesRefs)
                        await $_getPrefetchedData<
                          WorkoutDay,
                          $WorkoutDaysTable,
                          WorkoutExercise
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutDaysTableReferences
                              ._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutSessionsRefs)
                        await $_getPrefetchedData<
                          WorkoutDay,
                          $WorkoutDaysTable,
                          WorkoutSession
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutDaysTableReferences
                              ._workoutSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutDaysTable,
      WorkoutDay,
      $$WorkoutDaysTableFilterComposer,
      $$WorkoutDaysTableOrderingComposer,
      $$WorkoutDaysTableAnnotationComposer,
      $$WorkoutDaysTableCreateCompanionBuilder,
      $$WorkoutDaysTableUpdateCompanionBuilder,
      (WorkoutDay, $$WorkoutDaysTableReferences),
      WorkoutDay,
      PrefetchHooks Function({
        bool splitId,
        bool workoutDaySchedulesRefs,
        bool workoutExercisesRefs,
        bool workoutSessionsRefs,
      })
    >;
typedef $$WorkoutDaySchedulesTableCreateCompanionBuilder =
    WorkoutDaySchedulesCompanion Function({
      required int dayId,
      required int weekday,
      Value<int> rowid,
    });
typedef $$WorkoutDaySchedulesTableUpdateCompanionBuilder =
    WorkoutDaySchedulesCompanion Function({
      Value<int> dayId,
      Value<int> weekday,
      Value<int> rowid,
    });

final class $$WorkoutDaySchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkoutDaySchedulesTable,
          WorkoutDaySchedule
        > {
  $$WorkoutDaySchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) => db.workoutDays
      .createAlias('workout_day_schedules__day_id__workout_days__id');

  $$WorkoutDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutDaySchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDaySchedulesTable> {
  $$WorkoutDaySchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutDaySchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDaySchedulesTable> {
  $$WorkoutDaySchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableOrderingComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutDaySchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDaySchedulesTable> {
  $$WorkoutDaySchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutDaySchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutDaySchedulesTable,
          WorkoutDaySchedule,
          $$WorkoutDaySchedulesTableFilterComposer,
          $$WorkoutDaySchedulesTableOrderingComposer,
          $$WorkoutDaySchedulesTableAnnotationComposer,
          $$WorkoutDaySchedulesTableCreateCompanionBuilder,
          $$WorkoutDaySchedulesTableUpdateCompanionBuilder,
          (WorkoutDaySchedule, $$WorkoutDaySchedulesTableReferences),
          WorkoutDaySchedule,
          PrefetchHooks Function({bool dayId})
        > {
  $$WorkoutDaySchedulesTableTableManager(
    _$AppDatabase db,
    $WorkoutDaySchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaySchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaySchedulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkoutDaySchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> dayId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutDaySchedulesCompanion(
                dayId: dayId,
                weekday: weekday,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int dayId,
                required int weekday,
                Value<int> rowid = const Value.absent(),
              }) => WorkoutDaySchedulesCompanion.insert(
                dayId: dayId,
                weekday: weekday,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutDaySchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayId,
                                referencedTable:
                                    $$WorkoutDaySchedulesTableReferences
                                        ._dayIdTable(db),
                                referencedColumn:
                                    $$WorkoutDaySchedulesTableReferences
                                        ._dayIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutDaySchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutDaySchedulesTable,
      WorkoutDaySchedule,
      $$WorkoutDaySchedulesTableFilterComposer,
      $$WorkoutDaySchedulesTableOrderingComposer,
      $$WorkoutDaySchedulesTableAnnotationComposer,
      $$WorkoutDaySchedulesTableCreateCompanionBuilder,
      $$WorkoutDaySchedulesTableUpdateCompanionBuilder,
      (WorkoutDaySchedule, $$WorkoutDaySchedulesTableReferences),
      WorkoutDaySchedule,
      PrefetchHooks Function({bool dayId})
    >;
typedef $$WorkoutExercisesTableCreateCompanionBuilder =
    WorkoutExercisesCompanion Function({
      Value<int> id,
      required int dayId,
      required String exerciseId,
      Value<int> position,
      Value<int> defaultSets,
      Value<int> warmupSets,
      Value<int> defaultReps,
      Value<int?> defaultRepsMax,
      Value<int?> supersetGroup,
      Value<double?> targetPercent,
    });
typedef $$WorkoutExercisesTableUpdateCompanionBuilder =
    WorkoutExercisesCompanion Function({
      Value<int> id,
      Value<int> dayId,
      Value<String> exerciseId,
      Value<int> position,
      Value<int> defaultSets,
      Value<int> warmupSets,
      Value<int> defaultReps,
      Value<int?> defaultRepsMax,
      Value<int?> supersetGroup,
      Value<double?> targetPercent,
    });

final class $$WorkoutExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutExercisesTable, WorkoutExercise> {
  $$WorkoutExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias('workout_exercises__day_id__workout_days__id');

  $$WorkoutDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('workout_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: 'workout_exercises__id__session_exercises__workout_exercise_id',
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.workoutExerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultSets => $composableBuilder(
    column: $table.defaultSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultReps => $composableBuilder(
    column: $table.defaultReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultRepsMax => $composableBuilder(
    column: $table.defaultRepsMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPercent => $composableBuilder(
    column: $table.targetPercent,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.workoutExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultSets => $composableBuilder(
    column: $table.defaultSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultReps => $composableBuilder(
    column: $table.defaultReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultRepsMax => $composableBuilder(
    column: $table.defaultRepsMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPercent => $composableBuilder(
    column: $table.targetPercent,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableOrderingComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get defaultSets => $composableBuilder(
    column: $table.defaultSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultReps => $composableBuilder(
    column: $table.defaultReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultRepsMax => $composableBuilder(
    column: $table.defaultRepsMax,
    builder: (column) => column,
  );

  GeneratedColumn<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetPercent => $composableBuilder(
    column: $table.targetPercent,
    builder: (column) => column,
  );

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.workoutExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutExercisesTable,
          WorkoutExercise,
          $$WorkoutExercisesTableFilterComposer,
          $$WorkoutExercisesTableOrderingComposer,
          $$WorkoutExercisesTableAnnotationComposer,
          $$WorkoutExercisesTableCreateCompanionBuilder,
          $$WorkoutExercisesTableUpdateCompanionBuilder,
          (WorkoutExercise, $$WorkoutExercisesTableReferences),
          WorkoutExercise,
          PrefetchHooks Function({
            bool dayId,
            bool exerciseId,
            bool sessionExercisesRefs,
          })
        > {
  $$WorkoutExercisesTableTableManager(
    _$AppDatabase db,
    $WorkoutExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> defaultSets = const Value.absent(),
                Value<int> warmupSets = const Value.absent(),
                Value<int> defaultReps = const Value.absent(),
                Value<int?> defaultRepsMax = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<double?> targetPercent = const Value.absent(),
              }) => WorkoutExercisesCompanion(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                position: position,
                defaultSets: defaultSets,
                warmupSets: warmupSets,
                defaultReps: defaultReps,
                defaultRepsMax: defaultRepsMax,
                supersetGroup: supersetGroup,
                targetPercent: targetPercent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayId,
                required String exerciseId,
                Value<int> position = const Value.absent(),
                Value<int> defaultSets = const Value.absent(),
                Value<int> warmupSets = const Value.absent(),
                Value<int> defaultReps = const Value.absent(),
                Value<int?> defaultRepsMax = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<double?> targetPercent = const Value.absent(),
              }) => WorkoutExercisesCompanion.insert(
                id: id,
                dayId: dayId,
                exerciseId: exerciseId,
                position: position,
                defaultSets: defaultSets,
                warmupSets: warmupSets,
                defaultReps: defaultReps,
                defaultRepsMax: defaultRepsMax,
                supersetGroup: supersetGroup,
                targetPercent: targetPercent,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dayId = false,
                exerciseId = false,
                sessionExercisesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionExercisesRefs) db.sessionExercises,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (dayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayId,
                                    referencedTable:
                                        $$WorkoutExercisesTableReferences
                                            ._dayIdTable(db),
                                    referencedColumn:
                                        $$WorkoutExercisesTableReferences
                                            ._dayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (exerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseId,
                                    referencedTable:
                                        $$WorkoutExercisesTableReferences
                                            ._exerciseIdTable(db),
                                    referencedColumn:
                                        $$WorkoutExercisesTableReferences
                                            ._exerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionExercisesRefs)
                        await $_getPrefetchedData<
                          WorkoutExercise,
                          $WorkoutExercisesTable,
                          SessionExercise
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutExercisesTableReferences
                              ._sessionExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutExercisesTable,
      WorkoutExercise,
      $$WorkoutExercisesTableFilterComposer,
      $$WorkoutExercisesTableOrderingComposer,
      $$WorkoutExercisesTableAnnotationComposer,
      $$WorkoutExercisesTableCreateCompanionBuilder,
      $$WorkoutExercisesTableUpdateCompanionBuilder,
      (WorkoutExercise, $$WorkoutExercisesTableReferences),
      WorkoutExercise,
      PrefetchHooks Function({
        bool dayId,
        bool exerciseId,
        bool sessionExercisesRefs,
      })
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<int?> dayId,
      required String name,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<int?> dayId,
      Value<String> name,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias('workout_sessions__day_id__workout_days__id');

  $$WorkoutDaysTableProcessedTableManager? get dayId {
    final $_column = $_itemColumn<int>('day_id');
    if ($_column == null) return null;
    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoggedSetsTable, List<LoggedSet>>
  _loggedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loggedSets,
    aliasName: 'workout_sessions__id__logged_sets__session_id',
  );

  $$LoggedSetsTableProcessedTableManager get loggedSetsRefs {
    final manager = $$LoggedSetsTableTableManager(
      $_db,
      $_db.loggedSets,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_loggedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: 'workout_sessions__id__session_exercises__session_id',
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> loggedSetsRefs(
    Expression<bool> Function($$LoggedSetsTableFilterComposer f) f,
  ) {
    final $$LoggedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableFilterComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableOrderingComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> loggedSetsRefs<T extends Object>(
    Expression<T> Function($$LoggedSetsTableAnnotationComposer a) f,
  ) {
    final $$LoggedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({
            bool dayId,
            bool loggedSetsRefs,
            bool sessionExercisesRefs,
          })
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> dayId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                dayId: dayId,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> dayId = const Value.absent(),
                required String name,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                dayId: dayId,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dayId = false,
                loggedSetsRefs = false,
                sessionExercisesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (loggedSetsRefs) db.loggedSets,
                    if (sessionExercisesRefs) db.sessionExercises,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (dayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayId,
                                    referencedTable:
                                        $$WorkoutSessionsTableReferences
                                            ._dayIdTable(db),
                                    referencedColumn:
                                        $$WorkoutSessionsTableReferences
                                            ._dayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loggedSetsRefs)
                        await $_getPrefetchedData<
                          WorkoutSession,
                          $WorkoutSessionsTable,
                          LoggedSet
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutSessionsTableReferences
                              ._loggedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).loggedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionExercisesRefs)
                        await $_getPrefetchedData<
                          WorkoutSession,
                          $WorkoutSessionsTable,
                          SessionExercise
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutSessionsTableReferences
                              ._sessionExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({
        bool dayId,
        bool loggedSetsRefs,
        bool sessionExercisesRefs,
      })
    >;
typedef $$LoggedSetsTableCreateCompanionBuilder =
    LoggedSetsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String exerciseId,
      required int setNumber,
      Value<double> weight,
      Value<int> reps,
      Value<int?> seconds,
      Value<String> setType,
      Value<double?> rpe,
      Value<int?> rir,
    });
typedef $$LoggedSetsTableUpdateCompanionBuilder =
    LoggedSetsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> exerciseId,
      Value<int> setNumber,
      Value<double> weight,
      Value<int> reps,
      Value<int?> seconds,
      Value<String> setType,
      Value<double?> rpe,
      Value<int?> rir,
    });

final class $$LoggedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $LoggedSetsTable, LoggedSet> {
  $$LoggedSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .workoutSessions
      .createAlias('logged_sets__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('logged_sets__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoggedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoggedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoggedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoggedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoggedSetsTable,
          LoggedSet,
          $$LoggedSetsTableFilterComposer,
          $$LoggedSetsTableOrderingComposer,
          $$LoggedSetsTableAnnotationComposer,
          $$LoggedSetsTableCreateCompanionBuilder,
          $$LoggedSetsTableUpdateCompanionBuilder,
          (LoggedSet, $$LoggedSetsTableReferences),
          LoggedSet,
          PrefetchHooks Function({bool sessionId, bool exerciseId})
        > {
  $$LoggedSetsTableTableManager(_$AppDatabase db, $LoggedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoggedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoggedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoggedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int?> seconds = const Value.absent(),
                Value<String> setType = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<int?> rir = const Value.absent(),
              }) => LoggedSetsCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                weight: weight,
                reps: reps,
                seconds: seconds,
                setType: setType,
                rpe: rpe,
                rir: rir,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String exerciseId,
                required int setNumber,
                Value<double> weight = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int?> seconds = const Value.absent(),
                Value<String> setType = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<int?> rir = const Value.absent(),
              }) => LoggedSetsCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                weight: weight,
                reps: reps,
                seconds: seconds,
                setType: setType,
                rpe: rpe,
                rir: rir,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoggedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$LoggedSetsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$LoggedSetsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$LoggedSetsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$LoggedSetsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LoggedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoggedSetsTable,
      LoggedSet,
      $$LoggedSetsTableFilterComposer,
      $$LoggedSetsTableOrderingComposer,
      $$LoggedSetsTableAnnotationComposer,
      $$LoggedSetsTableCreateCompanionBuilder,
      $$LoggedSetsTableUpdateCompanionBuilder,
      (LoggedSet, $$LoggedSetsTableReferences),
      LoggedSet,
      PrefetchHooks Function({bool sessionId, bool exerciseId})
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String exerciseId,
      Value<int> position,
      Value<int?> workoutExerciseId,
      Value<int?> supersetGroup,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> exerciseId,
      Value<int> position,
      Value<int?> workoutExerciseId,
      Value<int?> supersetGroup,
    });

final class $$SessionExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise> {
  $$SessionExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .workoutSessions
      .createAlias('session_exercises__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('session_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkoutExercisesTable _workoutExerciseIdTable(_$AppDatabase db) =>
      db.workoutExercises.createAlias(
        'session_exercises__workout_exercise_id__workout_exercises__id',
      );

  $$WorkoutExercisesTableProcessedTableManager? get workoutExerciseId {
    final $_column = $_itemColumn<int>('workout_exercise_id');
    if ($_column == null) return null;
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableFilterComposer get workoutExerciseId {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableOrderingComposer get workoutExerciseId {
    final $$WorkoutExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableAnnotationComposer get workoutExerciseId {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (SessionExercise, $$SessionExercisesTableReferences),
          SessionExercise,
          PrefetchHooks Function({
            bool sessionId,
            bool exerciseId,
            bool workoutExerciseId,
          })
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> workoutExerciseId = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                workoutExerciseId: workoutExerciseId,
                supersetGroup: supersetGroup,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String exerciseId,
                Value<int> position = const Value.absent(),
                Value<int?> workoutExerciseId = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                workoutExerciseId: workoutExerciseId,
                supersetGroup: supersetGroup,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                exerciseId = false,
                workoutExerciseId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (exerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseId,
                                    referencedTable:
                                        $$SessionExercisesTableReferences
                                            ._exerciseIdTable(db),
                                    referencedColumn:
                                        $$SessionExercisesTableReferences
                                            ._exerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workoutExerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutExerciseId,
                                    referencedTable:
                                        $$SessionExercisesTableReferences
                                            ._workoutExerciseIdTable(db),
                                    referencedColumn:
                                        $$SessionExercisesTableReferences
                                            ._workoutExerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (SessionExercise, $$SessionExercisesTableReferences),
      SessionExercise,
      PrefetchHooks Function({
        bool sessionId,
        bool exerciseId,
        bool workoutExerciseId,
      })
    >;
typedef $$CalorieEntriesTableCreateCompanionBuilder =
    CalorieEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required String name,
      Value<int> calories,
      Value<int> protein,
      Value<int> carbs,
      Value<int> fat,
      Value<DateTime> createdAt,
    });
typedef $$CalorieEntriesTableUpdateCompanionBuilder =
    CalorieEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> name,
      Value<int> calories,
      Value<int> protein,
      Value<int> carbs,
      Value<int> fat,
      Value<DateTime> createdAt,
    });

class $$CalorieEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CalorieEntriesTable> {
  $$CalorieEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalorieEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalorieEntriesTable> {
  $$CalorieEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalorieEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalorieEntriesTable> {
  $$CalorieEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CalorieEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalorieEntriesTable,
          CalorieEntry,
          $$CalorieEntriesTableFilterComposer,
          $$CalorieEntriesTableOrderingComposer,
          $$CalorieEntriesTableAnnotationComposer,
          $$CalorieEntriesTableCreateCompanionBuilder,
          $$CalorieEntriesTableUpdateCompanionBuilder,
          (
            CalorieEntry,
            BaseReferences<_$AppDatabase, $CalorieEntriesTable, CalorieEntry>,
          ),
          CalorieEntry,
          PrefetchHooks Function()
        > {
  $$CalorieEntriesTableTableManager(
    _$AppDatabase db,
    $CalorieEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalorieEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalorieEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalorieEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> fat = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CalorieEntriesCompanion(
                id: id,
                date: date,
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String name,
                Value<int> calories = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> fat = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CalorieEntriesCompanion.insert(
                id: id,
                date: date,
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalorieEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalorieEntriesTable,
      CalorieEntry,
      $$CalorieEntriesTableFilterComposer,
      $$CalorieEntriesTableOrderingComposer,
      $$CalorieEntriesTableAnnotationComposer,
      $$CalorieEntriesTableCreateCompanionBuilder,
      $$CalorieEntriesTableUpdateCompanionBuilder,
      (
        CalorieEntry,
        BaseReferences<_$AppDatabase, $CalorieEntriesTable, CalorieEntry>,
      ),
      CalorieEntry,
      PrefetchHooks Function()
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<double?> weightKg,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> armsCm,
      Value<double?> legsCm,
      Value<DateTime> updatedAt,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double?> weightKg,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> armsCm,
      Value<double?> legsCm,
      Value<DateTime> updatedAt,
    });

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get armsCm => $composableBuilder(
    column: $table.armsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get legsCm => $composableBuilder(
    column: $table.legsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get armsCm => $composableBuilder(
    column: $table.armsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get legsCm => $composableBuilder(
    column: $table.legsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get hipsCm =>
      $composableBuilder(column: $table.hipsCm, builder: (column) => column);

  GeneratedColumn<double> get armsCm =>
      $composableBuilder(column: $table.armsCm, builder: (column) => column);

  GeneratedColumn<double> get legsCm =>
      $composableBuilder(column: $table.legsCm, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (
            BodyMeasurement,
            BaseReferences<
              _$AppDatabase,
              $BodyMeasurementsTable,
              BodyMeasurement
            >,
          ),
          BodyMeasurement,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> armsCm = const Value.absent(),
                Value<double?> legsCm = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                date: date,
                weightKg: weightKg,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                armsCm: armsCm,
                legsCm: legsCm,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<double?> weightKg = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> armsCm = const Value.absent(),
                Value<double?> legsCm = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                date: date,
                weightKg: weightKg,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                armsCm: armsCm,
                legsCm: legsCm,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (
        BodyMeasurement,
        BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>,
      ),
      BodyMeasurement,
      PrefetchHooks Function()
    >;
typedef $$ProgressPhotosTableCreateCompanionBuilder =
    ProgressPhotosCompanion Function({
      Value<int> id,
      required DateTime date,
      required String fileName,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$ProgressPhotosTableUpdateCompanionBuilder =
    ProgressPhotosCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> fileName,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

class $$ProgressPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProgressPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressPhotosTable,
          ProgressPhoto,
          $$ProgressPhotosTableFilterComposer,
          $$ProgressPhotosTableOrderingComposer,
          $$ProgressPhotosTableAnnotationComposer,
          $$ProgressPhotosTableCreateCompanionBuilder,
          $$ProgressPhotosTableUpdateCompanionBuilder,
          (
            ProgressPhoto,
            BaseReferences<_$AppDatabase, $ProgressPhotosTable, ProgressPhoto>,
          ),
          ProgressPhoto,
          PrefetchHooks Function()
        > {
  $$ProgressPhotosTableTableManager(
    _$AppDatabase db,
    $ProgressPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProgressPhotosCompanion(
                id: id,
                date: date,
                fileName: fileName,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String fileName,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProgressPhotosCompanion.insert(
                id: id,
                date: date,
                fileName: fileName,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressPhotosTable,
      ProgressPhoto,
      $$ProgressPhotosTableFilterComposer,
      $$ProgressPhotosTableOrderingComposer,
      $$ProgressPhotosTableAnnotationComposer,
      $$ProgressPhotosTableCreateCompanionBuilder,
      $$ProgressPhotosTableUpdateCompanionBuilder,
      (
        ProgressPhoto,
        BaseReferences<_$AppDatabase, $ProgressPhotosTable, ProgressPhoto>,
      ),
      ProgressPhoto,
      PrefetchHooks Function()
    >;
typedef $$TestedOneRmsTableCreateCompanionBuilder =
    TestedOneRmsCompanion Function({
      required String exerciseId,
      required double weightKg,
      required DateTime testedOn,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TestedOneRmsTableUpdateCompanionBuilder =
    TestedOneRmsCompanion Function({
      Value<String> exerciseId,
      Value<double> weightKg,
      Value<DateTime> testedOn,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TestedOneRmsTableReferences
    extends BaseReferences<_$AppDatabase, $TestedOneRmsTable, TestedOneRm> {
  $$TestedOneRmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('tested_one_rms__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TestedOneRmsTableFilterComposer
    extends Composer<_$AppDatabase, $TestedOneRmsTable> {
  $$TestedOneRmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get testedOn => $composableBuilder(
    column: $table.testedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TestedOneRmsTableOrderingComposer
    extends Composer<_$AppDatabase, $TestedOneRmsTable> {
  $$TestedOneRmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get testedOn => $composableBuilder(
    column: $table.testedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TestedOneRmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TestedOneRmsTable> {
  $$TestedOneRmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get testedOn =>
      $composableBuilder(column: $table.testedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TestedOneRmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TestedOneRmsTable,
          TestedOneRm,
          $$TestedOneRmsTableFilterComposer,
          $$TestedOneRmsTableOrderingComposer,
          $$TestedOneRmsTableAnnotationComposer,
          $$TestedOneRmsTableCreateCompanionBuilder,
          $$TestedOneRmsTableUpdateCompanionBuilder,
          (TestedOneRm, $$TestedOneRmsTableReferences),
          TestedOneRm,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$TestedOneRmsTableTableManager(_$AppDatabase db, $TestedOneRmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestedOneRmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestedOneRmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestedOneRmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> testedOn = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TestedOneRmsCompanion(
                exerciseId: exerciseId,
                weightKg: weightKg,
                testedOn: testedOn,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required double weightKg,
                required DateTime testedOn,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TestedOneRmsCompanion.insert(
                exerciseId: exerciseId,
                weightKg: weightKg,
                testedOn: testedOn,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TestedOneRmsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$TestedOneRmsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$TestedOneRmsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TestedOneRmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TestedOneRmsTable,
      TestedOneRm,
      $$TestedOneRmsTableFilterComposer,
      $$TestedOneRmsTableOrderingComposer,
      $$TestedOneRmsTableAnnotationComposer,
      $$TestedOneRmsTableCreateCompanionBuilder,
      $$TestedOneRmsTableUpdateCompanionBuilder,
      (TestedOneRm, $$TestedOneRmsTableReferences),
      TestedOneRm,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String name,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                name: name,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                name: name,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$RestTimersTableCreateCompanionBuilder =
    RestTimersCompanion Function({
      required String exerciseId,
      required int seconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RestTimersTableUpdateCompanionBuilder =
    RestTimersCompanion Function({
      Value<String> exerciseId,
      Value<int> seconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RestTimersTableReferences
    extends BaseReferences<_$AppDatabase, $RestTimersTable, RestTimer> {
  $$RestTimersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('rest_timers__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RestTimersTableFilterComposer
    extends Composer<_$AppDatabase, $RestTimersTable> {
  $$RestTimersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RestTimersTableOrderingComposer
    extends Composer<_$AppDatabase, $RestTimersTable> {
  $$RestTimersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RestTimersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestTimersTable> {
  $$RestTimersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RestTimersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestTimersTable,
          RestTimer,
          $$RestTimersTableFilterComposer,
          $$RestTimersTableOrderingComposer,
          $$RestTimersTableAnnotationComposer,
          $$RestTimersTableCreateCompanionBuilder,
          $$RestTimersTableUpdateCompanionBuilder,
          (RestTimer, $$RestTimersTableReferences),
          RestTimer,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$RestTimersTableTableManager(_$AppDatabase db, $RestTimersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestTimersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestTimersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestTimersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestTimersCompanion(
                exerciseId: exerciseId,
                seconds: seconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required int seconds,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestTimersCompanion.insert(
                exerciseId: exerciseId,
                seconds: seconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RestTimersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$RestTimersTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$RestTimersTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RestTimersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestTimersTable,
      RestTimer,
      $$RestTimersTableFilterComposer,
      $$RestTimersTableOrderingComposer,
      $$RestTimersTableAnnotationComposer,
      $$RestTimersTableCreateCompanionBuilder,
      $$RestTimersTableUpdateCompanionBuilder,
      (RestTimer, $$RestTimersTableReferences),
      RestTimer,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required String kind,
      Value<String?> exerciseId,
      required double target,
      Value<double?> startValue,
      Value<DateTime?> deadline,
      Value<DateTime> createdAt,
      Value<DateTime?> celebratedAt,
      Value<DateTime?> archivedAt,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String?> exerciseId,
      Value<double> target,
      Value<double?> startValue,
      Value<DateTime?> deadline,
      Value<DateTime> createdAt,
      Value<DateTime?> celebratedAt,
      Value<DateTime?> archivedAt,
    });

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('goals__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startValue => $composableBuilder(
    column: $table.startValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get celebratedAt => $composableBuilder(
    column: $table.celebratedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startValue => $composableBuilder(
    column: $table.startValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get celebratedAt => $composableBuilder(
    column: $table.celebratedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<double> get startValue => $composableBuilder(
    column: $table.startValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get celebratedAt => $composableBuilder(
    column: $table.celebratedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, $$GoalsTableReferences),
          Goal,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<double> target = const Value.absent(),
                Value<double?> startValue = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> celebratedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                kind: kind,
                exerciseId: exerciseId,
                target: target,
                startValue: startValue,
                deadline: deadline,
                createdAt: createdAt,
                celebratedAt: celebratedAt,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                Value<String?> exerciseId = const Value.absent(),
                required double target,
                Value<double?> startValue = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> celebratedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                kind: kind,
                exerciseId: exerciseId,
                target: target,
                startValue: startValue,
                deadline: deadline,
                createdAt: createdAt,
                celebratedAt: celebratedAt,
                archivedAt: archivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GoalsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$GoalsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$GoalsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, $$GoalsTableReferences),
      Goal,
      PrefetchHooks Function({bool exerciseId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db, _db.splits);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db, _db.workoutDays);
  $$WorkoutDaySchedulesTableTableManager get workoutDaySchedules =>
      $$WorkoutDaySchedulesTableTableManager(_db, _db.workoutDaySchedules);
  $$WorkoutExercisesTableTableManager get workoutExercises =>
      $$WorkoutExercisesTableTableManager(_db, _db.workoutExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$LoggedSetsTableTableManager get loggedSets =>
      $$LoggedSetsTableTableManager(_db, _db.loggedSets);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$CalorieEntriesTableTableManager get calorieEntries =>
      $$CalorieEntriesTableTableManager(_db, _db.calorieEntries);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$ProgressPhotosTableTableManager get progressPhotos =>
      $$ProgressPhotosTableTableManager(_db, _db.progressPhotos);
  $$TestedOneRmsTableTableManager get testedOneRms =>
      $$TestedOneRmsTableTableManager(_db, _db.testedOneRms);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$RestTimersTableTableManager get restTimers =>
      $$RestTimersTableTableManager(_db, _db.restTimers);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide access to the database. Kept alive for the app's lifetime and
/// closed automatically when the provider is disposed.
///
/// Use it later with: `final db = ref.watch(appDatabaseProvider);`

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// App-wide access to the database. Kept alive for the app's lifetime and
/// closed automatically when the provider is disposed.
///
/// Use it later with: `final db = ref.watch(appDatabaseProvider);`

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// App-wide access to the database. Kept alive for the app's lifetime and
  /// closed automatically when the provider is disposed.
  ///
  /// Use it later with: `final db = ref.watch(appDatabaseProvider);`
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
