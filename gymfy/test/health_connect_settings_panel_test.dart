// The Health Connect section of Settings: what it says about availability,
// what each switch asks for, and what happens when Health Connect says no.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/health_connect/data/health_connect_bridge.dart';
import 'package:gymfy/features/health_connect/data/health_connect_sync.dart';
import 'package:gymfy/features/health_connect/widgets/health_connect_settings_panel.dart';
import 'package:gymfy/features/settings/screens/settings_screen.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/fake_health_connect.dart';

void main() {
  late AppDatabase db;
  late FakeHealthConnect health;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    health = FakeHealthConnect()..granted = {};
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        healthConnectBridgeProvider.overrideWithValue(health),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Drains the real database and fake Health Connect work a tap starts.
  /// Several rounds: a switch asks for a permission, then writes a setting,
  /// then the setting's stream rebuilds the panel.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
    }
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HealthConnectSettingsPanel()),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  SwitchListTile switchTile(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));

  Future<String?> setting(WidgetTester tester, String key) =>
      tester.runAsync<String?>(
        () => container.read(settingsRepositoryProvider).readRaw(key),
      );

  testWidgets('without Health Connect it says so and offers to install it', (
    tester,
  ) async {
    health.status = HealthConnectAvailability.notInstalled;
    await pump(tester);

    expect(find.text('Not installed'), findsOneWidget);
    expect(switchTile(tester, 'Write workouts').onChanged, isNull);
    expect(switchTile(tester, 'Read bodyweight').onChanged, isNull);

    await tester.tap(find.text('Install'));
    await settle(tester);
    expect(health.storeOpened, 1);
  });

  testWidgets('on a phone that cannot have it, nothing can be switched on', (
    tester,
  ) async {
    health.status = HealthConnectAvailability.unsupported;
    await pump(tester);

    expect(find.text('Not available on this phone'), findsOneWidget);
    expect(find.text('Install'), findsNothing);
    expect(switchTile(tester, 'Write workouts').onChanged, isNull);
    expect(find.text('Manage in Health Connect'), findsNothing);
  });

  testWidgets('while it is still asking, it says so and offers nothing', (
    tester,
  ) async {
    final answer = Completer<void>();
    health.availabilityGate = answer.future;
    await pump(tester);

    expect(find.text('Checking…'), findsOneWidget);
    expect(find.text('Not available on this phone'), findsNothing);
    expect(switchTile(tester, 'Write workouts').onChanged, isNull);

    answer.complete();
    await settle(tester);
    expect(find.text('Available'), findsOneWidget);
    expect(switchTile(tester, 'Write workouts').onChanged, isNotNull);
  });

  testWidgets('both switches start off', (tester) async {
    await pump(tester);

    expect(find.text('Available'), findsOneWidget);
    expect(switchTile(tester, 'Write workouts').value, isFalse);
    expect(switchTile(tester, 'Read bodyweight').value, isFalse);
    expect(health.permissionRequests, isEmpty);
  });

  testWidgets('turning on writing asks for that permission alone', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Write workouts'));
    await settle(tester);

    expect(health.permissionRequests, [
      {writeExercisePermission},
    ]);
    expect(await setting(tester, healthConnectWriteKey), 'true');
    expect(await setting(tester, healthConnectWriteSinceKey), isNotNull);
    expect(switchTile(tester, 'Write workouts').value, isTrue);
  });

  testWidgets('a refused permission leaves the switch off, and says so', (
    tester,
  ) async {
    health.grantsOnRequest = {};
    await pump(tester);

    await tester.tap(find.text('Write workouts'));
    await settle(tester);

    expect(await setting(tester, healthConnectWriteKey), isNull);
    expect(switchTile(tester, 'Write workouts').value, isFalse);
    expect(
      find.text('Health Connect did not allow Gymfy to write workouts.'),
      findsOneWidget,
    );
  });

  testWidgets('turning on reading imports weigh-ins straight away', (
    tester,
  ) async {
    final today = DateTime.now();
    health.weights = [
      (
        id: 'scale-1',
        // Yesterday morning, not today's: between midnight and seven a
        // weigh-in at 7:00 today is still in the future, and the import
        // rightly reads nothing — which made this test fail every night.
        time: DateTime(today.year, today.month, today.day - 1, 7),
        offsetSeconds: null,
        kg: 80.4,
      ),
    ];
    await pump(tester);

    await tester.tap(find.text('Read bodyweight'));
    await settle(tester);

    expect(health.permissionRequests, [
      {readWeightPermission},
    ]);
    expect(find.text('Added 1 weigh-in to your measurements.'), findsOneWidget);
    final rows = await tester.runAsync(
      () => db.select(db.bodyMeasurements).get(),
    );
    expect(rows!.single.weightKg, 80.4);
  });

  testWidgets('a permission revoked in Health Connect is shown with the fix', (
    tester,
  ) async {
    await tester.runAsync(
      () => container
          .read(settingsRepositoryProvider)
          .write(healthConnectWriteKey, 'true'),
    );
    await pump(tester);

    expect(
      find.text('Health Connect no longer lets Gymfy write workouts'),
      findsOneWidget,
    );
    expect(find.text('Write past workouts'), findsNothing);

    await tester.tap(find.text('Grant'));
    await settle(tester);
    expect(health.permissionRequests.single, contains(writeExercisePermission));
    expect(find.textContaining('no longer lets'), findsNothing);
  });

  testWidgets('past workouts are written only after asking', (tester) async {
    health.granted = {writeExercisePermission};
    await tester.runAsync(() async {
      await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Old push',
              startedAt: Value(DateTime(2026, 1, 5, 18)),
              completedAt: Value(DateTime(2026, 1, 5, 19)),
            ),
          );
      await container.read(healthConnectSyncProvider).setWriteWorkouts(true);
    });
    await pump(tester);

    await tester.tap(find.text('Write past workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Write past workouts?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(health.writeCalls, isEmpty);

    await tester.tap(find.text('Write past workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write'));
    await settle(tester);

    expect(health.sessions.values.single.title, 'Old push');
    expect(find.text('Wrote 1 workout to Health Connect.'), findsOneWidget);
  });

  testWidgets('Health Connect itself is one tap away, to revoke or delete', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Manage in Health Connect'));
    await settle(tester);
    expect(health.healthConnectOpened, 1);
  });

  testWidgets('Settings has the section, last', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await settle(tester);

    await tester.scrollUntilVisible(
      find.byType(HealthConnectSettingsPanel),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    expect(find.text('Health Connect'), findsWidgets);
    expect(
      tester.getTopLeft(find.byType(HealthConnectSettingsPanel)).dy,
      greaterThan(tester.getTopLeft(find.text('Export data')).dy),
    );
  });
}
