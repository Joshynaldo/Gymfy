// A Health Connect that lives in memory, for tests.

import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';

/// Stands in for [HealthConnectBridge] without a platform channel.
///
/// Behaves like the real thing where it matters: a write under an existing
/// client record id *replaces* the record (that is what makes rewrites
/// harmless), and deleting by client record id removes only those.
class FakeHealthConnect implements HealthConnectBridge {
  HealthConnectAvailability status = HealthConnectAvailability.available;

  /// What is granted. Both by default; tests about permissions clear it.
  Set<String> granted = {writeExercisePermission, readWeightPermission};

  /// What a permission request grants, when one is made.
  Set<String> grantsOnRequest = {writeExercisePermission, readWeightPermission};

  /// The records "in Health Connect", by client record id.
  final sessions = <String, HealthConnectSession>{};

  /// Every write call, in order — to count round trips and chunk sizes.
  final writeCalls = <List<HealthConnectSession>>[];
  final deleteCalls = <List<String>>[];
  final permissionRequests = <Set<String>>[];
  final readWindows = <({DateTime from, DateTime to})>[];

  /// The weigh-ins a read returns (filtered to the window asked for).
  List<HealthConnectWeighIn> weights = [];

  /// When set, every write, delete and read throws this.
  String? failWith;

  int storeOpened = 0;
  int healthConnectOpened = 0;

  /// How often availability or permissions were asked — zero while both
  /// switches are off is the promise.
  int queries = 0;

  /// When set, availability waits for it — the moment before the answer.
  Future<void>? availabilityGate;

  @override
  Future<HealthConnectAvailability> availability() async {
    queries++;
    await availabilityGate;
    return status;
  }

  @override
  Future<Set<String>> grantedPermissions() async {
    queries++;
    return status == HealthConnectAvailability.available ? {...granted} : {};
  }

  @override
  Future<Set<String>> requestPermissions(Set<String> permissions) async {
    permissionRequests.add(permissions);
    granted = {...granted, ...permissions.intersection(grantsOnRequest)};
    return {...granted};
  }

  @override
  Future<void> writeSessions(List<HealthConnectSession> sessions) async {
    if (failWith != null) throw HealthConnectException(failWith!);
    writeCalls.add(sessions);
    for (final session in sessions) {
      this.sessions[session.clientRecordId] = session;
    }
  }

  @override
  Future<void> deleteSessions(List<String> clientRecordIds) async {
    if (failWith != null) throw HealthConnectException(failWith!);
    deleteCalls.add(clientRecordIds);
    clientRecordIds.forEach(sessions.remove);
  }

  @override
  Future<List<HealthConnectWeighIn>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    if (failWith != null) throw HealthConnectException(failWith!);
    readWindows.add((from: from, to: to));
    return [
      for (final w in weights)
        if (!w.time.isBefore(from) && w.time.isBefore(to)) w,
    ];
  }

  @override
  Future<bool> openHealthConnect() async {
    healthConnectOpened++;
    return true;
  }

  @override
  Future<bool> openStore() async {
    storeOpened++;
    return true;
  }
}
