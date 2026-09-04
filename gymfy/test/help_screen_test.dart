// The Help screen under More.
//
// The link target is worth a test of its own: it points at a profile page, not
// at a payment page, and that distinction is what keeps the button out of
// App Review's "steering users to outside payment" rule. A future edit that
// quietly repointed it at the tip jar would be an App Store problem, not a
// cosmetic one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/help/data/feedback_mail.dart';
import 'package:gymfy/features/help/screens/help_screen.dart';

import 'support/default_accent.dart';

void main() {
  testWidgets('offers the developer profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: const MaterialApp(home: HelpScreen()),
      ),
    );

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Joshynaldo on GitHub'), findsOneWidget);
    // Marks every outbound row as leaving the app, so no tap is a
    // surprise.
    expect(find.byIcon(Icons.open_in_new), findsNWidgets(3));
  });

  testWidgets('offers a way to send feedback', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: const MaterialApp(home: HelpScreen()),
      ),
    );

    expect(find.text('Send feedback'), findsOneWidget);
    // Feedback is the only route a bug has out of this app — there is no crash
    // reporting — so it sits above the developer link rather than below it.
    final feedback = tester.getTopLeft(find.text('Send feedback')).dy;
    final developer = tester.getTopLeft(find.text('Developer')).dy;
    expect(feedback, lessThan(developer));
  });

  testWidgets('shows the version', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [defaultAccentOverride],
        child: const MaterialApp(home: HelpScreen()),
      ),
    );

    // Worth a row of its own: the first thing anyone answering a bug report
    // asks is which build it happened on, and a user cannot read it off a
    // store listing.
    expect(find.text('Version'), findsOneWidget);
    expect(find.text(appVersion), findsOneWidget);
  });

  group('the link target', () {
    test('is the developer profile, not a payment page', () {
      final uri = Uri.parse(developerGitHub);

      expect(uri.host, 'github.com');
      expect(uri.pathSegments, ['Joshynaldo']);
    });

    test('is https, so the link cannot be tampered with in transit', () {
      expect(Uri.parse(developerGitHub).scheme, 'https');
    });
  });
}
