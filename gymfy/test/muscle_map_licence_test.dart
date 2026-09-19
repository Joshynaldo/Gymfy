// Guards the two things the muscle-map pack's licence actually constrains.
//
// The body diagrams are generated from a purchased Envato item under a
// Regular License (see assets/musclemap/README.md). Neither constraint is
// visible in the code, and neither would produce a failure anyone would
// notice — the app would build, run and look right while being out of
// licence. That is precisely why they are checked here.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the provenance note exists', () {
    // Everything below is meaningless without the document that says which
    // item this is and who bought it. A repository that ships derived
    // artwork with no record of where it came from is the state this whole
    // exercise was about getting out of.
    final readme = File('assets/musclemap/README.md');
    expect(readme.existsSync(), isTrue);

    final text = readme.readAsStringSync();
    expect(text, contains('39853847'), reason: 'the Envato item ID');
    expect(text, contains('Regular License'));
  });

  test('the raw pack is never bundled into the app', () {
    // Clause 11: an end user must not be able to extract the item and use it
    // separately. The generated diagrams in assets/svg/ are a heavily
    // modified derivative and are fine to ship; the pack in
    // assets/musclemap/source/ is the item itself.
    //
    // Adding `- assets/musclemap/` to pubspec is a one-line change that looks
    // like tidying and would put the original artwork in every APK.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assetLines = pubspec
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.startsWith('- assets/'));

    expect(
      assetLines.where((l) => l.contains('musclemap')),
      isEmpty,
      reason: 'assets/musclemap/ holds the unmodified purchased pack and must '
          'not ship inside the app',
    );

    // Counter-check: the diagrams the app does use are still bundled. A
    // pubspec with no asset lines at all would satisfy the rule above and
    // break the Muscle Map tab.
    expect(assetLines.any((l) => l.contains('assets/svg')), isTrue);
  });

  test('and the diagrams it does ship are present', () {
    for (final name in const [
      'body_front.svg',
      'body_back.svg',
      'body_front_female.svg',
      'body_back_female.svg',
    ]) {
      expect(
        File('assets/svg/$name').existsSync(),
        isTrue,
        reason: '$name is generated, not authored — if it is missing, '
            'regenerate with tool/build_muscle_map.dart',
      );
    }
  });
}
