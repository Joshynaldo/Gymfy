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
}
