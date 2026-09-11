// The accent colour survives a restart, and a junk stored value degrades to
// the default instead of theming the app something the picker can't show.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('parseAccentColor', () {
    test('reads back a palette colour', () {
      final raw = AccentPalette.teal.toARGB32().toString();

      expect(parseAccentColor(raw), AccentPalette.teal);
    });

    test('an unset value is not a colour', () {
      expect(parseAccentColor(null), isNull);
    });

    test('junk is not a colour', () {
      expect(parseAccentColor(''), isNull);
      expect(parseAccentColor('blue'), isNull);
      expect(parseAccentColor('#4F8CFF'), isNull);
    });

    test('a colour outside the palette is refused', () {
      // Some colour nobody can pick — an older build, or a hand-edited row.
      // Honouring it would theme the app a colour the picker can't show, and
      // the user would have no way to get back to it after changing.
      final orphan = const Color(0xFF123456).toARGB32().toString();

      expect(parseAccentColor(orphan), isNull);
    });
  });

  group('accentColorProvider', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('starts on the default accent', () {
      expect(container.read(accentColorProvider), AccentPalette.defaultAccent);
    });

    test('a chosen accent is stored and read back', () async {
      // Listen before awaiting: without a listener Riverpod can dispose the
      // stream while it is still loading and the await never completes.
      container.listen(accentColorProvider, (_, _) {});

      await container
          .read(accentColorProvider.notifier)
          .setAccent(AccentPalette.pink);
      await container.read(storedAccentProvider.future);

      expect(container.read(accentColorProvider), AccentPalette.pink);

      // What a restart would read: a fresh container over the same database.
      final restarted = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(restarted.dispose);
      restarted.listen(accentColorProvider, (_, _) {});
      await restarted.read(storedAccentProvider.future);

      expect(restarted.read(accentColorProvider), AccentPalette.pink);
    });

    test(
      'a stored value outside the palette falls back to the default',
      () async {
        await container
            .read(settingsRepositoryProvider)
            .write(accentColorSetting, '999');
        container.listen(accentColorProvider, (_, _) {});
        await container.read(storedAccentProvider.future);

        expect(
          container.read(accentColorProvider),
          AccentPalette.defaultAccent,
        );
      },
    );
  });
}
