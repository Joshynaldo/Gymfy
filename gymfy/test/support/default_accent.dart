// Shared overrides for widget tests that render themed UI.

import 'package:gymfy/app/theme/accent_color.dart';
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

/// Both of the above — what a widget test rendering a weight usually wants.
final defaultDisplayOverrides = [
  defaultBodyFigureOverride,
  defaultAccentOverride,
  defaultWeightUnitOverride,
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
