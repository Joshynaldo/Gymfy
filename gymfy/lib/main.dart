import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'features/exercises/data/exercise_repository.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

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
    UncontrolledProviderScope(
      container: container,
      child: const GymfyApp(),
    ),
  );
}

class GymfyApp extends ConsumerWidget {
  const GymfyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The whole app is themed from the user's chosen accent colour. Watching
    // it here means changing the accent instantly re-themes everything —
    // including the onboarding screen where it's picked.
    final accent = ref.watch(accentColorProvider);
    final theme = buildDarkTheme(accent);
    final onboarded = ref.watch(onboardingCompleteProvider);

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
        home: const OnboardingScreen(),
      ),
      AsyncData(value: true) => MaterialApp.router(
        title: 'Gymfy',
        debugShowCheckedModeBanner: false,
        // Dark mode first: we build a dark theme and lock the app to it.
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
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
