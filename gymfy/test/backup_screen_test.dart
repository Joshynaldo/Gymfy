// The backup screen: what it promises, and how a folder for the automatic
// backup is chosen — including the folder Android won't let the app write to.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/backup/data/auto_backup.dart';
import 'package:gymfy/features/backup/screens/backup_screen.dart';
import 'package:gymfy/features/data_export/screens/export_screen.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory temp;
  late ProviderContainer container;

  /// What the folder picker will answer next.
  String? picked;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    temp = Directory.systemTemp.createTempSync('gymfy_backup_screen_test');
    picked = null;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupFolderPickerProvider.overrideWithValue(() async => picked),
        appBackupFolderProvider.overrideWithValue(
          () async => '${temp.path}/AppFolder/Backups',
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    temp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, {Widget? screen}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: screen ?? const BackupScreen()),
      ),
    );
    await settle(tester);
  }

  SettingsRepository settings() => container.read(settingsRepositoryProvider);

  Future<String?> read(WidgetTester tester, String key) =>
      tester.runAsync<String?>(() => settings().readRaw(key));

  testWidgets('says plainly what a backup holds, photos included', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('progress photos'), findsOneWidget);
    expect(find.text('Save backup'), findsOneWidget);
    expect(find.text('Choose backup'), findsOneWidget);
    expect(find.text('No folder chosen'), findsOneWidget);
    expect(find.textContaining('Runs while Gymfy is open'), findsOneWidget);
  });

  testWidgets('turning automatic backup on asks for a folder first', (
    tester,
  ) async {
    picked = '${temp.path}/Documents/Gymfy';
    await pump(tester);

    await tester.tap(find.text('Weekly'));
    await settle(tester);

    expect(await read(tester, autoBackupFolderKey), picked);
    expect(await read(tester, autoBackupModeKey), 'weekly');
    expect(find.text(picked!), findsOneWidget);
  });

  testWidgets('a folder the app cannot write to offers its own instead', (
    tester,
  ) async {
    // A file where a folder should be: nothing can be written inside it.
    final blocker = File('${temp.path}/blocker')..writeAsStringSync('x');
    picked = '${blocker.path}/inside';
    await pump(tester);

    await tester.tap(find.text('Choose'));
    await settle(tester);

    expect(find.text('Gymfy can\'t write there'), findsOneWidget);
    expect(await read(tester, autoBackupFolderKey), isNull);

    await tester.tap(find.text('Use Gymfy\'s folder'));
    await settle(tester);

    expect(
      await read(tester, autoBackupFolderKey),
      '${temp.path}/AppFolder/Backups',
    );
  });

  testWidgets('switching off keeps the folder for next time', (tester) async {
    await tester.runAsync(() async {
      await settings().write(autoBackupFolderKey, temp.path);
      await settings().write(autoBackupModeKey, 'after_workout');
    });
    await pump(tester);

    await tester.tap(find.text('Off'));
    await settle(tester);

    expect(await read(tester, autoBackupModeKey), 'off');
    expect(await read(tester, autoBackupFolderKey), temp.path);
  });

  testWidgets('a failed automatic backup is shown, not hidden', (tester) async {
    await tester.runAsync(() async {
      await settings().write(autoBackupFolderKey, temp.path);
      await settings().write(autoBackupLastErrorKey, 'Permission denied');
    });
    await pump(tester);

    expect(
      find.text('Last automatic backup failed: Permission denied'),
      findsOneWidget,
    );
  });

  testWidgets('will not restore over a workout in progress', (tester) async {
    await tester.runAsync(() async {
      await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
    });
    await pump(tester);

    await tester.tap(find.text('Choose backup'));
    await settle(tester);

    expect(
      find.text('Finish or discard your current workout before restoring.'),
      findsOneWidget,
    );
  });

  testWidgets('the export points the way to a real backup', (tester) async {
    await pump(tester, screen: const ExportScreen());

    expect(find.text('This is a copy, not a backup'), findsOneWidget);
    expect(find.text('Backup & restore'), findsOneWidget);
  });
}

/// Drains real async work (database, file system) a tap kicks off. Inside
/// `testWidgets` the clock is faked, so this steps outside it.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}
