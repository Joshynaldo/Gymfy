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
