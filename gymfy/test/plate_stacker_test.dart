// Building a weight by stacking plates — the reverse of the calculator, used
// when logging a barbell set.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/plates/widgets/plate_stacker.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late List<double> reported;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    reported = [];
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // Only the accent is stubbed: the stacker is unit-sensitive, so pinning
        // the unit would make the pounds test meaningless.
        defaultAccentOverride,
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, {double initialWeight = 20}) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PlateStacker(
              initialWeight: initialWeight,
              onChanged: reported.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps the plate button for [weight]. The buttons show the bare number, and
  /// the running total is the only other place a bare number appears — so the
  /// finder is scoped to the button's own text style by looking it up last.
  Future<void> tapPlate(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(InkWell, label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('starts at the bar with nothing on it', (tester) async {
    await pump(tester);

    expect(find.text('20'), findsWidgets);
    expect(find.text('Just the bar'), findsOneWidget);
    expect(find.textContaining('Bar 20 kg + 0 in plates'), findsOneWidget);
  });

  testWidgets('a plate goes on both sides at once', (tester) async {
    await pump(tester);

    await tapPlate(tester, '10');

    // 20 kg bar + 10 a side = 40, not 30. Plates go on in pairs, and a stacker
    // that added one at a time would report every barbell set light.
    expect(reported.last, 40);
  });

  testWidgets('tapping twice stacks two plates', (tester) async {
    await pump(tester);

    await tapPlate(tester, '20');
    await tapPlate(tester, '20');

    expect(reported.last, 100);
    expect(find.text('×2'), findsOneWidget);
  });

  testWidgets('long-press takes one plate off', (tester) async {
    await pump(tester);
    await tapPlate(tester, '20');
    await tapPlate(tester, '20');

    await tester.longPress(find.widgetWithText(InkWell, '20').last);
    await tester.pumpAndSettle();

    expect(reported.last, 60);
  });

  testWidgets('clear takes the bar back to empty', (tester) async {
    await pump(tester);
    await tapPlate(tester, '25');

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(reported.last, 20);
    expect(find.text('Just the bar'), findsOneWidget);
  });

  testWidgets('an existing weight comes back as the plates that make it', (
    tester,
  ) async {
    // Reopening a logged set should show the bar as it was loaded, not empty.
    await pump(tester, initialWeight: 100);

    expect(find.text('×1'), findsNWidgets(2)); // one 25 and one 15
    expect(find.textContaining('Bar 20 kg + 80 in plates'), findsOneWidget);
  });

  testWidgets('the total is not reported until something changes', (
    tester,
  ) async {
    await pump(tester, initialWeight: 100);

    // The caller already has this weight; re-reporting it on build would make
    // an untouched dialog look edited.
    expect(reported, isEmpty);
  });

  testWidgets('in pounds it stacks pound plates on a pound bar', (
    tester,
  ) async {
    await container
        .read(settingsRepositoryProvider)
        .write(weightUnitSetting, 'lbs');
    await pump(tester, initialWeight: 45);

    await tapPlate(tester, '45');

    // 45 lb bar + 45 a side = 135. Nothing converted anywhere.
    expect(reported.last, 135);
    expect(find.textContaining('Bar 45 lbs'), findsOneWidget);
  });

  testWidgets('only the plates you own are offered', (tester) async {
    await container
        .read(settingsRepositoryProvider)
        .write(platesKgSetting, '20,10');
    await pump(tester);

    expect(find.widgetWithText(InkWell, '20'), findsWidgets);
    expect(find.widgetWithText(InkWell, '25'), findsNothing);
  });
}
