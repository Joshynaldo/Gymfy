import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/l10n.dart';

part 'health_connect_bridge.g.dart';

/// Whether Health Connect can be used on this phone, as the settings screen
/// says it.
enum HealthConnectAvailability {
  /// Not Android, or Android older than 9, or a profile where Health Connect
  /// is switched off. Nothing to install that would help.
  unsupported('Not available on this phone'),

  /// Android 9 to 13 without the Health Connect app.
  notInstalled('Not installed'),

  /// Installed, but older than the version the client library needs.
  needsUpdate('Needs an update'),

  available('Available');

  const HealthConnectAvailability(this.label);

  /// The English wording. On screen use [localizedLabel].
  final String label;

  /// What the settings line says, in the app's language.
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    HealthConnectAvailability.unsupported =>
      l10n.healthConnectAvailabilityUnsupported,
    HealthConnectAvailability.notInstalled =>
      l10n.healthConnectAvailabilityNotInstalled,
    HealthConnectAvailability.needsUpdate =>
      l10n.healthConnectAvailabilityNeedsUpdate,
    HealthConnectAvailability.available =>
      l10n.healthConnectAvailabilityAvailable,
  };

  /// Reads the bridge's answer. Anything unrecognised is [unsupported]: a
  /// feature that writes health data should never switch itself on because a
  /// newer Kotlin side said something this Dart side does not know.
  static HealthConnectAvailability parse(Object? raw) => values.firstWhere(
    (value) => value.name == raw,
    orElse: () => HealthConnectAvailability.unsupported,
  );
}

/// The permission to write exercise sessions — finished workouts.
///
/// Spelled exactly as AndroidManifest.xml declares it; both are pinned by
/// health_connect_test.dart, because a typo here would make Health Connect
/// quietly leave the permission off its screen.
const writeExercisePermission = 'android.permission.health.WRITE_EXERCISE';

/// The permission to read weight records — weigh-ins.
const readWeightPermission = 'android.permission.health.READ_WEIGHT';

/// One finished workout, as Health Connect is told about it.
///
/// Nothing but what the exercise session carries: no sets, weights or notes.
typedef HealthConnectSession = ({
  /// Stable per workout, so writing it again replaces rather than duplicates.
  String clientRecordId,

  /// The workout's name, e.g. "Push A".
  String title,
  DateTime start,
  DateTime end,
});

/// One weight record read from Health Connect.
typedef HealthConnectWeighIn = ({
  /// Health Connect's own id for the record, unique across every app.
  String id,

  /// When the weigh-in happened.
  DateTime time,

  /// The UTC offset it was taken in, in seconds, when the writing app said.
  int? offsetSeconds,
  double kg,
});

/// A Health Connect call that failed, with the reason the platform gave.
class HealthConnectException implements Exception {
  const HealthConnectException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to Health Connect through the hand-written channel in
/// `android/app/src/main/kotlin/de/kopten/gymfy/HealthConnectBridge.kt`.
///
/// A platform channel rather than a pub package, for the same reason as the
/// watch bridge: plugins that pin their own Gradle have cost this project
/// days, and the surface here is a handful of calls. Kotlin moves plain
/// values; every decision about *which* workouts and weigh-ins is made in
/// Dart, where it can be tested.
///
/// Health Connect is on-device IPC. Nothing here — or on the Kotlin side —
/// opens a network connection, and the app has no INTERNET permission.
class HealthConnectBridge {
  const HealthConnectBridge(this._channel);

  final MethodChannel _channel;

  static const channel = MethodChannel('de.kopten.gymfy/health_connect');

  /// Whether this platform has a Health Connect at all.
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether Health Connect can be used right now.
  ///
  /// Never throws: a platform without the channel — iOS, a test — is simply
  /// [HealthConnectAvailability.unsupported].
  Future<HealthConnectAvailability> availability() async {
    if (!supported) return HealthConnectAvailability.unsupported;
    try {
      return HealthConnectAvailability.parse(
        await _channel.invokeMethod<String>('availability'),
      );
    } on PlatformException {
      return HealthConnectAvailability.unsupported;
    } on MissingPluginException {
      return HealthConnectAvailability.unsupported;
    }
  }

  /// The Gymfy permissions Health Connect currently grants.
  ///
  /// Empty when it cannot be asked. Asked fresh every time rather than
  /// remembered: the user can revoke access in Health Connect at any moment,
  /// without Gymfy hearing about it.
  Future<Set<String>> grantedPermissions() async {
    if (!supported) return const {};
    try {
      final granted = await _channel.invokeListMethod<String>(
        'grantedPermissions',
      );
      return {...?granted};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  /// Opens Health Connect's permission screen for [permissions] and returns
  /// everything granted once it closes.
  Future<Set<String>> requestPermissions(Set<String> permissions) async {
    if (!supported) return const {};
    try {
      final granted = await _channel.invokeListMethod<String>(
        'requestPermissions',
        permissions.toList(),
      );
      return {...?granted};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  /// Writes [sessions], replacing any written before under the same ids.
  ///
  /// Throws [HealthConnectException] when Health Connect refuses — unlike the
  /// watch, where a missing wrist is normal, a write that did not happen has
  /// to be known so it can be tried again.
  Future<void> writeSessions(List<HealthConnectSession> sessions) async {
    if (sessions.isEmpty) return;
    await _call('writeSessions', [
      for (final s in sessions)
        {
          'clientRecordId': s.clientRecordId,
          'title': s.title,
          'startMs': s.start.millisecondsSinceEpoch,
          'endMs': s.end.millisecondsSinceEpoch,
        },
    ]);
  }

  /// Deletes sessions Gymfy wrote, by the ids they were written with.
  Future<void> deleteSessions(List<String> clientRecordIds) async {
    if (clientRecordIds.isEmpty) return;
    await _call('deleteSessions', clientRecordIds);
  }

  /// Every weight record from [from] up to [to].
  Future<List<HealthConnectWeighIn>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = await _call('readWeights', {
      'startMs': from.millisecondsSinceEpoch,
      'endMs': to.millisecondsSinceEpoch,
    });
    final records = <HealthConnectWeighIn>[];
    for (final item in raw is List ? raw : const []) {
      if (item is! Map) continue;
      final id = item['id'];
      final timeMs = item['timeMs'];
      final kg = item['kg'];
      // A record missing any of these is not one this app can place on a
      // day; skipping it beats inventing a value.
      if (id is! String || timeMs is! int || kg is! num) continue;
      final offset = item['offsetSeconds'];
      records.add((
        id: id,
        time: DateTime.fromMillisecondsSinceEpoch(timeMs),
        offsetSeconds: offset is int ? offset : null,
        kg: kg.toDouble(),
      ));
    }
    return records;
  }

  /// Opens Health Connect on Gymfy's own page — permissions and the data
  /// Gymfy wrote. False if nothing could be opened.
  Future<bool> openHealthConnect() => _open('openHealthConnect');

  /// Opens the Play Store on Health Connect, to install or update it.
  Future<bool> openStore() => _open('openStore');

  Future<bool> _open(String method) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Object?> _call(String method, Object arguments) async {
    if (!supported) {
      throw const HealthConnectException('Health Connect needs Android');
    }
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw HealthConnectException(error.message ?? error.code);
    } on MissingPluginException {
      throw const HealthConnectException('Health Connect is not available');
    }
  }
}

@Riverpod(keepAlive: true)
HealthConnectBridge healthConnectBridge(Ref ref) =>
    const HealthConnectBridge(HealthConnectBridge.channel);

/// Whether Health Connect can be used, asked once per screen visit.
///
/// Not kept alive: the answer changes behind the app's back — installing
/// Health Connect from the Play Store and coming back is the normal way to
/// fix "not installed" — so the settings panel invalidates it on resume.
@riverpod
Future<HealthConnectAvailability> healthConnectAvailability(Ref ref) =>
    ref.watch(healthConnectBridgeProvider).availability();

/// The Gymfy permissions Health Connect grants right now.
@riverpod
Future<Set<String>> healthConnectGranted(Ref ref) async {
  final availability = await ref.watch(
    healthConnectAvailabilityProvider.future,
  );
  if (availability != HealthConnectAvailability.available) return const {};
  return ref.watch(healthConnectBridgeProvider).grantedPermissions();
}
