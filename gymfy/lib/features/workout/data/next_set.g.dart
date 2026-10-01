// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_set.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The exercise you picked by hand on the active workout, if you picked one.
///
/// Held by id rather than by index: the running order can be added to,
/// swapped and reordered mid-session, and an index would then point at a
/// different movement. (A lift appears once per session, so the id is
/// enough.)
///
/// A provider rather than widget state so a set logged from the notification
/// or the wrist can move it too — mid-superset that is exactly what has to
/// happen — and so the notification shows the exercise the card shows.
/// Disposed with its last listener, like the screen state it replaced.

@ProviderFor(PickedExercise)
final pickedExerciseProvider = PickedExerciseFamily._();

/// The exercise you picked by hand on the active workout, if you picked one.
///
/// Held by id rather than by index: the running order can be added to,
/// swapped and reordered mid-session, and an index would then point at a
/// different movement. (A lift appears once per session, so the id is
/// enough.)
///
/// A provider rather than widget state so a set logged from the notification
/// or the wrist can move it too — mid-superset that is exactly what has to
/// happen — and so the notification shows the exercise the card shows.
/// Disposed with its last listener, like the screen state it replaced.
final class PickedExerciseProvider
    extends $NotifierProvider<PickedExercise, String?> {
  /// The exercise you picked by hand on the active workout, if you picked one.
  ///
  /// Held by id rather than by index: the running order can be added to,
  /// swapped and reordered mid-session, and an index would then point at a
  /// different movement. (A lift appears once per session, so the id is
  /// enough.)
  ///
  /// A provider rather than widget state so a set logged from the notification
  /// or the wrist can move it too — mid-superset that is exactly what has to
  /// happen — and so the notification shows the exercise the card shows.
  /// Disposed with its last listener, like the screen state it replaced.
  PickedExerciseProvider._({
    required PickedExerciseFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'pickedExerciseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pickedExerciseHash();

  @override
  String toString() {
    return r'pickedExerciseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PickedExercise create() => PickedExercise();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PickedExerciseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pickedExerciseHash() => r'07a58b14056ba33c3de916a14b90b04b22cf643f';

/// The exercise you picked by hand on the active workout, if you picked one.
///
/// Held by id rather than by index: the running order can be added to,
/// swapped and reordered mid-session, and an index would then point at a
/// different movement. (A lift appears once per session, so the id is
/// enough.)
///
/// A provider rather than widget state so a set logged from the notification
/// or the wrist can move it too — mid-superset that is exactly what has to
/// happen — and so the notification shows the exercise the card shows.
/// Disposed with its last listener, like the screen state it replaced.

final class PickedExerciseFamily extends $Family
    with $ClassFamilyOverride<PickedExercise, String?, String?, String?, int> {
  PickedExerciseFamily._()
    : super(
        retry: null,
        name: r'pickedExerciseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The exercise you picked by hand on the active workout, if you picked one.
  ///
  /// Held by id rather than by index: the running order can be added to,
  /// swapped and reordered mid-session, and an index would then point at a
  /// different movement. (A lift appears once per session, so the id is
  /// enough.)
  ///
  /// A provider rather than widget state so a set logged from the notification
  /// or the wrist can move it too — mid-superset that is exactly what has to
  /// happen — and so the notification shows the exercise the card shows.
  /// Disposed with its last listener, like the screen state it replaced.

  PickedExerciseProvider call(int sessionId) =>
      PickedExerciseProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'pickedExerciseProvider';
}

/// The exercise you picked by hand on the active workout, if you picked one.
///
/// Held by id rather than by index: the running order can be added to,
/// swapped and reordered mid-session, and an index would then point at a
/// different movement. (A lift appears once per session, so the id is
/// enough.)
///
/// A provider rather than widget state so a set logged from the notification
/// or the wrist can move it too — mid-superset that is exactly what has to
/// happen — and so the notification shows the exercise the card shows.
/// Disposed with its last listener, like the screen state it replaced.

abstract class _$PickedExercise extends $Notifier<String?> {
  late final _$args = ref.$arg as int;
  int get sessionId => _$args;

  String? build(int sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
