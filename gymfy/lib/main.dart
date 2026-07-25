import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/accent_color.dart';
import 'app/theme/app_theme.dart';
import 'features/exercises/data/exercise_repository.dart';

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
    // it here means changing the accent instantly re-themes everything.
    final accent = ref.watch(accentColorProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Gymfy',
      debugShowCheckedModeBanner: false,
      // Dark mode first: we build a dark theme and lock the app to it.
      theme: buildDarkTheme(accent),
      darkTheme: buildDarkTheme(accent),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
