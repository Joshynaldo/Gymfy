// The plate calculator screen: what it says for a loadable weight, an
// unloadable one, and a weight lighter than the bar itself.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/plates/screens/plate_calculator_screen.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

import 'support/default_accent.dart';
import 'support/weight_wheel.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // Only the accent is stubbed. This screen is *about* the unit, so
        // `defaultWeightUnitOverride` would pin it to kilograms and quietly
        // make the pounds test meaningless.
        defaultAccentOverride,
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, {double? initialWeight}) async {
    // Taller than the default 800×600 so the result sits on screen without
    // scrolling to it.
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PlateCalculatorScreen(initialWeight: initialWeight),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The loaded total, which the screen draws as three pieces — the word
  /// "Total", the number at display size, and the unit beside it — rather than
  /// one sentence. Asserting the number and the unit separately keeps the
  /// pounds test honest: a conversion bug would still change the number.
  void expectTotal(WidgetTester tester, String weight, String unit) {
    expect(find.text('Total'), findsOneWidget);
    // Read through the key rather than by text: the target wheel is showing
    // the same number, so matching on text alone cannot tell the answer from
    // the question.
    expect(tester.widget<Text>(find.byKey(plateTotalKey)).data, weight);
    expect(find.text(unit), findsWidgets);
  }

  testWidgets('asks for a weight before saying anything', (tester) async {
    await pump(tester);

    expect(find.textContaining('Dial in a target weight'), findsOneWidget);
  });

  testWidgets('shows the plates for a loadable weight', (tester) async {
    await pump(tester, initialWeight: 100);

    // 100 kg on a 20 kg bar is 25 + 15 a side.
    expect(find.text('25 kg × 1'), findsOneWidget);
    expect(find.text('15 kg × 1'), findsOneWidget);
    expectTotal(tester, '100', 'kg');
  });

  testWidgets('counts repeated plates instead of listing them twice', (
    tester,
  ) async {
    await pump(tester, initialWeight: 140);

    expect(find.text('25 kg × 2'), findsOneWidget);
    expect(find.text('10 kg × 1'), findsOneWidget);
  });

  testWidgets('names the bar separately in the breakdown', (tester) async {
    await pump(tester, initialWeight: 100);

    // Forgetting the bar is the commonest mistake, so the total is shown split.
    expect(find.textContaining('Bar 20 + plates 80 kg'), findsOneWidget);
  });

  testWidgets('an empty bar is called that, not left blank', (tester) async {
    await pump(tester, initialWeight: 20);

    expect(find.text('Just the bar'), findsOneWidget);
    expectTotal(tester, '20', 'kg');
  });

  testWidgets('a weight under the bar is explained', (tester) async {
    await pump(tester, initialWeight: 10);

    // Rather than showing a negative plate load.
    expect(find.textContaining('lighter than the bar'), findsOneWidget);
  });

  testWidgets('an unloadable weight says how far short it falls', (
    tester,
  ) async {
    await pump(tester, initialWeight: 61);

    expectTotal(tester, '60', 'kg');
    expect(find.textContaining('1 kg under your target'), findsOneWidget);
  });

  testWidgets('dialling a weight updates the answer', (tester) async {
    await pump(tester);

    await pickWeight(tester, whole: 60);

    expect(find.text('20 kg × 1'), findsOneWidget);
    expectTotal(tester, '60', 'kg');
  });

  testWidgets('the bar can be changed', (tester) async {
    await pump(tester, initialWeight: 60);

    await tester.tap(find.text('15 kg'));
    await tester.runAsync(() => pumpEventQueue());
    await tester.pumpAndSettle();

    // 60 on a 15 kg bar is 22.5 a side: 20 + 2.5.
    expect(find.text('20 kg × 1'), findsOneWidget);
    expect(find.text('2.5 kg × 1'), findsOneWidget);
    expectTotal(tester, '60', 'kg');
  });

  testWidgets('only the plates you own are suggested', (tester) async {
    await container
        .read(settingsRepositoryProvider)
        .write(platesKgSetting, '20,10');
    await pump(tester, initialWeight: 100);

    // Without a 25 or a 15, 100 kg is two 20s a side.
    expect(find.text('20 kg × 2'), findsOneWidget);
    expect(find.text('25 kg × 1'), findsNothing);
  });

  testWidgets('in pounds it uses pound plates and a pound bar', (tester) async {
    await container
        .read(settingsRepositoryProvider)
        .write(weightUnitSetting, 'lbs');
    await pump(tester, initialWeight: 225);

    // Nothing is converted: 225 lb is a 45 lb bar and two 45s a side.
    expect(find.text('45 lbs × 2'), findsOneWidget);
    expectTotal(tester, '225', 'lbs');
    expect(find.textContaining('kg'), findsNothing);
  });
}
