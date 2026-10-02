// The Play Store listing copy, checked against Play's character limits.
//
// Store copy is prose in a markdown file, so nothing else in this project
// would ever notice it drifting. The failure mode is specific and annoying:
// you paste a full description into the Console on submission day and it is
// eleven characters over, so you edit it there, and the file in the repo is
// now not what is published.
//
// Reads `store/play-listing.md` rather than duplicating the text — a copy
// would pass this test while the real listing was over the limit.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Play's limits, per
/// https://support.google.com/googleplay/android-developer/answer/9859455
const _limits = <String, int>{
  'App name': 30,
  'Short description': 80,
  'Full description': 4000,
  'Release notes': 500,
};

void main() {
  late List<({String heading, String body})> blocks;

  setUpAll(() {
    final file = File('store/play-listing.md');
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'the listing copy is the deliverable; without it there is '
          'nothing to submit',
    );
    final text = file.readAsStringSync();

    // Each fenced block is preceded by the nearest `## ` heading above it.
    final found = <({String heading, String body})>[];
    var heading = '';
    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('## ')) {
        heading = line.substring(3).trim();
      } else if (line.trim() == '```') {
        final body = <String>[];
        i++;
        while (i < lines.length && lines[i].trim() != '```') {
          body.add(lines[i]);
          i++;
        }
        found.add((heading: heading, body: body.join('\n')));
      }
    }
    blocks = found;
  });

  test('every limited field is present', () {
    // A missing field is the worse failure: the loop below would simply not
    // check it and the suite would stay green.
    for (final name in _limits.keys) {
      expect(
        blocks.any((b) => b.heading.startsWith(name)),
        isTrue,
        reason: '"$name" has no copy block in store/play-listing.md',
      );
    }
  });

  test('and fits what Play will accept', () {
    for (final name in _limits.keys) {
      final block = blocks.firstWhere((b) => b.heading.startsWith(name));
      expect(
        block.body.length,
        lessThanOrEqualTo(_limits[name]!),
        reason:
            '"$name" is ${block.body.length} characters, '
            '${block.body.length - _limits[name]!} over Play\'s limit',
      );
    }
  });

  test('the app name is not the package name', () {
    // Copy-paste from the manifest is a real mistake and looks terrible on a
    // store page.
    final name = blocks.firstWhere((b) => b.heading.startsWith('App name'));
    expect(name.body, isNot(contains('com.')));
    expect(name.body.trim(), isNotEmpty);
  });

  group('the privacy policy', () {
    test('exists in both the source and the published form', () {
      // Play needs a URL, so the .html is what actually gets published; the
      // .md is what gets edited. Losing either one silently is easy.
      expect(File('store/privacy-policy.md').existsSync(), isTrue);
      expect(File('store/privacy-policy.html').existsSync(), isTrue);
    });

    test('and the copy the website serves has not drifted from it', () {
      // The page exists twice: store/ is where it is written, docs/ is what
      // GitHub Pages actually serves. Two copies of a legal document is
      // exactly the arrangement that ends with the published one being a
      // year out of date, because nothing reads the other.
      final source = File('store/privacy-policy.html');
      final published = File('../docs/privacy-policy.html');
      expect(
        published.existsSync(),
        isTrue,
        reason:
            'the website serves docs/privacy-policy.html; copy it from '
            'store/ rather than deleting this test',
      );
      expect(
        published.readAsStringSync(),
        source.readAsStringSync(),
        reason:
            'docs/privacy-policy.html is a copy of '
            'store/privacy-policy.html — re-copy it after editing',
      );
    });

    test('still claims nothing leaves the device', () {
      // A guard on the claim, not on the wording: if a future version adds
      // analytics or crash reporting, this test is the thing that should stop
      // the old policy going out with it. The Data safety form answers, the
      // store description and this file all rest on the same sentence.
      //
      // The sentence used to be "Nothing you enter into Gymfy ever leaves your
      // phone", which stopped being true once export, backup, review sharing
      // and the watch app existed. It now says nothing leaves unless you send
      // it, and the next test holds it to listing every way you can.
      final policy = File(
        'store/privacy-policy.md',
      ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      expect(
        policy,
        contains('leaves your phone unless you send it somewhere'),
      );
      expect(policy, isNot(contains('ever leaves your phone')));
      expect(policy, contains('No analytics'));
      expect(policy, contains('No crash reporting'));
    });

    test('names every way data can leave the device', () {
      // The policy once counted three ways out and said Gymfy had no
      // backup, while the app could save backups and share a review as a
      // picture. Each feature here hands data to a file or another app.
      // Whitespace folded, so a phrase is found across a line break.
      final policy = File(
        'store/privacy-policy.md',
      ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      for (final feature in const [
        '**Export**',
        '**Backup**',
        '**Share a plan**',
        '**Share a review**',
        '**Send feedback**',
        '**Wear OS watch**',
      ]) {
        expect(policy, contains(feature), reason: feature);
      }
      // The watch's data goes through Google Play services, and without
      // Bluetooth through Google's servers. The policy has to say so rather
      // than imply the phone talks to the watch privately.
      expect(policy, contains("Google routes it through its own servers"));
      expect(policy, contains('end-to-end encrypted'));
      expect(policy, isNot(contains('Three features')));
      expect(policy, isNot(contains('has no backup')));
      // Backups are not encrypted, which is the thing to know about them.
      expect(policy, contains('not encrypted'));
    });

    test('says what the workout notification shows on the lock screen', () {
      final policy = File(
        'store/privacy-policy.md',
      ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      expect(policy, contains('workout notification'));
      expect(policy, contains('lock screen'));
      expect(policy, contains('hide sensitive notification content'));
    });

    test('and the app still has no networking code to contradict it', () {
      // The claim above is only honest while this is true. Checked here
      // rather than trusted, because adding an HTTP call is one line and
      // would make the published policy a false statement.
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (RegExp(
          r'\bHttpClient\b|package:http/|\bWebSocket\b|Socket\.connect',
        ).hasMatch(source)) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'the privacy policy and the Play Data safety form both say '
            'the app cannot transmit anything',
      );
    });
  });

  group('the website and the README', () {
    test('promise no watch button the phone never lets it show', () {
      // The watch shows its logging screen whenever the phone sends a next
      // set — which this phone does for any workout with an exercise in it —
      // and returns before the repeat button is drawn. Repeat only appears
      // beside a phone on an older build, so it is not something to offer.
      final watch = File(
        'android/wear/src/main/kotlin/de/kopten/gymfy/wear/MainActivity.kt',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(
        watch,
        contains('if (state.canLog) {\n        LogSet(state)\n        return'),
        reason: 'if the watch can reach repeat again, this test can go',
      );

      final site = File('../docs/index.html').readAsStringSync();
      final card = RegExp(
        r'<h3>Wear OS companion</h3>\s*<p>(.*?)</p>',
        dotAll: true,
      ).firstMatch(site);
      expect(card, isNotNull, reason: 'the Wear OS card on the website');
      expect(card!.group(1)!.toLowerCase(), isNot(contains('repeat')));

      final readme = File(
        '../README.md',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      final wrist = RegExp(
        r'### On your wrist\s*(.*?)\n\n',
        dotAll: true,
      ).firstMatch(readme);
      expect(wrist, isNotNull, reason: 'the "On your wrist" section');
      expect(wrist!.group(1)!.toLowerCase(), isNot(contains('repeat')));
    });
  });
}
