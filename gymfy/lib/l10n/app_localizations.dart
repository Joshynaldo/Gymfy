import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// A setting or profile value the user has not given yet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// Marks the split that is currently being followed.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// Joins two names in a list. Applied pairwise, so three names read 'A and B and C'.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String commonListAnd(String first, String second);

  /// No description provided for @shellNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellNavHome;

  /// No description provided for @shellNavWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get shellNavWorkout;

  /// No description provided for @shellNavProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get shellNavProgress;

  /// No description provided for @shellNavMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get shellNavMore;

  /// No description provided for @sharedWeightWheelLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get sharedWeightWheelLabel;

  /// One logged set. weight is already formatted with its unit, e.g. 80 kg.
  ///
  /// In en, this message translates to:
  /// **'{weight} × {reps} reps'**
  String sharedLoggedSetReps(String weight, int reps);

  /// Adding exercises to a workout day added none, because the day had them all already.
  ///
  /// In en, this message translates to:
  /// **'{asked, plural, =1{Already in that day} other{All {asked} were already in that day}}'**
  String sharedAddedToDayNone(int asked);

  /// No description provided for @sharedAddedToDayAdded.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =1{1 exercise added} other{{added} exercises added}}'**
  String sharedAddedToDayAdded(int added);

  /// addedText is sharedAddedToDayAdded; skipped counts the exercises the day already had.
  ///
  /// In en, this message translates to:
  /// **'{addedText} — {skipped} already there'**
  String sharedAddedToDaySkipped(String addedText, int skipped);

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleFrontDeltoid.
  ///
  /// In en, this message translates to:
  /// **'Front Deltoid'**
  String get muscleFrontDeltoid;

  /// No description provided for @muscleSideDeltoid.
  ///
  /// In en, this message translates to:
  /// **'Side Deltoid'**
  String get muscleSideDeltoid;

  /// No description provided for @muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// No description provided for @muscleAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get muscleAbs;

  /// No description provided for @muscleObliques.
  ///
  /// In en, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// No description provided for @muscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get muscleQuads;

  /// No description provided for @muscleAdductors.
  ///
  /// In en, this message translates to:
  /// **'Adductors'**
  String get muscleAdductors;

  /// No description provided for @muscleTrapezius.
  ///
  /// In en, this message translates to:
  /// **'Trapezius'**
  String get muscleTrapezius;

  /// No description provided for @muscleRearDeltoid.
  ///
  /// In en, this message translates to:
  /// **'Rear Deltoid'**
  String get muscleRearDeltoid;

  /// No description provided for @muscleLats.
  ///
  /// In en, this message translates to:
  /// **'Lats'**
  String get muscleLats;

  /// No description provided for @muscleLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower Back'**
  String get muscleLowerBack;

  /// No description provided for @muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// No description provided for @muscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// No description provided for @muscleNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get muscleNeck;

  /// No description provided for @equipmentBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipmentBarbell;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get equipmentMachine;

  /// No description provided for @equipmentCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get equipmentCable;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get equipmentOther;

  /// No description provided for @setTypeWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get setTypeWarmup;

  /// No description provided for @setTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get setTypeNormal;

  /// No description provided for @setTypeDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get setTypeDrop;

  /// No description provided for @setTypeFailure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get setTypeFailure;

  /// No description provided for @lifterSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get lifterSexMale;

  /// No description provided for @lifterSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get lifterSexFemale;

  /// No description provided for @measurementFieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get measurementFieldWeight;

  /// No description provided for @measurementFieldChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measurementFieldChest;

  /// No description provided for @measurementFieldWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measurementFieldWaist;

  /// No description provided for @measurementFieldHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measurementFieldHips;

  /// No description provided for @measurementFieldArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get measurementFieldArms;

  /// No description provided for @measurementFieldLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get measurementFieldLegs;

  /// No description provided for @goalKindLift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get goalKindLift;

  /// No description provided for @goalKindFrequency.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get goalKindFrequency;

  /// No description provided for @goalKindBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get goalKindBodyweight;

  /// No description provided for @bodyProfileHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bodyProfileHeightLabel;

  /// No description provided for @bodyProfileHeightQuestion.
  ///
  /// In en, this message translates to:
  /// **'How tall are you?'**
  String get bodyProfileHeightQuestion;

  /// No description provided for @bodyProfileAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get bodyProfileAgeLabel;

  /// No description provided for @bodyProfileAgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get bodyProfileAgeQuestion;

  /// No description provided for @bodyProfileAgeHelper.
  ///
  /// In en, this message translates to:
  /// **'Kept as your year of birth, so it stays correct.'**
  String get bodyProfileAgeHelper;

  /// No description provided for @themeDarkDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDarkDefaultLabel;

  /// No description provided for @themeDarkDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Near-black with soft grey cards.'**
  String get themeDarkDefaultDescription;

  /// No description provided for @themeAmoledLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black'**
  String get themeAmoledLabel;

  /// No description provided for @themeAmoledDescription.
  ///
  /// In en, this message translates to:
  /// **'True black. Saves power on OLED screens.'**
  String get themeAmoledDescription;

  /// No description provided for @themeHighContrastLabel.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get themeHighContrastLabel;

  /// No description provided for @themeHighContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Brighter text and visible borders.'**
  String get themeHighContrastDescription;

  /// No description provided for @themeTokyoNightDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep blue-grey with a soft indigo cast.'**
  String get themeTokyoNightDescription;

  /// No description provided for @themeDraculaDescription.
  ///
  /// In en, this message translates to:
  /// **'Dark violet with high-saturation accents.'**
  String get themeDraculaDescription;

  /// No description provided for @themeCatppuccinMochaDescription.
  ///
  /// In en, this message translates to:
  /// **'Warm, muted pastels on deep charcoal.'**
  String get themeCatppuccinMochaDescription;

  /// No description provided for @themeGruvboxDescription.
  ///
  /// In en, this message translates to:
  /// **'Warm retro browns and greens.'**
  String get themeGruvboxDescription;

  /// No description provided for @themeHyperDescription.
  ///
  /// In en, this message translates to:
  /// **'Translucent glass over a living backdrop.'**
  String get themeHyperDescription;

  /// No description provided for @notificationRestRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get notificationRestRunningTitle;

  /// No description provided for @notificationRestRunningChannel.
  ///
  /// In en, this message translates to:
  /// **'Rest timer countdown'**
  String get notificationRestRunningChannel;

  /// No description provided for @notificationRestRunningChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows the rest countdown while you are in another app.'**
  String get notificationRestRunningChannelDescription;

  /// No description provided for @notificationRestOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest over'**
  String get notificationRestOverTitle;

  /// No description provided for @notificationRestOverBody.
  ///
  /// In en, this message translates to:
  /// **'Next set of {exercise}'**
  String notificationRestOverBody(String exercise);

  /// No description provided for @notificationRestOverChannel.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get notificationRestOverChannel;

  /// No description provided for @notificationRestOverChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Tells you when a rest between sets is over.'**
  String get notificationRestOverChannelDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsSectionAccent;

  /// No description provided for @settingsSectionUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsSectionUnits;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionPlates.
  ///
  /// In en, this message translates to:
  /// **'Plates'**
  String get settingsSectionPlates;

  /// No description provided for @settingsSectionOverload.
  ///
  /// In en, this message translates to:
  /// **'Progressive overload'**
  String get settingsSectionOverload;

  /// No description provided for @settingsSectionLogging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get settingsSectionLogging;

  /// No description provided for @settingsSectionYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get settingsSectionYou;

  /// No description provided for @settingsSectionRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get settingsSectionRestTimer;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get settingsSectionHealthConnect;

  /// No description provided for @settingsAccentCaption.
  ///
  /// In en, this message translates to:
  /// **'Drives buttons, highlights and charts.'**
  String get settingsAccentCaption;

  /// No description provided for @settingsUnitsCaption.
  ///
  /// In en, this message translates to:
  /// **'Weights are always stored in kilograms, so switching back and forth never changes what you logged.'**
  String get settingsUnitsCaption;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// language is the name of the language the phone's settings resolve to, in that language (English, Deutsch).
  ///
  /// In en, this message translates to:
  /// **'Follows your phone: {language}'**
  String settingsLanguageSystemSubtitle(String language);

  /// Shown under the language picker while the app is not in English: the bundled exercise library is not translated.
  ///
  /// In en, this message translates to:
  /// **'Exercise names stay in English.'**
  String get settingsLanguageExerciseNames;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything in one file, plus automatic backups'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your whole log as a spreadsheet or JSON'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsNameTitle;

  /// No description provided for @settingsNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsNameDialogTitle;

  /// No description provided for @settingsNameDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to remove'**
  String get settingsNameDialogHint;

  /// No description provided for @settingsDefaultRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Default rest'**
  String get settingsDefaultRestTitle;

  /// rest is an already formatted rest length, e.g. 2:00.
  ///
  /// In en, this message translates to:
  /// **'{rest} between sets'**
  String settingsDefaultRestSubtitle(String rest);

  /// No description provided for @settingsRestAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest timer notifications'**
  String get settingsRestAlertsTitle;

  /// No description provided for @settingsRestAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the countdown in the notification shade and alert you when it runs out'**
  String get settingsRestAlertsSubtitle;

  /// No description provided for @settingsVibrateTitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get settingsVibrateTitle;

  /// No description provided for @settingsVibrateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Useful with the phone in a pocket'**
  String get settingsVibrateSubtitle;

  /// No description provided for @settingsWorkoutNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout notification'**
  String get settingsWorkoutNotificationTitle;

  /// No description provided for @settingsWorkoutNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the current set and rest in the notification shade, with buttons to log a set and control the rest'**
  String get settingsWorkoutNotificationSubtitle;

  /// No description provided for @settingsBodyDiagramTitle.
  ///
  /// In en, this message translates to:
  /// **'Body diagram'**
  String get settingsBodyDiagramTitle;

  /// No description provided for @settingsBodyDiagramNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — showing the male diagram, no strength ranks'**
  String get settingsBodyDiagramNotSet;

  /// sex is the stored lifter sex: male or female.
  ///
  /// In en, this message translates to:
  /// **'{sex, select, female{Female diagram and strength standards} other{Male diagram and strength standards}}'**
  String settingsBodyDiagramSubtitle(String sex);

  /// No description provided for @settingsThemeAccentSuggestion.
  ///
  /// In en, this message translates to:
  /// **'{theme} was designed around its own accent.'**
  String settingsThemeAccentSuggestion(String theme);

  /// No description provided for @settingsThemeUseAccent.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get settingsThemeUseAccent;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreExerciseLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise library'**
  String get moreExerciseLibraryTitle;

  /// No description provided for @moreExerciseLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every movement, searchable by name or muscle'**
  String get moreExerciseLibrarySubtitle;

  /// No description provided for @moreCalorieLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie log'**
  String get moreCalorieLogTitle;

  /// No description provided for @moreCalorieLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track meals, calories and macros'**
  String get moreCalorieLogSubtitle;

  /// No description provided for @moreWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get moreWeeklyTitle;

  /// No description provided for @moreWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calories over the last 7 days'**
  String get moreWeeklySubtitle;

  /// No description provided for @moreOneRmTitle.
  ///
  /// In en, this message translates to:
  /// **'1RM calculator'**
  String get moreOneRmTitle;

  /// No description provided for @moreOneRmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate your one-rep max from any set'**
  String get moreOneRmSubtitle;

  /// No description provided for @moreStrengthRankTitle.
  ///
  /// In en, this message translates to:
  /// **'Strength rank'**
  String get moreStrengthRankTitle;

  /// No description provided for @moreStrengthRankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your big lifts compare to your bodyweight'**
  String get moreStrengthRankSubtitle;

  /// No description provided for @moreSharePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a plan'**
  String get moreSharePlanTitle;

  /// No description provided for @moreSharePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send your splits to someone, or import theirs'**
  String get moreSharePlanSubtitle;

  /// No description provided for @moreImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a history'**
  String get moreImportTitle;

  /// No description provided for @moreImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your workouts over from Hevy, Strong or similar'**
  String get moreImportSubtitle;

  /// No description provided for @moreHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get moreHelpTitle;

  /// No description provided for @moreHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'About Gymfy and who made it'**
  String get moreHelpSubtitle;

  /// No description provided for @moreSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moreSettingsTitle;

  /// No description provided for @moreSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accent colour, your name, rest timer alerts'**
  String get moreSettingsSubtitle;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Gymfy is made by one person. Everything you log stays on your phone — there is no account and no server.'**
  String get helpIntro;

  /// No description provided for @helpFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get helpFeedbackTitle;

  /// No description provided for @helpFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens your mail app · only the app version is attached'**
  String get helpFeedbackSubtitle;

  /// No description provided for @helpDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get helpDeveloperTitle;

  /// No description provided for @helpDeveloperSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Joshynaldo on GitHub'**
  String get helpDeveloperSubtitle;

  /// No description provided for @helpAnimationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise animations'**
  String get helpAnimationsTitle;

  /// No description provided for @helpAnimationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ExerciseGymGifsDB · used with permission'**
  String get helpAnimationsSubtitle;

  /// No description provided for @helpVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get helpVersionTitle;

  /// No description provided for @helpOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String helpOpenLinkFailed(String url);

  /// No description provided for @helpNoMailApp.
  ///
  /// In en, this message translates to:
  /// **'No mail app found. Write to {address}'**
  String helpNoMailApp(String address);

  /// First attached line of a feedback mail. platform is e.g. android, osVersion the system's own version string.
  ///
  /// In en, this message translates to:
  /// **'Gymfy {version} on {platform} {osVersion}'**
  String helpFeedbackMailDevice(
    String version,
    String platform,
    String osVersion,
  );

  /// No description provided for @helpFeedbackMailNote.
  ///
  /// In en, this message translates to:
  /// **'Only these two lines are attached. Delete them if you would rather not send them.'**
  String get helpFeedbackMailNote;

  /// No description provided for @onboardingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get onboardingSaving;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Start lifting'**
  String get onboardingFinish;

  /// No description provided for @onboardingChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change any of this later in Settings.'**
  String get onboardingChangeLater;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Gymfy'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you log stays on this phone — there is no account and nothing gets uploaded. What should we call you?'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get onboardingNameHint;

  /// No description provided for @onboardingSexTitle.
  ///
  /// In en, this message translates to:
  /// **'Body diagram and strength standards'**
  String get onboardingSexTitle;

  /// No description provided for @onboardingSexBody.
  ///
  /// In en, this message translates to:
  /// **'Picks which body the muscle map draws, and which strength table your lifts are compared against. Optional — skip it and the app works the same, minus the ranks.'**
  String get onboardingSexBody;

  /// No description provided for @onboardingSexDecline.
  ///
  /// In en, this message translates to:
  /// **'Rather not say'**
  String get onboardingSexDecline;

  /// No description provided for @onboardingBodyweightTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you weigh?'**
  String get onboardingBodyweightTitle;

  /// No description provided for @onboardingBodyweightBody.
  ///
  /// In en, this message translates to:
  /// **'Used to rank your lifts against your own bodyweight, and it becomes the first point on your weight chart. Leave it at zero to skip — nothing else depends on it.'**
  String get onboardingBodyweightBody;

  /// No description provided for @onboardingBodyweightLabel.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get onboardingBodyweightLabel;

  /// Shown as the value of the height and age fields while they are left out.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkipped;

  /// No description provided for @onboardingOverloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Should Gymfy suggest heavier weights?'**
  String get onboardingOverloadTitle;

  /// No description provided for @onboardingOverloadBody.
  ///
  /// In en, this message translates to:
  /// **'When you hit every set at the top of your rep range, the next session opens with a bit more on the bar. It only ever suggests — the weight stays yours to change.'**
  String get onboardingOverloadBody;

  /// No description provided for @onboardingAccentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your colour'**
  String get onboardingAccentTitle;

  /// No description provided for @onboardingAccentBody.
  ///
  /// In en, this message translates to:
  /// **'Drives buttons, highlights and charts across the app. Tap one to try it — the app changes as you go.'**
  String get onboardingAccentBody;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeFindExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find an exercise'**
  String get homeFindExerciseTooltip;

  /// No description provided for @homeStreakSemantics.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{{days} day workout streak}}'**
  String homeStreakSemantics(int days);

  /// No description provided for @homeTodayNoSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'No active split'**
  String get homeTodayNoSplitTitle;

  /// No description provided for @homeTodayNoSplitMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick the programme you are following to plan your week.'**
  String get homeTodayNoSplitMessage;

  /// No description provided for @homeTodayNoSplitAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a split'**
  String get homeTodayNoSplitAction;

  /// No description provided for @homeTodayRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get homeTodayRestTitle;

  /// No description provided for @homeTodayRestMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled in {split}.'**
  String homeTodayRestMessage(String split);

  /// No description provided for @homeTodayNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet — open the day to add some.'**
  String get homeTodayNoExercises;

  /// No description provided for @homeTodayResume.
  ///
  /// In en, this message translates to:
  /// **'Resume {workout}'**
  String homeTodayResume(String workout);

  /// No description provided for @homeTodayStart.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get homeTodayStart;

  /// No description provided for @homeTodayAddExercises.
  ///
  /// In en, this message translates to:
  /// **'Add exercises'**
  String get homeTodayAddExercises;

  /// No description provided for @homeTodayStartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start empty workout'**
  String get homeTodayStartEmpty;

  /// No description provided for @homeNextUpTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeNextUpTomorrow;

  /// A training day exactly one week away. weekday is the full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Next {weekday}'**
  String homeNextUpNextWeekday(String weekday);

  /// No description provided for @homeLastWorkoutHeading.
  ///
  /// In en, this message translates to:
  /// **'LAST WORKOUT'**
  String get homeLastWorkoutHeading;

  /// volume is an already formatted weight with its unit, e.g. 4,200 kg.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}} • {volume}'**
  String homeLastWorkoutSets(int count, String volume);

  /// No description provided for @homeWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get homeWeekTitle;

  /// No description provided for @homeWeekWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String homeWeekWorkouts(int count);

  /// Under the week's total volume. weekday is the full name of the first day counted.
  ///
  /// In en, this message translates to:
  /// **'lifted since {weekday}'**
  String homeWeekLiftedSince(String weekday);

  /// No description provided for @homeRecapPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get homeRecapPeriodWeek;

  /// No description provided for @homeRecapPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get homeRecapPeriodMonth;

  /// No description provided for @homeRecapPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get homeRecapPeriodYear;

  /// No description provided for @muscleMapFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get muscleMapFront;

  /// No description provided for @muscleMapBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscleMapBack;

  /// No description provided for @muscleMapShowHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Switch to heatmap'**
  String get muscleMapShowHeatmap;

  /// No description provided for @muscleMapShowColours.
  ///
  /// In en, this message translates to:
  /// **'Switch to per-muscle colours'**
  String get muscleMapShowColours;

  /// No description provided for @muscleMapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the muscle map.\n{error}'**
  String muscleMapLoadFailed(String error);

  /// No description provided for @muscleMapBodyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the body map.\n{error}'**
  String muscleMapBodyLoadFailed(String error);

  /// No description provided for @muscleMapContrastCaption.
  ///
  /// In en, this message translates to:
  /// **'Each muscle has its own colour. Brighter still means more volume.'**
  String get muscleMapContrastCaption;

  /// No description provided for @workoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTitle;

  /// No description provided for @workoutSplitsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your splits.\n{error}'**
  String workoutSplitsLoadFailed(String error);

  /// No description provided for @workoutAddDay.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get workoutAddDay;

  /// No description provided for @workoutStartEmptyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start empty workout'**
  String get workoutStartEmptyTooltip;

  /// No description provided for @workoutSwitchSplitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch split'**
  String get workoutSwitchSplitTooltip;

  /// No description provided for @workoutSwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Your splits'**
  String get workoutSwitcherTitle;

  /// No description provided for @workoutNewSplit.
  ///
  /// In en, this message translates to:
  /// **'New split'**
  String get workoutNewSplit;

  /// No description provided for @workoutBrowsePrograms.
  ///
  /// In en, this message translates to:
  /// **'Browse programs'**
  String get workoutBrowsePrograms;

  /// No description provided for @workoutManageSplits.
  ///
  /// In en, this message translates to:
  /// **'Manage splits'**
  String get workoutManageSplits;

  /// No description provided for @workoutNoSplitsTitle.
  ///
  /// In en, this message translates to:
  /// **'No splits yet'**
  String get workoutNoSplitsTitle;

  /// No description provided for @workoutNoSplitsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first split to start planning your training.'**
  String get workoutNoSplitsMessage;

  /// No description provided for @workoutNoSplitsFromProgram.
  ///
  /// In en, this message translates to:
  /// **'Start from a program'**
  String get workoutNoSplitsFromProgram;

  /// No description provided for @workoutNoSplitsFreeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Or start an empty workout'**
  String get workoutNoSplitsFreeWorkout;

  /// No description provided for @workoutNoActiveSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'No active split'**
  String get workoutNoActiveSplitTitle;

  /// No description provided for @workoutNoActiveSplitMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick the programme you are following and its days will show up here.'**
  String get workoutNoActiveSplitMessage;

  /// No description provided for @workoutNoActiveSplitAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a split'**
  String get workoutNoActiveSplitAction;

  /// Saved as the name of a workout started without a planned day, and shown as its heading.
  ///
  /// In en, this message translates to:
  /// **'Free workout'**
  String get workoutFreeWorkoutName;

  /// No description provided for @workoutSplitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get workoutSplitsTitle;

  /// No description provided for @workoutSplitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Split name'**
  String get workoutSplitNameLabel;

  /// No description provided for @workoutSplitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push / Pull / Legs'**
  String get workoutSplitNameHint;

  /// No description provided for @workoutDeleteSplitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete split'**
  String get workoutDeleteSplitTooltip;

  /// Confirming the deletion of a split or a day. name is what the user called it.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String workoutDeleteTitle(String name);

  /// No description provided for @workoutDeleteSplitMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the split and everything inside it. This cannot be undone.'**
  String get workoutDeleteSplitMessage;

  /// No description provided for @workoutSplitFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get workoutSplitFallbackTitle;

  /// No description provided for @workoutDayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Day name'**
  String get workoutDayNameLabel;

  /// No description provided for @workoutDayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push'**
  String get workoutDayNameHint;

  /// No description provided for @workoutNowFollowing.
  ///
  /// In en, this message translates to:
  /// **'Now following {split}'**
  String workoutNowFollowing(String split);

  /// No description provided for @workoutSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set active'**
  String get workoutSetActive;

  /// No description provided for @workoutSplitLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this split.\n{error}'**
  String workoutSplitLoadFailed(String error);

  /// Under a day's name. schedule is its weekdays, e.g. 'Mon, Thu', or workoutDayNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}} • {schedule}'**
  String workoutDayCardSubtitle(int count, String schedule);

  /// No description provided for @workoutDayNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get workoutDayNotScheduled;

  /// No description provided for @workoutDeleteDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete day'**
  String get workoutDeleteDayTooltip;

  /// No description provided for @workoutDayNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet — tap to add some.'**
  String get workoutDayNoExercises;

  /// No description provided for @workoutDeleteDayMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the day and its exercises. This cannot be undone.'**
  String get workoutDeleteDayMessage;

  /// No description provided for @workoutNoDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No days yet'**
  String get workoutNoDaysTitle;

  /// No description provided for @workoutNoDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a training day (like \"Push\" or \"Legs\") to start building this split.'**
  String get workoutNoDaysMessage;

  /// No description provided for @workoutDayFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get workoutDayFallbackTitle;

  /// No description provided for @workoutDayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this day.\n{error}'**
  String workoutDayLoadFailed(String error);

  /// No description provided for @workoutStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutStartWorkout;

  /// No description provided for @workoutAddExercises.
  ///
  /// In en, this message translates to:
  /// **'Add exercises'**
  String get workoutAddExercises;

  /// A planned exercise's target in the day builder. reps is already formatted: 10, or a range like 8–12.
  ///
  /// In en, this message translates to:
  /// **'{sets, plural, other{{sets} sets}} × {reps} reps'**
  String workoutPlannedSetsReps(int sets, String reps);

  /// No description provided for @workoutPlannedWarmups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warm-up} other{{count} warm-ups}}'**
  String workoutPlannedWarmups(int count);

  /// A planned percentage of the one-rep max. percent is already formatted, e.g. 75%.
  ///
  /// In en, this message translates to:
  /// **'@ {percent} 1RM'**
  String workoutPlannedPercent(String percent);

  /// No description provided for @workoutSuperset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get workoutSuperset;

  /// No description provided for @workoutRemoveExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get workoutRemoveExerciseTooltip;

  /// No description provided for @workoutDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get workoutDragToReorder;

  /// No description provided for @workoutSupersetRestAfterLast.
  ///
  /// In en, this message translates to:
  /// **'SUPERSET · REST AFTER THE LAST'**
  String get workoutSupersetRestAfterLast;

  /// No description provided for @workoutSupersetWithAbove.
  ///
  /// In en, this message translates to:
  /// **'Superset with the exercise above'**
  String get workoutSupersetWithAbove;

  /// No description provided for @workoutSupersetWithBelow.
  ///
  /// In en, this message translates to:
  /// **'Superset with the exercise below'**
  String get workoutSupersetWithBelow;

  /// No description provided for @workoutSupersetLeave.
  ///
  /// In en, this message translates to:
  /// **'Remove from superset'**
  String get workoutSupersetLeave;

  /// No description provided for @workoutUpdatedExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 exercise} other{Updated all {count} exercises}}'**
  String workoutUpdatedExercises(int count);

  /// No description provided for @workoutSetsRepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sets & reps'**
  String get workoutSetsRepsTitle;

  /// No description provided for @workoutWheelSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get workoutWheelSets;

  /// No description provided for @workoutWheelReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutWheelReps;

  /// No description provided for @workoutWheelFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get workoutWheelFrom;

  /// No description provided for @workoutWheelTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get workoutWheelTo;

  /// No description provided for @workoutRepRange.
  ///
  /// In en, this message translates to:
  /// **'Rep range'**
  String get workoutRepRange;

  /// No description provided for @workoutWarmupSets.
  ///
  /// In en, this message translates to:
  /// **'Warm-up sets'**
  String get workoutWarmupSets;

  /// Saves the same targets on every exercise of the day. count is how many that is.
  ///
  /// In en, this message translates to:
  /// **'Save to all {count}'**
  String workoutSaveToAll(int count);

  /// No description provided for @workoutDayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get workoutDayEmptyTitle;

  /// No description provided for @workoutDayEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add exercises from the library and set their sets and reps.'**
  String get workoutDayEmptyMessage;

  /// No description provided for @workoutPickerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get workoutPickerClear;

  /// No description provided for @workoutPickerNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No exercises match your filters.'**
  String get workoutPickerNoMatches;

  /// No description provided for @workoutPickerSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing selected} =1{1 selected} other{{count} selected}}'**
  String workoutPickerSelected(int count);

  /// The picker's confirm button once more than one exercise is ticked; with one it says commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String workoutPickerAddCount(int count);

  /// No description provided for @workoutLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this workout.\n{error}'**
  String workoutLoadFailed(String error);

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found.'**
  String get workoutNotFound;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinish;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutAddExercise;

  /// No description provided for @workoutUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get workoutUpNext;

  /// No description provided for @workoutReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get workoutReorder;

  /// No description provided for @workoutSwapExercise.
  ///
  /// In en, this message translates to:
  /// **'Swap exercise'**
  String get workoutSwapExercise;

  /// No description provided for @workoutSwapExerciseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Do something else in its place'**
  String get workoutSwapExerciseSubtitle;

  /// No description provided for @workoutRemoveFromWorkout.
  ///
  /// In en, this message translates to:
  /// **'Remove from workout'**
  String get workoutRemoveFromWorkout;

  /// No description provided for @workoutPlanUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Your plan stays as it is'**
  String get workoutPlanUnchanged;

  /// Heading of the log sheet for a ramp-up set.
  ///
  /// In en, this message translates to:
  /// **'Warm-up {number}'**
  String workoutPhaseWarmup(int number);

  /// No description provided for @workoutPhaseWorking.
  ///
  /// In en, this message translates to:
  /// **'Set {number} · working set'**
  String workoutPhaseWorking(int number);

  /// No description provided for @workoutExerciseOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exercise options'**
  String get workoutExerciseOptionsTooltip;

  /// No description provided for @workoutWarmupCalculator.
  ///
  /// In en, this message translates to:
  /// **'Warm-up calculator'**
  String get workoutWarmupCalculator;

  /// No description provided for @workoutLogSet.
  ///
  /// In en, this message translates to:
  /// **'Log set {number}'**
  String workoutLogSet(int number);

  /// partners are the other exercise names of the superset, joined with commonListAnd.
  ///
  /// In en, this message translates to:
  /// **'Superset with {partners} — rest after the last one'**
  String workoutSupersetWith(String partners);

  /// No description provided for @workoutSupersetCaps.
  ///
  /// In en, this message translates to:
  /// **'SUPERSET'**
  String get workoutSupersetCaps;

  /// The warm-up button while the plan still expects ramp-up sets.
  ///
  /// In en, this message translates to:
  /// **'Warm-up {number} of {expected}'**
  String workoutWarmupProgress(int number, int expected);

  /// No description provided for @workoutWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get workoutWarmup;

  /// Overload suggestions on the exercise card. weight is formatted with its unit.
  ///
  /// In en, this message translates to:
  /// **'You hit every set last time — going up to {weight}'**
  String workoutSuggestionEarned(String weight);

  /// No description provided for @workoutSuggestionDeload.
  ///
  /// In en, this message translates to:
  /// **'Several increases in a row — a lighter {weight} is suggested'**
  String workoutSuggestionDeload(String weight);

  /// No description provided for @workoutSuggestionAtLimit.
  ///
  /// In en, this message translates to:
  /// **'Top set was a limit effort last time — holding at {weight}'**
  String workoutSuggestionAtLimit(String weight);

  /// No description provided for @workoutSuggestionPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} of your 1RM — {weight}'**
  String workoutSuggestionPercent(String percent, String weight);

  /// No description provided for @workoutSuggestionBlockDeload.
  ///
  /// In en, this message translates to:
  /// **'Deload week at {percent} — {weight}'**
  String workoutSuggestionBlockDeload(String percent, String weight);

  /// No description provided for @workoutSuggestionSame.
  ///
  /// In en, this message translates to:
  /// **'Same {weight} as last time'**
  String workoutSuggestionSame(String weight);

  /// No description provided for @workoutChangeSetTypeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change set type'**
  String get workoutChangeSetTypeTooltip;

  /// No description provided for @workoutSetTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set type'**
  String get workoutSetTypeTitle;

  /// No description provided for @workoutDeleteSetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete set'**
  String get workoutDeleteSetTooltip;

  /// One letter on a logged warm-up set.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get workoutBadgeWarmup;

  /// One letter on a logged drop set.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get workoutBadgeDrop;

  /// One letter on a logged set taken to failure.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get workoutBadgeFailure;

  /// No description provided for @workoutEmptyFreeMessage.
  ///
  /// In en, this message translates to:
  /// **'Add exercises as you go. Nothing here changes your plan.'**
  String get workoutEmptyFreeMessage;

  /// No description provided for @workoutEmptyNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to log'**
  String get workoutEmptyNothingTitle;

  /// No description provided for @workoutEmptyNothingMessage.
  ///
  /// In en, this message translates to:
  /// **'This day has no exercises. Add some for today — your plan stays as it is.'**
  String get workoutEmptyNothingMessage;

  /// No description provided for @workoutLogWarmupCaption.
  ///
  /// In en, this message translates to:
  /// **'Warm-up · ramping up'**
  String get workoutLogWarmupCaption;

  /// No description provided for @workoutLogDropCaption.
  ///
  /// In en, this message translates to:
  /// **'Drop set · lighter, straight after'**
  String get workoutLogDropCaption;

  /// phase is workoutPhaseWorking or workoutWorkingSet.
  ///
  /// In en, this message translates to:
  /// **'{phase} · to failure'**
  String workoutLogFailureCaption(String phase);

  /// No description provided for @workoutWorkingSet.
  ///
  /// In en, this message translates to:
  /// **'Working set'**
  String get workoutWorkingSet;

  /// No description provided for @workoutLogRepsUnit.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get workoutLogRepsUnit;

  /// No description provided for @workoutLogStepWeight.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 — WEIGHT'**
  String get workoutLogStepWeight;

  /// No description provided for @workoutLogStepReps.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 — REPS'**
  String get workoutLogStepReps;

  /// No description provided for @workoutLogStepTime.
  ///
  /// In en, this message translates to:
  /// **'STEP 2 — TIME'**
  String get workoutLogStepTime;

  /// No description provided for @workoutLogTypeWeight.
  ///
  /// In en, this message translates to:
  /// **'Type a weight'**
  String get workoutLogTypeWeight;

  /// No description provided for @workoutLogStackPlates.
  ///
  /// In en, this message translates to:
  /// **'Stack plates'**
  String get workoutLogStackPlates;

  /// No description provided for @workoutLogRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat last set'**
  String get workoutLogRepeat;

  /// No description provided for @workoutLogNextTime.
  ///
  /// In en, this message translates to:
  /// **'Next: time'**
  String get workoutLogNextTime;

  /// No description provided for @workoutLogNextReps.
  ///
  /// In en, this message translates to:
  /// **'Next: reps'**
  String get workoutLogNextReps;

  /// No description provided for @workoutLogSaveSet.
  ///
  /// In en, this message translates to:
  /// **'Save set'**
  String get workoutLogSaveSet;

  /// No description provided for @workoutLogHolding.
  ///
  /// In en, this message translates to:
  /// **'HOLDING'**
  String get workoutLogHolding;

  /// No description provided for @workoutLogMinutes.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get workoutLogMinutes;

  /// No description provided for @workoutLogSeconds.
  ///
  /// In en, this message translates to:
  /// **'SEC'**
  String get workoutLogSeconds;

  /// No description provided for @workoutTimerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get workoutTimerStop;

  /// No description provided for @workoutTimerStart.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get workoutTimerStart;

  /// No description provided for @workoutEffortRpeLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW HARD · RPE'**
  String get workoutEffortRpeLabel;

  /// No description provided for @workoutEffortRirLabel.
  ///
  /// In en, this message translates to:
  /// **'REPS LEFT · RIR'**
  String get workoutEffortRirLabel;

  /// Why the log sheet prefilled the weight it did. weight is formatted with its unit.
  ///
  /// In en, this message translates to:
  /// **'You hit every set last time — going up to {weight}.'**
  String workoutNoteEarned(String weight);

  /// No description provided for @workoutNoteDeload.
  ///
  /// In en, this message translates to:
  /// **'Several increases in a row. A lighter week at {weight} is suggested.'**
  String workoutNoteDeload(String weight);

  /// No description provided for @workoutNoteAtLimit.
  ///
  /// In en, this message translates to:
  /// **'You hit every set, but the top set was a limit effort — staying at {weight}.'**
  String workoutNoteAtLimit(String weight);

  /// No description provided for @workoutNotePercent.
  ///
  /// In en, this message translates to:
  /// **'Planned at {percent} of your 1RM — {weight}.'**
  String workoutNotePercent(String percent, String weight);

  /// No description provided for @workoutNoteBlockDeload.
  ///
  /// In en, this message translates to:
  /// **'Deload week: {percent} of your working weight — {weight}.'**
  String workoutNoteBlockDeload(String percent, String weight);

  /// No description provided for @workoutNoteSame.
  ///
  /// In en, this message translates to:
  /// **'Same weight as last time — the rep target wasn\'t met yet.'**
  String get workoutNoteSame;

  /// No description provided for @workoutRestOverCaps.
  ///
  /// In en, this message translates to:
  /// **'REST OVER'**
  String get workoutRestOverCaps;

  /// No description provided for @workoutRestingCaps.
  ///
  /// In en, this message translates to:
  /// **'RESTING'**
  String get workoutRestingCaps;

  /// No description provided for @workoutRestAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add 30 seconds'**
  String get workoutRestAddTooltip;

  /// No description provided for @workoutRestDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get workoutRestDismissTooltip;

  /// No description provided for @workoutRestSkipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skip rest'**
  String get workoutRestSkipTooltip;

  /// No description provided for @workoutRestOver.
  ///
  /// In en, this message translates to:
  /// **'Rest over'**
  String get workoutRestOver;

  /// A rep count on its own, e.g. a bodyweight set or a rep record.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} reps}}'**
  String workoutReps(int count);

  /// One beaten record. kind is a workoutRecordKind… label; value and previous are formatted.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {value}, was {previous}'**
  String workoutRecordLine(String kind, String value, String previous);

  /// No description provided for @workoutRecordNew.
  ///
  /// In en, this message translates to:
  /// **'New personal record'**
  String get workoutRecordNew;

  /// No description provided for @workoutRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 personal record} other{{count} personal records}}'**
  String workoutRecordCount(int count);

  /// No description provided for @workoutRecordKindWeight.
  ///
  /// In en, this message translates to:
  /// **'Heaviest weight'**
  String get workoutRecordKindWeight;

  /// No description provided for @workoutRecordKindOneRm.
  ///
  /// In en, this message translates to:
  /// **'Best estimated 1RM'**
  String get workoutRecordKindOneRm;

  /// No description provided for @workoutRecordKindReps.
  ///
  /// In en, this message translates to:
  /// **'Most reps'**
  String get workoutRecordKindReps;

  /// No description provided for @workoutRecordKindHold.
  ///
  /// In en, this message translates to:
  /// **'Longest hold'**
  String get workoutRecordKindHold;

  /// No description provided for @workoutRecordKindVolume.
  ///
  /// In en, this message translates to:
  /// **'Best session volume'**
  String get workoutRecordKindVolume;

  /// No description provided for @workoutSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap {exercise}'**
  String workoutSwapTitle(String exercise);

  /// No description provided for @workoutSwapScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap for how long?'**
  String get workoutSwapScopeTitle;

  /// No description provided for @workoutSwapScopeSession.
  ///
  /// In en, this message translates to:
  /// **'Just this workout'**
  String get workoutSwapScopeSession;

  /// No description provided for @workoutSwapScopePlan.
  ///
  /// In en, this message translates to:
  /// **'This workout and the plan'**
  String get workoutSwapScopePlan;

  /// No description provided for @workoutSwapScopePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Future workouts of this day use it too'**
  String get workoutSwapScopePlanSubtitle;

  /// No description provided for @workoutSwapPlanClash.
  ///
  /// In en, this message translates to:
  /// **'That exercise is already in this day\'s plan, so the swap is for this workout only.'**
  String get workoutSwapPlanClash;

  /// No description provided for @workoutReorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder exercises'**
  String get workoutReorderTitle;

  /// ramp is the warm-up percentages, e.g. 40 · 60 · 80 %.
  ///
  /// In en, this message translates to:
  /// **'{exercise} · ramp {ramp}'**
  String workoutWarmupRampCaption(String exercise, String ramp);

  /// No description provided for @workoutWarmupWorkingWeight.
  ///
  /// In en, this message translates to:
  /// **'WORKING WEIGHT'**
  String get workoutWarmupWorkingWeight;

  /// No description provided for @workoutWarmupLighter.
  ///
  /// In en, this message translates to:
  /// **'Lighter'**
  String get workoutWarmupLighter;

  /// No description provided for @workoutWarmupHeavier.
  ///
  /// In en, this message translates to:
  /// **'Heavier'**
  String get workoutWarmupHeavier;

  /// No description provided for @workoutWarmupEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter the weight you are working up to.'**
  String get workoutWarmupEnterWeight;

  /// No description provided for @workoutWarmupTooLight.
  ///
  /// In en, this message translates to:
  /// **'Too light to need a ramp — go straight to work.'**
  String get workoutWarmupTooLight;

  /// No description provided for @workoutWarmupLogSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Log 1 warm-up set} other{Log {count} warm-up sets}}'**
  String workoutWarmupLogSets(int count);

  /// No description provided for @workoutWarmupEmptyBar.
  ///
  /// In en, this message translates to:
  /// **'Empty bar'**
  String get workoutWarmupEmptyBar;

  /// One warm-up step. plates is what goes on each side, e.g. 20 + 5.
  ///
  /// In en, this message translates to:
  /// **'{percent} % · {plates} per side'**
  String workoutWarmupStepPlates(int percent, String plates);

  /// No description provided for @workoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get workoutSummaryTitle;

  /// No description provided for @workoutSummaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the summary.\n{error}'**
  String workoutSummaryLoadFailed(String error);

  /// No description provided for @workoutSummaryNoSets.
  ///
  /// In en, this message translates to:
  /// **'No sets were logged in this workout.'**
  String get workoutSummaryNoSets;

  /// No description provided for @workoutSummaryExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get workoutSummaryExercises;

  /// No description provided for @workoutSummaryMusclesWorked.
  ///
  /// In en, this message translates to:
  /// **'Muscles worked'**
  String get workoutSummaryMusclesWorked;

  /// No description provided for @workoutSummaryNoMuscles.
  ///
  /// In en, this message translates to:
  /// **'No muscles to show for this workout.'**
  String get workoutSummaryNoMuscles;

  /// No description provided for @workoutSummaryDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutSummaryDuration;

  /// No description provided for @workoutSummarySets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get workoutSummarySets;

  /// No description provided for @workoutSummaryVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get workoutSummaryVolume;

  /// No description provided for @workoutSummaryExerciseSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String workoutSummaryExerciseSets(int count);

  /// set is one logged set, e.g. 80 kg × 8 reps.
  ///
  /// In en, this message translates to:
  /// **'Top set {set}'**
  String workoutSummaryTopSet(String set);

  /// No description provided for @workoutSummaryTopSetTotal.
  ///
  /// In en, this message translates to:
  /// **'Top set {set}  •  {volume} total'**
  String workoutSummaryTopSetTotal(String set, String volume);

  /// No description provided for @workoutLoggingRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate how hard each set was'**
  String get workoutLoggingRateTitle;

  /// No description provided for @workoutLoggingOffCaption.
  ///
  /// In en, this message translates to:
  /// **'Off: the log sheet asks for weight and reps only.'**
  String get workoutLoggingOffCaption;

  /// No description provided for @workoutLoggingRpeCaption.
  ///
  /// In en, this message translates to:
  /// **'RPE 6–10, optional on every working set. A top set rated 9.5 or 10 holds the overload suggestion at the same weight next time.'**
  String get workoutLoggingRpeCaption;

  /// No description provided for @workoutLoggingRirCaption.
  ///
  /// In en, this message translates to:
  /// **'Reps left in the tank, optional on every working set. A top set with none left holds the overload suggestion at the same weight next time.'**
  String get workoutLoggingRirCaption;

  /// No description provided for @workoutWarmupRampTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm-up ramp'**
  String get workoutWarmupRampTitle;

  /// No description provided for @workoutWarmupRampSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{ramp} of your working weight, after the bar'**
  String workoutWarmupRampSubtitle(String ramp);

  /// No description provided for @workoutWarmupRampSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} steps}}'**
  String workoutWarmupRampSteps(int count);

  /// No description provided for @workoutRestBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets'**
  String get workoutRestBetweenSets;

  /// No description provided for @workoutRestUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use the default instead'**
  String get workoutRestUseDefault;

  /// No description provided for @workoutRestFollowingDefault.
  ///
  /// In en, this message translates to:
  /// **'{rest} — following the default'**
  String workoutRestFollowingDefault(String rest);

  /// No description provided for @workoutRestOwn.
  ///
  /// In en, this message translates to:
  /// **'{rest} — set for this exercise'**
  String workoutRestOwn(String rest);

  /// No description provided for @workoutSetPositionOf.
  ///
  /// In en, this message translates to:
  /// **'Set {number} of {planned}'**
  String workoutSetPositionOf(int number, int planned);

  /// A set past the plan's count, where 'of' would read like a bug.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String workoutSetPosition(int number);

  /// No description provided for @workoutNotificationNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get workoutNotificationNoExercises;

  /// Expanded notification: what one tap on Log set will log, e.g. 80 kg × 8 reps.
  ///
  /// In en, this message translates to:
  /// **'Next: {set}'**
  String workoutNotificationNext(String set);

  /// No description provided for @workoutNotificationResting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get workoutNotificationResting;

  /// No description provided for @workoutNotificationLogSet.
  ///
  /// In en, this message translates to:
  /// **'Log set'**
  String get workoutNotificationLogSet;

  /// No description provided for @workoutNotificationSkipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip rest'**
  String get workoutNotificationSkipRest;

  /// Shown on the notification once the app is no longer running.
  ///
  /// In en, this message translates to:
  /// **'Tap to open Gymfy'**
  String get workoutNotificationTapToOpen;

  /// No description provided for @workoutNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutNotificationChannel;

  /// No description provided for @workoutNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'The current set and rest, with buttons to log and skip'**
  String get workoutNotificationChannelDescription;

  /// No description provided for @overloadModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get overloadModeAuto;

  /// No description provided for @overloadModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get overloadModeFixed;

  /// No description provided for @overloadModePercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get overloadModePercent;

  /// A percentage. percent is the number, already formatted for the language.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String overloadPercentValue(String percent);

  /// No description provided for @overloadSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest heavier weights'**
  String get overloadSuggestTitle;

  /// No description provided for @overloadSuggestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you hit every set at the top of your rep range, the next session opens with a bit more on the bar.'**
  String get overloadSuggestSubtitle;

  /// No description provided for @overloadHowMuchTitle.
  ///
  /// In en, this message translates to:
  /// **'How much to add'**
  String get overloadHowMuchTitle;

  /// No description provided for @overloadDeloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Deload'**
  String get overloadDeloadTitle;

  /// No description provided for @overloadDeloadCaption.
  ///
  /// In en, this message translates to:
  /// **'After a run of increases, suggest dropping 10%. Only ever a suggestion — nothing changes on its own.'**
  String get overloadDeloadCaption;

  /// No description provided for @overloadDeloadNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get overloadDeloadNever;

  /// How many increases in a row before a deload is suggested.
  ///
  /// In en, this message translates to:
  /// **'{weeks} in a row'**
  String overloadDeloadInARow(int weeks);

  /// Each placeholder is a weight with its unit, e.g. 5 kg.
  ///
  /// In en, this message translates to:
  /// **'Bigger jumps on big lifts: {legs} on legs, {backChest} on back and chest, {armsShoulders} on arms and shoulders. Core exercises are never auto-progressed.'**
  String overloadAutoCaption(
    String legs,
    String backChest,
    String armsShoulders,
  );

  /// No description provided for @overloadFixedCaption.
  ///
  /// In en, this message translates to:
  /// **'The same jump on every exercise.'**
  String get overloadFixedCaption;

  /// Every placeholder is a weight with its unit.
  ///
  /// In en, this message translates to:
  /// **'Adds {lightStep} to a {light} lift and {heavyStep} to a {heavy} one.'**
  String overloadPercentExample(
    String lightStep,
    String light,
    String heavyStep,
    String heavy,
  );

  /// No description provided for @platesTitle.
  ///
  /// In en, this message translates to:
  /// **'Plate calculator'**
  String get platesTitle;

  /// No description provided for @platesLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you loading?'**
  String get platesLoadingTitle;

  /// No description provided for @platesTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get platesTargetWeight;

  /// No description provided for @platesHint.
  ///
  /// In en, this message translates to:
  /// **'Dial in a target weight to see what goes on the bar.'**
  String get platesHint;

  /// No description provided for @platesBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get platesBar;

  /// The bar choice for plates loaded onto a machine with no barbell.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get platesNoBar;

  /// Both are weights with their unit.
  ///
  /// In en, this message translates to:
  /// **'{target} is lighter than the bar itself ({bar}).'**
  String platesBelowBar(String target, String bar);

  /// No description provided for @platesEachSide.
  ///
  /// In en, this message translates to:
  /// **'Each side'**
  String get platesEachSide;

  /// bar is the bar's weight without a unit; plates is the plates' weight with its unit.
  ///
  /// In en, this message translates to:
  /// **'Bar {bar} + plates {plates}'**
  String platesExact(String bar, String plates);

  /// shortfall is a weight with its unit, target the target weight without one.
  ///
  /// In en, this message translates to:
  /// **'Closest loadable — {shortfall} under your target of {target}'**
  String platesClosest(String shortfall, String target);

  /// No description provided for @platesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get platesTotal;

  /// No description provided for @platesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get platesClear;

  /// No description provided for @platesInPlatesNoBar.
  ///
  /// In en, this message translates to:
  /// **'{total} in plates, no bar'**
  String platesInPlatesNoBar(String total);

  /// bar is the bar's weight with its unit; plates is the plates' weight without one.
  ///
  /// In en, this message translates to:
  /// **'Bar {bar} + {plates} in plates'**
  String platesBarPlusPlates(String bar, String plates);

  /// No description provided for @platesTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a plate to each side'**
  String get platesTapToAdd;

  /// Screen reader label of a plate button. plate is its weight with the unit.
  ///
  /// In en, this message translates to:
  /// **'{plate}, {count} on the bar'**
  String platesPlateSemantics(String plate, int count);

  /// No description provided for @platesChangeBarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change the bar'**
  String get platesChangeBarTooltip;

  /// No description provided for @platesJustTheBar.
  ///
  /// In en, this message translates to:
  /// **'Just the bar'**
  String get platesJustTheBar;

  /// No description provided for @platesInventoryCaption.
  ///
  /// In en, this message translates to:
  /// **'The plates your gym has, in {unit}. The calculator only suggests these.'**
  String platesInventoryCaption(String unit);

  /// No description provided for @planShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a plan'**
  String get planShareTitle;

  /// No description provided for @planShareNoSplits.
  ///
  /// In en, this message translates to:
  /// **'You have no splits to save yet — but you can still import one from someone else.'**
  String get planShareNoSplits;

  /// No description provided for @planShareSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get planShareSend;

  /// No description provided for @planShareReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get planShareReceive;

  /// No description provided for @planShareImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a plan'**
  String get planShareImportTitle;

  /// No description provided for @planShareImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a .gymfy file someone sent you'**
  String get planShareImportSubtitle;

  /// No description provided for @planShareSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your plan'**
  String get planShareSaveDialogTitle;

  /// No description provided for @planShareSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved — send it from your files app.'**
  String get planShareSaved;

  /// No description provided for @planShareSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save that plan.\n{error}'**
  String planShareSaveFailed(String error);

  /// No description provided for @planSharePdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build that PDF.\n{error}'**
  String planSharePdfFailed(String error);

  /// No description provided for @planShareReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file.\n{error}'**
  String planShareReadFailed(String error);

  /// No description provided for @planShareImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing imported} =1{Plan imported} other{{count} plans imported}}'**
  String planShareImported(int count);

  /// No description provided for @planShareExplainer.
  ///
  /// In en, this message translates to:
  /// **'A plan file holds your splits, their days and the exercises in them. It never includes your workouts, your weights, your measurements or your photos.'**
  String get planShareExplainer;

  /// No description provided for @planShareSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get planShareSaveFile;

  /// No description provided for @planSharePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get planSharePdf;

  /// No description provided for @planShareErrorNotJson.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Gymfy plan — it isn\'t even JSON.'**
  String get planShareErrorNotJson;

  /// No description provided for @planShareErrorNotPlan.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Gymfy plan.'**
  String get planShareErrorNotPlan;

  /// No description provided for @planShareErrorWrongFormat.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Gymfy plan. Look for a file ending in .{extension}.'**
  String planShareErrorWrongFormat(String extension);

  /// No description provided for @planShareErrorTooNew.
  ///
  /// In en, this message translates to:
  /// **'That plan was made by a newer version of Gymfy. Update the app and try again.'**
  String get planShareErrorTooNew;

  /// No description provided for @planShareErrorNoSplits.
  ///
  /// In en, this message translates to:
  /// **'That plan file doesn\'t contain a split.'**
  String get planShareErrorNoSplits;

  /// No description provided for @planShareRenameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give it a name.'**
  String get planShareRenameEmpty;

  /// No description provided for @planShareRenameTaken.
  ///
  /// In en, this message translates to:
  /// **'You already have a plan called that.'**
  String get planShareRenameTaken;

  /// No description provided for @planShareRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name already used'**
  String get planShareRenameTitle;

  /// No description provided for @planShareRenameMessage.
  ///
  /// In en, this message translates to:
  /// **'You already have a plan called \"{name}\". Give the imported one a different name — your own plan is kept either way.'**
  String planShareRenameMessage(String name);

  /// No description provided for @planShareRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get planShareRenameLabel;

  /// No description provided for @planShareRenameSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this one'**
  String get planShareRenameSkip;

  /// No description provided for @planShareRenameImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get planShareRenameImport;

  /// Footer of the printed plan. The PDF font only has Latin-1: no en dashes or curly quotes in any planSharePdf… message.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String planSharePdfPage(int page, int pages);

  /// No description provided for @planSharePdfNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get planSharePdfNotScheduled;

  /// No description provided for @planSharePdfNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get planSharePdfNoExercises;

  /// No description provided for @planSharePdfExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get planSharePdfExercise;

  /// No description provided for @planSharePdfSetsReps.
  ///
  /// In en, this message translates to:
  /// **'Sets × reps'**
  String get planSharePdfSetsReps;

  /// No description provided for @planSharePdfWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get planSharePdfWarmup;

  /// No description provided for @planSharePdfWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get planSharePdfWeight;

  /// No description provided for @programsTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// level is programsLevelBeginner or programsLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day a week} other{{days} days a week}} · {level}'**
  String programsFacts(int days, String level);

  /// No description provided for @programsLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get programsLevelBeginner;

  /// No description provided for @programsLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get programsLevelIntermediate;

  /// No description provided for @programsIntro.
  ///
  /// In en, this message translates to:
  /// **'Each programme is added as a new split you can edit like any other. Your own splits are never changed.'**
  String get programsIntro;

  /// No description provided for @programsFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get programsFallbackTitle;

  /// No description provided for @programsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program not found.'**
  String get programsNotFound;

  /// No description provided for @programsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this program.\n{error}'**
  String programsOpenFailed(String error);

  /// No description provided for @programsAddToSplits.
  ///
  /// In en, this message translates to:
  /// **'Add to my splits'**
  String get programsAddToSplits;

  /// No description provided for @programsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {program}. Set it active to follow it.'**
  String programsAdded(String program);

  /// No description provided for @programsAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add that program.\n{error}'**
  String programsAddFailed(String error);

  /// No description provided for @programsSupersetNote.
  ///
  /// In en, this message translates to:
  /// **'Marked exercises are done back to back as a superset.'**
  String get programsSupersetNote;

  /// No description provided for @programsBeginnerFullBodySummary.
  ///
  /// In en, this message translates to:
  /// **'One machine-and-dumbbell session, three times a week'**
  String get programsBeginnerFullBodySummary;

  /// No description provided for @programsBeginnerFullBodyDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle first programme built on machines, cables and dumbbells, so there is no barbell technique to learn before you start. The same full-body session three times a week, with rep ranges: once you hit the top of the range on every set, add a little weight.'**
  String get programsBeginnerFullBodyDescription;

  /// No description provided for @programsFullBody5x5Summary.
  ///
  /// In en, this message translates to:
  /// **'Two alternating barbell workouts, five sets of five'**
  String get programsFullBody5x5Summary;

  /// No description provided for @programsFullBody5x5Description.
  ///
  /// In en, this message translates to:
  /// **'A classic linear-progression programme for building a strength base on the big barbell lifts. Alternate workout A and workout B three days a week and add a small amount of weight each time you complete every rep. Simple, fast, and it works for months before it stops.'**
  String get programsFullBody5x5Description;

  /// No description provided for @programsUpperLowerSummary.
  ///
  /// In en, this message translates to:
  /// **'Four days, each muscle trained twice a week'**
  String get programsUpperLowerSummary;

  /// No description provided for @programsUpperLowerDescription.
  ///
  /// In en, this message translates to:
  /// **'Two upper-body and two lower-body days. Each opens with a heavy compound in a low rep range, then moves to higher-rep accessories, with arm and shoulder work paired as supersets to save time. A good next step once three full-body days stop being enough.'**
  String get programsUpperLowerDescription;

  /// No description provided for @programsPushPullLegsSummary.
  ///
  /// In en, this message translates to:
  /// **'Six days, the classic bodybuilding rotation'**
  String get programsPushPullLegsSummary;

  /// No description provided for @programsPushPullLegsDescription.
  ///
  /// In en, this message translates to:
  /// **'Pressing muscles, pulling muscles and legs on their own days, run twice through the week. Lots of volume for building muscle, with arm work done as supersets. Demanding on time: if six days is too many, run each day once and take the weekend off.'**
  String get programsPushPullLegsDescription;

  /// No description provided for @programsPercentageStrengthSummary.
  ///
  /// In en, this message translates to:
  /// **'Four days, main lifts planned as a percentage of your 1RM'**
  String get programsPercentageStrengthSummary;

  /// No description provided for @programsPercentageStrengthDescription.
  ///
  /// In en, this message translates to:
  /// **'One day each for squat, bench, deadlift and overhead press. The main lift is planned as a percentage of your one-rep max, and Gymfy works out the weight from your tested or estimated 1RM, rounded to plates you can load. Pairs well with a training block on the split, such as three weeks of training and a deload week.'**
  String get programsPercentageStrengthDescription;

  /// No description provided for @programsBodyPartSplitSummary.
  ///
  /// In en, this message translates to:
  /// **'Five days, one muscle group per day'**
  String get programsBodyPartSplitSummary;

  /// No description provided for @programsBodyPartSplitDescription.
  ///
  /// In en, this message translates to:
  /// **'Chest, back, shoulders, arms and legs, each with a day to itself. Every muscle is trained hard once a week with plenty of exercises, and arm day runs as two supersets. Suits people who like long, focused sessions and can train five days in a row.'**
  String get programsBodyPartSplitDescription;

  /// No description provided for @programsBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Training block'**
  String get programsBlockTitle;

  /// No description provided for @programsBlockIntro.
  ///
  /// In en, this message translates to:
  /// **'Train for a set number of weeks, then take one lighter deload week, then start again. During the deload week the suggested weights drop to the deload load.'**
  String get programsBlockIntro;

  /// No description provided for @programsBlockSwitch.
  ///
  /// In en, this message translates to:
  /// **'Run in training blocks'**
  String get programsBlockSwitch;

  /// No description provided for @programsBlockWeeksLabel.
  ///
  /// In en, this message translates to:
  /// **'Training weeks'**
  String get programsBlockWeeksLabel;

  /// No description provided for @programsBlockFewerWeeks.
  ///
  /// In en, this message translates to:
  /// **'Fewer weeks'**
  String get programsBlockFewerWeeks;

  /// No description provided for @programsBlockMoreWeeks.
  ///
  /// In en, this message translates to:
  /// **'More weeks'**
  String get programsBlockMoreWeeks;

  /// No description provided for @programsBlockWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String programsBlockWeeks(int count);

  /// No description provided for @programsBlockThenDeload.
  ///
  /// In en, this message translates to:
  /// **'then 1 deload week'**
  String get programsBlockThenDeload;

  /// No description provided for @programsBlockDeloadLoad.
  ///
  /// In en, this message translates to:
  /// **'Deload load'**
  String get programsBlockDeloadLoad;

  /// No description provided for @programsBlockOfWorkingWeights.
  ///
  /// In en, this message translates to:
  /// **'of your usual working weights'**
  String get programsBlockOfWorkingWeights;

  /// No description provided for @programsBlockWeekOneBegan.
  ///
  /// In en, this message translates to:
  /// **'Week 1 began'**
  String get programsBlockWeekOneBegan;

  /// No description provided for @programsBlockPickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Week 1 began on'**
  String get programsBlockPickerHelp;

  /// No description provided for @programsBlockStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String programsBlockStarts(String date);

  /// week is programsBlockWeekOf or programsBlockDeloadWeek.
  ///
  /// In en, this message translates to:
  /// **'Today: {week}'**
  String programsBlockToday(String week);

  /// No description provided for @programsBlockDeloadWeek.
  ///
  /// In en, this message translates to:
  /// **'Deload week'**
  String get programsBlockDeloadWeek;

  /// No description provided for @programsBlockWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week {week} of {weeks}'**
  String programsBlockWeekOf(int week, int weeks);

  /// No description provided for @programsBlockBannerDeload.
  ///
  /// In en, this message translates to:
  /// **'Suggested weights at {percent}. A new block starts next week.'**
  String programsBlockBannerDeload(String percent);

  /// No description provided for @programsBlockBannerNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Deload week at {percent} next week · block {cycle}'**
  String programsBlockBannerNextWeek(String percent, int cycle);

  /// weeks is always 2 or more; one week away is programsBlockBannerNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Deload at {percent} in {weeks} weeks · block {cycle}'**
  String programsBlockBannerInWeeks(String percent, int weeks, int cycle);

  /// No description provided for @programsPercentOfMax.
  ///
  /// In en, this message translates to:
  /// **'% of 1RM'**
  String get programsPercentOfMax;

  /// No description provided for @programsPercentNoMax.
  ///
  /// In en, this message translates to:
  /// **'No 1RM yet. Log a set or enter a tested max and the weight appears in your workout.'**
  String get programsPercentNoMax;

  /// Both are weights with their unit.
  ///
  /// In en, this message translates to:
  /// **'≈ {weight} today, from your 1RM of {max}.'**
  String programsPercentPreview(String weight, String max);

  /// No description provided for @exercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesTitle;

  /// No description provided for @exercisesCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get exercisesCancelSelection;

  /// No description provided for @exercisesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String exercisesSelected(int count);

  /// No description provided for @exercisesAddToDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to day'**
  String get exercisesAddToDayTooltip;

  /// No description provided for @exercisesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load exercises.\n{error}'**
  String exercisesLoadFailed(String error);

  /// No description provided for @exercisesAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get exercisesAddExercise;

  /// No description provided for @exercisesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or muscle'**
  String get exercisesSearchHint;

  /// No description provided for @exercisesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get exercisesClearSearch;

  /// No description provided for @exercisesGroupChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get exercisesGroupChest;

  /// No description provided for @exercisesGroupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get exercisesGroupBack;

  /// No description provided for @exercisesGroupShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get exercisesGroupShoulders;

  /// No description provided for @exercisesGroupArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get exercisesGroupArms;

  /// No description provided for @exercisesGroupLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get exercisesGroupLegs;

  /// No description provided for @exercisesGroupCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get exercisesGroupCore;

  /// No description provided for @exercisesGroupNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get exercisesGroupNeck;

  /// No description provided for @exercisesNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get exercisesNoMatchesTitle;

  /// No description provided for @exercisesNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or clear a muscle filter.'**
  String get exercisesNoMatchesMessage;

  /// Marks an exercise the user made themselves.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get exercisesCustomBadge;

  /// No description provided for @exercisesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercisesDetailTitle;

  /// No description provided for @exercisesDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this exercise.\n{error}'**
  String exercisesDetailLoadFailed(String error);

  /// No description provided for @exercisesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found.'**
  String get exercisesNotFound;

  /// No description provided for @exercisesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String exercisesDeleteTitle(String name);

  /// No description provided for @exercisesDeleteWithHistory.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your library and from every picker. Workouts you already logged with it keep their sets.'**
  String get exercisesDeleteWithHistory;

  /// No description provided for @exercisesDeleteNoHistory.
  ///
  /// In en, this message translates to:
  /// **'It has never been logged, so it will be removed completely.'**
  String get exercisesDeleteNoHistory;

  /// No description provided for @exercisesArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} removed — past workouts kept it'**
  String exercisesArchived(String name);

  /// No description provided for @exercisesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String exercisesDeleted(String name);

  /// No description provided for @exercisesMusclesWorked.
  ///
  /// In en, this message translates to:
  /// **'Muscles worked'**
  String get exercisesMusclesWorked;

  /// No description provided for @exercisesPreviewSoon.
  ///
  /// In en, this message translates to:
  /// **'Preview coming soon'**
  String get exercisesPreviewSoon;

  /// No description provided for @exercisesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get exercisesEditTitle;

  /// No description provided for @exercisesNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get exercisesNewTitle;

  /// No description provided for @exercisesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exercisesNameLabel;

  /// No description provided for @exercisesNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cable Fly'**
  String get exercisesNameHint;

  /// No description provided for @exercisesMusclesHelp.
  ///
  /// In en, this message translates to:
  /// **'Drives the muscle map, so pick everything this lift actually hits.'**
  String get exercisesMusclesHelp;

  /// No description provided for @exercisesEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get exercisesEquipment;

  /// No description provided for @exercisesPlateLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded with plates'**
  String get exercisesPlateLoaded;

  /// No description provided for @exercisesPlateLoadedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log sets by tapping plates instead of typing a weight. For barbell and EZ-bar lifts.'**
  String get exercisesPlateLoadedSubtitle;

  /// No description provided for @exercisesImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get exercisesImage;

  /// No description provided for @exercisesImageHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. A GIF from your gallery animates just like the built-in ones.'**
  String get exercisesImageHelp;

  /// No description provided for @exercisesChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get exercisesChooseImage;

  /// No description provided for @exercisesReplaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get exercisesReplaceImage;

  /// No description provided for @exercisesRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get exercisesRemoveImage;

  /// No description provided for @exercisesAddToDayTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add to day} other{Add {count} exercises to day}}'**
  String exercisesAddToDayTitle(int count);

  /// No description provided for @exercisesNoDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No workout days yet'**
  String get exercisesNoDaysTitle;

  /// No description provided for @exercisesNoDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a split with at least one day in the Workout tab, then come back here.'**
  String get exercisesNoDaysMessage;

  /// No description provided for @exercisesNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get exercisesNoteLabel;

  /// No description provided for @exercisesNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Seat height, pin, grip width, which machine…'**
  String get exercisesNoteHint;

  /// No description provided for @exercisesNoteClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get exercisesNoteClear;

  /// No description provided for @exercisesNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a note — seat height, pin, grip…'**
  String get exercisesNoteEmpty;

  /// No description provided for @exercisesEquipmentFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Equipment ({count})'**
  String exercisesEquipmentFilterActive(int count);

  /// No description provided for @exercisesEquipmentFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter by equipment'**
  String get exercisesEquipmentFilter;

  /// No description provided for @exercisesAllEquipment.
  ///
  /// In en, this message translates to:
  /// **'All equipment'**
  String get exercisesAllEquipment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
