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
  String get workoutSupersetActionSubtitle =>
      'Pair it with the exercise before or after';

  @override
  String workoutSupersetWithExercise(String exercise) {
    return 'Superset with $exercise';
  }

  @override
  String get workoutSupersetBackToBack => 'Back to back, rest after the last';

  @override
  String get workoutSupersetScopeTitle => 'For how long?';

  @override
  String get workoutSupersetPlanApart =>
      'These two aren\'t next to each other in the plan, so the superset is for this workout only.';

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

  @override
  String get strengthTierBeginner => 'Beginner';

  @override
  String get strengthTierNovice => 'Novice';

  @override
  String get strengthTierIntermediate => 'Intermediate';

  @override
  String get strengthTierAdvanced => 'Advanced';

  @override
  String get strengthTierElite => 'Elite';

  @override
  String get calculatorOneRmTitle => '1RM calculator';

  @override
  String get calculatorOneRmSetTitle => 'The set you did';

  @override
  String get calculatorOneRmWeightLabel => 'Weight lifted';

  @override
  String get calculatorOneRmReps => 'Reps';

  @override
  String get calculatorOneRmEmpty =>
      'Enter the weight you lifted and how many reps you got, and the estimate appears here.';

  @override
  String get calculatorOneRmEstimated => 'Estimated 1RM';

  @override
  String get calculatorOneRmSingleRep =>
      'A single rep is already your max — no estimating needed.';

  @override
  String get calculatorOneRmFormulasAgree => 'All three formulas agree.';

  @override
  String calculatorOneRmRange(int count, String low, String high, String unit) {
    return 'Average of $count formulas • they range $low–$high $unit';
  }

  @override
  String get calculatorOneRmPlates => 'What plates is that?';

  @override
  String calculatorOneRmRoughGuess(int reps) {
    return 'Above $reps reps this is a rough guess — the formula was built from heavy sets, and high-rep sets say more about your endurance than your max.';
  }

  @override
  String get calculatorFormulaTitle => 'Formula comparison';

  @override
  String get calculatorFormulaEpleyNote => 'The common default';

  @override
  String get calculatorFormulaBrzyckiNote => 'Conservative on high reps';

  @override
  String get calculatorFormulaLanderNote => 'Close to Epley when heavy';

  @override
  String get calculatorFormulaCaveat =>
      'All three are curve fits, not measurements. They line up on heavy sets and drift apart as the reps climb — if you need the real number, test it.';

  @override
  String get calculatorLoadTitle => 'What to load';

  @override
  String get calculatorLoadSubtitle =>
      'Weights you should manage for a given rep count.';

  @override
  String calculatorLoadReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String get calculatorRankTitle => 'Strength rank';

  @override
  String get calculatorYourLifts => 'Your lifts';

  @override
  String calculatorRankNotLogged(String names) {
    return 'Not logged yet: $names';
  }

  @override
  String get calculatorRankHowToReadTitle => 'How to read this';

  @override
  String get calculatorRankHowToReadMessage =>
      'Standards are population averages from published tables, not physics. Limb lengths and bodyweight both skew them — treat a rank as a rough bracket, not a verdict.';

  @override
  String calculatorRankStandards(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Female standards',
      'other': 'Male standards',
    });
    return '$_temp0';
  }

  @override
  String calculatorRankBasis(String standards, String bodyweight) {
    return '$standards • $bodyweight bodyweight';
  }

  @override
  String calculatorRankBasisDated(
    String standards,
    String bodyweight,
    String date,
  ) {
    return '$standards • $bodyweight bodyweight ($date)';
  }

  @override
  String calculatorRankUseSex(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Use female',
      'other': 'Use male',
    });
    return '$_temp0';
  }

  @override
  String calculatorLiftTested(String weight, String ratio) {
    return '$weight tested • $ratio× bodyweight';
  }

  @override
  String calculatorLiftEstimated(String weight, String ratio) {
    return '$weight estimated • $ratio× bodyweight';
  }

  @override
  String get calculatorLiftTopTier => 'Top tier — nothing above this';

  @override
  String calculatorLiftToNext(String weight, String tier) {
    return '$weight to $tier';
  }

  @override
  String get calculatorNothingRankedTitle => 'No ranked lifts yet';

  @override
  String get calculatorNothingRankedMessage =>
      'Log a set of any barbell or cable lift — bench, squat, deadlift, press, row, curl, pulldown — and its rank appears here. Dumbbell, machine and bodyweight work is left out: there is no way to compare those numbers between two gyms.';

  @override
  String get calculatorSetupTitle => 'Before we can rank you';

  @override
  String get calculatorSetupMessage =>
      'A rank compares your lifts to your own bodyweight, so it needs two things from you.';

  @override
  String get calculatorSetupSexTitle => 'Which standards should we use?';

  @override
  String get calculatorSetupSexMessage =>
      'Published strength standards differ by sex: a bodyweight bench press is intermediate for men and advanced for women. Picking the wrong table would just give you a wrong rank.';

  @override
  String get calculatorSetupBodyweightTitle => 'Log your bodyweight';

  @override
  String get calculatorSetupBodyweightMessage =>
      'Ranks are a ratio of what you lift to what you weigh. Add your weight under Progress → Measurements and it shows up here.';

  @override
  String get calculatorSetupOpenMeasurements => 'Open measurements';

  @override
  String get calculatorBadgeHeading => 'STRENGTH RANK';

  @override
  String calculatorBadgeTested(String weight, String ratio) {
    return '$weight tested · $ratio× bodyweight';
  }

  @override
  String calculatorBadgeEstimated(String weight, String ratio) {
    return '$weight estimated · $ratio× bodyweight';
  }

  @override
  String get calculatorBadgeTopTier => 'Top tier';

  @override
  String calculatorBadgeToNext(String weight, String tier) {
    return '+$weight to $tier';
  }

  @override
  String get calculatorBadgeNudgeTitle => 'This lift can be ranked';

  @override
  String get calculatorBadgeNudgeMessage =>
      'Add your bodyweight and pick a standards table to see where you sit.';

  @override
  String get statsReadingVolume => 'Volume';

  @override
  String get statsReadingFatigue => 'Fatigue';

  @override
  String get statsFatigueEmpty =>
      'Everything is recovered — nothing you have trained recently is still weighing on you.';

  @override
  String get statsVolumeEmpty =>
      'No training logged in the last 7 days — finish a workout to light up your muscle map.';

  @override
  String get statsFatigueCaption =>
      'Brighter means less recovered — recent work halves every two days.';

  @override
  String get statsVolumeCaption =>
      'Brighter means more volume this week, relative to your hardest-hit muscle.';

  @override
  String get statsFatigueContrastCaption =>
      'Each muscle has its own colour. Brighter still means less recovered.';

  @override
  String get statsRankNeedsSetup =>
      'Ranks compare your lifts to your own bodyweight, so they need your bodyweight and which standards table to use.';

  @override
  String get statsRankSetUp => 'Set it up';

  @override
  String get statsRankEmpty =>
      'Log a barbell or cable lift — bench, squat, deadlift, press, row, curl — and its medal appears here.';

  @override
  String get statsRankFullBreakdown => 'See the full breakdown';

  @override
  String get statsOverallLabel => 'Overall';

  @override
  String statsOverallEvery(String tier) {
    String _temp0 = intl.Intl.selectLogic(tier, {
      'beginner': 'beginner',
      'novice': 'novice',
      'intermediate': 'intermediate',
      'advanced': 'advanced',
      'other': 'elite',
    });
    return 'Every ranked lift is $_temp0.';
  }

  @override
  String statsOverallWeakest(String best) {
    String _temp0 = intl.Intl.selectLogic(best, {
      'beginner': 'beginner',
      'novice': 'novice',
      'intermediate': 'intermediate',
      'advanced': 'advanced',
      'other': 'elite',
    });
    return 'Your weakest ranked lift. Your best is $_temp0.';
  }

  @override
  String statsRankRowTested(String tier, String weight) {
    return '$tier • $weight tested';
  }

  @override
  String statsRankRowEstimated(String tier, String weight) {
    return '$tier • $weight est.';
  }

  @override
  String get statsRankRowTop => 'Top';

  @override
  String get statsAllTimeTitle => 'All time';

  @override
  String statsTotalsWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'workouts',
      one: 'workout',
    );
    return '$_temp0';
  }

  @override
  String statsTotalsSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sets',
      one: 'set',
    );
    return '$_temp0';
  }

  @override
  String get statsTotalsTrained => 'trained';

  @override
  String get statsTotalsLifted => 'lifted';

  @override
  String statsTotalsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String statsTotalsStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'day streak',
    );
    return '$_temp0';
  }

  @override
  String statsComparisonPiano(String times) {
    return 'That is $times× a grand piano.';
  }

  @override
  String statsComparisonCar(String times) {
    return 'That is $times× a small car.';
  }

  @override
  String statsComparisonRhino(String times) {
    return 'That is $times× a rhino.';
  }

  @override
  String statsComparisonBus(String times) {
    return 'That is $times× a London bus.';
  }

  @override
  String statsComparisonWhale(String times) {
    return 'That is $times× a humpback whale.';
  }

  @override
  String statsComparisonJumbo(String times) {
    return 'That is $times× a loaded 747.';
  }

  @override
  String get caloriesLogTitle => 'Calorie log';

  @override
  String caloriesLogLoadFailed(String error) {
    return 'Could not load the log.\n$error';
  }

  @override
  String get caloriesAddMeal => 'Add meal';

  @override
  String get commonPreviousDay => 'Previous day';

  @override
  String get commonNextDay => 'Next day';

  @override
  String get caloriesNoMeals => 'No meals logged for this day yet.';

  @override
  String get caloriesMealsTitle => 'Meals';

  @override
  String caloriesLeft(int count) {
    return '$count left';
  }

  @override
  String caloriesOver(int count) {
    return '$count over';
  }

  @override
  String caloriesMacroLine(int protein, int carbs, int fat) {
    return 'P ${protein}g • C ${carbs}g • F ${fat}g';
  }

  @override
  String get caloriesDeleteEntry => 'Delete entry';

  @override
  String get caloriesMealLabel => 'Meal';

  @override
  String get caloriesMealHint => 'e.g. Chicken & rice';

  @override
  String get caloriesCaloriesLabel => 'Calories (kcal)';

  @override
  String get caloriesProteinLabel => 'Protein g';

  @override
  String get caloriesCarbsLabel => 'Carbs g';

  @override
  String get caloriesFatLabel => 'Fat g';

  @override
  String get caloriesWeekTitle => 'This week';

  @override
  String caloriesWeekLoadFailed(String error) {
    return 'Could not load the week.\n$error';
  }

  @override
  String get caloriesWeekCalories => 'Calories';

  @override
  String get caloriesWeekNothing => 'Nothing logged in the last 7 days.';

  @override
  String caloriesWeekSummary(int average, int onTarget, int logged) {
    String _temp0 = intl.Intl.pluralLogic(
      logged,
      locale: localeName,
      other: '$logged logged days',
      one: '1 logged day',
    );
    return '$average kcal average • $onTarget of $_temp0 within goal';
  }

  @override
  String caloriesWeekGoalLine(int goal) {
    return 'Dashed line = daily goal ($goal kcal)';
  }

  @override
  String get caloriesMacrosTitle => 'Macros';

  @override
  String get caloriesMacrosEmpty => 'Add meals with macros to see your split.';

  @override
  String get caloriesMacroProtein => 'Protein';

  @override
  String get caloriesMacroCarbs => 'Carbs';

  @override
  String get caloriesMacroFat => 'Fat';

  @override
  String caloriesMacroShare(int grams, int percent) {
    return '${grams}g · $percent%';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarDayTrainedSemantics(String date) {
    return '$date, trained';
  }

  @override
  String calendarRestDay(String day) {
    return '$day — rest day';
  }

  @override
  String calendarDaySets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsExercise => 'Exercise';

  @override
  String goalsTitleBodyweight(String weight) {
    return 'Bodyweight · $weight';
  }

  @override
  String goalsWorkoutsPerWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts a week',
      one: '1 workout a week',
    );
    return '$_temp0';
  }

  @override
  String goalsValueOf(int current, int target) {
    return '$current of $target';
  }

  @override
  String get goalsCaptionWeekDone => 'Done this week';

  @override
  String goalsCaptionWeekToGo(int count) {
    return '$count to go this week';
  }

  @override
  String goalsCaptionWeeksInARow(int count) {
    return '$count weeks in a row';
  }

  @override
  String goalsCaptionReached(String date) {
    return 'Reached $date';
  }

  @override
  String goalsCaptionWasDue(String date) {
    return 'Was due $date';
  }

  @override
  String get goalsCaptionDueToday => 'Due today';

  @override
  String goalsCaptionDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String goalsCaptionBy(String date) {
    return 'By $date';
  }

  @override
  String get goalsCaptionNotTrained => 'Not trained yet';

  @override
  String get goalsCaptionNoWeighIn => 'No weigh-in yet';

  @override
  String get goalsCaptionHeaviest => 'Heaviest working set';

  @override
  String get goalsCaptionLatestWeighIn => 'Latest weigh-in';

  @override
  String get goalsProblemPastDate => 'Pick a date that has not passed yet.';

  @override
  String get goalsProblemChooseExercise => 'Choose the exercise.';

  @override
  String get goalsProblemSetWeight => 'Set the weight to reach.';

  @override
  String get goalsProblemAlreadyLifted =>
      'You have already lifted that — aim higher.';

  @override
  String goalsProblemWorkoutsRange(int max) {
    return 'Pick between 1 and $max workouts a week.';
  }

  @override
  String get goalsProblemLogWeight => 'Log your current weight first.';

  @override
  String get goalsProblemSameWeight =>
      'That is the weight you are now — pick a different one.';

  @override
  String get goalsSectionWorking => 'Working on';

  @override
  String get goalsSectionReached => 'Reached';

  @override
  String get goalsSectionArchived => 'Archived';

  @override
  String get goalsActionsTooltip => 'More';

  @override
  String get goalsRestore => 'Restore';

  @override
  String get goalsArchive => 'Archive';

  @override
  String get goalsRestoreSubtitle => 'Back on Home and in the list';

  @override
  String get goalsArchiveSubtitle => 'Off Home, kept here for the record';

  @override
  String get goalsDeleteTitle => 'Delete this goal?';

  @override
  String get goalsDeleteFrequencyMessage =>
      'Your workouts stay as they are. Only the goal goes.';

  @override
  String get goalsDeleteMessage =>
      'Your log stays as it is. Archive it instead to keep it on record.';

  @override
  String get goalsEmptyTitle => 'No goals yet';

  @override
  String get goalsEmptyMessage =>
      'A weight on a lift by a date, a number of workouts every week, or a bodyweight to reach. Progress fills in from what you log.';

  @override
  String get goalsSetGoal => 'Set a goal';

  @override
  String goalsCardActive(int count) {
    return '$count active';
  }

  @override
  String goalsCardMore(int count) {
    return '+$count more';
  }

  @override
  String get goalsLinkYourGoals => 'Your goals';

  @override
  String get goalsLinkEmpty =>
      'A lift, a weekly habit or a bodyweight to reach';

  @override
  String goalsLinkReachedOnly(int reached) {
    return '$reached reached — set the next one';
  }

  @override
  String goalsLinkActiveOnly(int active) {
    return '$active in progress';
  }

  @override
  String goalsLinkBoth(int active, int reached) {
    return '$active in progress, $reached reached';
  }

  @override
  String get goalsCelebrationWeekDone => 'Week done';

  @override
  String get goalsCelebrationReached => 'Goal reached';

  @override
  String get goalsCelebrationNice => 'Nice';

  @override
  String get goalsFormEditTitle => 'Edit goal';

  @override
  String get goalsFormBy => 'By';

  @override
  String get goalsFormNoDeadline => 'No deadline';

  @override
  String get goalsFormSaveChanges => 'Save changes';

  @override
  String get goalsFormSaveGoal => 'Save goal';

  @override
  String get goalsFormChooseExercise => 'Choose an exercise';

  @override
  String get goalsFormLiftHint =>
      'Counts your heaviest working set — warm-ups and drop sets never do — or a tested max.';

  @override
  String goalsFormLiftHintBest(String weight) {
    return 'Your best so far: $weight. Counts your heaviest working set, or a tested max.';
  }

  @override
  String get goalsFormTarget => 'Target';

  @override
  String get goalsFormPickLift => 'Goal for which lift?';

  @override
  String get goalsFormHowOften => 'How often';

  @override
  String get goalsFormWorkoutsAWeek => 'Workouts a week';

  @override
  String goalsFormFrequencyHint(String weekday) {
    return 'Counts finished workouts, free ones included. Weeks start on $weekday.';
  }

  @override
  String goalsFormStartedFrom(String weight) {
    return 'Started from $weight.';
  }

  @override
  String goalsFormStartingFrom(String weight, String day) {
    return 'Starting from $weight, logged $day.';
  }

  @override
  String get goalsFormNoWeighIn =>
      'No weigh-in yet. What do you weigh today? It is saved to your measurements too.';

  @override
  String get goalsFormNow => 'Now';

  @override
  String get goalsFormReachBy => 'Reach it by';

  @override
  String goalsFormInWeeks(int count) {
    return 'In $count weeks';
  }

  @override
  String get goalsFormInSixMonths => 'In 6 months';

  @override
  String get goalsFormPickDate => 'Pick a date';

  @override
  String goalsFormSaveFailed(String error) {
    return 'Could not save that goal.\n$error';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressViewBody => 'Body';

  @override
  String get progressViewTrends => 'Trends';

  @override
  String get progressViewAllTime => 'All-time';

  @override
  String get progressPerExercise => 'Per exercise';

  @override
  String get progressTrackedByHand => 'Tracked by hand';

  @override
  String get progressMeasurementsTitle => 'Measurements';

  @override
  String get progressMeasurementsSubtitle =>
      'Weight, waist, arms — and how they have moved';

  @override
  String get progressPhotosTitle => 'Progress photos';

  @override
  String get progressPhotosSubtitle => 'Compare two dates side by side';

  @override
  String get progressNoHistoryTitle => 'Nothing logged yet';

  @override
  String get progressNoHistoryMessage =>
      'Finish a workout and its exercises appear here, each with its own chart.';

  @override
  String get progressClear => 'Clear';

  @override
  String progressExerciseLoadFailed(String error) {
    return 'Could not load progress.\n$error';
  }

  @override
  String get progressExerciseNoSessions =>
      'No logged sessions for this exercise yet.';

  @override
  String get progressExerciseRecords => 'Personal records';

  @override
  String get progressExerciseLongestHold => 'Longest hold';

  @override
  String get progressExerciseTopSetWeight => 'Top-set weight';

  @override
  String get progressExerciseLongestHoldCaption =>
      'The longest single hold each session.';

  @override
  String get progressExerciseTopSetCaption =>
      'The heaviest set you did each session.';

  @override
  String get progressExerciseTrendHint =>
      'Log this exercise in more sessions to see a trend line.';

  @override
  String get progressOneRmTested => 'Tested 1RM';

  @override
  String get progressOneRmEstimated => 'Estimated 1RM';

  @override
  String progressOneRmTestedOn(String date) {
    return 'Tested on $date';
  }

  @override
  String progressOneRmTestedOnSuggests(String date, String weight) {
    return 'Tested on $date • log suggests ≈ $weight';
  }

  @override
  String get progressOneRmTapToEnter => 'Tap to enter a max you tested';

  @override
  String progressOneRmSingle(String date) {
    return 'You lifted this for a single on $date';
  }

  @override
  String progressOneRmFrom(String weight, int reps, String date) {
    return 'From $weight × $reps on $date';
  }

  @override
  String get progressRecordHeaviest => 'Heaviest';

  @override
  String get progressRecordMostTime => 'Most time';

  @override
  String get progressRecordBestVolume => 'Best volume';

  @override
  String progressRecordInASession(String date) {
    return 'in a session • $date';
  }

  @override
  String get progressMeasurementsHistoryTooltip => 'History';

  @override
  String progressMeasurementsLoadFailed(String error) {
    return 'Could not load measurements.\n$error';
  }

  @override
  String progressMeasurementsLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get progressMeasurementsNothing =>
      'Nothing measured on this day yet — tap a row to add it.';

  @override
  String progressMeasurementsWas(String value, String date) {
    return 'Was $value on $date';
  }

  @override
  String get progressHistoryTitle => 'Measurement history';

  @override
  String progressHistoryCount(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$count measurements over $_temp0';
  }

  @override
  String progressHistoryNone(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weight': 'weight',
      'chest': 'chest',
      'waist': 'waist',
      'hips': 'hips',
      'arms': 'arms',
      'other': 'legs',
    });
    return 'No $_temp0 measurements yet';
  }

  @override
  String progressHistoryOnlyOne(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weight': 'weight',
      'chest': 'chest',
      'waist': 'waist',
      'hips': 'hips',
      'arms': 'arms',
      'other': 'legs',
    });
    return 'Only one $_temp0 measurement so far';
  }

  @override
  String progressHistoryNoneHint(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weight': 'weight',
      'chest': 'chest',
      'waist': 'waist',
      'hips': 'hips',
      'arms': 'arms',
      'other': 'legs',
    });
    return 'Measure your $_temp0 on the measurements screen and it will show up here.';
  }

  @override
  String progressHistoryOnlyOneHint(String value, String date) {
    return '$value on $date. Log it again on another day to see a trend.';
  }

  @override
  String get progressPhotosCompareTooltip => 'Compare';

  @override
  String progressPhotosLoadFailed(String error) {
    return 'Could not load photos.\n$error';
  }

  @override
  String get progressPhotosAdd => 'Add photo';

  @override
  String get progressPhotosClose => 'Close';

  @override
  String get progressPhotosDeleteTooltip => 'Delete photo';

  @override
  String get progressPhotosDeleteTitle => 'Delete photo?';

  @override
  String get progressPhotosDeleteMessage =>
      'This removes the photo from Gymfy for good. The original in your gallery is untouched.';

  @override
  String get progressPhotosNoteLabel => 'Note (optional)';

  @override
  String get progressPhotosNoteHint => 'e.g. front relaxed';

  @override
  String get progressPhotosEmptyTitle => 'No photos yet';

  @override
  String get progressPhotosEmptyMessage =>
      'Add a photo from your gallery and Gymfy keeps its own copy, so your progress shots stay put even if you clear your gallery.';

  @override
  String get progressCompareTitle => 'Compare';

  @override
  String get progressComparePickBefore => 'Pick the \"before\" photo';

  @override
  String get progressComparePickAfter => 'Pick the \"after\" photo';

  @override
  String get progressCompareSameDay => 'Same day';

  @override
  String progressCompareDaysApart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days apart',
      one: '1 day apart',
    );
    return '$_temp0';
  }

  @override
  String progressCompareWeeksApart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks apart',
      one: '1 week apart',
    );
    return '$_temp0';
  }

  @override
  String progressCompareMonthsApart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months apart',
      one: '1 month apart',
    );
    return '$_temp0';
  }

  @override
  String get progressCompareBefore => 'Before';

  @override
  String get progressCompareAfter => 'After';

  @override
  String get progressCompareNotEnoughTitle => 'Nothing to compare yet';

  @override
  String get progressCompareNotEnoughMessage =>
      'Add at least two progress photos and you can fade between any two of them here.';

  @override
  String get progressActivityTitle => 'Activity';

  @override
  String progressActivityRestDay(String day) {
    return '$day — rest day';
  }

  @override
  String progressActivityUntimed(String day) {
    return '$day — trained, length not recorded';
  }

  @override
  String progressActivityTrained(String day, String duration) {
    return '$day — $duration trained';
  }

  @override
  String progressActivityTrainedPlusUntimed(String day, String duration) {
    return '$day — $duration trained, and one more not recorded';
  }

  @override
  String progressActivityYear(int days, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 • $duration this year';
  }

  @override
  String get progressActivityLess => 'Less';

  @override
  String get progressActivityMore => 'More';

  @override
  String get progressStreakTitle => 'Streak';

  @override
  String progressStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get progressStreakCurrent => 'current';

  @override
  String get progressStreakBest => 'best ever';

  @override
  String progressRecapEmpty(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'week',
      'month': 'month',
      'other': 'year',
    });
    return 'Nothing logged in the last $_temp0.';
  }

  @override
  String get progressRecapVolumeTitle => 'Volume';

  @override
  String progressRecapVolumeDetail(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'week',
      'month': 'month',
      'other': 'year',
    });
    return 'lifted in the last $_temp0';
  }

  @override
  String get progressRecapOneDay => 'One day is not a trend yet.';

  @override
  String get progressRecapWorkoutsTitle => 'Workouts';

  @override
  String progressRecapSessionsDetail(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'week': 'week',
      'month': 'month',
      'other': 'year',
    });
    return 'sessions in the last $_temp0';
  }

  @override
  String progressRecapSessionsRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personal records',
      one: '1 personal record',
    );
    return 'sessions • $_temp0';
  }

  @override
  String progressRecapWorkoutsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String get progressRecapMusclesTitle => 'What you trained';

  @override
  String get progressRecapMusclesDetail => 'took the most sets';

  @override
  String progressRecapMuscleSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsMonthlyTitle => 'Monthly review';

  @override
  String get reviewsYearTitle => 'Year in training';

  @override
  String reviewsMonthlySubtitle(String period) {
    return '$period — and how it compares';
  }

  @override
  String reviewsYearSubtitle(String period) {
    return '$period, start to finish';
  }

  @override
  String get reviewsShareTooltip => 'Share as image';

  @override
  String reviewsShareTitle(String period) {
    return 'Share your $period review';
  }

  @override
  String get reviewsSaveImageTitle => 'Save image';

  @override
  String get reviewsImageSaved => 'Image saved — send it from your files.';

  @override
  String reviewsImageFailed(String error) {
    return 'Could not make the image.\n$error';
  }

  @override
  String get reviewsEarlier => 'Earlier';

  @override
  String get reviewsLater => 'Later';

  @override
  String reviewsNoWorkoutsMonth(String period) {
    return 'No workouts in $period.';
  }

  @override
  String reviewsNoWorkoutsYear(String period) {
    return 'No workouts in $period.';
  }

  @override
  String reviewsStepBack(String span) {
    String _temp0 = intl.Intl.selectLogic(span, {
      'month': 'month',
      'other': 'year',
    });
    return 'Step back to an earlier $_temp0 with the arrows above.';
  }

  @override
  String get reviewsExercisesTitle => 'Exercises';

  @override
  String reviewsSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String reviewsWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String reviewsVersus(String period) {
    return 'vs $period';
  }

  @override
  String get reviewsCardMonthHeading => 'YOUR MONTH IN TRAINING';

  @override
  String get reviewsCardYearHeading => 'YOUR YEAR IN TRAINING';

  @override
  String reviewsCardSoFar(String period) {
    return 'So far — $period is not over yet';
  }

  @override
  String reviewsCardWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'workouts',
      one: 'workout',
    );
    return '$_temp0';
  }

  @override
  String get reviewsCardLifted => 'lifted';

  @override
  String get reviewsCardTrained => 'trained';

  @override
  String reviewsCardTrainedUntimed(int count) {
    return 'trained, $count not timed';
  }

  @override
  String reviewsCardRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personal records',
      one: 'personal record',
    );
    return '$_temp0';
  }

  @override
  String reviewsCardDaysTrained(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days trained',
      one: '1 day trained',
    );
    return '$_temp0';
  }

  @override
  String reviewsCardLongestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'longest streak $_temp0';
  }

  @override
  String get reviewsCardTopExercises => 'Top exercises';

  @override
  String get reviewsCardMostTrained => 'Most trained';

  @override
  String get reviewsCardTrackedWith => 'Tracked with Gymfy';

  @override
  String get healthConnectAvailabilityUnsupported =>
      'Not available on this phone';

  @override
  String get healthConnectAvailabilityNotInstalled => 'Not installed';

  @override
  String get healthConnectAvailabilityNeedsUpdate => 'Needs an update';

  @override
  String get healthConnectAvailabilityAvailable => 'Available';

  @override
  String get healthConnectIntro =>
      'Android\'s store for health data, on this phone. Gymfy can add your finished workouts to it and fill in your bodyweight from a smart scale. It all stays on the device — Gymfy has no internet access.';

  @override
  String get healthConnectChecking => 'Checking…';

  @override
  String get healthConnectInstall => 'Install';

  @override
  String get healthConnectUpdate => 'Update';

  @override
  String get healthConnectStoreFailed => 'Could not open the Play Store.';

  @override
  String get healthConnectWriteTitle => 'Write workouts';

  @override
  String get healthConnectWriteSubtitle =>
      'Each workout you finish appears as strength training, with its name, start and end';

  @override
  String get healthConnectReadTitle => 'Read bodyweight';

  @override
  String get healthConnectReadSubtitle =>
      'Weigh-ins fill in days where you haven\'t entered a weight. A weight you typed is never replaced';

  @override
  String get healthConnectWriteRefused =>
      'Health Connect did not allow Gymfy to write workouts.';

  @override
  String get healthConnectReadRefused =>
      'Health Connect did not allow Gymfy to read your weight.';

  @override
  String healthConnectWeighInsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count weigh-ins to your measurements.',
      one: 'Added 1 weigh-in to your measurements.',
    );
    return '$_temp0';
  }

  @override
  String get healthConnectPermissionsTitle => 'Permissions';

  @override
  String healthConnectPermissionsMissing(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'write': 'write workouts',
      'read': 'read your weight',
      'other': 'write workouts or read your weight',
    });
    return 'Health Connect no longer lets Gymfy $_temp0';
  }

  @override
  String healthConnectPermissionsStatus(String workouts, String weight) {
    String _temp0 = intl.Intl.selectLogic(workouts, {
      'yes': 'allowed',
      'other': 'not allowed',
    });
    String _temp1 = intl.Intl.selectLogic(weight, {
      'yes': 'allowed',
      'other': 'not allowed',
    });
    return 'Workouts: $_temp0 · Weight: $_temp1';
  }

  @override
  String get healthConnectGrant => 'Grant';

  @override
  String get healthConnectBackfillTile => 'Write past workouts';

  @override
  String get healthConnectBackfillTileSubtitle =>
      'Only workouts finished from now on are written by themselves';

  @override
  String get healthConnectBackfillTitle => 'Write past workouts?';

  @override
  String get healthConnectBackfillMessage =>
      'Adds every finished workout from before you switched this on to Health Connect, as strength training with its start and end time. Workouts already there are not added twice.';

  @override
  String get healthConnectBackfillConfirm => 'Write';

  @override
  String get healthConnectWriteNotAllowed =>
      'Health Connect is not allowing Gymfy to write workouts.';

  @override
  String healthConnectBackfillWrote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrote $count workouts to Health Connect.',
      one: 'Wrote 1 workout to Health Connect.',
      zero: 'No workouts needed writing.',
    );
    return '$_temp0';
  }

  @override
  String healthConnectBackfillUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count without a recorded length were left out.',
      one: '1 without a recorded length was left out.',
    );
    return '$_temp0';
  }

  @override
  String healthConnectBackfillStopped(String error) {
    return 'Then it stopped: $error';
  }

  @override
  String get healthConnectManageTitle => 'Manage in Health Connect';

  @override
  String get healthConnectManageSubtitle =>
      'Revoke access, or delete what Gymfy wrote there';

  @override
  String get healthConnectOpenFailed => 'Could not open Health Connect.';

  @override
  String healthConnectLastError(String error) {
    return 'Last sync with Health Connect failed: $error';
  }

  @override
  String wearSetsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets logged',
      one: '1 set logged',
      zero: 'No sets yet',
    );
    return '$_temp0';
  }

  @override
  String wearRepeatReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String wearRepeatSet(String weight, int reps) {
    return '$weight x $reps';
  }

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupIntro =>
      'One file with everything in Gymfy — workouts, plans, exercises, measurements, meals, settings and progress photos. Restore it on this phone or a new one. Nothing is uploaded anywhere.';

  @override
  String get backupSectionBackUp => 'Back up';

  @override
  String get backupSaveTitle => 'Save a backup';

  @override
  String backupSaveMessage(String extension) {
    return 'Saves a .$extension file wherever you choose. Keep a copy somewhere other than this phone.';
  }

  @override
  String get backupSaveButton => 'Save backup';

  @override
  String get backupSectionRestore => 'Restore';

  @override
  String get backupRestoreTitle => 'Restore from a backup';

  @override
  String get backupRestoreMessage =>
      'Replaces everything on this phone with what is in the backup. You will see what it holds before anything changes.';

  @override
  String get backupChooseButton => 'Choose backup';

  @override
  String get backupAutomaticTitle => 'Automatic backup';

  @override
  String get backupSaveDialogTitle => 'Save your backup';

  @override
  String backupSaved(String name) {
    return 'Saved $name';
  }

  @override
  String backupSaveFailed(String error) {
    return 'Could not save the backup.\n$error';
  }

  @override
  String get backupFinishWorkoutFirst =>
      'Finish or discard your current workout before restoring.';

  @override
  String get backupPickDialogTitle => 'Choose a backup';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String backupRestoreFailed(String error) {
    return 'Could not restore that backup.\n$error';
  }

  @override
  String get backupFolderPickerTitle => 'Folder for backups';

  @override
  String get backupCantWriteTitle => 'Gymfy can\'t write there';

  @override
  String backupCantWriteMessage(String folder) {
    return 'Android only lets Gymfy save into some folders. Try a folder inside Documents or Download — or use Gymfy\'s own folder, which always works but is deleted if you uninstall the app:\n\n$folder';
  }

  @override
  String get backupUseAppFolder => 'Use Gymfy\'s folder';

  @override
  String backupFolderFailed(String problem) {
    return 'Could not use that folder either.\n$problem';
  }

  @override
  String backupFolderSet(String path) {
    return 'Backups will be saved to $path';
  }

  @override
  String get backupReplaceTitle => 'Replace everything?';

  @override
  String backupReplaceMessage(String date, int workouts, int sets, int photos) {
    String _temp0 = intl.Intl.pluralLogic(
      workouts,
      locale: localeName,
      other: '$workouts workouts',
      one: '1 workout',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    String _temp2 = intl.Intl.pluralLogic(
      photos,
      locale: localeName,
      other: '$photos photos',
      one: '1 photo',
    );
    return 'Backup from $date: $_temp0, $_temp1, $_temp2.\n\nEverything currently on this phone will be replaced by it. This cannot be undone — save a backup first if you might want today\'s data back.';
  }

  @override
  String get backupRestoreButton => 'Restore';

  @override
  String get backupModeWeekly => 'Weekly';

  @override
  String get backupModeAfterWorkout => 'After workout';

  @override
  String get backupNoFolder => 'No folder chosen';

  @override
  String backupLastFailed(String error) {
    return 'Last automatic backup failed: $error';
  }

  @override
  String backupLastAt(String date) {
    return 'Last backup $date';
  }

  @override
  String get backupNoneYet => 'No automatic backup yet';

  @override
  String get backupChange => 'Change';

  @override
  String get backupChoose => 'Choose';

  @override
  String get backupNowButton => 'Back up to folder now';

  @override
  String backupAutoExplainer(int keep) {
    return 'Runs while Gymfy is open — when you open it once a week has passed, or right after you finish a workout. The last $keep automatic backups are kept. Choose a folder in Documents or Download; cloud drives and SD cards are not supported.';
  }

  @override
  String get backupErrorNotBackup => 'That file is not a Gymfy backup.';

  @override
  String get backupErrorTooNew =>
      'That backup was made by a newer version of Gymfy. Update the app to restore it.';

  @override
  String get backupErrorTooOld =>
      'That backup is from a version of Gymfy too old to restore.';

  @override
  String backupErrorNoMigration(String version) {
    return 'Gymfy cannot read backups from version $version yet.';
  }

  @override
  String backupErrorDamaged(String detail) {
    return 'That backup is damaged and cannot be read ($detail).';
  }

  @override
  String get dataExportTitle => 'Export data';

  @override
  String get dataExportIntro =>
      'Save a copy of everything you have logged. The file is written wherever you choose — nothing is uploaded anywhere.';

  @override
  String get dataExportFormatTitle => 'Format';

  @override
  String get dataExportCsvTitle => 'Spreadsheet';

  @override
  String get dataExportCsvSubtitle =>
      'One row per set, ready to open in Excel or Sheets and chart however you like.';

  @override
  String get dataExportCsvButton => 'Save CSV';

  @override
  String get dataExportJsonTitle => 'Everything';

  @override
  String get dataExportJsonSubtitle =>
      'Your workouts with their sets kept together, plus your body measurements and calorie log.';

  @override
  String get dataExportJsonButton => 'Save JSON';

  @override
  String get dataExportCopyTitle => 'This is a copy, not a backup';

  @override
  String get dataExportCopyMessage =>
      'Gymfy cannot import these files back, and progress photos are not included. To move to a new phone, or to keep a copy you can restore, use a backup instead.';

  @override
  String get dataExportNoWorkouts => 'No finished workouts to export yet.';

  @override
  String get dataExportNothing => 'Nothing logged to export yet.';

  @override
  String get dataExportSaveDialogTitle => 'Save your data';

  @override
  String dataExportSaved(String name) {
    return 'Saved $name';
  }

  @override
  String dataExportSaveFailed(String error) {
    return 'Could not save that file.\n$error';
  }

  @override
  String commonListOr(String first, String second) {
    return '$first or $second';
  }

  @override
  String get importTitle => 'Import a history';

  @override
  String get importErrorTitle => 'That file could not be read';

  @override
  String get importErrorNotText =>
      'That file is not readable as text. Export it again as CSV.';

  @override
  String importErrorReadFailed(String error) {
    return 'Could not read that file.\n$error';
  }

  @override
  String importErrorImportFailed(String error) {
    return 'Could not import that file.\n$error';
  }

  @override
  String importErrorSplitFailed(String error) {
    return 'Your workouts were imported, but the split could not be built.\n$error';
  }

  @override
  String get importErrorUnclosedQuote =>
      'This file has a quote that is never closed, so the rest of it cannot be read. It may have been cut short while being saved.';

  @override
  String get importErrorEmpty => 'That file is empty.';

  @override
  String importErrorNotWorkoutExport(String fields, String headers) {
    return 'This does not look like a workout export — it has no $fields column.\n\nThe columns found were: $headers.';
  }

  @override
  String get importFieldDate => 'a date';

  @override
  String get importFieldExercise => 'an exercise name';

  @override
  String get importFieldReps => 'reps';

  @override
  String get importFieldWeight => 'a weight';

  @override
  String get importSplitNameDefault => 'Imported split';

  @override
  String importSplitNameFrom(String source) {
    return '$source import';
  }

  @override
  String get importChooseFile => 'Choose a file';

  @override
  String get importChooseAnother => 'Choose another file';

  @override
  String get importImporting => 'Importing…';

  @override
  String get importButton => 'Import';

  @override
  String importButtonWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count workouts',
      one: 'Import 1 workout',
    );
    return '$_temp0';
  }

  @override
  String importButtonSplit(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Import a split of $days days',
      one: 'Import a split of 1 day',
    );
    return '$_temp0';
  }

  @override
  String importButtonBoth(int workouts, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      workouts,
      locale: localeName,
      other: '$workouts workouts',
      one: '1 workout',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'a split of $days days',
      one: 'a split of 1 day',
    );
    return 'Import $_temp0 and $_temp1';
  }

  @override
  String get importExplainerTitle => 'Bring your history with you';

  @override
  String get importExplainerMessage =>
      'Export your workouts from the other app as a CSV file, then pick it here. Hevy and Strong both do this from their settings.\n\nColumns are matched by name, so most exports work without anything being configured. Nothing is overwritten — importing only adds, and importing the same file twice adds nothing the second time.';

  @override
  String get importNothingTitle => 'Nothing to import';

  @override
  String importNothingUnreadableDates(int count, String sample) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'That file was read, but $count of its rows have a date this app could not make sense of — the first one is \"$sample\".\n\nSend that line on and it can be taught to read it.',
      one:
          'That file was read, but one of its rows has a date this app could not make sense of: \"$sample\".\n\nSend that line on and it can be taught to read it.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNoSets =>
      'That file was read, but none of its rows were sets — no exercise name, reps and weight together on any line.';

  @override
  String get importPreviewTitle => 'What is in this file';

  @override
  String importPreviewSource(String source) {
    return 'Looks like a $source export';
  }

  @override
  String get importPreviewWorkouts => 'Workouts';

  @override
  String get importPreviewSets => 'Sets';

  @override
  String get importPreviewExercises => 'Exercises';

  @override
  String get importPreviewFrom => 'From';

  @override
  String get importPreviewTo => 'To';

  @override
  String get importAlreadyHere => 'Already here';

  @override
  String importPreviewWillSkip(int count) {
    return '$count — will be skipped';
  }

  @override
  String get importPreviewNotSets => 'Rows that were not sets';

  @override
  String importPreviewDatesSkipped(int count, String sample) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count rows were left out because their date could not be read — the first is \"$sample\". Send that line on and it can be taught to read it.',
      one:
          '1 row was left out because its date could not be read: \"$sample\". Send that line on and it can be taught to read it.',
    );
    return '$_temp0';
  }

  @override
  String get importPreviewAllHere =>
      'Every workout in this file is already on your phone.';

  @override
  String importPreviewWillAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts will be added.',
      one: '1 workout will be added.',
    );
    return '$_temp0';
  }

  @override
  String importPreviewNearDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count of them start within an hour of a workout you already have. If you have imported the same training from another app, those will be added a second time.',
      one:
          '1 of them starts within an hour of a workout you already have. If you have imported the same training from another app, it will be added a second time.',
    );
    return '$_temp0';
  }

  @override
  String get importPlanTitle => 'Build a split from this file';

  @override
  String importPlanWillBeCalled(String name) {
    return 'Will be called \"$name\"';
  }

  @override
  String get importPlanExplainer =>
      'Your workout names become the days of a split, each holding the exercises you actually train on it, with the sets and reps you have been doing. Nothing existing is changed — this adds a new split you can edit or delete.';

  @override
  String importPlanExists(String name) {
    return 'You already have a split called \"$name\". Turning this on adds a second one with the same name.';
  }

  @override
  String get importPlanCreate => 'Create the split';

  @override
  String importPlanDayWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String importPlanDayExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get importUnitTitle => 'What unit is this file in?';

  @override
  String get importUnitMessage =>
      'This export does not name its unit, so it has to be told. Getting it wrong scales every weight you import.';

  @override
  String get importUnitKilograms => 'Kilograms';

  @override
  String get importUnitPounds => 'Pounds';

  @override
  String get importOutcomeTitle => 'Imported';

  @override
  String get importOutcomeWorkoutsAdded => 'Workouts added';

  @override
  String get importOutcomeSetsAdded => 'Sets added';

  @override
  String importOutcomeSkipped(int count) {
    return '$count — skipped';
  }

  @override
  String get importOutcomeSplitCreated => 'Split created';

  @override
  String get importOutcomeDays => 'Days';

  @override
  String importOutcomeDaysValue(int days, int exercises) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      exercises,
      locale: localeName,
      other: '$exercises exercises',
      one: '1 exercise',
    );
    return '$_temp0, with $_temp1';
  }

  @override
  String get importOutcomeFindSplit =>
      'Find it under Workout → Splits. Its days are already on the weekdays you have been training them on — open a day to change that, or to add one the history was not clear about.';

  @override
  String importOutcomeNewExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count exercises were new and have been added to your library. They have no muscles set yet, so they will not appear on the muscle map until you edit them.',
      one:
          '1 exercise was new and has been added to your library. It has no muscles set yet, so it will not appear on the muscle map until you edit it.',
    );
    return '$_temp0';
  }

  @override
  String get importUntitledWorkout => 'Imported workout';
}
