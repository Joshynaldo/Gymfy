import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../data/feedback_mail.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_scaffold.dart';
import '../../../app/theme/glass.dart';

/// Where the developer can be found.
///
/// Deliberately a link to a profile rather than a "support me" button pointing
/// straight at a payment page. Apple's review guidelines treat an in-app call
/// to action that steers users to an outside payment mechanism as something
/// that belongs in an in-app purchase instead, and tip links are a routine
/// rejection. A plain link to the developer's GitHub is the ordinary,
/// uncontroversial thing open-source apps have always shipped — anything found
/// from there is between the user and that page.
const developerGitHub = 'https://github.com/Joshynaldo';

/// Where the exercise animations came from.
///
/// Credited on screen rather than only in a source comment. The upstream
/// author states he does not hold copyright in the images themselves — they
/// are used here with his written permission — so naming the source is the
/// least the app can do, and it is the trail anyone would need to follow if
/// the real rights holder ever asks. See `tool/fetch_exercise_gifs.dart` for
/// the full provenance note.
const exerciseAnimationCredit =
    'https://github.com/JahelCuadrado/ExerciseGymGifsDB';

/// The Help screen: who made this, how to get in touch, where to find them.
///
/// Its own entry under More rather than a section at the bottom of Settings.
/// Settings is for things you change; this is something you go and read, and it
/// was invisible in practice buried under eight rows of preferences.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('Help')),
      body: (context) => FadeSlideIn(
        child: ListView(
          padding:
              const EdgeInsets.only(top: 8, bottom: 24) + barInsets(context),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Gymfy is made by one person. Everything you log stays on your '
                'phone — there is no account and no server.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AppTile(
              icon: Icons.mail_outline,
              title: 'Send feedback',
              // Says up front what the mail will carry. There is no crash
              // reporting in this app, so a bug that is never written down is a
              // bug that is never fixed — but that is not a reason to attach
              // anything the user didn't agree to.
              subtitle:
                  'Opens your mail app · only the app version is '
                  'attached',
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => sendFeedback(context),
            ),
            AppTile(
              icon: Icons.code,
              title: 'Developer',
              subtitle: 'Joshynaldo on GitHub',
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openDeveloperPage(context),
            ),
            AppTile(
              icon: Icons.animation,
              title: 'Exercise animations',
              subtitle: 'ExerciseGymGifsDB · used with permission',
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openLink(context, exerciseAnimationCredit),
            ),
            AppTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: appVersion,
              // Nothing to tap, so no chevron promising otherwise.
              trailing: null,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openDeveloperPage(BuildContext context) =>
    openLink(context, developerGitHub);

/// Opens [url] in the browser, complaining if it can't.
///
/// A failure here is rare but real — a device with no browser, or a work
/// profile that blocks the intent. Silently doing nothing on tap looks like a
/// broken button, so it says so.
Future<void> openLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  if (await _launch(
    Uri.parse(url),
    // Hands it to the browser rather than a web view inside the app: these are
    // someone else's pages, and an in-app browser would imply otherwise.
    mode: LaunchMode.externalApplication,
  )) {
    return;
  }

  messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
}

/// Opens the mail app with a feedback mail composed and ready to edit.
///
/// Composed, never sent: the user reads it, edits it, and sends it themselves.
Future<void> sendFeedback(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  if (await _launch(currentFeedbackUri())) return;

  // No mail app configured is common enough on a fresh phone. The address is
  // the whole point of the button, so it goes on screen with a way to keep it
  // rather than vanishing behind "something went wrong".
  messenger.showSnackBar(
    SnackBar(
      content: const Text('No mail app found. Write to $feedbackAddress'),
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () =>
            Clipboard.setData(const ClipboardData(text: feedbackAddress)),
      ),
    ),
  );
}

/// [launchUrl] that reports failure instead of throwing.
///
/// It throws when no app can handle the link, which is an ordinary outcome
/// here, not an error worth crashing over.
Future<bool> _launch(Uri uri, {LaunchMode? mode}) async {
  try {
    return await launchUrl(
      uri,
      // `platformDefault` for mail: iOS wants the mailto handed to the system,
      // and forcing `externalApplication` there refuses links it would
      // otherwise open fine.
      mode: mode ?? LaunchMode.platformDefault,
    );
  } catch (_) {
    return false;
  }
}
