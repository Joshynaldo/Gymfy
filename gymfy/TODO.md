# Gymfy — Build TODO

Track progress here. Update after each session.

---

## 🔴 Not started

### Phase 2b — Exercise Library Erweiterung 🔥 PRIORITÄT
- [ ] "Add Exercise" Button im Exercises-Tab (FAB oder Header-Button)
- [ ] Screen: Custom Exercise erstellen (Name, Kategorie, Muskelgruppen, optional GIF aus Galerie)
- [ ] Custom Exercises in Drift speichern (`isCustom` flag auf Exercise model)
- [ ] Custom Exercises editieren + löschen (Swipe-to-delete oder Long-press Menü)
- [ ] Mehrere Übungen gleichzeitig zu einem Split-Tag hinzufügen (Multi-Select im Exercise-Tab, dann "Add to Day" Button)
- [ ] Übungen direkt aus dem Exercises-Tab zu einem Workout-Tag hinzufügen (Ziel-Tag auswählbar per Bottom Sheet)
- [ ] Seed Data erweitern — mindestens 60–80 Übungen total
  - [ ] Chest: Cable Fly, Incline DB Press, Dips, Pec Deck
  - [ ] Back: Cable Row, T-Bar Row, Lat Pullover, Face Pull
  - [ ] Legs: Leg Press, Romanian Deadlift, Leg Curl, Leg Extension, Hip Thrust, Bulgarian Split Squat
  - [ ] Shoulders: Lateral Raise, Front Raise, Arnold Press, Cable Lateral Raise, Rear Delt Fly
  - [ ] Arms: Preacher Curl, Hammer Curl, Cable Curl, Skull Crusher, Cable Tricep Pushdown, Overhead Tricep Extension
  - [ ] Core: Plank, Hanging Leg Raise, Cable Crunch, Ab Wheel Rollout, Russian Twist
  - [ ] Compound: Barbell Row, Power Clean, Push Press, Farmer's Walk
- [ ] Filter by Category UX verbessern (Chips, Multi-Select)
- [ ] Suche verbessern (auch nach Muskelgruppe suchen)

### Phase 3b — Split Erweiterungen 🔥 PRIORITÄT
- [ ] Rep Range pro Übung im Split einstellen (z.B. 3×8–12 statt fixer Zahl)
- [ ] Split-Tage zu Wochentagen zuweisen (Mo–So, auch Rest Day markierbar)
- [ ] Rest Day Logik: wenn kein Split-Tag für heute → Rest Day anzeigen

### Phase 14 — Main Tab (Home) 🔥 PRIORITÄT
- [ ] Home Tab erstellen (erster Tab in der Bottom Nav)
- [ ] Zeigt ob heute Rest Day oder Trainingstag ist (basierend auf Split-Wochentag-Zuweisung)
- [ ] Zeigt den heutigen Workout-Tag: Split-Name, Übungsliste, Rep Ranges
- [ ] Zeigt was als nächstes kommt (morgiger oder übernächster Trainingstag)
- [ ] Quick-Start Button: startet direkt die heutige Session
- [ ] Letzte Workout-Session kurz zusammengefasst (Datum, Volumen, Muscle Map Miniatur)

### Phase 15 — Progressive Overload 🔥 PRIORITÄT
- [ ] Progressive Overload Einstellungen pro Übung (aktivierbar im Split-Builder)
- [ ] Wöchentliche Gewichtssteigerung konfigurierbar (z.B. +2.5 kg/Woche)
- [ ] Muskelgruppen-basierte Standardwerte für Steigerungsrate:
  - Beine (Quad, Glute, Hamstring): +2.5–5 kg/Woche
  - Rücken (Lat, Trap, Lower Back): +2.5 kg/Woche
  - Brust: +1.25–2.5 kg/Woche
  - Schultern: +1.25 kg/Woche
  - Arme (Bicep, Tricep): +0.5–1.25 kg/Woche
  - Core: kein Auto-Overload (nur Wiederholungen steigern)
- [ ] App schlägt beim nächsten Workout automatisch das neue Gewicht vor
- [ ] Overload-Vorschlag kann manuell überschrieben werden (falls Satz nicht sauber)
- [ ] Deload-Option: nach N Wochen Steigerung automatisch 10% reduzieren

### Phase 16 — Plate Calculator 🔥 PRIORITÄT
- [ ] Plate Calculator Screen (erreichbar aus 1RM-Rechner und aktiver Workout-Session)
- [ ] Input: Zielgewicht + Stange (Standard 20 kg / leichte 15 kg / EZ-Bar 10 kg)
- [ ] Output: Welche Scheiben auf welche Seite (visuell als Stangen-Diagram)
- [ ] Verfügbare Scheiben konfigurierbar in Settings (welche Gewichte hat der User)
- [ ] Unterstützt kg und lbs (folgt der globalen Einheit-Einstellung)

### Phase 17 — UI Overhaul 🔥 PRIORITÄT
- [ ] Theme-System erweitern: mehrere Themes wählbar (nicht nur Akzentfarbe)
  - Dark Default (aktuell)
  - Dark High Contrast
  - AMOLED Black
  - Light (optional, later)
- [ ] Theme-Auswahl in Settings mit Live-Preview
- [ ] Muscle Map: Contrast Mode hinzufügen
  - Standard Mode: Heatmap (ein Farbton, Intensität variiert)
  - Contrast Mode: jede Muskelgruppe hat eine eigene Farbe (wie ein anatomisches Diagramm)
  - Toggle zwischen Modi per Icon-Button auf der Muscle Map
- [ ] Scroll Wheel für alle Gewichts-Inputs (Gewichte eintragen, Körpergewicht, Größe)
  - CupertinoPicker-Style Drum Wheel
  - kg: 0–300 in 0.25-Schritten; lbs: 0–660 in 0.5-Schritten
  - Körpergröße: 100–250 cm oder 3'0"–8'2"
- [ ] Scroll Wheel auch im aktiven Workout für Set-Gewichte (schneller als Tastatur)

### Phase 7b — Calories Tracker (bereinigt)
- [ ] Habit Tracker komplett entfernen (Screen, DB-Tabelle `HabitEntry`, alle Provider + Routes)
- [ ] Streak-Zähler auf Workout-Streak umbauen (Tage in Folge trainiert — basierend auf geloggten Sessions)
- [ ] Kalorien-Log bleibt bestehen (Mahlzeiten, Makros, Tagesziel)
- [ ] Wochenübersicht: nur Kalorien-Chart (Habit-Chart entfernen)

### Phase 11 — Android Home Screen Widgets
- [x] Research Glance API — `glance-appwidget:1.2.0-rc01`, `home_widget: ^0.9.3`
- [ ] "Today's Workout" Widget — zeigt heutigen Split-Tag + Übungen (nutzt Wochentag-Zuweisung aus Phase 3b)
- [ ] "Weekly Volume" Widget — Gesamtvolumen diese Woche
- [ ] "Streak" Widget — aktueller Workout-Streak (nach Phase 7b Umbau)
- [ ] Widget-Refresh nach Workout-Abschluss
- [ ] Test auf physischem Gerät

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
