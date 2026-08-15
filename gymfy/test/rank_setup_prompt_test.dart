// The setup prompt: asks only for what's actually missing, explains why it
// wants the lifter's sex, and saves that choice on tap.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/rank_inputs.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/calculator/widgets/rank_setup_prompt.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, RankInputs inputs) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          defaultAccentOverride,
        ],
        child: MaterialApp(
          home: Scaffold(body: RankSetupPrompt(inputs: inputs)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for both when neither is known', (tester) async {
    await pump(tester, (sex: null, bodyweightKg: null, measuredOn: null));

    expect(find.text('Which standards should we use?'), findsOneWidget);
    expect(find.text('Log your bodyweight'), findsOneWidget);
    // The reason is spelled out, not just the question.
    expect(find.textContaining('differ by sex'), findsOneWidget);
  });

  testWidgets('only asks for the bodyweight once sex is known', (tester) async {
    await pump(tester, (
      sex: LifterSex.male,
      bodyweightKg: null,
      measuredOn: null,
    ));

    expect(find.text('Which standards should we use?'), findsNothing);
    expect(find.text('Log your bodyweight'), findsOneWidget);
  });

  testWidgets('only asks for sex once a bodyweight is logged', (tester) async {
    await pump(tester, (
      sex: null,
      bodyweightKg: 82.5,
      measuredOn: DateTime(2026, 7, 20),
    ));

    expect(find.text('Which standards should we use?'), findsOneWidget);
    expect(find.text('Log your bodyweight'), findsNothing);
  });

  testWidgets('picking a sex stores it', (tester) async {
    await pump(tester, (sex: null, bodyweightKg: null, measuredOn: null));

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    final stored = await SettingsRepository(db).readRaw(lifterSexSetting);
    expect(parseLifterSex(stored), LifterSex.female);
  });
}
