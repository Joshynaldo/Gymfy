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
  String get commonDelete => 'Löschen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonOff => 'Aus';

  @override
  String get commonActive => 'Aktiv';

  @override
  String commonListAnd(String first, String second) {
    return '$first und $second';
  }

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

  @override
  String get workoutTitle => 'Training';

  @override
  String workoutSplitsLoadFailed(String error) {
    return 'Deine Splits konnten nicht geladen werden.\n$error';
  }

  @override
  String get workoutAddDay => 'Tag hinzufügen';

  @override
  String get workoutStartEmptyTooltip => 'Leeres Training starten';

  @override
  String get workoutSwitchSplitTooltip => 'Split wechseln';

  @override
  String get workoutSwitcherTitle => 'Deine Splits';

  @override
  String get workoutNewSplit => 'Neuer Split';

  @override
  String get workoutBrowsePrograms => 'Programme ansehen';

  @override
  String get workoutManageSplits => 'Splits verwalten';

  @override
  String get workoutNoSplitsTitle => 'Noch keine Splits';

  @override
  String get workoutNoSplitsMessage =>
      'Erstell deinen ersten Split und plane dein Training.';

  @override
  String get workoutNoSplitsFromProgram => 'Mit einem Programm starten';

  @override
  String get workoutNoSplitsFreeWorkout => 'Oder starte ein leeres Training';

  @override
  String get workoutNoActiveSplitTitle => 'Kein aktiver Split';

  @override
  String get workoutNoActiveSplitMessage =>
      'Wähl das Programm, dem du folgst – dann erscheinen seine Tage hier.';

  @override
  String get workoutNoActiveSplitAction => 'Split auswählen';

  @override
  String get workoutFreeWorkoutName => 'Freies Training';

  @override
  String get workoutSplitsTitle => 'Splits';

  @override
  String get workoutSplitNameLabel => 'Name des Splits';

  @override
  String get workoutSplitNameHint => 'z. B. Push / Pull / Legs';

  @override
  String get workoutDeleteSplitTooltip => 'Split löschen';

  @override
  String workoutDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get workoutDeleteSplitMessage =>
      'Damit werden der Split und alles darin entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get workoutSplitFallbackTitle => 'Split';

  @override
  String get workoutDayNameLabel => 'Name des Tags';

  @override
  String get workoutDayNameHint => 'z. B. Push';

  @override
  String workoutNowFollowing(String split) {
    return 'Du folgst jetzt $split';
  }

  @override
  String get workoutSetActive => 'Aktivieren';

  @override
  String workoutSplitLoadFailed(String error) {
    return 'Dieser Split konnte nicht geladen werden.\n$error';
  }

  @override
  String workoutDayCardSubtitle(int count, String schedule) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen',
      one: '1 Übung',
    );
    return '$_temp0 • $schedule';
  }

  @override
  String get workoutDayNotScheduled => 'Nicht eingeplant';

  @override
  String get workoutDeleteDayTooltip => 'Tag löschen';

  @override
  String get workoutDayNoExercises =>
      'Noch keine Übungen – tipp, um welche hinzuzufügen.';

  @override
  String get workoutDeleteDayMessage =>
      'Damit werden der Tag und seine Übungen entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get workoutNoDaysTitle => 'Noch keine Tage';

  @override
  String get workoutNoDaysMessage =>
      'Füg einen Trainingstag hinzu (etwa „Push“ oder „Beine“), um diesen Split aufzubauen.';

  @override
  String get workoutDayFallbackTitle => 'Tag';

  @override
  String workoutDayLoadFailed(String error) {
    return 'Dieser Tag konnte nicht geladen werden.\n$error';
  }

  @override
  String get workoutStartWorkout => 'Training starten';

  @override
  String get workoutAddExercises => 'Übungen hinzufügen';

  @override
  String workoutPlannedSetsReps(int sets, String reps) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets Sätze',
      one: '1 Satz',
    );
    return '$_temp0 × $reps Wdh.';
  }

  @override
  String workoutPlannedWarmups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufwärmsätze',
      one: '1 Aufwärmsatz',
    );
    return '$_temp0';
  }

  @override
  String workoutPlannedPercent(String percent) {
    return '@ $percent 1RM';
  }

  @override
  String get workoutSuperset => 'Supersatz';

  @override
  String get workoutRemoveExerciseTooltip => 'Übung entfernen';

  @override
  String get workoutDragToReorder => 'Zum Sortieren ziehen';

  @override
  String get workoutSupersetRestAfterLast =>
      'SUPERSATZ · PAUSE NACH DER LETZTEN';

  @override
  String get workoutSupersetWithAbove => 'Supersatz mit der Übung darüber';

  @override
  String get workoutSupersetWithBelow => 'Supersatz mit der Übung darunter';

  @override
  String get workoutSupersetLeave => 'Aus dem Supersatz nehmen';

  @override
  String workoutUpdatedExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Übungen aktualisiert',
      one: '1 Übung aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String get workoutSetsRepsTitle => 'Sätze & Wiederholungen';

  @override
  String get workoutWheelSets => 'Sätze';

  @override
  String get workoutWheelReps => 'Wdh.';

  @override
  String get workoutWheelFrom => 'Von';

  @override
  String get workoutWheelTo => 'Bis';

  @override
  String get workoutRepRange => 'Wiederholungsbereich';

  @override
  String get workoutWarmupSets => 'Aufwärmsätze';

  @override
  String workoutSaveToAll(int count) {
    return 'Für alle $count speichern';
  }

  @override
  String get workoutDayEmptyTitle => 'Noch keine Übungen';

  @override
  String get workoutDayEmptyMessage =>
      'Füg Übungen aus der Bibliothek hinzu und leg ihre Sätze und Wiederholungen fest.';

  @override
  String get workoutPickerClear => 'Zurücksetzen';

  @override
  String get workoutPickerNoMatches => 'Keine Übung passt zu deinen Filtern.';

  @override
  String workoutPickerSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
      zero: 'Nichts ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String workoutPickerAddCount(int count) {
    return '$count hinzufügen';
  }

  @override
  String workoutLoadFailed(String error) {
    return 'Dieses Training konnte nicht geladen werden.\n$error';
  }

  @override
  String get workoutNotFound => 'Training nicht gefunden.';

  @override
  String get workoutFinish => 'Beenden';

  @override
  String get workoutAddExercise => 'Übung hinzufügen';

  @override
  String get workoutUpNext => 'ALS NÄCHSTES';

  @override
  String get workoutReorder => 'Sortieren';

  @override
  String get workoutSwapExercise => 'Übung tauschen';

  @override
  String get workoutSwapExerciseSubtitle => 'Stattdessen etwas anderes machen';

  @override
  String get workoutRemoveFromWorkout => 'Aus dem Training entfernen';

  @override
  String get workoutPlanUnchanged => 'Dein Plan bleibt, wie er ist';

  @override
  String workoutPhaseWarmup(int number) {
    return 'Aufwärmsatz $number';
  }

  @override
  String workoutPhaseWorking(int number) {
    return 'Satz $number · Arbeitssatz';
  }

  @override
  String get workoutExerciseOptionsTooltip => 'Übungsoptionen';

  @override
  String get workoutWarmupCalculator => 'Aufwärmrechner';

  @override
  String workoutLogSet(int number) {
    return 'Satz $number loggen';
  }

  @override
  String workoutSupersetWith(String partners) {
    return 'Supersatz mit $partners – Pause erst nach der letzten Übung';
  }

  @override
  String get workoutSupersetCaps => 'SUPERSATZ';

  @override
  String workoutWarmupProgress(int number, int expected) {
    return 'Aufwärmen $number/$expected';
  }

  @override
  String get workoutWarmup => 'Aufwärmen';

  @override
  String workoutSuggestionEarned(String weight) {
    return 'Letztes Mal alle Sätze geschafft – rauf auf $weight';
  }

  @override
  String workoutSuggestionDeload(String weight) {
    return 'Mehrere Steigerungen in Folge – etwas leichter mit $weight';
  }

  @override
  String workoutSuggestionAtLimit(String weight) {
    return 'Topsatz war letztes Mal am Limit – bleib bei $weight';
  }

  @override
  String workoutSuggestionPercent(String percent, String weight) {
    return '$percent deines 1RM – $weight';
  }

  @override
  String workoutSuggestionBlockDeload(String percent, String weight) {
    return 'Deload-Woche mit $percent – $weight';
  }

  @override
  String workoutSuggestionSame(String weight) {
    return 'Wieder $weight wie letztes Mal';
  }

  @override
  String get workoutChangeSetTypeTooltip => 'Satztyp ändern';

  @override
  String get workoutSetTypeTitle => 'Satztyp';

  @override
  String get workoutDeleteSetTooltip => 'Satz löschen';

  @override
  String get workoutBadgeWarmup => 'A';

  @override
  String get workoutBadgeDrop => 'D';

  @override
  String get workoutBadgeFailure => 'V';

  @override
  String get workoutEmptyFreeMessage =>
      'Füg Übungen nach und nach hinzu. Nichts hier ändert deinen Plan.';

  @override
  String get workoutEmptyNothingTitle => 'Nichts zu loggen';

  @override
  String get workoutEmptyNothingMessage =>
      'Dieser Tag hat keine Übungen. Füg welche für heute hinzu – dein Plan bleibt, wie er ist.';

  @override
  String get workoutLogWarmupCaption => 'Aufwärmsatz · langsam steigern';

  @override
  String get workoutLogDropCaption => 'Dropsatz · leichter, direkt danach';

  @override
  String workoutLogFailureCaption(String phase) {
    return '$phase · bis zum Versagen';
  }

  @override
  String get workoutWorkingSet => 'Arbeitssatz';

  @override
  String get workoutLogRepsUnit => 'Wdh.';

  @override
  String get workoutLogStepWeight => 'SCHRITT 1 – GEWICHT';

  @override
  String get workoutLogStepReps => 'SCHRITT 2 – WIEDERHOLUNGEN';

  @override
  String get workoutLogStepTime => 'SCHRITT 2 – ZEIT';

  @override
  String get workoutLogTypeWeight => 'Gewicht eintippen';

  @override
  String get workoutLogStackPlates => 'Scheiben stapeln';

  @override
  String get workoutLogRepeat => 'Satz wiederholen';

  @override
  String get workoutLogNextTime => 'Weiter: Zeit';

  @override
  String get workoutLogNextReps => 'Weiter: Wdh.';

  @override
  String get workoutLogSaveSet => 'Satz speichern';

  @override
  String get workoutLogHolding => 'LÄUFT';

  @override
  String get workoutLogMinutes => 'MIN';

  @override
  String get workoutLogSeconds => 'SEK';

  @override
  String get workoutTimerStop => 'Stopp';

  @override
  String get workoutTimerStart => 'Timer starten';

  @override
  String get workoutEffortRpeLabel => 'WIE SCHWER · RPE';

  @override
  String get workoutEffortRirLabel => 'WDH. IN RESERVE · RIR';

  @override
  String workoutNoteEarned(String weight) {
    return 'Letztes Mal hast du alle Sätze geschafft – jetzt geht\'s rauf auf $weight.';
  }

  @override
  String workoutNoteDeload(String weight) {
    return 'Mehrere Steigerungen in Folge. Empfohlen ist eine leichtere Woche mit $weight.';
  }

  @override
  String workoutNoteAtLimit(String weight) {
    return 'Du hast alle Sätze geschafft, aber der Topsatz war am Limit – es bleibt bei $weight.';
  }

  @override
  String workoutNotePercent(String percent, String weight) {
    return 'Geplant mit $percent deines 1RM – $weight.';
  }

  @override
  String workoutNoteBlockDeload(String percent, String weight) {
    return 'Deload-Woche: $percent deines Arbeitsgewichts – $weight.';
  }

  @override
  String get workoutNoteSame =>
      'Gleiches Gewicht wie letztes Mal – das Wiederholungsziel hast du noch nicht erreicht.';

  @override
  String get workoutRestOverCaps => 'PAUSE VORBEI';

  @override
  String get workoutRestingCaps => 'PAUSE';

  @override
  String get workoutRestAddTooltip => '30 Sekunden mehr';

  @override
  String get workoutRestDismissTooltip => 'Schließen';

  @override
  String get workoutRestSkipTooltip => 'Pause überspringen';

  @override
  String get workoutRestOver => 'Pause vorbei';

  @override
  String workoutReps(int count) {
    return '$count Wdh.';
  }

  @override
  String workoutRecordLine(String kind, String value, String previous) {
    return '$kind · $value, vorher $previous';
  }

  @override
  String get workoutRecordNew => 'Neue Bestleistung';

  @override
  String workoutRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bestleistungen',
      one: '1 Bestleistung',
    );
    return '$_temp0';
  }

  @override
  String get workoutRecordKindWeight => 'Höchstes Gewicht';

  @override
  String get workoutRecordKindOneRm => 'Bestes geschätztes 1RM';

  @override
  String get workoutRecordKindReps => 'Meiste Wiederholungen';

  @override
  String get workoutRecordKindHold => 'Längstes Halten';

  @override
  String get workoutRecordKindVolume => 'Höchstes Trainingsvolumen';

  @override
  String workoutSwapTitle(String exercise) {
    return '$exercise tauschen';
  }

  @override
  String get workoutSwapScopeTitle => 'Wie lange tauschen?';

  @override
  String get workoutSwapScopeSession => 'Nur dieses Training';

  @override
  String get workoutSwapScopePlan => 'Dieses Training und den Plan';

  @override
  String get workoutSwapScopePlanSubtitle =>
      'Künftige Trainings dieses Tages nutzen sie auch';

  @override
  String get workoutSwapPlanClash =>
      'Diese Übung ist schon im Plan dieses Tages – der Tausch gilt also nur für dieses Training.';

  @override
  String get workoutReorderTitle => 'Übungen sortieren';

  @override
  String workoutWarmupRampCaption(String exercise, String ramp) {
    return '$exercise · Schema $ramp';
  }

  @override
  String get workoutWarmupWorkingWeight => 'ARBEITSGEWICHT';

  @override
  String get workoutWarmupLighter => 'Leichter';

  @override
  String get workoutWarmupHeavier => 'Schwerer';

  @override
  String get workoutWarmupEnterWeight =>
      'Gib das Gewicht ein, auf das du hinarbeitest.';

  @override
  String get workoutWarmupTooLight =>
      'Zu leicht zum Aufwärmen – leg direkt los.';

  @override
  String workoutWarmupLogSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufwärmsätze loggen',
      one: '1 Aufwärmsatz loggen',
    );
    return '$_temp0';
  }

  @override
  String get workoutWarmupEmptyBar => 'Leere Stange';

  @override
  String workoutWarmupStepPlates(int percent, String plates) {
    return '$percent % · $plates pro Seite';
  }

  @override
  String get workoutSummaryTitle => 'Training abgeschlossen';

  @override
  String workoutSummaryLoadFailed(String error) {
    return 'Die Zusammenfassung konnte nicht geladen werden.\n$error';
  }

  @override
  String get workoutSummaryNoSets =>
      'In diesem Training wurden keine Sätze geloggt.';

  @override
  String get workoutSummaryExercises => 'Übungen';

  @override
  String get workoutSummaryMusclesWorked => 'Trainierte Muskeln';

  @override
  String get workoutSummaryNoMuscles =>
      'Für dieses Training gibt es keine Muskeln anzuzeigen.';

  @override
  String get workoutSummaryDuration => 'Dauer';

  @override
  String get workoutSummarySets => 'Sätze';

  @override
  String get workoutSummaryVolume => 'Volumen';

  @override
  String workoutSummaryExerciseSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String workoutSummaryTopSet(String set) {
    return 'Topsatz $set';
  }

  @override
  String workoutSummaryTopSetTotal(String set, String volume) {
    return 'Topsatz $set  •  $volume gesamt';
  }

  @override
  String get workoutLoggingRateTitle => 'Bewerte, wie schwer jeder Satz war';

  @override
  String get workoutLoggingOffCaption =>
      'Aus: Beim Loggen werden nur Gewicht und Wiederholungen abgefragt.';

  @override
  String get workoutLoggingRpeCaption =>
      'RPE 6–10, optional bei jedem Arbeitssatz. Ein Topsatz mit 9,5 oder 10 hält den Overload-Vorschlag beim nächsten Mal auf demselben Gewicht.';

  @override
  String get workoutLoggingRirCaption =>
      'Wiederholungen in Reserve, optional bei jedem Arbeitssatz. Ein Topsatz ohne Reserve hält den Overload-Vorschlag beim nächsten Mal auf demselben Gewicht.';

  @override
  String get workoutWarmupRampTitle => 'Aufwärmschema';

  @override
  String workoutWarmupRampSubtitle(String ramp) {
    return '$ramp deines Arbeitsgewichts, nach der leeren Stange';
  }

  @override
  String workoutWarmupRampSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stufen',
      one: '1 Stufe',
    );
    return '$_temp0';
  }

  @override
  String get workoutRestBetweenSets => 'Pause zwischen den Sätzen';

  @override
  String get workoutRestUseDefault => 'Stattdessen die Standardpause nutzen';

  @override
  String workoutRestFollowingDefault(String rest) {
    return '$rest – wie die Standardpause';
  }

  @override
  String workoutRestOwn(String rest) {
    return '$rest – für diese Übung festgelegt';
  }

  @override
  String workoutSetPositionOf(int number, int planned) {
    return 'Satz $number von $planned';
  }

  @override
  String workoutSetPosition(int number) {
    return 'Satz $number';
  }

  @override
  String get workoutNotificationNoExercises => 'Noch keine Übungen';

  @override
  String workoutNotificationNext(String set) {
    return 'Als Nächstes: $set';
  }

  @override
  String get workoutNotificationResting => 'Pause';

  @override
  String get workoutNotificationLogSet => 'Satz loggen';

  @override
  String get workoutNotificationSkipRest => 'Pause überspringen';

  @override
  String get workoutNotificationTapToOpen => 'Tippen, um Gymfy zu öffnen';

  @override
  String get workoutNotificationChannel => 'Laufendes Training';

  @override
  String get workoutNotificationChannelDescription =>
      'Aktueller Satz und Pause, mit Buttons zum Loggen und Überspringen';

  @override
  String get overloadModeAuto => 'Auto';

  @override
  String get overloadModeFixed => 'Fest';

  @override
  String get overloadModePercent => 'Prozent';

  @override
  String overloadPercentValue(String percent) {
    return '$percent %';
  }

  @override
  String get overloadSuggestTitle => 'Schwerere Gewichte vorschlagen';

  @override
  String get overloadSuggestSubtitle =>
      'Wenn du in jedem Satz das obere Ende deines Wiederholungsbereichs schaffst, startet das nächste Training mit etwas mehr auf der Stange.';

  @override
  String get overloadHowMuchTitle => 'Um wie viel steigern';

  @override
  String get overloadDeloadTitle => 'Deload';

  @override
  String get overloadDeloadCaption =>
      'Nach mehreren Steigerungen in Folge 10 % weniger vorschlagen. Immer nur ein Vorschlag – nichts ändert sich von selbst.';

  @override
  String get overloadDeloadNever => 'Nie';

  @override
  String overloadDeloadInARow(int weeks) {
    return '$weeks in Folge';
  }

  @override
  String overloadAutoCaption(
    String legs,
    String backChest,
    String armsShoulders,
  ) {
    return 'Größere Sprünge bei großen Übungen: $legs bei Beinen, $backChest bei Rücken und Brust, $armsShoulders bei Armen und Schultern. Rumpfübungen werden nie automatisch gesteigert.';
  }

  @override
  String get overloadFixedCaption => 'Bei jeder Übung derselbe Sprung.';

  @override
  String overloadPercentExample(
    String lightStep,
    String light,
    String heavyStep,
    String heavy,
  ) {
    return 'Das sind $lightStep mehr bei $light und $heavyStep mehr bei $heavy.';
  }

  @override
  String get platesTitle => 'Scheibenrechner';

  @override
  String get platesLoadingTitle => 'Was legst du auf?';

  @override
  String get platesTargetWeight => 'Zielgewicht';

  @override
  String get platesHint =>
      'Stell ein Zielgewicht ein, um zu sehen, was auf die Stange kommt.';

  @override
  String get platesBar => 'Stange';

  @override
  String get platesNoBar => 'Keine';

  @override
  String platesBelowBar(String target, String bar) {
    return '$target ist leichter als die Stange selbst ($bar).';
  }

  @override
  String get platesEachSide => 'Pro Seite';

  @override
  String platesExact(String bar, String plates) {
    return 'Stange $bar + Scheiben $plates';
  }

  @override
  String platesClosest(String shortfall, String target) {
    return 'Nächstes machbares Gewicht – $shortfall unter deinem Ziel von $target';
  }

  @override
  String get platesTotal => 'Gesamt';

  @override
  String get platesClear => 'Abräumen';

  @override
  String platesInPlatesNoBar(String total) {
    return '$total in Scheiben, ohne Stange';
  }

  @override
  String platesBarPlusPlates(String bar, String plates) {
    return 'Stange $bar + $plates in Scheiben';
  }

  @override
  String get platesTapToAdd =>
      'Tippen, um auf jede Seite eine Scheibe zu legen';

  @override
  String platesPlateSemantics(String plate, int count) {
    return '$plate, $count auf der Stange';
  }

  @override
  String get platesChangeBarTooltip => 'Stange wechseln';

  @override
  String get platesJustTheBar => 'Nur die Stange';

  @override
  String platesInventoryCaption(String unit) {
    return 'Die Scheiben, die dein Gym hat, in $unit. Der Rechner schlägt nur diese vor.';
  }

  @override
  String get planShareTitle => 'Plan teilen';

  @override
  String get planShareNoSplits =>
      'Du hast noch keine Splits zum Speichern – aber du kannst trotzdem einen von jemand anderem importieren.';

  @override
  String get planShareSend => 'Senden';

  @override
  String get planShareReceive => 'Empfangen';

  @override
  String get planShareImportTitle => 'Plan importieren';

  @override
  String get planShareImportSubtitle =>
      'Öffne eine .gymfy-Datei, die dir jemand geschickt hat';

  @override
  String get planShareSaveDialogTitle => 'Plan speichern';

  @override
  String get planShareSaved =>
      'Plan gespeichert – verschick ihn aus deiner Dateien-App.';

  @override
  String planShareSaveFailed(String error) {
    return 'Der Plan konnte nicht gespeichert werden.\n$error';
  }

  @override
  String planSharePdfFailed(String error) {
    return 'Das PDF konnte nicht erstellt werden.\n$error';
  }

  @override
  String planShareReadFailed(String error) {
    return 'Die Datei konnte nicht gelesen werden.\n$error';
  }

  @override
  String planShareImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pläne importiert',
      one: 'Plan importiert',
      zero: 'Nichts importiert',
    );
    return '$_temp0';
  }

  @override
  String get planShareExplainer =>
      'Eine Plandatei enthält deine Splits, ihre Tage und die Übungen darin. Deine Trainings, Gewichte, Maße und Fotos sind nie dabei.';

  @override
  String get planShareSaveFile => 'Datei speichern';

  @override
  String get planSharePdf => 'PDF';

  @override
  String get planShareErrorNotJson =>
      'Diese Datei ist kein Gymfy-Plan – nicht einmal JSON.';

  @override
  String get planShareErrorNotPlan => 'Diese Datei ist kein Gymfy-Plan.';

  @override
  String planShareErrorWrongFormat(String extension) {
    return 'Diese Datei ist kein Gymfy-Plan. Such nach einer Datei mit der Endung .$extension.';
  }

  @override
  String get planShareErrorTooNew =>
      'Dieser Plan stammt aus einer neueren Gymfy-Version. Aktualisiere die App und versuch es noch einmal.';

  @override
  String get planShareErrorNoSplits => 'Diese Plandatei enthält keinen Split.';

  @override
  String get planShareRenameEmpty => 'Gib ihm einen Namen.';

  @override
  String get planShareRenameTaken =>
      'Du hast schon einen Plan mit diesem Namen.';

  @override
  String get planShareRenameTitle => 'Name schon vergeben';

  @override
  String planShareRenameMessage(String name) {
    return 'Du hast schon einen Plan namens „$name“. Gib dem importierten einen anderen Namen – dein eigener Plan bleibt in jedem Fall erhalten.';
  }

  @override
  String get planShareRenameLabel => 'Planname';

  @override
  String get planShareRenameSkip => 'Diesen überspringen';

  @override
  String get planShareRenameImport => 'Importieren';

  @override
  String planSharePdfPage(int page, int pages) {
    return 'Seite $page von $pages';
  }

  @override
  String get planSharePdfNotScheduled => 'Nicht eingeplant';

  @override
  String get planSharePdfNoExercises => 'Keine Übungen';

  @override
  String get planSharePdfExercise => 'Übung';

  @override
  String get planSharePdfSetsReps => 'Sätze × Wdh.';

  @override
  String get planSharePdfWarmup => 'Aufwärmen';

  @override
  String get planSharePdfWeight => 'Gewicht';

  @override
  String get programsTitle => 'Programme';

  @override
  String programsFacts(int days, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage pro Woche',
      one: '1 Tag pro Woche',
    );
    return '$_temp0 · $level';
  }

  @override
  String get programsLevelBeginner => 'Einsteiger';

  @override
  String get programsLevelIntermediate => 'Fortgeschritten';

  @override
  String get programsIntro =>
      'Jedes Programm wird als neuer Split hinzugefügt, den du wie jeden anderen bearbeiten kannst. Deine eigenen Splits werden nie verändert.';

  @override
  String get programsFallbackTitle => 'Programm';

  @override
  String get programsNotFound => 'Programm nicht gefunden.';

  @override
  String programsOpenFailed(String error) {
    return 'Dieses Programm konnte nicht geöffnet werden.\n$error';
  }

  @override
  String get programsAddToSplits => 'Zu meinen Splits hinzufügen';

  @override
  String programsAdded(String program) {
    return '$program hinzugefügt. Aktivier den Split, um ihm zu folgen.';
  }

  @override
  String programsAddFailed(String error) {
    return 'Das Programm konnte nicht hinzugefügt werden.\n$error';
  }

  @override
  String get programsSupersetNote =>
      'Markierte Übungen werden direkt nacheinander als Supersatz gemacht.';

  @override
  String get programsBeginnerFullBodySummary =>
      'Eine Einheit an Maschinen und mit Kurzhanteln, dreimal pro Woche';

  @override
  String get programsBeginnerFullBodyDescription =>
      'Ein sanfter Einstieg mit Maschinen, Kabelzug und Kurzhanteln – so musst du vor dem Start keine Langhanteltechnik lernen. Dreimal pro Woche dieselbe Ganzkörpereinheit mit Wiederholungsbereichen: Sobald du in jedem Satz das obere Ende schaffst, legst du etwas Gewicht drauf.';

  @override
  String get programsFullBody5x5Summary =>
      'Zwei abwechselnde Langhanteltrainings, fünf Sätze à fünf Wiederholungen';

  @override
  String get programsFullBody5x5Description =>
      'Ein klassisches Programm mit linearer Progression, um an den großen Langhantelübungen eine Kraftbasis aufzubauen. Wechsle an drei Tagen pro Woche zwischen Training A und Training B und leg jedes Mal etwas Gewicht drauf, wenn du alle Wiederholungen schaffst. Einfach, schnell – und es funktioniert monatelang, bevor es stockt.';

  @override
  String get programsUpperLowerSummary =>
      'Vier Tage, jeder Muskel zweimal pro Woche';

  @override
  String get programsUpperLowerDescription =>
      'Zwei Oberkörper- und zwei Unterkörpertage. Jeder beginnt mit einer schweren Grundübung im niedrigen Wiederholungsbereich und geht dann zu Zusatzübungen mit mehr Wiederholungen über; Arme und Schultern laufen als Supersätze, um Zeit zu sparen. Ein guter nächster Schritt, wenn drei Ganzkörpertage nicht mehr reichen.';

  @override
  String get programsPushPullLegsSummary =>
      'Sechs Tage, die klassische Bodybuilding-Rotation';

  @override
  String get programsPushPullLegsDescription =>
      'Drückende Muskeln, ziehende Muskeln und Beine an eigenen Tagen, zweimal pro Woche durchlaufen. Viel Volumen für den Muskelaufbau, Armübungen als Supersätze. Zeitintensiv: Wenn dir sechs Tage zu viel sind, mach jeden Tag nur einmal und nimm dir das Wochenende frei.';

  @override
  String get programsPercentageStrengthSummary =>
      'Vier Tage, Hauptübungen als Prozent deines 1RM geplant';

  @override
  String get programsPercentageStrengthDescription =>
      'Je ein Tag für Kniebeuge, Bankdrücken, Kreuzheben und Schulterdrücken. Die Hauptübung ist als Prozentsatz deines 1RM geplant, und Gymfy berechnet das Gewicht aus deinem getesteten oder geschätzten 1RM – gerundet auf Scheiben, die du auflegen kannst. Passt gut zu einem Trainingsblock auf dem Split, etwa drei Trainingswochen und eine Deload-Woche.';

  @override
  String get programsBodyPartSplitSummary =>
      'Fünf Tage, eine Muskelgruppe pro Tag';

  @override
  String get programsBodyPartSplitDescription =>
      'Brust, Rücken, Schultern, Arme und Beine, jeweils mit einem eigenen Tag. Jeder Muskel wird einmal pro Woche hart und mit vielen Übungen trainiert, der Armtag läuft als zwei Supersätze. Passt zu allen, die lange, fokussierte Einheiten mögen und fünf Tage am Stück trainieren können.';

  @override
  String get programsBlockTitle => 'Trainingsblock';

  @override
  String get programsBlockIntro =>
      'Trainiere eine feste Anzahl Wochen, mach dann eine leichtere Deload-Woche und fang von vorn an. In der Deload-Woche sinken die vorgeschlagenen Gewichte auf die Deload-Last.';

  @override
  String get programsBlockSwitch => 'In Trainingsblöcken trainieren';

  @override
  String get programsBlockWeeksLabel => 'Trainingswochen';

  @override
  String get programsBlockFewerWeeks => 'Weniger Wochen';

  @override
  String get programsBlockMoreWeeks => 'Mehr Wochen';

  @override
  String programsBlockWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen',
      one: '1 Woche',
    );
    return '$_temp0';
  }

  @override
  String get programsBlockThenDeload => 'dann 1 Deload-Woche';

  @override
  String get programsBlockDeloadLoad => 'Deload-Last';

  @override
  String get programsBlockOfWorkingWeights => 'deiner üblichen Arbeitsgewichte';

  @override
  String get programsBlockWeekOneBegan => 'Woche 1 begann';

  @override
  String get programsBlockPickerHelp => 'Woche 1 begann am';

  @override
  String programsBlockStarts(String date) {
    return 'Beginnt am $date';
  }

  @override
  String programsBlockToday(String week) {
    return 'Heute: $week';
  }

  @override
  String get programsBlockDeloadWeek => 'Deload-Woche';

  @override
  String programsBlockWeekOf(int week, int weeks) {
    return 'Woche $week von $weeks';
  }

  @override
  String programsBlockBannerDeload(String percent) {
    return 'Vorgeschlagene Gewichte bei $percent. Nächste Woche beginnt ein neuer Block.';
  }

  @override
  String programsBlockBannerNextWeek(String percent, int cycle) {
    return 'Nächste Woche Deload bei $percent · Block $cycle';
  }

  @override
  String programsBlockBannerInWeeks(String percent, int weeks, int cycle) {
    return 'Deload bei $percent in $weeks Wochen · Block $cycle';
  }

  @override
  String get programsPercentOfMax => '% des 1RM';

  @override
  String get programsPercentNoMax =>
      'Noch kein 1RM. Logg einen Satz oder trag ein getestetes Maximum ein, dann erscheint das Gewicht in deinem Training.';

  @override
  String programsPercentPreview(String weight, String max) {
    return '≈ $weight heute, ausgehend von deinem 1RM von $max.';
  }

  @override
  String get exercisesTitle => 'Übungen';

  @override
  String get exercisesCancelSelection => 'Auswahl aufheben';

  @override
  String exercisesSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get exercisesAddToDayTooltip => 'Zu einem Tag hinzufügen';

  @override
  String exercisesLoadFailed(String error) {
    return 'Die Übungen konnten nicht geladen werden.\n$error';
  }

  @override
  String get exercisesAddExercise => 'Übung hinzufügen';

  @override
  String get exercisesSearchHint => 'Nach Name oder Muskel suchen';

  @override
  String get exercisesClearSearch => 'Suche leeren';

  @override
  String get exercisesGroupChest => 'Brust';

  @override
  String get exercisesGroupBack => 'Rücken';

  @override
  String get exercisesGroupShoulders => 'Schultern';

  @override
  String get exercisesGroupArms => 'Arme';

  @override
  String get exercisesGroupLegs => 'Beine';

  @override
  String get exercisesGroupCore => 'Rumpf';

  @override
  String get exercisesGroupNeck => 'Nacken';

  @override
  String get exercisesNoMatchesTitle => 'Keine Treffer';

  @override
  String get exercisesNoMatchesMessage =>
      'Versuch ein anderes Wort oder entferne einen Muskelfilter.';

  @override
  String get exercisesCustomBadge => 'Eigene';

  @override
  String get exercisesDetailTitle => 'Übung';

  @override
  String exercisesDetailLoadFailed(String error) {
    return 'Diese Übung konnte nicht geladen werden.\n$error';
  }

  @override
  String get exercisesNotFound => 'Übung nicht gefunden.';

  @override
  String exercisesDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get exercisesDeleteWithHistory =>
      'Sie wird aus deiner Bibliothek und aus jeder Auswahl entfernt. Trainings, die du schon damit geloggt hast, behalten ihre Sätze.';

  @override
  String get exercisesDeleteNoHistory =>
      'Sie wurde nie geloggt und wird deshalb komplett entfernt.';

  @override
  String exercisesArchived(String name) {
    return '$name entfernt – vergangene Trainings behalten sie';
  }

  @override
  String exercisesDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get exercisesMusclesWorked => 'Trainierte Muskeln';

  @override
  String get exercisesPreviewSoon => 'Vorschau folgt bald';

  @override
  String get exercisesEditTitle => 'Übung bearbeiten';

  @override
  String get exercisesNewTitle => 'Neue Übung';

  @override
  String get exercisesNameLabel => 'Name';

  @override
  String get exercisesNameHint => 'z. B. Cable Fly';

  @override
  String get exercisesMusclesHelp =>
      'Daraus entsteht die Muskelkarte – wähl also alles, was diese Übung wirklich trainiert.';

  @override
  String get exercisesEquipment => 'Ausrüstung';

  @override
  String get exercisesPlateLoaded => 'Mit Scheiben beladen';

  @override
  String get exercisesPlateLoadedSubtitle =>
      'Logg Sätze, indem du Scheiben antippst, statt ein Gewicht einzutippen. Für Übungen mit Lang- oder SZ-Stange.';

  @override
  String get exercisesImage => 'Bild';

  @override
  String get exercisesImageHelp =>
      'Optional. Ein GIF aus deiner Galerie bewegt sich genau wie die eingebauten.';

  @override
  String get exercisesChooseImage => 'Bild auswählen';

  @override
  String get exercisesReplaceImage => 'Ersetzen';

  @override
  String get exercisesRemoveImage => 'Entfernen';

  @override
  String exercisesAddToDayTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen zu einem Tag hinzufügen',
      one: 'Zu einem Tag hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoDaysTitle => 'Noch keine Trainingstage';

  @override
  String get exercisesNoDaysMessage =>
      'Erstell im Tab „Training“ einen Split mit mindestens einem Tag und komm dann hierher zurück.';

  @override
  String get exercisesNoteLabel => 'Notiz';

  @override
  String get exercisesNoteHint =>
      'Sitzhöhe, Stecker, Griffbreite, welche Maschine…';

  @override
  String get exercisesNoteClear => 'Löschen';

  @override
  String get exercisesNoteEmpty =>
      'Notiz hinzufügen – Sitzhöhe, Stecker, Griff…';

  @override
  String exercisesEquipmentFilterActive(int count) {
    return 'Ausrüstung ($count)';
  }

  @override
  String get exercisesEquipmentFilter => 'Nach Ausrüstung filtern';

  @override
  String get exercisesAllEquipment => 'Jede Ausrüstung';
}
