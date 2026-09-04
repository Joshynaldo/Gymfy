// The feedback mail link.
//
// There is no crash reporting in this app, so this link is the only path a bug
// has from a user's phone back to the developer. If it composes a broken URI,
// nobody finds out — the mail app just doesn't open, and the report is lost.
//
// The body is worth testing for a second reason: the screen promises that only
// the app version is attached. That promise has to keep matching what is
// actually in the mail.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/help/data/feedback_mail.dart';

void main() {
  group('the mailto link', () {
    final uri = buildFeedbackUri(
      platform: 'android',
      osVersion: '14',
      version: '1.2.3',
    );

    test('addresses the feedback inbox', () {
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'gymfy.dev@gmail.com');
    });

    test('carries a fixed subject, so the inbox can be filtered on it', () {
      expect(uri.queryParameters['subject'], 'Gymfy feedback');
    });

    test('names the app version and platform', () {
      final body = uri.queryParameters['body']!;

      expect(body, contains('Gymfy 1.2.3'));
      expect(body, contains('android 14'));
    });

    test('starts with blank lines, so the cursor lands above the details', () {
      expect(uri.queryParameters['body']!.startsWith('\n\n'), isTrue);
    });

    test('says the attached lines can be deleted', () {
      expect(uri.queryParameters['body'], contains('Delete them'));
    });

    test('encodes spaces as %20, not "+"', () {
      // Mail clients render a "+" literally, which would scatter plus signs
      // through the body the user is about to read.
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.toString(), contains('%20'));
    });

    test('attaches nothing else about the user', () {
      // The screen promises "only the app version is attached". Anything the
      // app knows about the person — their name, their weight — must not be
      // able to reach the body by a later edit.
      final body = uri.queryParameters['body']!.toLowerCase();

      for (final leak in ['kg', 'lbs', 'name', 'weight', 'email']) {
        expect(body, isNot(contains(leak)), reason: 'body mentions "$leak"');
      }
    });

    test('clips a long OS version instead of wrapping the mail', () {
      // Android reports a whole build banner here.
      final long = buildFeedbackUri(
        platform: 'android',
        osVersion: 'A' * 200,
        version: '1.0.0',
      );

      expect(long.queryParameters['body']!.length, lessThan(400));
    });

    test('uses only the first line of a multi-line OS version', () {
      final multi = buildFeedbackUri(
        platform: 'android',
        osVersion: '14\nbuild UP1A.231005.007',
        version: '1.0.0',
      );

      expect(multi.queryParameters['body'], isNot(contains('UP1A')));
    });
  });

  test('the version constant matches pubspec.yaml', () {
    // The constant is hand-maintained so the app needs no plugin to read its
    // own version. This is what stops it going stale: bump pubspec without
    // bumping the constant and every feedback mail reports the wrong build.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(declared, isNotNull, reason: 'no version line in pubspec.yaml');
    expect(appVersion, declared!.group(1));
  });
}
