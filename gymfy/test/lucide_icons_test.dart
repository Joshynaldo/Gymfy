// The vendored Lucide font (lib/shared/widgets/lucide_icons.dart): the icons
// must point at a font the app actually bundles, its licence must travel with
// it, and the package it replaced must not come back with its six unused
// weight fonts.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/widgets/lucide_icons.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('the font is declared and present', () {
    expect(pubspec, contains('family: Lucide'));
    expect(pubspec, contains('asset: assets/fonts/lucide/Lucide.ttf'));
    expect(File('assets/fonts/lucide/Lucide.ttf').existsSync(), isTrue);
  });

  test('every icon draws from it', () {
    for (final icon in [
      LucideIcons.plus,
      LucideIcons.chevronLeft,
      LucideIcons.x,
      LucideIcons.trash2,
    ]) {
      expect(icon.fontFamily, 'Lucide');
      expect(icon.fontPackage, isNull, reason: 'the font is the app\'s own');
    }
  });

  test('its licence travels with it', () async {
    final text = File('assets/fonts/lucide/LICENSE.txt').readAsStringSync();
    expect(text, startsWith('ISC License'));

    registerLucideLicense();
    final entries = await LicenseRegistry.licenses.toList();
    expect(
      entries.any((e) => e.packages.contains('Lucide')),
      isTrue,
      reason: 'a vendored font is not picked up with the package licences',
    );
  });

  test('the lucide_icons_flutter package stays out', () {
    // It ships six stroke-weight fonts besides the one used, and Flutter
    // bundles a dependency's fonts whether the app draws them or not:
    // about 1.4 MB of every download.
    expect(pubspec, isNot(contains('lucide_icons_flutter:')));
  });
}
