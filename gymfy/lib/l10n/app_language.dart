import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/data/settings_repository.dart';
import 'l10n.dart';

/// Setting key for the language the app is shown in.
const appLanguageSetting = 'app_language';

/// The languages the app can be shown in, plus "whatever the phone says".
///
/// [system] is the default and the reason this exists at all is the other
/// two: a German phone gets a German app without anyone touching Settings,
/// and someone who would rather read the app in English than in their phone's
/// language can say so.
enum AppLanguage {
  system('system', null),
  english('en', Locale('en')),
  german('de', Locale('de'));

  const AppLanguage(this.storedValue, this.locale);

  /// What goes into `app_settings`: a language code, so another language is
  /// one more row here and nothing to migrate.
  final String storedValue;

  /// The locale to force, or null to follow the phone.
  final Locale? locale;

  /// The language's own name for itself, shown in the picker.
  ///
  /// Not translated, on purpose: someone who can't read the current language
  /// is exactly the person looking for theirs, and "Deutsch" is what they will
  /// recognise — never "German", and never "Englisch".
  static const _endonyms = {'en': 'English', 'de': 'Deutsch'};

  /// The endonym for [locale]'s language.
  static String endonymFor(Locale locale) =>
      _endonyms[locale.languageCode] ?? locale.languageCode;

  /// Parses a stored value. Anything unknown follows the phone, the same as
  /// never having picked — the worst case is the user picking again.
  static AppLanguage parse(String? raw) {
    return AppLanguage.values.firstWhere(
      (language) => language.storedValue == raw,
      orElse: () => AppLanguage.system,
    );
  }
}

/// The language as stored on disk; null while the first read is in flight.
final storedAppLanguageProvider = StreamProvider<AppLanguage?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(appLanguageSetting)
      .map((raw) => raw == null ? null : AppLanguage.parse(raw));
});

/// The language choice in use. Like the theme there is no in-memory copy:
/// [setAppLanguage] only writes, and the change arrives back through
/// [storedAppLanguageProvider], so the app re-renders in the new language the
/// moment it is stored.
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(storedAppLanguageProvider).value ?? AppLanguage.system;
});

/// The locale handed to `MaterialApp`, or null to let Flutter match the
/// phone's own list of languages against the supported ones.
final appLocaleProvider = Provider<Locale?>((ref) {
  return ref.watch(appLanguageProvider).locale;
});

/// The locale the phone's settings resolve to among the supported ones.
///
/// The same rule `MaterialApp` applies when [appLocaleProvider] is null: the
/// first of the phone's languages that the app has, matched on language (so
/// `de_AT` is German), else English. Exposed so Settings can say what "system
/// default" currently means, and so code without a widget can match the UI.
Locale resolveSystemLocale(List<Locale> phoneLocales) {
  return basicLocaleListResolution(
    phoneLocales,
    AppLocalizations.supportedLocales,
  );
}

/// The strings in the language the app is currently shown in, for code with
/// no [BuildContext] — notifications, mostly.
///
/// Widgets use `context.l10n` instead: it rebuilds them when the language
/// changes, which a value read from here once does not.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale =
      ref.watch(appLocaleProvider) ??
      resolveSystemLocale(PlatformDispatcher.instance.locales);
  return lookupAppLocalizations(locale);
});

/// Stores a language choice, from a widget. Mirrors `setAppTheme`.
Future<void> setAppLanguage(WidgetRef ref, AppLanguage language) {
  return ref
      .read(settingsRepositoryProvider)
      .write(appLanguageSetting, language.storedValue);
}
