// Shared overrides for widget tests that render themed UI.

import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/workout/data/logging_preferences.dart';
import 'package:gymfy/shared/data/lifter_sex.dart';
import 'package:gymfy/shared/utils/units.dart';

/// Pins the accent colour to the default without touching the database.
///
/// `accentColorProvider` reads the chosen accent out of the settings table, so
/// any widget test that renders themed UI would otherwise open a real database
/// just to look up a colour it doesn't care about — which is slow, warns about
/// duplicate database instances, and leaves a drift cleanup timer pending at
/// teardown.
///
/// Tests that are actually *about* the accent (see `accent_color_test.dart` and
/// the picker in `onboarding_test.dart`) deliberately don't use this.
final defaultAccentOverride = storedAccentProvider.overrideWith(
  (ref) => Stream.value(null),
);

/// Pins the weight unit to kilograms without touching the database.
///
/// Same reasoning as [defaultAccentOverride]: any widget that shows a weight
/// reads the unit setting, so a test about ranks or records would otherwise open
/// a real database to look up a unit it doesn't care about.
///
/// Tests that are actually *about* units (`units_test.dart`) don't use this.
final defaultWeightUnitOverride = storedWeightUnitProvider.overrideWith(
  (ref) => Stream.value(null),
);

/// All of these — what a widget test rendering a weight usually wants.
final defaultDisplayOverrides = [
  defaultBodyFigureOverride,
  defaultAccentOverride,
  defaultWeightUnitOverride,
  ...defaultLoggingOverrides,
  defaultWorkoutNotificationOverride,
];

/// Switches the ongoing workout notification off without touching the
/// database.
///
/// The active workout reads the setting as it opens, to decide whether to ask
/// for notification permission. Same reasoning as the overrides above — and
/// off rather than on, so a test about the screen never reaches for the real
/// notification plugin. `workout_notification_test.dart` is the one about it.
final defaultWorkoutNotificationOverride = workoutNotificationProvider
    .overrideWith((ref) => Stream.value(false));

/// Pins the logging preferences (effort rating, warm-up ramp) to their
/// defaults without touching the database.
///
/// The active workout reads both when a set is logged or the warm-up
/// calculator opens. Same reasoning as the overrides above: a test about the
/// workout screen should not open a real database to learn that rating is off.
final defaultLoggingOverrides = [
  effortRatingModeProvider.overrideWith(
    (ref) => Stream.value(EffortRatingMode.off),
  ),
  warmupRampProvider.overrideWith((ref) => Stream.value(defaultWarmupRamp)),
];

/// Pins the body diagram to the male figure without touching the database.
///
/// Same reasoning again: the muscle map picks its diagram from the lifter-sex
/// setting, so any test that renders a body would otherwise open a real
/// database to answer a question it isn't about — and leave drift's stream
/// cleanup timer pending at teardown, which fails the test after it passed.
///
/// Tests that are actually *about* which figure is drawn
/// (`muscle_map_figure_test.dart`) don't use this.
final defaultBodyFigureOverride = lifterSexProvider.overrideWith(
  (ref) => Stream.value(null),
);
