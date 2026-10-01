// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonAll => 'All';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonOff => 'Off';

  @override
  String get commonActive => 'Active';

  @override
  String commonListAnd(String first, String second) {
    return '$first and $second';
  }

  @override
  String get shellNavHome => 'Home';

  @override
  String get shellNavWorkout => 'Workout';

  @override
  String get shellNavProgress => 'Progress';

  @override
  String get shellNavMore => 'More';

  @override
  String get sharedWeightWheelLabel => 'Weight';

  @override
  String sharedLoggedSetReps(String weight, int reps) {
    return '$weight × $reps reps';
  }

  @override
  String sharedAddedToDayNone(int asked) {
    String _temp0 = intl.Intl.pluralLogic(
      asked,
      locale: localeName,
      other: 'All $asked were already in that day',
      one: 'Already in that day',
    );
    return '$_temp0';
  }

  @override
  String sharedAddedToDayAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added exercises added',
      one: '1 exercise added',
    );
    return '$_temp0';
  }

  @override
  String sharedAddedToDaySkipped(String addedText, int skipped) {
    return '$addedText — $skipped already there';
  }

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleFrontDeltoid => 'Front Deltoid';

  @override
  String get muscleSideDeltoid => 'Side Deltoid';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleAbs => 'Abs';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleAdductors => 'Adductors';

  @override
  String get muscleTrapezius => 'Trapezius';

  @override
  String get muscleRearDeltoid => 'Rear Deltoid';

  @override
  String get muscleLats => 'Lats';

  @override
  String get muscleLowerBack => 'Lower Back';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleNeck => 'Neck';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentBodyweight => 'Bodyweight';

  @override
  String get equipmentOther => 'Other';

  @override
  String get setTypeWarmup => 'Warm-up';

  @override
  String get setTypeNormal => 'Working';

  @override
  String get setTypeDrop => 'Drop set';

  @override
  String get setTypeFailure => 'Failure';

  @override
  String get lifterSexMale => 'Male';

  @override
  String get lifterSexFemale => 'Female';

  @override
  String get measurementFieldWeight => 'Weight';

  @override
  String get measurementFieldChest => 'Chest';

  @override
  String get measurementFieldWaist => 'Waist';

  @override
  String get measurementFieldHips => 'Hips';

  @override
  String get measurementFieldArms => 'Arms';

  @override
  String get measurementFieldLegs => 'Legs';

  @override
  String get goalKindLift => 'Lift';

  @override
  String get goalKindFrequency => 'Workouts';

  @override
  String get goalKindBodyweight => 'Bodyweight';

  @override
  String get bodyProfileHeightLabel => 'Height';

  @override
  String get bodyProfileHeightQuestion => 'How tall are you?';

  @override
  String get bodyProfileAgeLabel => 'Age';

  @override
  String get bodyProfileAgeQuestion => 'How old are you?';

  @override
  String get bodyProfileAgeHelper =>
      'Kept as your year of birth, so it stays correct.';

  @override
  String get themeDarkDefaultLabel => 'Dark';

  @override
  String get themeDarkDefaultDescription => 'Near-black with soft grey cards.';

  @override
  String get themeAmoledLabel => 'AMOLED black';

  @override
  String get themeAmoledDescription =>
      'True black. Saves power on OLED screens.';

  @override
  String get themeHighContrastLabel => 'High contrast';

  @override
  String get themeHighContrastDescription =>
      'Brighter text and visible borders.';

  @override
  String get themeTokyoNightDescription =>
      'Deep blue-grey with a soft indigo cast.';

  @override
  String get themeDraculaDescription =>
      'Dark violet with high-saturation accents.';

  @override
  String get themeCatppuccinMochaDescription =>
      'Warm, muted pastels on deep charcoal.';

  @override
  String get themeGruvboxDescription => 'Warm retro browns and greens.';

  @override
  String get themeHyperDescription =>
      'Translucent glass over a living backdrop.';

  @override
  String get notificationRestRunningTitle => 'Resting';

  @override
  String get notificationRestRunningChannel => 'Rest timer countdown';

  @override
  String get notificationRestRunningChannelDescription =>
      'Shows the rest countdown while you are in another app.';

  @override
  String get notificationRestOverTitle => 'Rest over';

  @override
  String notificationRestOverBody(String exercise) {
    return 'Next set of $exercise';
  }

  @override
  String get notificationRestOverChannel => 'Rest timer';

  @override
  String get notificationRestOverChannelDescription =>
      'Tells you when a rest between sets is over.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionTheme => 'Theme';

  @override
  String get settingsSectionAccent => 'Accent';

  @override
  String get settingsSectionUnits => 'Units';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionPlates => 'Plates';

  @override
  String get settingsSectionOverload => 'Progressive overload';

  @override
  String get settingsSectionLogging => 'Logging';

  @override
  String get settingsSectionYou => 'You';

  @override
  String get settingsSectionRestTimer => 'Rest timer';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionHealthConnect => 'Health Connect';

  @override
  String get settingsAccentCaption => 'Drives buttons, highlights and charts.';

  @override
  String get settingsUnitsCaption =>
      'Weights are always stored in kilograms, so switching back and forth never changes what you logged.';

  @override
  String get settingsLanguageTitle => 'App language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String settingsLanguageSystemSubtitle(String language) {
    return 'Follows your phone: $language';
  }

  @override
  String get settingsLanguageExerciseNames => 'Exercise names stay in English.';

  @override
  String get settingsBackupTitle => 'Backup & restore';

  @override
  String get settingsBackupSubtitle =>
      'Everything in one file, plus automatic backups';

  @override
  String get settingsExportTitle => 'Export data';

  @override
  String get settingsExportSubtitle =>
      'Save your whole log as a spreadsheet or JSON';

  @override
  String get settingsNameTitle => 'Name';

  @override
  String get settingsNameDialogTitle => 'Your name';

  @override
  String get settingsNameDialogHint => 'Leave empty to remove';

  @override
  String get settingsDefaultRestTitle => 'Default rest';

  @override
  String settingsDefaultRestSubtitle(String rest) {
    return '$rest between sets';
  }

  @override
  String get settingsRestAlertsTitle => 'Rest timer notifications';

  @override
  String get settingsRestAlertsSubtitle =>
      'Show the countdown in the notification shade and alert you when it runs out';

  @override
  String get settingsVibrateTitle => 'Vibrate';

  @override
  String get settingsVibrateSubtitle => 'Useful with the phone in a pocket';

  @override
  String get settingsWorkoutNotificationTitle => 'Workout notification';

  @override
  String get settingsWorkoutNotificationSubtitle =>
      'Keep the current set and rest in the notification shade, with buttons to log a set and control the rest';

  @override
  String get settingsBodyDiagramTitle => 'Body diagram';

  @override
  String get settingsBodyDiagramNotSet =>
      'Not set — showing the male diagram, no strength ranks';

  @override
  String settingsBodyDiagramSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Female diagram and strength standards',
      'other': 'Male diagram and strength standards',
    });
    return '$_temp0';
  }

  @override
  String settingsThemeAccentSuggestion(String theme) {
    return '$theme was designed around its own accent.';
  }

  @override
  String get settingsThemeUseAccent => 'Use it';

  @override
  String get moreTitle => 'More';

  @override
  String get moreExerciseLibraryTitle => 'Exercise library';

  @override
  String get moreExerciseLibrarySubtitle =>
      'Every movement, searchable by name or muscle';

  @override
  String get moreCalorieLogTitle => 'Calorie log';

  @override
  String get moreCalorieLogSubtitle => 'Track meals, calories and macros';

  @override
  String get moreWeeklyTitle => 'This week';

  @override
  String get moreWeeklySubtitle => 'Calories over the last 7 days';

  @override
  String get moreOneRmTitle => '1RM calculator';

  @override
  String get moreOneRmSubtitle => 'Estimate your one-rep max from any set';

  @override
  String get moreStrengthRankTitle => 'Strength rank';

  @override
  String get moreStrengthRankSubtitle =>
      'How your big lifts compare to your bodyweight';

  @override
  String get moreSharePlanTitle => 'Share a plan';

  @override
  String get moreSharePlanSubtitle =>
      'Send your splits to someone, or import theirs';

  @override
  String get moreImportTitle => 'Import a history';

  @override
  String get moreImportSubtitle =>
      'Bring your workouts over from Hevy, Strong or similar';

  @override
  String get moreHelpTitle => 'Help';

  @override
  String get moreHelpSubtitle => 'About Gymfy and who made it';

  @override
  String get moreSettingsTitle => 'Settings';

  @override
  String get moreSettingsSubtitle =>
      'Accent colour, your name, rest timer alerts';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpIntro =>
      'Gymfy is made by one person. Everything you log stays on your phone — there is no account and no server.';

  @override
  String get helpFeedbackTitle => 'Send feedback';

  @override
  String get helpFeedbackSubtitle =>
      'Opens your mail app · only the app version is attached';

  @override
  String get helpDeveloperTitle => 'Developer';

  @override
  String get helpDeveloperSubtitle => 'Joshynaldo on GitHub';

  @override
  String get helpAnimationsTitle => 'Exercise animations';

  @override
  String get helpAnimationsSubtitle =>
      'ExerciseGymGifsDB · used with permission';

  @override
  String get helpVersionTitle => 'Version';

  @override
  String helpOpenLinkFailed(String url) {
    return 'Could not open $url';
  }

  @override
  String helpNoMailApp(String address) {
    return 'No mail app found. Write to $address';
  }

  @override
  String helpFeedbackMailDevice(
    String version,
    String platform,
    String osVersion,
  ) {
    return 'Gymfy $version on $platform $osVersion';
  }

  @override
  String get helpFeedbackMailNote =>
      'Only these two lines are attached. Delete them if you would rather not send them.';

  @override
  String get onboardingSaving => 'Saving…';

  @override
  String get onboardingFinish => 'Start lifting';

  @override
  String get onboardingChangeLater =>
      'You can change any of this later in Settings.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Gymfy';

  @override
  String get onboardingWelcomeBody =>
      'Everything you log stays on this phone — there is no account and nothing gets uploaded. What should we call you?';

  @override
  String get onboardingNameLabel => 'Your name';

  @override
  String get onboardingNameHint => 'Optional';

  @override
  String get onboardingSexTitle => 'Body diagram and strength standards';

  @override
  String get onboardingSexBody =>
      'Picks which body the muscle map draws, and which strength table your lifts are compared against. Optional — skip it and the app works the same, minus the ranks.';

  @override
  String get onboardingSexDecline => 'Rather not say';

  @override
  String get onboardingBodyweightTitle => 'How much do you weigh?';

  @override
  String get onboardingBodyweightBody =>
      'Used to rank your lifts against your own bodyweight, and it becomes the first point on your weight chart. Leave it at zero to skip — nothing else depends on it.';

  @override
  String get onboardingBodyweightLabel => 'Bodyweight';

  @override
  String get onboardingSkipped => 'Skip';

  @override
  String get onboardingOverloadTitle => 'Should Gymfy suggest heavier weights?';

  @override
  String get onboardingOverloadBody =>
      'When you hit every set at the top of your rep range, the next session opens with a bit more on the bar. It only ever suggests — the weight stays yours to change.';

  @override
  String get onboardingAccentTitle => 'Pick your colour';

  @override
  String get onboardingAccentBody =>
      'Drives buttons, highlights and charts across the app. Tap one to try it — the app changes as you go.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get homeFindExerciseTooltip => 'Find an exercise';

  @override
  String homeStreakSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days day workout streak',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayNoSplitTitle => 'No active split';

  @override
  String get homeTodayNoSplitMessage =>
      'Pick the programme you are following to plan your week.';

  @override
  String get homeTodayNoSplitAction => 'Choose a split';

  @override
  String get homeTodayRestTitle => 'Rest day';

  @override
  String homeTodayRestMessage(String split) {
    return 'Nothing scheduled in $split.';
  }

  @override
  String get homeTodayNoExercises =>
      'No exercises yet — open the day to add some.';

  @override
  String homeTodayResume(String workout) {
    return 'Resume $workout';
  }

  @override
  String get homeTodayStart => 'Start workout';

  @override
  String get homeTodayAddExercises => 'Add exercises';

  @override
  String get homeTodayStartEmpty => 'Start empty workout';

  @override
  String get homeNextUpTomorrow => 'Tomorrow';

  @override
  String homeNextUpNextWeekday(String weekday) {
    return 'Next $weekday';
  }

  @override
  String get homeLastWorkoutHeading => 'LAST WORKOUT';

  @override
  String homeLastWorkoutSets(int count, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0 • $volume';
  }

  @override
  String get homeWeekTitle => 'This week';

  @override
  String homeWeekWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String homeWeekLiftedSince(String weekday) {
    return 'lifted since $weekday';
  }

  @override
  String get homeRecapPeriodWeek => 'Week';

  @override
  String get homeRecapPeriodMonth => 'Month';

  @override
  String get homeRecapPeriodYear => 'Year';

  @override
  String get muscleMapFront => 'Front';

  @override
  String get muscleMapBack => 'Back';

  @override
  String get muscleMapShowHeatmap => 'Switch to heatmap';

  @override
  String get muscleMapShowColours => 'Switch to per-muscle colours';

  @override
  String muscleMapLoadFailed(String error) {
    return 'Could not load the muscle map.\n$error';
  }

  @override
  String muscleMapBodyLoadFailed(String error) {
    return 'Could not load the body map.\n$error';
  }

  @override
  String get muscleMapContrastCaption =>
      'Each muscle has its own colour. Brighter still means more volume.';

  @override
  String get workoutTitle => 'Workout';

  @override
  String workoutSplitsLoadFailed(String error) {
    return 'Could not load your splits.\n$error';
  }

  @override
  String get workoutAddDay => 'Add day';

  @override
  String get workoutStartEmptyTooltip => 'Start empty workout';

  @override
  String get workoutSwitchSplitTooltip => 'Switch split';

  @override
  String get workoutSwitcherTitle => 'Your splits';

  @override
  String get workoutNewSplit => 'New split';

  @override
  String get workoutBrowsePrograms => 'Browse programs';

  @override
  String get workoutManageSplits => 'Manage splits';

  @override
  String get workoutNoSplitsTitle => 'No splits yet';

  @override
  String get workoutNoSplitsMessage =>
      'Create your first split to start planning your training.';

  @override
  String get workoutNoSplitsFromProgram => 'Start from a program';

  @override
  String get workoutNoSplitsFreeWorkout => 'Or start an empty workout';

  @override
  String get workoutNoActiveSplitTitle => 'No active split';

  @override
  String get workoutNoActiveSplitMessage =>
      'Pick the programme you are following and its days will show up here.';

  @override
  String get workoutNoActiveSplitAction => 'Choose a split';

  @override
  String get workoutFreeWorkoutName => 'Free workout';

  @override
  String get workoutSplitsTitle => 'Splits';

  @override
  String get workoutSplitNameLabel => 'Split name';

  @override
  String get workoutSplitNameHint => 'e.g. Push / Pull / Legs';

  @override
  String get workoutDeleteSplitTooltip => 'Delete split';

  @override
  String workoutDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get workoutDeleteSplitMessage =>
      'This removes the split and everything inside it. This cannot be undone.';

  @override
  String get workoutSplitFallbackTitle => 'Split';

  @override
  String get workoutDayNameLabel => 'Day name';

  @override
  String get workoutDayNameHint => 'e.g. Push';

  @override
  String workoutNowFollowing(String split) {
    return 'Now following $split';
  }

  @override
  String get workoutSetActive => 'Set active';

  @override
  String workoutSplitLoadFailed(String error) {
    return 'Could not load this split.\n$error';
  }

  @override
  String workoutDayCardSubtitle(int count, String schedule) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 • $schedule';
  }

  @override
  String get workoutDayNotScheduled => 'Not scheduled';

  @override
  String get workoutDeleteDayTooltip => 'Delete day';

  @override
  String get workoutDayNoExercises => 'No exercises yet — tap to add some.';

  @override
  String get workoutDeleteDayMessage =>
      'This removes the day and its exercises. This cannot be undone.';

  @override
  String get workoutNoDaysTitle => 'No days yet';

  @override
  String get workoutNoDaysMessage =>
      'Add a training day (like \"Push\" or \"Legs\") to start building this split.';

  @override
  String get workoutDayFallbackTitle => 'Day';

  @override
  String workoutDayLoadFailed(String error) {
    return 'Could not load this day.\n$error';
  }

  @override
  String get workoutStartWorkout => 'Start workout';

  @override
  String get workoutAddExercises => 'Add exercises';

  @override
  String workoutPlannedSetsReps(int sets, String reps) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
    );
    return '$_temp0 × $reps reps';
  }

  @override
  String workoutPlannedWarmups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warm-ups',
      one: '1 warm-up',
    );
    return '$_temp0';
  }

  @override
  String workoutPlannedPercent(String percent) {
    return '@ $percent 1RM';
  }

  @override
  String get workoutSuperset => 'Superset';

  @override
  String get workoutRemoveExerciseTooltip => 'Remove exercise';

  @override
  String get workoutDragToReorder => 'Drag to reorder';

  @override
  String get workoutSupersetRestAfterLast => 'SUPERSET · REST AFTER THE LAST';

  @override
  String get workoutSupersetWithAbove => 'Superset with the exercise above';

  @override
  String get workoutSupersetWithBelow => 'Superset with the exercise below';

  @override
  String get workoutSupersetLeave => 'Remove from superset';

  @override
  String workoutUpdatedExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated all $count exercises',
      one: 'Updated 1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get workoutSetsRepsTitle => 'Sets & reps';

  @override
  String get workoutWheelSets => 'Sets';

  @override
  String get workoutWheelReps => 'Reps';

  @override
  String get workoutWheelFrom => 'From';

  @override
  String get workoutWheelTo => 'To';

  @override
  String get workoutRepRange => 'Rep range';

  @override
  String get workoutWarmupSets => 'Warm-up sets';

  @override
  String workoutSaveToAll(int count) {
    return 'Save to all $count';
  }

  @override
  String get workoutDayEmptyTitle => 'No exercises yet';

  @override
  String get workoutDayEmptyMessage =>
      'Add exercises from the library and set their sets and reps.';

  @override
  String get workoutPickerClear => 'Clear';

  @override
  String get workoutPickerNoMatches => 'No exercises match your filters.';

  @override
  String workoutPickerSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'Nothing selected',
    );
    return '$_temp0';
  }

  @override
  String workoutPickerAddCount(int count) {
    return 'Add $count';
  }

  @override
  String workoutLoadFailed(String error) {
    return 'Could not load this workout.\n$error';
  }

  @override
  String get workoutNotFound => 'Workout not found.';

  @override
  String get workoutFinish => 'Finish';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutUpNext => 'UP NEXT';

  @override
  String get workoutReorder => 'Reorder';

  @override
  String get workoutSwapExercise => 'Swap exercise';

  @override
  String get workoutSwapExerciseSubtitle => 'Do something else in its place';

  @override
  String get workoutRemoveFromWorkout => 'Remove from workout';

  @override
  String get workoutPlanUnchanged => 'Your plan stays as it is';

  @override
  String workoutPhaseWarmup(int number) {
    return 'Warm-up $number';
  }

  @override
  String workoutPhaseWorking(int number) {
    return 'Set $number · working set';
  }

  @override
  String get workoutExerciseOptionsTooltip => 'Exercise options';

  @override
  String get workoutWarmupCalculator => 'Warm-up calculator';

  @override
  String workoutLogSet(int number) {
    return 'Log set $number';
  }

  @override
  String workoutSupersetWith(String partners) {
    return 'Superset with $partners — rest after the last one';
  }

  @override
  String get workoutSupersetCaps => 'SUPERSET';

  @override
  String workoutWarmupProgress(int number, int expected) {
    return 'Warm-up $number of $expected';
  }

  @override
  String get workoutWarmup => 'Warm-up';

  @override
  String workoutSuggestionEarned(String weight) {
    return 'You hit every set last time — going up to $weight';
  }

  @override
  String workoutSuggestionDeload(String weight) {
    return 'Several increases in a row — a lighter $weight is suggested';
  }

  @override
  String workoutSuggestionAtLimit(String weight) {
    return 'Top set was a limit effort last time — holding at $weight';
  }

  @override
  String workoutSuggestionPercent(String percent, String weight) {
    return '$percent of your 1RM — $weight';
  }

  @override
  String workoutSuggestionBlockDeload(String percent, String weight) {
    return 'Deload week at $percent — $weight';
  }

  @override
  String workoutSuggestionSame(String weight) {
    return 'Same $weight as last time';
  }

  @override
  String get workoutChangeSetTypeTooltip => 'Change set type';

  @override
  String get workoutSetTypeTitle => 'Set type';

  @override
  String get workoutDeleteSetTooltip => 'Delete set';

  @override
  String get workoutBadgeWarmup => 'W';

  @override
  String get workoutBadgeDrop => 'D';

  @override
  String get workoutBadgeFailure => 'F';

  @override
  String get workoutEmptyFreeMessage =>
      'Add exercises as you go. Nothing here changes your plan.';

  @override
  String get workoutEmptyNothingTitle => 'Nothing to log';

  @override
  String get workoutEmptyNothingMessage =>
      'This day has no exercises. Add some for today — your plan stays as it is.';

  @override
  String get workoutLogWarmupCaption => 'Warm-up · ramping up';

  @override
  String get workoutLogDropCaption => 'Drop set · lighter, straight after';

  @override
  String workoutLogFailureCaption(String phase) {
    return '$phase · to failure';
  }

  @override
  String get workoutWorkingSet => 'Working set';

  @override
  String get workoutLogRepsUnit => 'reps';

  @override
  String get workoutLogStepWeight => 'STEP 1 — WEIGHT';

  @override
  String get workoutLogStepReps => 'STEP 2 — REPS';

  @override
  String get workoutLogStepTime => 'STEP 2 — TIME';

  @override
  String get workoutLogTypeWeight => 'Type a weight';

  @override
  String get workoutLogStackPlates => 'Stack plates';

  @override
  String get workoutLogRepeat => 'Repeat last set';

  @override
  String get workoutLogNextTime => 'Next: time';

  @override
  String get workoutLogNextReps => 'Next: reps';

  @override
  String get workoutLogSaveSet => 'Save set';

  @override
  String get workoutLogHolding => 'HOLDING';

  @override
  String get workoutLogMinutes => 'MIN';

  @override
  String get workoutLogSeconds => 'SEC';

  @override
  String get workoutTimerStop => 'Stop';

  @override
  String get workoutTimerStart => 'Start timer';

  @override
  String get workoutEffortRpeLabel => 'HOW HARD · RPE';

  @override
  String get workoutEffortRirLabel => 'REPS LEFT · RIR';

  @override
  String workoutNoteEarned(String weight) {
    return 'You hit every set last time — going up to $weight.';
  }

  @override
  String workoutNoteDeload(String weight) {
    return 'Several increases in a row. A lighter week at $weight is suggested.';
  }

  @override
  String workoutNoteAtLimit(String weight) {
    return 'You hit every set, but the top set was a limit effort — staying at $weight.';
  }

  @override
  String workoutNotePercent(String percent, String weight) {
    return 'Planned at $percent of your 1RM — $weight.';
  }

  @override
  String workoutNoteBlockDeload(String percent, String weight) {
    return 'Deload week: $percent of your working weight — $weight.';
  }

  @override
  String get workoutNoteSame =>
      'Same weight as last time — the rep target wasn\'t met yet.';

  @override
  String get workoutRestOverCaps => 'REST OVER';

  @override
  String get workoutRestingCaps => 'RESTING';

  @override
  String get workoutRestAddTooltip => 'Add 30 seconds';

  @override
  String get workoutRestDismissTooltip => 'Dismiss';

  @override
  String get workoutRestSkipTooltip => 'Skip rest';

  @override
  String get workoutRestOver => 'Rest over';

  @override
  String workoutReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
    );
    return '$_temp0';
  }

  @override
  String workoutRecordLine(String kind, String value, String previous) {
    return '$kind · $value, was $previous';
  }

  @override
  String get workoutRecordNew => 'New personal record';

  @override
  String workoutRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personal records',
      one: '1 personal record',
    );
    return '$_temp0';
  }

  @override
  String get workoutRecordKindWeight => 'Heaviest weight';

  @override
  String get workoutRecordKindOneRm => 'Best estimated 1RM';

  @override
  String get workoutRecordKindReps => 'Most reps';

  @override
  String get workoutRecordKindHold => 'Longest hold';

  @override
  String get workoutRecordKindVolume => 'Best session volume';

  @override
  String workoutSwapTitle(String exercise) {
    return 'Swap $exercise';
  }

  @override
  String get workoutSwapScopeTitle => 'Swap for how long?';

  @override
  String get workoutSwapScopeSession => 'Just this workout';

  @override
  String get workoutSwapScopePlan => 'This workout and the plan';

  @override
  String get workoutSwapScopePlanSubtitle =>
      'Future workouts of this day use it too';

  @override
  String get workoutSwapPlanClash =>
      'That exercise is already in this day\'s plan, so the swap is for this workout only.';

  @override
  String get workoutReorderTitle => 'Reorder exercises';

  @override
  String workoutWarmupRampCaption(String exercise, String ramp) {
    return '$exercise · ramp $ramp';
  }

  @override
  String get workoutWarmupWorkingWeight => 'WORKING WEIGHT';

  @override
  String get workoutWarmupLighter => 'Lighter';

  @override
  String get workoutWarmupHeavier => 'Heavier';

  @override
  String get workoutWarmupEnterWeight =>
      'Enter the weight you are working up to.';

  @override
  String get workoutWarmupTooLight =>
      'Too light to need a ramp — go straight to work.';

  @override
  String workoutWarmupLogSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Log $count warm-up sets',
      one: 'Log 1 warm-up set',
    );
    return '$_temp0';
  }

  @override
  String get workoutWarmupEmptyBar => 'Empty bar';

  @override
  String workoutWarmupStepPlates(int percent, String plates) {
    return '$percent % · $plates per side';
  }

  @override
  String get workoutSummaryTitle => 'Workout complete';

  @override
  String workoutSummaryLoadFailed(String error) {
    return 'Could not load the summary.\n$error';
  }

  @override
  String get workoutSummaryNoSets => 'No sets were logged in this workout.';

  @override
  String get workoutSummaryExercises => 'Exercises';

  @override
  String get workoutSummaryMusclesWorked => 'Muscles worked';

  @override
  String get workoutSummaryNoMuscles => 'No muscles to show for this workout.';

  @override
  String get workoutSummaryDuration => 'Duration';

  @override
  String get workoutSummarySets => 'Sets';

  @override
  String get workoutSummaryVolume => 'Volume';

  @override
  String workoutSummaryExerciseSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String workoutSummaryTopSet(String set) {
    return 'Top set $set';
  }

  @override
  String workoutSummaryTopSetTotal(String set, String volume) {
    return 'Top set $set  •  $volume total';
  }

  @override
  String get workoutLoggingRateTitle => 'Rate how hard each set was';

  @override
  String get workoutLoggingOffCaption =>
      'Off: the log sheet asks for weight and reps only.';

  @override
  String get workoutLoggingRpeCaption =>
      'RPE 6–10, optional on every working set. A top set rated 9.5 or 10 holds the overload suggestion at the same weight next time.';

  @override
  String get workoutLoggingRirCaption =>
      'Reps left in the tank, optional on every working set. A top set with none left holds the overload suggestion at the same weight next time.';

  @override
  String get workoutWarmupRampTitle => 'Warm-up ramp';

  @override
  String workoutWarmupRampSubtitle(String ramp) {
    return '$ramp of your working weight, after the bar';
  }

  @override
  String workoutWarmupRampSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
    );
    return '$_temp0';
  }

  @override
  String get workoutRestBetweenSets => 'Rest between sets';

  @override
  String get workoutRestUseDefault => 'Use the default instead';

  @override
  String workoutRestFollowingDefault(String rest) {
    return '$rest — following the default';
  }

  @override
  String workoutRestOwn(String rest) {
    return '$rest — set for this exercise';
  }

  @override
  String workoutSetPositionOf(int number, int planned) {
    return 'Set $number of $planned';
  }

  @override
  String workoutSetPosition(int number) {
    return 'Set $number';
  }

  @override
  String get workoutNotificationNoExercises => 'No exercises yet';

  @override
  String workoutNotificationNext(String set) {
    return 'Next: $set';
  }

  @override
  String get workoutNotificationResting => 'Resting';

  @override
  String get workoutNotificationLogSet => 'Log set';

  @override
  String get workoutNotificationSkipRest => 'Skip rest';

  @override
  String get workoutNotificationTapToOpen => 'Tap to open Gymfy';

  @override
  String get workoutNotificationChannel => 'Workout in progress';

  @override
  String get workoutNotificationChannelDescription =>
      'The current set and rest, with buttons to log and skip';

  @override
  String get overloadModeAuto => 'Auto';

  @override
  String get overloadModeFixed => 'Fixed';

  @override
  String get overloadModePercent => 'Percent';

  @override
  String overloadPercentValue(String percent) {
    return '$percent%';
  }

  @override
  String get overloadSuggestTitle => 'Suggest heavier weights';

  @override
  String get overloadSuggestSubtitle =>
      'When you hit every set at the top of your rep range, the next session opens with a bit more on the bar.';

  @override
  String get overloadHowMuchTitle => 'How much to add';

  @override
  String get overloadDeloadTitle => 'Deload';

  @override
  String get overloadDeloadCaption =>
      'After a run of increases, suggest dropping 10%. Only ever a suggestion — nothing changes on its own.';

  @override
  String get overloadDeloadNever => 'Never';

  @override
  String overloadDeloadInARow(int weeks) {
    return '$weeks in a row';
  }

  @override
  String overloadAutoCaption(
    String legs,
    String backChest,
    String armsShoulders,
  ) {
    return 'Bigger jumps on big lifts: $legs on legs, $backChest on back and chest, $armsShoulders on arms and shoulders. Core exercises are never auto-progressed.';
  }

  @override
  String get overloadFixedCaption => 'The same jump on every exercise.';

  @override
  String overloadPercentExample(
    String lightStep,
    String light,
    String heavyStep,
    String heavy,
  ) {
    return 'Adds $lightStep to a $light lift and $heavyStep to a $heavy one.';
  }

  @override
  String get platesTitle => 'Plate calculator';

  @override
  String get platesLoadingTitle => 'What are you loading?';

  @override
  String get platesTargetWeight => 'Target weight';

  @override
  String get platesHint =>
      'Dial in a target weight to see what goes on the bar.';

  @override
  String get platesBar => 'Bar';

  @override
  String get platesNoBar => 'None';

  @override
  String platesBelowBar(String target, String bar) {
    return '$target is lighter than the bar itself ($bar).';
  }

  @override
  String get platesEachSide => 'Each side';

  @override
  String platesExact(String bar, String plates) {
    return 'Bar $bar + plates $plates';
  }

  @override
  String platesClosest(String shortfall, String target) {
    return 'Closest loadable — $shortfall under your target of $target';
  }

  @override
  String get platesTotal => 'Total';

  @override
  String get platesClear => 'Clear';

  @override
  String platesInPlatesNoBar(String total) {
    return '$total in plates, no bar';
  }

  @override
  String platesBarPlusPlates(String bar, String plates) {
    return 'Bar $bar + $plates in plates';
  }

  @override
  String get platesTapToAdd => 'Tap to add a plate to each side';

  @override
  String platesPlateSemantics(String plate, int count) {
    return '$plate, $count on the bar';
  }

  @override
  String get platesChangeBarTooltip => 'Change the bar';

  @override
  String get platesJustTheBar => 'Just the bar';

  @override
  String platesInventoryCaption(String unit) {
    return 'The plates your gym has, in $unit. The calculator only suggests these.';
  }

  @override
  String get planShareTitle => 'Share a plan';

  @override
  String get planShareNoSplits =>
      'You have no splits to save yet — but you can still import one from someone else.';

  @override
  String get planShareSend => 'Send';

  @override
  String get planShareReceive => 'Receive';

  @override
  String get planShareImportTitle => 'Import a plan';

  @override
  String get planShareImportSubtitle => 'Open a .gymfy file someone sent you';

  @override
  String get planShareSaveDialogTitle => 'Save your plan';

  @override
  String get planShareSaved => 'Plan saved — send it from your files app.';

  @override
  String planShareSaveFailed(String error) {
    return 'Could not save that plan.\n$error';
  }

  @override
  String planSharePdfFailed(String error) {
    return 'Could not build that PDF.\n$error';
  }

  @override
  String planShareReadFailed(String error) {
    return 'Could not read that file.\n$error';
  }

  @override
  String planShareImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plans imported',
      one: 'Plan imported',
      zero: 'Nothing imported',
    );
    return '$_temp0';
  }

  @override
  String get planShareExplainer =>
      'A plan file holds your splits, their days and the exercises in them. It never includes your workouts, your weights, your measurements or your photos.';

  @override
  String get planShareSaveFile => 'Save file';

  @override
  String get planSharePdf => 'PDF';

  @override
  String get planShareErrorNotJson =>
      'That file isn\'t a Gymfy plan — it isn\'t even JSON.';

  @override
  String get planShareErrorNotPlan => 'That file isn\'t a Gymfy plan.';

  @override
  String planShareErrorWrongFormat(String extension) {
    return 'That file isn\'t a Gymfy plan. Look for a file ending in .$extension.';
  }

  @override
  String get planShareErrorTooNew =>
      'That plan was made by a newer version of Gymfy. Update the app and try again.';

  @override
  String get planShareErrorNoSplits =>
      'That plan file doesn\'t contain a split.';

  @override
  String get planShareRenameEmpty => 'Give it a name.';

  @override
  String get planShareRenameTaken => 'You already have a plan called that.';

  @override
  String get planShareRenameTitle => 'Name already used';

  @override
  String planShareRenameMessage(String name) {
    return 'You already have a plan called \"$name\". Give the imported one a different name — your own plan is kept either way.';
  }

  @override
  String get planShareRenameLabel => 'Plan name';

  @override
  String get planShareRenameSkip => 'Skip this one';

  @override
  String get planShareRenameImport => 'Import';

  @override
  String planSharePdfPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get planSharePdfNotScheduled => 'Not scheduled';

  @override
  String get planSharePdfNoExercises => 'No exercises';

  @override
  String get planSharePdfExercise => 'Exercise';

  @override
  String get planSharePdfSetsReps => 'Sets × reps';

  @override
  String get planSharePdfWarmup => 'Warm-up';

  @override
  String get planSharePdfWeight => 'Weight';

  @override
  String get programsTitle => 'Programs';

  @override
  String programsFacts(int days, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days a week',
      one: '1 day a week',
    );
    return '$_temp0 · $level';
  }

  @override
  String get programsLevelBeginner => 'Beginner';

  @override
  String get programsLevelIntermediate => 'Intermediate';

  @override
  String get programsIntro =>
      'Each programme is added as a new split you can edit like any other. Your own splits are never changed.';

  @override
  String get programsFallbackTitle => 'Program';

  @override
  String get programsNotFound => 'Program not found.';

  @override
  String programsOpenFailed(String error) {
    return 'Could not open this program.\n$error';
  }

  @override
  String get programsAddToSplits => 'Add to my splits';

  @override
  String programsAdded(String program) {
    return 'Added $program. Set it active to follow it.';
  }

  @override
  String programsAddFailed(String error) {
    return 'Could not add that program.\n$error';
  }

  @override
  String get programsSupersetNote =>
      'Marked exercises are done back to back as a superset.';

  @override
  String get programsBeginnerFullBodySummary =>
      'One machine-and-dumbbell session, three times a week';

  @override
  String get programsBeginnerFullBodyDescription =>
      'A gentle first programme built on machines, cables and dumbbells, so there is no barbell technique to learn before you start. The same full-body session three times a week, with rep ranges: once you hit the top of the range on every set, add a little weight.';

  @override
  String get programsFullBody5x5Summary =>
      'Two alternating barbell workouts, five sets of five';

  @override
  String get programsFullBody5x5Description =>
      'A classic linear-progression programme for building a strength base on the big barbell lifts. Alternate workout A and workout B three days a week and add a small amount of weight each time you complete every rep. Simple, fast, and it works for months before it stops.';

  @override
  String get programsUpperLowerSummary =>
      'Four days, each muscle trained twice a week';

  @override
  String get programsUpperLowerDescription =>
      'Two upper-body and two lower-body days. Each opens with a heavy compound in a low rep range, then moves to higher-rep accessories, with arm and shoulder work paired as supersets to save time. A good next step once three full-body days stop being enough.';

  @override
  String get programsPushPullLegsSummary =>
      'Six days, the classic bodybuilding rotation';

  @override
  String get programsPushPullLegsDescription =>
      'Pressing muscles, pulling muscles and legs on their own days, run twice through the week. Lots of volume for building muscle, with arm work done as supersets. Demanding on time: if six days is too many, run each day once and take the weekend off.';

  @override
  String get programsPercentageStrengthSummary =>
      'Four days, main lifts planned as a percentage of your 1RM';

  @override
  String get programsPercentageStrengthDescription =>
      'One day each for squat, bench, deadlift and overhead press. The main lift is planned as a percentage of your one-rep max, and Gymfy works out the weight from your tested or estimated 1RM, rounded to plates you can load. Pairs well with a training block on the split, such as three weeks of training and a deload week.';

  @override
  String get programsBodyPartSplitSummary =>
      'Five days, one muscle group per day';

  @override
  String get programsBodyPartSplitDescription =>
      'Chest, back, shoulders, arms and legs, each with a day to itself. Every muscle is trained hard once a week with plenty of exercises, and arm day runs as two supersets. Suits people who like long, focused sessions and can train five days in a row.';

  @override
  String get programsBlockTitle => 'Training block';

  @override
  String get programsBlockIntro =>
      'Train for a set number of weeks, then take one lighter deload week, then start again. During the deload week the suggested weights drop to the deload load.';

  @override
  String get programsBlockSwitch => 'Run in training blocks';

  @override
  String get programsBlockWeeksLabel => 'Training weeks';

  @override
  String get programsBlockFewerWeeks => 'Fewer weeks';

  @override
  String get programsBlockMoreWeeks => 'More weeks';

  @override
  String programsBlockWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get programsBlockThenDeload => 'then 1 deload week';

  @override
  String get programsBlockDeloadLoad => 'Deload load';

  @override
  String get programsBlockOfWorkingWeights => 'of your usual working weights';

  @override
  String get programsBlockWeekOneBegan => 'Week 1 began';

  @override
  String get programsBlockPickerHelp => 'Week 1 began on';

  @override
  String programsBlockStarts(String date) {
    return 'Starts $date';
  }

  @override
  String programsBlockToday(String week) {
    return 'Today: $week';
  }

  @override
  String get programsBlockDeloadWeek => 'Deload week';

  @override
  String programsBlockWeekOf(int week, int weeks) {
    return 'Week $week of $weeks';
  }

  @override
  String programsBlockBannerDeload(String percent) {
    return 'Suggested weights at $percent. A new block starts next week.';
  }

  @override
  String programsBlockBannerNextWeek(String percent, int cycle) {
    return 'Deload week at $percent next week · block $cycle';
  }

  @override
  String programsBlockBannerInWeeks(String percent, int weeks, int cycle) {
    return 'Deload at $percent in $weeks weeks · block $cycle';
  }

  @override
  String get programsPercentOfMax => '% of 1RM';

  @override
  String get programsPercentNoMax =>
      'No 1RM yet. Log a set or enter a tested max and the weight appears in your workout.';

  @override
  String programsPercentPreview(String weight, String max) {
    return '≈ $weight today, from your 1RM of $max.';
  }

  @override
  String get exercisesTitle => 'Exercises';

  @override
  String get exercisesCancelSelection => 'Cancel selection';

  @override
  String exercisesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get exercisesAddToDayTooltip => 'Add to day';

  @override
  String exercisesLoadFailed(String error) {
    return 'Could not load exercises.\n$error';
  }

  @override
  String get exercisesAddExercise => 'Add exercise';

  @override
  String get exercisesSearchHint => 'Search by name or muscle';

  @override
  String get exercisesClearSearch => 'Clear search';

  @override
  String get exercisesGroupChest => 'Chest';

  @override
  String get exercisesGroupBack => 'Back';

  @override
  String get exercisesGroupShoulders => 'Shoulders';

  @override
  String get exercisesGroupArms => 'Arms';

  @override
  String get exercisesGroupLegs => 'Legs';

  @override
  String get exercisesGroupCore => 'Core';

  @override
  String get exercisesGroupNeck => 'Neck';

  @override
  String get exercisesNoMatchesTitle => 'Nothing matches';

  @override
  String get exercisesNoMatchesMessage =>
      'Try a different word, or clear a muscle filter.';

  @override
  String get exercisesCustomBadge => 'Custom';

  @override
  String get exercisesDetailTitle => 'Exercise';

  @override
  String exercisesDetailLoadFailed(String error) {
    return 'Could not load this exercise.\n$error';
  }

  @override
  String get exercisesNotFound => 'Exercise not found.';

  @override
  String exercisesDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get exercisesDeleteWithHistory =>
      'It will be removed from your library and from every picker. Workouts you already logged with it keep their sets.';

  @override
  String get exercisesDeleteNoHistory =>
      'It has never been logged, so it will be removed completely.';

  @override
  String exercisesArchived(String name) {
    return '$name removed — past workouts kept it';
  }

  @override
  String exercisesDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get exercisesMusclesWorked => 'Muscles worked';

  @override
  String get exercisesPreviewSoon => 'Preview coming soon';

  @override
  String get exercisesEditTitle => 'Edit exercise';

  @override
  String get exercisesNewTitle => 'New exercise';

  @override
  String get exercisesNameLabel => 'Name';

  @override
  String get exercisesNameHint => 'e.g. Cable Fly';

  @override
  String get exercisesMusclesHelp =>
      'Drives the muscle map, so pick everything this lift actually hits.';

  @override
  String get exercisesEquipment => 'Equipment';

  @override
  String get exercisesPlateLoaded => 'Loaded with plates';

  @override
  String get exercisesPlateLoadedSubtitle =>
      'Log sets by tapping plates instead of typing a weight. For barbell and EZ-bar lifts.';

  @override
  String get exercisesImage => 'Image';

  @override
  String get exercisesImageHelp =>
      'Optional. A GIF from your gallery animates just like the built-in ones.';

  @override
  String get exercisesChooseImage => 'Choose image';

  @override
  String get exercisesReplaceImage => 'Replace';

  @override
  String get exercisesRemoveImage => 'Remove';

  @override
  String exercisesAddToDayTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count exercises to day',
      one: 'Add to day',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoDaysTitle => 'No workout days yet';

  @override
  String get exercisesNoDaysMessage =>
      'Create a split with at least one day in the Workout tab, then come back here.';

  @override
  String get exercisesNoteLabel => 'Note';

  @override
  String get exercisesNoteHint =>
      'Seat height, pin, grip width, which machine…';

  @override
  String get exercisesNoteClear => 'Clear';

  @override
  String get exercisesNoteEmpty => 'Add a note — seat height, pin, grip…';

  @override
  String exercisesEquipmentFilterActive(int count) {
    return 'Equipment ($count)';
  }

  @override
  String get exercisesEquipmentFilter => 'Filter by equipment';

  @override
  String get exercisesAllEquipment => 'All equipment';
}
