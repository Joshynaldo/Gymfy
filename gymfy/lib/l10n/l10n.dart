import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The English strings, with no [BuildContext] needed.
///
/// What [AppLocalizationsContext.l10n] falls back to, and what the formatting
/// helpers mean by "no localisations given". English is the template, so this
/// is exactly what the app said before it spoke anything else.
final AppLocalizations englishLocalizations = lookupAppLocalizations(
  const Locale('en'),
);

/// The one way widgets read their strings: `context.l10n.settingsTitle`.
///
/// Never `AppLocalizations.of(context)!`. Most widget tests pump a widget
/// inside a bare `MaterialApp` with no localisation delegates, where `of`
/// returns null and the bang would crash a hundred tests that are about
/// something else entirely. Falling back to English keeps every one of them
/// describing the app as it reads in English, which is what they were
/// written against.
///
/// The fallback is only for that case. The app itself always installs the
/// delegates (see `main.dart`), so there it is the chosen language or the
/// phone's.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? englishLocalizations;
}
