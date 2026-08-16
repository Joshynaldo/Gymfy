# Gymfy — Build TODO

Track progress here. Update after each session.

---

## 🔴 Not started

### Priority
- [x] Themes: Tokyo Night, Dracula, Catppuccin Mocha, Gruvbox — jeweils mit den echten veröffentlichten Farben und einer passenden Akzentfarbe, die *angeboten* (nicht erzwungen) wird
- [x] Homescreen-Widgets komplett entfernt — Kotlin/Glance, XML, Manifest-Receiver, `home_widget`, Compose-Plugin. Cold Build wieder bei ~11 s statt ~94 s
- [x] Stale/ungenutztes entfernt — `placeholder_view.dart` (nichts importierte es), `docs/glance-widgets-research.md` (beschreibt ein entferntes Feature), `assets/musclemap/__MACOSX` + `documentation/` (430 KB Zip-Müll und Vendor-HTML)
- [ ] **Offen: die Body-SVGs.** `body_front.svg` / `body_back.svg` sind *nicht* von mir gezeichnet, sondern per `tool/build_muscle_map.dart` aus dem lizenzierten Pack in `assets/musclemap/source/` erzeugt. Löschen = Muscle-Map-Tab ist tot. Entweder Feature ganz raus oder neues Pack liefern
- [x] Recap-Charts auf dem Home-Tab — ein Woche/Monat/Jahr-Umschalter für drei Karten: **Volumen** (Balken je Bucket), **Workouts** (Häufigkeit + Anzahl PRs) und **Was trainiert** (Volumen je Muskel, in den Farben der Muscle Map)
  - Buckets: Woche = 7 Tage, Monat = 5 × 7 Tage, Jahr = 12 Kalendermonate
  - PRs werden über die **komplette** Historie berechnet und danach aufs Fenster gefiltert — ob 100 kg heute ein Rekord sind, hängt von jedem Satz davor ab
  - "Was trainiert" zählt **Sätze, kein Volumen**: ein Satz Kniebeugen bewegt das Fünffache eines Satzes Curls, nach Kilogramm sortiert stünden Beine immer oben. Sätze messen Aufmerksamkeit statt Last
  - `WeeklyBarChart` → `shared/widgets/bar_chart.dart` (`SimpleBarChart`, nimmt Labels statt Daten), damit Kalorien- und Recap-Charts nicht auseinanderlaufen



### Phase 17 — UI Overhaul 🔥 PRIORITÄT
- [x] Theme-System — `AppTheme` Enum mit eigener `AppPalette` je Theme: Dark Default, AMOLED Black, High Contrast. Theme und Akzentfarbe sind unabhängig, jede Kombination funktioniert
- [x] Theme-Auswahl in Settings mit Preview-Swatch je Option; die Auswahl greift sofort app-weit — der Screen färbt sich unter dem Finger um
- [ ] ~~Light Theme~~ — bewusst nicht gebaut: ein eigenes Design, keine invertierte Kopie. Lieber gar nicht als schlecht
- [x] Muscle Map Contrast Mode — Palette-Icon oben rechts auf der Map schaltet um. Heatmap = ein Farbton (Akzent), Contrast = eigene Farbe pro Muskel, **weiterhin von der Intensität gedimmt**: gleiche Daten, nur unterscheidbar. Legende zeigt nur trainierte Muskeln
- [x] Scroll Wheel für alle Gewichts-Inputs — `shared/widgets/weight_wheel.dart`. **Zwei Räder** (ganze Zahl + Nachkomma) statt eines 1200er-Rads: dieselben Werte, aber 82.5 sind zwei Wischer statt vierhundert Einträge scrollen
  - kg: 0–300, Schritte .0/.25/.5/.75 — lbs: 0–660, Schritte .0/.5
  - Überall: Satz loggen, Körpergewicht (Onboarding + Messungen), getestetes 1RM, 1RM-Rechner, Plate Calculator
- [x] Scroll Wheel im aktiven Workout für Set-Gewichte — ersetzt die Tastatur, Umschalter zum Scheiben-Stapler bleibt
- [ ] Körpergröße (100–250 cm) — **nicht gebaut**: es gibt bislang gar kein Größen-Feld in der App. Das wäre ein neuer Messwert inkl. Schema-Änderung, keine reine Input-Umstellung


### Phase 11 — Android Home Screen Widgets
- [x] Research Glance API — `glance-appwidget:1.2.0-rc01`, `home_widget: ^0.9.3`
- [x] "Today's Workout" Widget — Split-Tag + Übungsliste, nutzt die Wochentag-Zuweisung aus Phase 3b
- [x] "Weekly Volume" Widget — Gesamtvolumen + Anzahl Workouts der letzten 7 Tage
- [x] "Streak" Widget — Workout-Streak aus Phase 7b
- [x] Widget-Refresh nach Workout-Abschluss **und** bei jedem App-Start (sonst wäre "heute" nach Mitternacht falsch)
- [x] Kotlin/Glance unter `android/app/src/main/kotlin/…/GymfyWidgets.kt`, Sizing-XML unter `res/xml/`, Receiver im Manifest (im gemergten Manifest verifiziert)
- [x] Widgets lesen **nie** die Datenbank — Dart schiebt fertige Strings über `home_widget`. Schema-Wissen bleibt in einer Sprache, dafür zeigen die Widgets den *zuletzt gepushten* Stand
- [ ] **Test auf physischem Gerät — offen.** Widgets lassen sich nicht per `flutter test` prüfen; das Hinzufügen auf den Homescreen und das Rendern muss auf dem Telefon passieren

### Phase 12 — WearOS Companion App
- [ ] WearOS Modul einrichten
- [ ] Active Workout Screen für die Uhr (Übung, Set-Zähler, Rest Timer)
- [ ] Sync Phone ↔ Watch (Wearable Data Layer)
- [ ] Quick Log per Scroll Wheel auf der Uhr
- [ ] Rest Timer mit haptischem Feedback
- [ ] Schritte / Herzfrequenz Glance (falls Health APIs verfügbar)

### Phase 13 — Polish & Release
- [x] App Icon + Splash Screen
- [x] Onboarding Flow — Name, Körpergewicht, Akzentfarbe (persistent)
- [x] Settings Screen — Akzentfarbe, Name, Rest Timer
- [x] Einheiten kg/lbs — Storage bleibt immer kg
- [x] Rest Timer mit Notification — Schema v10, `flutter_local_notifications`
- [ ] Daten-Export (CSV aller geloggten Workouts)
- [ ] Play Store Listing — Screenshots, Beschreibung, Datenschutzerklärung
- [ ] Crash Reporting (Firebase Crashlytics oder Sentry)

---

## 🟡 In progress

---

## 🟢 Done

### Phase 7b — Calories Tracker (bereinigt) ✅
- [x] Habit Tracker komplett entfernt — Screen, Repository, Model, Route, More-Eintrag. Schema v17 droppt `habits` + `habit_entries`. **Vorhandene Habit-Daten sind damit gelöscht** — es gibt nichts mehr, was sie liest
- [x] Workout-Streak statt Habit-Streak — `streakEndingAt` nach `shared/utils/dates.dart` verschoben, zählt jetzt abgeschlossene Sessions. Tage, nicht Sessions: zweimal an einem Tag ist ein Tag
- [x] Streak-Badge in der Home-AppBar, bei 0 unsichtbar
- [x] Kalorien-Log unverändert (Mahlzeiten, Makros, Tagesziel)
- [x] Wochenübersicht: nur noch das Kalorien-Chart

### Phase 15 — Progressive Overload ✅
- [x] **Komplett app-weit statt pro Übung** — ein `OverloadSettingsPanel`, identisch im Onboarding (Seite 3) und in Settings. Der ↗-Dialog im Day-Builder ist weg. Schema v19 + v20 entfernen alle vier Spalten von `WorkoutExercises`; die Konfiguration liegt jetzt in der Settings-Tabelle und brauchte dafür keine eigene Migration
- [x] Drei Modi: **Auto** (Muskel-Standardwerte), **Fixed** (1.25/2.5/5/10 kg), **Percent** (1/2.5/5/7.5 %)
- [x] Deload nur in Settings, nicht im Onboarding — eine Frage über Monat drei, gestellt vor Workout eins
- [x] **Doppelte Progression** statt Kalender: das Gewicht steigt, wenn *alle* geplanten Sätze das obere Ende der Rep-Range erreicht haben. Eine schlechte Woche löst einfach keine Steigerung aus — nichts staut sich auf
- [x] Vorschlag basiert auf dem **tatsächlich geloggten** Top-Gewicht, nicht auf einem gespeicherten Plan-Ziel. Kein Progressions-Status wird gespeichert; alles wird aus den Sätzen abgeleitet
- [x] Muskelgruppen-Standardwerte: Beine 5 kg, Rücken/Brust 2.5 kg, Schultern/Arme 1.25 kg, Core kein Auto-Overload. Bei mehreren Muskeln gilt der **kleinste** Wert
- [x] Steigerung konfigurierbar — **Fixed** (Auto / 1.25 / 2.5 / 5 / 10 kg) oder **Percent** (1 / 2.5 / 5 / 7.5 %). Schema v18, `overloadPercent`. Prozent skaliert mit dem Gewicht: 2.5 % sind 2.5 kg auf 100 kg Bank und 1 kg auf 40 kg Curls — genau das, was die Muskel-Standardwerte nur angenähert haben
  - Prozent hat Vorrang vor dem festen Schritt; beim Umschalten wird der jeweils andere Wert explizit auf null gesetzt, damit kein alter Wert unsichtbar liegen bleibt
  - Prozent von einer Körpergewichtsübung (0 kg) wäre 0 → fällt auf den festen Schritt zurück, sonst gäbe es nie eine Steigerung
- [x] Vorschlag wird auf ein **ladbares** Gewicht gerundet — nach oben, damit aus einer Steigerung nicht versehentlich keine wird
- [x] Vorschlag ist immer nur ein Vorschlag: vorausgefüllt, mit einer Zeile Begründung, jederzeit überschreibbar
- [x] Deload — nach N Steigerungen in Folge werden 10% weniger *vorgeschlagen*, nie automatisch gesetzt. Der Zähler wird aus der Historie abgeleitet, ein manueller Deload setzt ihn von selbst zurück

### Phase 16 — Plate Calculator ✅
- [x] Plate Calculator Screen — erreichbar über More, aus dem 1RM-Rechner ("What plates is that?") und aus der aktiven Session (Icon in der AppBar). Wird *gepusht*, nicht geroutet, damit man zurück im Workout landet
- [x] Input: Zielgewicht + Stange (kg: 20/15/10, lbs: 45/35/25)
- [x] Output: Scheiben pro Seite als Stangen-Diagramm, plus "20 kg × 2"-Chips
- [x] Verfügbare Scheiben in Settings konfigurierbar — pro Einheit eine eigene Liste
- [x] kg und lbs — **nichts wird umgerechnet**. Scheiben sind physische Objekte; eine 45-lb-Scheibe ist keine 20,41-kg-Scheibe. Begründung im Header von `plate_math.dart`
- [x] Scheiben in echten Wettkampf-Farben (25 rot, 20 blau, 15 gelb, 10 grün, 5 weiß) — die einzige Stelle, an der eine feste Farbe richtig ist
- [x] `isPlateLoaded` pro Übung (Schema v15) — 23 Langhantel-Übungen markiert. Plate-Maschinen (Leg Press, Hack Squat) bewusst nicht: deren Schlitten hat ein unbekanntes Eigengewicht
- [x] Plate Stacker im Log-Dialog — bei Langhantel-Übungen tippt man Scheiben statt Zahlen, das Ergebnis wird als Gewicht des Satzes gespeichert. Tippen bleibt per Umschalter verfügbar

### Phase 14 — Main Tab (Home) ✅
- [x] Home Tab — erster Tab, `initialLocation` ist jetzt `/home`
- [x] Rest Day vs. Trainingstag — `TodayCard`, vier Zustände (kein aktiver Split / Rest Day / Workout / Workout läuft schon)
- [x] Heutiger Workout-Tag mit Split-Name, Übungsliste und Rep Ranges
- [x] `NextUpCard` — "Tomorrow" / Wochentag / "Next Monday". Rendert nichts, wenn nichts geplant ist
- [x] Quick-Start Button — startet die Session direkt. Läuft schon eine, wird "Resume" angeboten statt einer zweiten
- [x] `LastWorkoutCard` — Name, Datum, Satzanzahl, Volumen, Muscle-Map-Miniatur. Tippen öffnet die Zusammenfassung

### Phase 3b — Split Erweiterungen ✅
- [x] Rep Range pro Übung — Schema v14, `defaultRepsMax` nullable. Null = feste Zahl, damit "3 × 10" nicht zu "3 × 10–10" wird
- [x] Split-Tage zu Wochentagen zuweisen — Schema v13, eigene Tabelle `WorkoutDaySchedules`. Ein Tag kann auf mehreren Wochentagen liegen; ein Wochentag gehört immer nur einem Tag
- [x] Aktiver Split (`Splits.isActive`) — nur der aktive Split bestimmt, was heute ansteht. Der erste erstellte Split wird automatisch aktiv
- [x] Rest Day Logik — kein Tag für heute → "Rest day". Rest ist die *Abwesenheit* eines Eintrags, kein gespeichertes Flag

### Phase 2b — Exercise Library Erweiterung ✅
- [x] "Add Exercise" FAB im Exercises-Tab
- [x] Custom Exercises erstellen + bearbeiten — `exercise_form_screen.dart`, ein Screen für beides
- [x] Schema v11 (`isCustom` + `isArchived`). Custom-IDs haben den Prefix `custom_`, damit der Seed-Upsert sie nie überschreibt
- [x] Löschen archiviert, wenn die Übung schon geloggt/eingeplant ist — alte Workouts behalten ihre Sätze
- [x] Multi-Select (Long-Press) + "Add to Day" Bottom Sheet, nach Split gruppiert. Bereits vorhandene Übungen werden übersprungen
- [x] Seed Data: **78 Übungen** (vorher 27) — Chest 10, Back 14, Shoulders 10, Arms 13, Legs 18, Core 9, Full Body 4. Regeln in `test/exercise_seed_data_test.dart`
- [x] Push/Pull/Legs/Core-Kategorie entfernt — Schema v12. Übungen werden nur über `muscleIds` beschrieben
- [x] Muskelgruppen-Filter mit Multi-Select (ODER-verknüpft) und Suche nach Muskelgruppe

### Phase 10 — Strength Rank ✅
- [x] Strength Standard Tabellen (Beginner → Elite)
- [x] Rang basiert auf Körpergewicht-Ratio
- [x] Körpergewicht-Prompt + Geschlecht (neues Settings-Table)
- [x] Strength Rank Screen mit Fortschrittsbalken
- [x] Rang-Badge auf Exercise Detail Screen

### Phase 9 — 1RM Calculator ✅
- [x] 1RM Calculator Screen (Epley, Brzycki, Lander)
- [x] Geschätztes 1RM Badge in Progress Charts
- [x] Manuelle 1RM Eingabe pro Übung

### Phase 8 — Body Measurements & Progress Photos ✅
- [x] BodyMeasurement Model + Input Screen
- [x] Timeline Charts pro Körperteil
- [x] Progress Photos + Side-by-Side Vergleich

### Phase 7 — Calories & Habit Tracker ✅ (Habit wird in Phase 7b entfernt)
- [x] CalorieEntry + HabitEntry Models
- [x] Kalorien-Log, Makro-Aufschlüsselung
- [x] Habit Tracker Screen + Streak
- [x] Wochenübersicht Chart

### Phase 6 — Progress ✅
- [x] Exercise Progress Chart + PR Anzeige

### Phase 5 — Muscle Map ✅
- [x] SVG Body Map (vorne + hinten), flutter_svg
- [x] Volumen → Intensitätskarte
- [x] Workout + Wochenansicht

### Phase 4 — Workout Logging ✅
- [x] WorkoutSession + LoggedSet, Active Workout Screen
- [x] Abschluss-Zusammenfassung, Drift-Persistierung

### Phase 3 — Workout Builder ✅
- [x] Split, WorkoutDay, WorkoutExercise Models
- [x] Split + Day Builder Screens

### Phase 2 — Exercise Library ✅
- [x] Exercise Model + Seed Data (~25 Übungen)
- [x] List Screen + Detail Screen mit GIF

### Phase 1 — Project Foundation ✅
- [x] Flutter Projekt, Dependencies, Theme, Router, Drift Shell
