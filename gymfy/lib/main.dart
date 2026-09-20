import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/hyper_backdrop.dart';
import 'features/exercises/data/exercise_repository.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/wear/data/wear_sync.dart';

Future<void> main() async {
  // Required because we touch the database (a platform plugin) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

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
    final onboarded = ref.watch(onboardingCompleteProvider);

    // Kept alive from the root, and watched rather than read: nothing reads
    // this provider's *value*, it exists for the push to the watch, so if no
    // one listened it would simply never build. At the root because the
    // moment the watch matters most is the moment the phone goes in a pocket
    // and every screen that could have owned this is gone.
    //
    // Free on every other platform — WearBridge.supported short-circuits.
    ref.watch(wearSyncProvider);

    // Onboarding is gated here rather than by a router redirect. A redirect has
    // to answer synchronously, but "has onboarding finished" comes from the
    // database, so the first redirect would run before the answer arrived and
    // let a brand-new user straight into the app. Swapping the whole app once,
    // when the answer lands, has no such race.
    return switch (onboarded) {
      AsyncData(value: false) => MaterialApp(
        title: 'Gymfy',
        debugShowCheckedModeBanner: false,
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
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    };
  }
}
