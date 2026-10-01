// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonCreate => 'Erstellen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonAll => 'Alle';

  @override
  String get commonNotSet => 'Nicht angegeben';

  @override
  String get commonToday => 'Heute';

  @override
  String get commonYesterday => 'Gestern';

  @override
  String get shellNavHome => 'Start';

  @override
  String get shellNavWorkout => 'Training';

  @override
  String get shellNavProgress => 'Fortschritt';

  @override
  String get shellNavMore => 'Mehr';

  @override
  String get sharedWeightWheelLabel => 'Gewicht';

  @override
  String sharedLoggedSetReps(String weight, int reps) {
    return '$weight × $reps Wdh.';
  }

  @override
  String sharedAddedToDayNone(int asked) {
    String _temp0 = intl.Intl.pluralLogic(
      asked,
      locale: localeName,
      other: 'Alle $asked waren schon in diesem Tag',
      one: 'Schon in diesem Tag',
    );
    return '$_temp0';
  }

  @override
  String sharedAddedToDayAdded(int added) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added Übungen hinzugefügt',
      one: '1 Übung hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String sharedAddedToDaySkipped(String addedText, int skipped) {
    return '$addedText – $skipped schon vorhanden';
  }

  @override
  String get muscleChest => 'Brust';

  @override
  String get muscleFrontDeltoid => 'Vordere Schulter';

  @override
  String get muscleSideDeltoid => 'Seitliche Schulter';

  @override
  String get muscleBiceps => 'Bizeps';

  @override
  String get muscleForearms => 'Unterarme';

  @override
  String get muscleAbs => 'Bauch';

  @override
  String get muscleObliques => 'Seitlicher Bauch';

  @override
  String get muscleQuads => 'Quadrizeps';

  @override
  String get muscleAdductors => 'Adduktoren';

  @override
  String get muscleTrapezius => 'Trapez';

  @override
  String get muscleRearDeltoid => 'Hintere Schulter';

  @override
  String get muscleLats => 'Latissimus';

  @override
  String get muscleLowerBack => 'Unterer Rücken';

  @override
  String get muscleTriceps => 'Trizeps';

  @override
  String get muscleGlutes => 'Gesäß';

  @override
  String get muscleHamstrings => 'Beinbeuger';

  @override
  String get muscleCalves => 'Waden';

  @override
  String get muscleNeck => 'Nacken';

  @override
  String get equipmentBarbell => 'Langhantel';

  @override
  String get equipmentDumbbell => 'Kurzhantel';

  @override
  String get equipmentMachine => 'Maschine';

  @override
  String get equipmentCable => 'Kabelzug';

  @override
  String get equipmentBodyweight => 'Körpergewicht';

  @override
  String get equipmentOther => 'Sonstiges';

  @override
  String get setTypeWarmup => 'Aufwärmsatz';

  @override
  String get setTypeNormal => 'Arbeitssatz';

  @override
  String get setTypeDrop => 'Dropsatz';

  @override
  String get setTypeFailure => 'Bis Versagen';

  @override
  String get lifterSexMale => 'Männlich';

  @override
  String get lifterSexFemale => 'Weiblich';

  @override
  String get measurementFieldWeight => 'Gewicht';

  @override
  String get measurementFieldChest => 'Brust';

  @override
  String get measurementFieldWaist => 'Taille';

  @override
  String get measurementFieldHips => 'Hüfte';

  @override
  String get measurementFieldArms => 'Arme';

  @override
  String get measurementFieldLegs => 'Beine';

  @override
  String get goalKindLift => 'Übung';

  @override
  String get goalKindFrequency => 'Trainings';

  @override
  String get goalKindBodyweight => 'Körpergewicht';

  @override
  String get bodyProfileHeightLabel => 'Größe';

  @override
  String get bodyProfileHeightQuestion => 'Wie groß bist du?';

  @override
  String get bodyProfileAgeLabel => 'Alter';

  @override
  String get bodyProfileAgeQuestion => 'Wie alt bist du?';

  @override
  String get bodyProfileAgeHelper =>
      'Wird als Geburtsjahr gespeichert, damit es immer stimmt.';

  @override
  String get themeDarkDefaultLabel => 'Dunkel';

  @override
  String get themeDarkDefaultDescription =>
      'Fast schwarz mit sanft grauen Karten.';

  @override
  String get themeAmoledLabel => 'AMOLED-Schwarz';

  @override
  String get themeAmoledDescription =>
      'Echtes Schwarz. Spart Strom auf OLED-Displays.';

  @override
  String get themeHighContrastLabel => 'Hoher Kontrast';

  @override
  String get themeHighContrastDescription =>
      'Hellere Schrift und sichtbare Ränder.';

  @override
  String get themeTokyoNightDescription =>
      'Tiefes Blaugrau mit leichtem Indigo-Stich.';

  @override
  String get themeDraculaDescription =>
      'Dunkles Violett mit kräftigen Akzenten.';

  @override
  String get themeCatppuccinMochaDescription =>
      'Warme, gedämpfte Pastelltöne auf tiefem Anthrazit.';

  @override
  String get themeGruvboxDescription => 'Warme Retro-Töne in Braun und Grün.';

  @override
  String get themeHyperDescription =>
      'Durchscheinendes Glas über einem lebendigen Hintergrund.';

  @override
  String get notificationRestRunningTitle => 'Pause';

  @override
  String get notificationRestRunningChannel => 'Pausen-Countdown';

  @override
  String get notificationRestRunningChannelDescription =>
      'Zeigt den Pausen-Countdown, während du in einer anderen App bist.';

  @override
  String get notificationRestOverTitle => 'Pause vorbei';

  @override
  String notificationRestOverBody(String exercise) {
    return 'Nächster Satz: $exercise';
  }

  @override
  String get notificationRestOverChannel => 'Pausentimer';

  @override
  String get notificationRestOverChannelDescription =>
      'Sagt dir, wenn die Satzpause vorbei ist.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionTheme => 'Design';

  @override
  String get settingsSectionAccent => 'Akzentfarbe';

  @override
  String get settingsSectionUnits => 'Einheiten';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionPlates => 'Hantelscheiben';

  @override
  String get settingsSectionOverload => 'Progressive Overload';

  @override
  String get settingsSectionLogging => 'Loggen';

  @override
  String get settingsSectionYou => 'Über dich';

  @override
  String get settingsSectionRestTimer => 'Pausentimer';

  @override
  String get settingsSectionData => 'Daten';

  @override
  String get settingsSectionHealthConnect => 'Health Connect';

  @override
  String get settingsAccentCaption =>
      'Färbt Buttons, Hervorhebungen und Diagramme.';

  @override
  String get settingsUnitsCaption =>
      'Gewichte werden immer in Kilogramm gespeichert – Umschalten ändert also nie, was du geloggt hast.';

  @override
  String get settingsLanguageTitle => 'App-Sprache';

  @override
  String get settingsLanguageSystem => 'Systemsprache';

  @override
  String settingsLanguageSystemSubtitle(String language) {
    return 'Wie am Handy: $language';
  }

  @override
  String get settingsLanguageExerciseNames =>
      'Übungsnamen bleiben auf Englisch.';

  @override
  String get settingsBackupTitle => 'Backup & Wiederherstellung';

  @override
  String get settingsBackupSubtitle =>
      'Alles in einer Datei, dazu automatische Backups';

  @override
  String get settingsExportTitle => 'Daten exportieren';

  @override
  String get settingsExportSubtitle =>
      'Speichere dein ganzes Trainingslog als Tabelle oder JSON';

  @override
  String get settingsNameTitle => 'Name';

  @override
  String get settingsNameDialogTitle => 'Dein Name';

  @override
  String get settingsNameDialogHint => 'Leer lassen zum Entfernen';

  @override
  String get settingsDefaultRestTitle => 'Standardpause';

  @override
  String settingsDefaultRestSubtitle(String rest) {
    return '$rest zwischen den Sätzen';
  }

  @override
  String get settingsRestAlertsTitle => 'Pausentimer-Benachrichtigungen';

  @override
  String get settingsRestAlertsSubtitle =>
      'Zeigt den Countdown in der Benachrichtigungsleiste und meldet sich, wenn die Pause vorbei ist';

  @override
  String get settingsVibrateTitle => 'Vibrieren';

  @override
  String get settingsVibrateSubtitle =>
      'Praktisch, wenn das Handy in der Tasche steckt';

  @override
  String get settingsWorkoutNotificationTitle => 'Trainingsbenachrichtigung';

  @override
  String get settingsWorkoutNotificationSubtitle =>
      'Zeigt den aktuellen Satz und die Pause in der Benachrichtigungsleiste, mit Buttons zum Loggen eines Satzes und zum Steuern der Pause';

  @override
  String get settingsBodyDiagramTitle => 'Körperdiagramm';

  @override
  String get settingsBodyDiagramNotSet =>
      'Nicht angegeben – zeigt das männliche Diagramm, ohne Kraftlevel';

  @override
  String settingsBodyDiagramSubtitle(String sex) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'female': 'Weibliches Diagramm und Kraftstandards',
      'other': 'Männliches Diagramm und Kraftstandards',
    });
    return '$_temp0';
  }

  @override
  String settingsThemeAccentSuggestion(String theme) {
    return '$theme ist auf eine eigene Akzentfarbe abgestimmt.';
  }

  @override
  String get settingsThemeUseAccent => 'Übernehmen';

  @override
  String get moreTitle => 'Mehr';

  @override
  String get moreExerciseLibraryTitle => 'Übungsbibliothek';

  @override
  String get moreExerciseLibrarySubtitle =>
      'Alle Übungen, durchsuchbar nach Name oder Muskel';

  @override
  String get moreCalorieLogTitle => 'Kalorientagebuch';

  @override
  String get moreCalorieLogSubtitle =>
      'Mahlzeiten, Kalorien und Makros tracken';

  @override
  String get moreWeeklyTitle => 'Diese Woche';

  @override
  String get moreWeeklySubtitle => 'Kalorien der letzten 7 Tage';

  @override
  String get moreOneRmTitle => '1RM-Rechner';

  @override
  String get moreOneRmSubtitle => 'Schätze dein 1RM aus einem beliebigen Satz';

  @override
  String get moreStrengthRankTitle => 'Kraftlevel';

  @override
  String get moreStrengthRankSubtitle =>
      'Deine Grundübungen im Verhältnis zum Körpergewicht';

  @override
  String get moreSharePlanTitle => 'Plan teilen';

  @override
  String get moreSharePlanSubtitle =>
      'Schick deine Splits an andere oder importiere ihre';

  @override
  String get moreImportTitle => 'Verlauf importieren';

  @override
  String get moreImportSubtitle =>
      'Hol deine Trainings aus Hevy, Strong oder ähnlichen Apps';

  @override
  String get moreHelpTitle => 'Hilfe';

  @override
  String get moreHelpSubtitle => 'Über Gymfy und wer dahintersteckt';

  @override
  String get moreSettingsTitle => 'Einstellungen';

  @override
  String get moreSettingsSubtitle =>
      'Akzentfarbe, dein Name, Pausentimer-Alarme';

  @override
  String get helpTitle => 'Hilfe';

  @override
  String get helpIntro =>
      'Gymfy wird von einer einzigen Person entwickelt. Alles, was du loggst, bleibt auf deinem Handy – es gibt kein Konto und keinen Server.';

  @override
  String get helpFeedbackTitle => 'Feedback senden';

  @override
  String get helpFeedbackSubtitle =>
      'Öffnet deine Mail-App · nur die App-Version wird angehängt';

  @override
  String get helpDeveloperTitle => 'Entwickler';

  @override
  String get helpDeveloperSubtitle => 'Joshynaldo auf GitHub';

  @override
  String get helpAnimationsTitle => 'Übungsanimationen';

  @override
  String get helpAnimationsSubtitle =>
      'ExerciseGymGifsDB · mit Genehmigung verwendet';

  @override
  String get helpVersionTitle => 'Version';

  @override
  String helpOpenLinkFailed(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String helpNoMailApp(String address) {
    return 'Keine Mail-App gefunden. Schreib an $address';
  }

  @override
  String helpFeedbackMailDevice(
    String version,
    String platform,
    String osVersion,
  ) {
    return 'Gymfy $version auf $platform $osVersion';
  }

  @override
  String get helpFeedbackMailNote =>
      'Nur diese zwei Zeilen werden angehängt. Lösch sie, wenn du sie lieber nicht mitschicken willst.';

  @override
  String get onboardingSaving => 'Speichern…';

  @override
  String get onboardingFinish => 'Los geht\'s';

  @override
  String get onboardingChangeLater =>
      'Das alles kannst du später in den Einstellungen ändern.';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei Gymfy';

  @override
  String get onboardingWelcomeBody =>
      'Alles, was du loggst, bleibt auf diesem Handy – es gibt kein Konto, und nichts wird hochgeladen. Wie sollen wir dich nennen?';

  @override
  String get onboardingNameLabel => 'Dein Name';

  @override
  String get onboardingNameHint => 'Optional';

  @override
  String get onboardingSexTitle => 'Körperdiagramm und Kraftstandards';

  @override
  String get onboardingSexBody =>
      'Legt fest, welchen Körper die Muskelkarte zeigt und mit welcher Krafttabelle deine Lifts verglichen werden. Optional – ohne Angabe funktioniert die App genauso, nur ohne Kraftlevel.';

  @override
  String get onboardingSexDecline => 'Keine Angabe';

  @override
  String get onboardingBodyweightTitle => 'Wie viel wiegst du?';

  @override
  String get onboardingBodyweightBody =>
      'Damit werden deine Lifts an deinem Körpergewicht gemessen, und es wird der erste Punkt in deinem Gewichtsverlauf. Lass es auf null, um es zu überspringen – sonst hängt nichts davon ab.';

  @override
  String get onboardingBodyweightLabel => 'Körpergewicht';

  @override
  String get onboardingSkipped => 'Keine Angabe';

  @override
  String get onboardingOverloadTitle =>
      'Soll Gymfy dir schwerere Gewichte vorschlagen?';

  @override
  String get onboardingOverloadBody =>
      'Wenn du in jedem Satz das obere Ende deines Wiederholungsbereichs schaffst, startet das nächste Training mit etwas mehr auf der Stange. Es bleibt immer ein Vorschlag – das Gewicht kannst du jederzeit selbst ändern.';

  @override
  String get onboardingAccentTitle => 'Wähl deine Farbe';

  @override
  String get onboardingAccentBody =>
      'Färbt Buttons, Hervorhebungen und Diagramme in der ganzen App. Tipp eine an, um sie auszuprobieren – die App ändert sich sofort.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get homeFindExerciseTooltip => 'Übung suchen';

  @override
  String homeStreakSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage in Folge trainiert',
      one: '1 Tag in Folge trainiert',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayNoSplitTitle => 'Kein aktiver Split';

  @override
  String get homeTodayNoSplitMessage =>
      'Wähl das Programm, dem du folgst, um deine Woche zu planen.';

  @override
  String get homeTodayNoSplitAction => 'Split auswählen';

  @override
  String get homeTodayRestTitle => 'Ruhetag';

  @override
  String homeTodayRestMessage(String split) {
    return 'Heute steht in $split nichts an.';
  }

  @override
  String get homeTodayNoExercises =>
      'Noch keine Übungen – öffne den Tag, um welche hinzuzufügen.';

  @override
  String homeTodayResume(String workout) {
    return '$workout fortsetzen';
  }

  @override
  String get homeTodayStart => 'Training starten';

  @override
  String get homeTodayAddExercises => 'Übungen hinzufügen';

  @override
  String get homeTodayStartEmpty => 'Leeres Training starten';

  @override
  String get homeNextUpTomorrow => 'Morgen';

  @override
  String homeNextUpNextWeekday(String weekday) {
    return 'Nächsten $weekday';
  }

  @override
  String get homeLastWorkoutHeading => 'LETZTES TRAINING';

  @override
  String homeLastWorkoutSets(int count, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0 • $volume';
  }

  @override
  String get homeWeekTitle => 'Diese Woche';

  @override
  String homeWeekWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainings',
      one: '1 Training',
    );
    return '$_temp0';
  }

  @override
  String homeWeekLiftedSince(String weekday) {
    return 'seit $weekday gestemmt';
  }

  @override
  String get homeRecapPeriodWeek => 'Woche';

  @override
  String get homeRecapPeriodMonth => 'Monat';

  @override
  String get homeRecapPeriodYear => 'Jahr';

  @override
  String get muscleMapFront => 'Vorne';

  @override
  String get muscleMapBack => 'Hinten';

  @override
  String get muscleMapShowHeatmap => 'Zur Heatmap wechseln';

  @override
  String get muscleMapShowColours => 'Zu Farben pro Muskel wechseln';

  @override
  String muscleMapLoadFailed(String error) {
    return 'Die Muskelkarte konnte nicht geladen werden.\n$error';
  }

  @override
  String muscleMapBodyLoadFailed(String error) {
    return 'Das Körperdiagramm konnte nicht geladen werden.\n$error';
  }

  @override
  String get muscleMapContrastCaption =>
      'Jeder Muskel hat seine eigene Farbe. Heller heißt weiterhin mehr Volumen.';
}
