import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/calculator/screens/one_rm_calculator_screen.dart';
import '../../features/calculator/screens/strength_rank_screen.dart';
import '../../features/calories/screens/calorie_log_screen.dart';
import '../../features/calories/screens/weekly_overview_screen.dart';
import '../../features/exercises/screens/exercise_detail_screen.dart';
import '../../features/exercises/screens/exercise_form_screen.dart';
import '../../features/exercises/screens/exercise_library_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/muscle_map/screens/muscle_map_screen.dart';
import '../../features/progress/screens/exercise_progress_screen.dart';
import '../../features/progress/screens/measurement_history_screen.dart';
import '../../features/progress/screens/measurements_screen.dart';
import '../../features/progress/screens/photo_comparison_screen.dart';
import '../../features/plates/screens/plate_calculator_screen.dart';
import '../../features/progress/screens/progress_photos_screen.dart';
import '../../features/data_export/screens/export_screen.dart';
import '../../features/plan_share/screens/share_plan_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/workout/screens/active_workout_screen.dart';
import '../../features/workout/screens/day_builder_screen.dart';
import '../../features/workout/screens/split_days_screen.dart';
import '../../features/workout/screens/split_list_screen.dart';
import '../../features/workout/screens/workout_screen.dart';
import '../../features/workout/screens/workout_summary_screen.dart';
import 'scaffold_with_nav_bar.dart';

part 'app_router.g.dart';

/// The app's navigation configuration.
///
/// We use a [StatefulShellRoute] so the bottom navigation bar stays put while
/// each tab keeps its own navigation stack / scroll position.
///
/// Kept alive for the app's lifetime so navigation state isn't thrown away —
/// e.g. when the accent colour changes and the theme (but not the router)
/// rebuilds.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1 — Workout
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                builder: (context, state) => const WorkoutScreen(),
                routes: [
                  // The split manager. The tab itself shows the active split,
                  // so this is a pushed screen rather than the tab's root.
                  GoRoute(
                    path: 'splits',
                    builder: (context, state) => const SplitListScreen(),
                  ),
                  GoRoute(
                    path: 'split/:splitId',
                    builder: (context, state) => SplitDaysScreen(
                      splitId: int.parse(state.pathParameters['splitId']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'day/:dayId',
                        builder: (context, state) => DayBuilderScreen(
                          dayId: int.parse(state.pathParameters['dayId']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'session/:sessionId',
                    builder: (context, state) => ActiveWorkoutScreen(
                      sessionId: int.parse(state.pathParameters['sessionId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'summary/:sessionId',
                    builder: (context, state) => WorkoutSummaryScreen(
                      sessionId: int.parse(state.pathParameters['sessionId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2 — Exercises
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                builder: (context, state) => const ExerciseLibraryScreen(),
                routes: [
                  // Must come before ':id', which would otherwise swallow
                  // "new" and try to look up an exercise with that id.
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ExerciseFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ExerciseDetailScreen(
                      exerciseId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => ExerciseFormScreen(
                          exerciseId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 3 — Muscle map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/muscle-map',
                builder: (context, state) => const MuscleMapScreen(),
              ),
            ],
          ),
          // Tab 4 — Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'exercise/:exerciseId',
                    builder: (context, state) => ExerciseProgressScreen(
                      exerciseId: state.pathParameters['exerciseId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'photos',
                    builder: (context, state) => const ProgressPhotosScreen(),
                    routes: [
                      GoRoute(
                        path: 'compare',
                        builder: (context, state) =>
                            const PhotoComparisonScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'measurements',
                    builder: (context, state) => const MeasurementsScreen(),
                    routes: [
                      GoRoute(
                        path: 'history',
                        builder: (context, state) =>
                            const MeasurementHistoryScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Tab 5 — More (hub for extra tools)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'calories',
                    builder: (context, state) => const CalorieLogScreen(),
                  ),
                  GoRoute(
                    path: 'weekly',
                    builder: (context, state) => const WeeklyOverviewScreen(),
                  ),
                  GoRoute(
                    path: 'one-rm',
                    builder: (context, state) =>
                        const OneRmCalculatorScreen(),
                  ),
                  GoRoute(
                    path: 'plates',
                    builder: (context, state) => PlateCalculatorScreen(
                      // Optional prefill, so a weight can be handed over from
                      // the 1RM calculator or a logged set.
                      initialWeight: double.tryParse(
                        state.uri.queryParameters['weight'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'rank',
                    builder: (context, state) => const StrengthRankScreen(),
                  ),
                  GoRoute(
                    path: 'share-plan',
                    builder: (context, state) => const SharePlanScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'export',
                        builder: (context, state) => const ExportScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
