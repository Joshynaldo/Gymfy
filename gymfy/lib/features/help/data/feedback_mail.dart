import 'dart:io';

import '../../../l10n/l10n.dart';

/// Where feedback goes.
///
/// A `mailto:` link rather than a form or an issue tracker. A form would need a
/// server, which would contradict the one thing the privacy policy gets to say
/// — that nothing leaves the device. A GitHub Issues link would demand an
/// account from someone whose only goal is to report a crash. Mail needs no
/// backend, and the user sees every line before it is sent.
const feedbackAddress = 'gymfy.dev@gmail.com';

/// The app's version, as shown to the user and attached to feedback.
///
/// Hand-maintained rather than read at runtime: that would mean another plugin,
/// and this project has already lost two builds to plugins that pin their own
/// Gradle. `test/feedback_mail_test.dart` fails if this drifts from the version
/// in `pubspec.yaml`, so the copy cannot go stale unnoticed.
const appVersion = '1.0.0';

/// The subject line. Fixed, so filtering the inbox on it actually works — and
/// so it stays English in every language, for the same reason.
const feedbackSubject = 'Gymfy feedback';

/// Builds the `mailto:` link for a feedback mail.
///
/// [platform] and [osVersion] are passed in rather than read from [Platform]
/// so this stays a pure function — the composed body is the part worth testing,
/// and it shouldn't depend on the machine the test runs on.
///
/// The two attached lines are written in [l10n]'s language (English without
/// one): the user reads them before sending and is told they may delete them,
/// which only works if they can read them.
Uri buildFeedbackUri({
  required String platform,
  required String osVersion,
  String version = appVersion,
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? englishLocalizations;
  final device = strings.helpFeedbackMailDevice(
    version,
    platform,
    _shortOsVersion(osVersion),
  );
  final body =
      '\n\n'
      '———\n'
      '$device\n'
      '${strings.helpFeedbackMailNote}\n';

  return Uri(
    scheme: 'mailto',
    path: feedbackAddress,
    // Built by hand instead of via `queryParameters`, which encodes spaces as
    // "+". Mail clients show that literally, so the body would arrive full of
    // plus signs.
    query:
        'subject=${Uri.encodeComponent(feedbackSubject)}'
        '&body=${Uri.encodeComponent(body)}',
  );
}

/// The current device's `mailto:` link.
Uri currentFeedbackUri({AppLocalizations? l10n}) => buildFeedbackUri(
  platform: Platform.operatingSystem,
  osVersion: Platform.operatingSystemVersion,
  l10n: l10n,
);

/// Android reports its version as a whole build banner — release, SDK level,
/// codename, incremental build id. Useful for a bug report, but not as four
/// wrapped lines in a mail the user is about to read. Kept to the first line
/// and clipped.
String _shortOsVersion(String raw) {
  final firstLine = raw.split('\n').first.trim();
  if (firstLine.length <= 60) return firstLine;
  return '${firstLine.substring(0, 60)}…';
}
