// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one rest timer.
///
/// Deliberately app-wide and single: you rest between sets of one exercise at a
/// time, and two countdowns at once would be a bug rather than a feature.
/// Starting a new one replaces whatever was running, notification included.
///
/// Null means no timer is running.
///
/// The countdown is driven from a wall-clock deadline rather than by counting
/// ticks, so a dropped or throttled tick — which is exactly what happens when
/// the screen sleeps mid-set — can't make the timer drift slow.

@ProviderFor(RestTimer)
final restTimerProvider = RestTimerProvider._();

/// The one rest timer.
///
/// Deliberately app-wide and single: you rest between sets of one exercise at a
/// time, and two countdowns at once would be a bug rather than a feature.
/// Starting a new one replaces whatever was running, notification included.
///
/// Null means no timer is running.
///
/// The countdown is driven from a wall-clock deadline rather than by counting
/// ticks, so a dropped or throttled tick — which is exactly what happens when
/// the screen sleeps mid-set — can't make the timer drift slow.
final class RestTimerProvider
    extends $NotifierProvider<RestTimer, RestTimerState?> {
  /// The one rest timer.
  ///
  /// Deliberately app-wide and single: you rest between sets of one exercise at a
  /// time, and two countdowns at once would be a bug rather than a feature.
  /// Starting a new one replaces whatever was running, notification included.
  ///
  /// Null means no timer is running.
  ///
  /// The countdown is driven from a wall-clock deadline rather than by counting
  /// ticks, so a dropped or throttled tick — which is exactly what happens when
  /// the screen sleeps mid-set — can't make the timer drift slow.
  RestTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restTimerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restTimerHash();

  @$internal
  @override
  RestTimer create() => RestTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestTimerState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestTimerState?>(value),
    );
  }
}

String _$restTimerHash() => r'0ebd1869d024180a4e8e97ae37057eca43dd105a';

/// The one rest timer.
///
/// Deliberately app-wide and single: you rest between sets of one exercise at a
/// time, and two countdowns at once would be a bug rather than a feature.
/// Starting a new one replaces whatever was running, notification included.
///
/// Null means no timer is running.
///
/// The countdown is driven from a wall-clock deadline rather than by counting
/// ticks, so a dropped or throttled tick — which is exactly what happens when
/// the screen sleeps mid-set — can't make the timer drift slow.

abstract class _$RestTimer extends $Notifier<RestTimerState?> {
  RestTimerState? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RestTimerState?, RestTimerState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RestTimerState?, RestTimerState?>,
              RestTimerState?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
