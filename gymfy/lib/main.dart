import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/hyper_backdrop.dart';
import 'features/backup/data/auto_backup.dart';
import 'features/exercises/data/exercise_repository.dart';
import 'features/health_connect/data/health_connect_sync.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/wear/data/wear_sync.dart';
import 'features/workout_notification/data/workout_notification.dart';
import 'l10n/app_language.dart';
import 'l10n/l10n.dart';
import 'shared/data/current_day.dart';
import 'shared/widgets/lucide_icons.dart';

Future<void> main() async {
  // Required because we touch the database (a platform plugin) before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  registerLucideLicense();

  // One shared Riverpod container for the whole app. We create it here so the
  // exercise library can be seeded before the first frame, then hand the SAME
  // container to the widget tree via UncontrolledProviderScope (so widgets and
  // the seeding above read the exact same providers / database instance).
  final container = ProviderContainer();
  await container.read(exerciseRepositoryProvider).seed();

  runApp(
    UncontrolledProviderScope(container: container, child: const GymfyApp()),
  );
}

class GymfyApp extends ConsumerWidget {
  const GymfyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The whole app is themed from the user's chosen theme and accent. Watching
    // both here means either choice instantly re-themes everything — including
    // the settings screen where they're picked, which is what makes the picker
    // its own live preview.
    final accent = ref.watch(accentColorProvider);
    final theme = buildAppTheme(ref.watch(appThemeProvider), accent);
    // The chosen language, or null to follow the phone. Watched before the
    // onboarding flag on purpose: both are one read of the same table, the
    // reads run in the order they were asked for, and this way the language
    // is known before the first real screen is — no English frame flashing up
    // on a phone set to German, or the other way round.
    final locale = ref.watch(appLocaleProvider);
    final onboarded = ref.watch(onboardingCompleteProvider);

    // Kept alive from the root, and watched rather than read: nothing reads
    // this provider's *value*, it exists for the push to the watch, so if no
    // one listened it would simply never build. At the root because the
    // moment the watch matters most is the moment the phone goes in a pocket
    // and every screen that could have owned this is gone.
    //
    // Free on every other platform — WearBridge.supported short-circuits.
    ref.watch(wearSyncProvider);
    // The reverse channel: logging a set, +30s and skip, sent from the wrist
    // or from the buttons on the workout notification.
    ref.watch(wearCommandsProvider);
    // The ongoing workout notification. Here for the same reason as the
    // watch: it matters once the phone is locked and every screen is gone.
    ref.watch(workoutNotificationSyncProvider);
    // Automatic backups. Here for the same reason: the moments they run on —
    // opening the app, finishing a workout — belong to other screens.
    ref.watch(autoBackupWatcherProvider);
    // Health Connect: workouts out, weigh-ins in. Same reason again. Costs a
    // settings read per trigger while both switches are off, which they are
    // until someone turns one on.
    ref.watch(healthConnectWatcherProvider);
    // A new day, noticed when the app comes back — goals count weeks and
    // deadlines, and nothing in the data changes at midnight to tell them.
    ref.watch(currentDayWatcherProvider);
    // The phone's language, for everything above that words things outside
    // the app: on "system default", switching the phone's language re-words
    // the notification and the watch along with the screens.
    ref.watch(systemLocalesWatcherProvider);

    // Onboarding is gated here rather than by a router redirect. A redirect has
    // to answer synchronously, but "has onboarding finished" comes from the
    // database, so the first redirect would run before the answer arrived and
    // let a brand-new user straight into the app. Swapping the whole app once,
    // when the answer lands, has no such race.
    //
    // All three apps carry the same localisation setup, so the language is
    // right from the first frame, the onboarding included.
    return switch (onboarded) {
      AsyncData(value: false) => MaterialApp(
        title: 'Gymfy',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        // The Hyper theme's glass needs a field behind it to refract; every
        // other theme gets its child back untouched.
        builder: (context, child) => HyperBackdrop(child: child!),
        home: const OnboardingScreen(),
      ),
      AsyncData(value: true) => MaterialApp.router(
        title: 'Gymfy',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Dark mode first: we build a dark theme and lock the app to it.
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        builder: (context, child) => HyperBackdrop(child: child!),
        routerConfig: ref.watch(goRouterProvider),
      ),
      // The single database read in flight, or it failed. Either way this is a
      // blank dark screen for a frame or two, which the native splash colour
      // matches — deliberately no spinner, since a spinner that flashes for
      // 20ms looks worse than nothing.
      _ => MaterialApp(
        title: 'Gymfy',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    };
  }
}
