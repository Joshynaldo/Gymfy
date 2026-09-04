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
- [x] **Workout-Tab neu gebaut** — der Tab zeigt jetzt direkt den **aktiven** Split mit seinen Tagen, statt erst eine Split-Liste. Zwei Taps weniger zum Programm, und für die meisten hatte diese Liste ohnehin genau einen Eintrag
  - Split-Wechsler (`swap_horiz`) in der AppBar: alle Splits mit Markierung des aktiven, plus "New split" und "Manage splits". Auch bei nur einem Split sichtbar — sonst käme man nie zu einem zweiten
  - Split-Verwaltung nach `/workout/splits` gezogen (`split_list_screen.dart`); `/workout/split/:id` bleibt für Splits, denen man gerade *nicht* folgt
  - Tages-Karten in `workout/widgets/split_day_list.dart` ausgelagert — Workout-Tab und Split-Übersicht rendern dieselben Daten, also dasselbe Widget
  - Zwei eigene Leerzustände: gar kein Split ("New split") vs. Splits ohne aktiven ("Choose a split"). Einen zu raten würde einen still auf ein Programm setzen, das man nicht gewählt hat
  - Übungs-Picker im Day Builder ist **Mehrfachauswahl**: Suche nach Name *oder* Muskel, Muskel-Filterchips, Auswahl übersteht das Umfiltern, "Add 3" fügt alles in einem Rutsch hinzu. Bereits geplante werden übersprungen, die Snackbar sagt was wirklich passiert ist
  - Filterlogik in `shared/utils/exercise_search.dart` und `shared/widgets/muscle_filter_bar.dart` — Exercises-Tab und Picker filtern garantiert gleich; "die Bibliothek findet es, der Picker nicht" kann nicht mehr passieren
- [x] 🔥 **Warm-up sets** — Ramp-up-Sätze werden markiert und bleiben aus den Zahlen raus, die sie nicht sehen sollen. Schema v21: `LoggedSets.isWarmup` + `WorkoutExercises.warmupSets`, beide additiv — jeder bereits geloggte Satz bleibt ein Arbeitssatz
  - **Raus aus:** geschätztem 1RM, PRs, Progress-Chart und dem Progressive-Overload-Vorschlag. Ein 60-kg-Aufwärmer ist kein Datenpunkt auf der Bankdrücken-Kurve, und ein leichter Aufwärmsatz darf den Vorschlag nicht nach unten ziehen
  - **Drin in:** Session-Volumen, Muscle Map, Recap-Charts und der Workout-Zusammenfassung — ein Aufwärmsatz ist Arbeit, die du tatsächlich gemacht hast. Die Trennung steht an *einer* Stelle: `isWorkingSet` in `session_repository.dart`
  - Beide Phasen zählen **unabhängig** ab 1 — Arbeitssätze lesen 1, 2, 3, egal wie lang das Ramp-up war. "Satz 5 von 3" wäre eine seltsame Sache auf der Karte
  - **Prefill folgt der Phase, nicht der Zeile davor**: nach drei Aufwärmsätzen wird für den ersten Arbeitssatz nicht 60 kg vorgeschlagen. Der Overload-Vorschlag gilt nur für Arbeitssätze
  - Zwei Buttons pro Übung: "Warm-up 2 of 3" (zählt gegen den geplanten Wert herunter, danach nur noch "Warm-up") und "Add set"
  - Aufwärmzeilen sind **gedimmt + kleines "W"**; ein Icon je Zeile taggt um. Das ist die häufige Reparatur: die Stange fühlt sich leicht an und der "Aufwärmsatz" war doch der erste Arbeitssatz. Umtaggen nummeriert beide Phasen neu, Löschen schließt die Lücke
  - Geplante Aufwärmsätze pro Übung im Day Builder (Chips 0–5). **Keine vorab angelegten Zeilen** — ein 0-kg-Platzhalter, den du nie gemacht hast, würde trotzdem im Volumen und auf der Muscle Map landen
- [x] **Fatigue map** — dieselbe Körperkarte, zweite Lesart: nicht was du trainiert *hast*, sondern was noch auf dir liegt. Umschalter **Volume / Fatigue** oben auf dem Muscles-Tab, `MuscleMapView` bleibt unverändert (nimmt schon ein fertiges `AsyncValue`)
  - **Exponentieller Zerfall, Halbwertszeit 48 h** — eine Session liest sich am nächsten Morgen fast voll, nach zwei Tagen halb, nach vier Tagen ein Viertel. Nach einer Woche ist sie Rauschen. Abfrage-Fenster 14 Tage: sieben Halbwertszeiten, unter 1 % — weiter zurückzulesen kostet Zeit und ändert nichts
  - **Sätze, kein Volumen** — nach Kilogramm wären die Beine dauerhaft am Anschlag und die Karte würde jeden Tag dasselbe sagen. Gleiche Begründung wie bei den Recap-Charts
  - **Absolut, nicht relativ** — anders als die Volumen-Heatmap wird *nicht* auf den größten Wert normiert. Nach einer Ruhewoche ist alles dunkel; normiert würde stattdessen der am wenigsten erholte Muskel hell leuchten und behaupten, er sei durch. Sättigung bei 12 zerfallenen Sätzen, darüber wird geklemmt
  - Aufwärmsätze zählen nicht — sich ans Arbeitsgewicht heranzutasten ist das Gegenteil von Arbeit ansammeln. Dank `isWorkingSet` eine Zeile
  - Laufende Sessions zählen sofort mit: du stehst im Studio und die Brust ist schon müde. Anders als beim Overload-Vorschlag gibt es keinen Grund, aufs Beenden zu warten
  - Eigener Leerzustand: "Everything is recovered" statt "No training logged" — du hast vielleicht hart trainiert und bist einfach wieder bereit
- [x] 🟩 **Activity heatmap** — GitHub-Jahresansicht unten auf dem Home-Tab, eingefärbt nach trainierter Zeit. 53 Wochen als Spalten, Wochentage als Zeilen, öffnet auf heute
  - **Feste Schwellen in Minuten** (1–29 / 30–59 / 60–89 / 90+), nicht auf den eigenen besten Tag skaliert. Gleiche Begründung wie bei der Fatigue Map: in einem ruhigen Jahr würde eine 20-Minuten-Session sonst so dunkel wie eine Zwei-Stunden-Einheit — und damit nichts mehr aussagen
  - Die unterste Stufe ist schon mit einer kurzen Einheit erreichbar. "Ich war da" ist die Unterscheidung, die das Raster am häufigsten treffen soll
  - Datiert nach `completedAt` wie Streak und Recap: eine Session über Mitternacht zählt einmal, am Tag des Abschlusses. Zwei Sessions an einem Tag addieren sich
  - **Eine abgeschlossene Session zählt immer**, egal wie kurz — auf mindestens eine Minute aufgerundet statt verworfen. `inMinutes` schneidet ab, ein in 40 Sekunden durchgezogenes Workout kam als 0 raus und verschwand komplett. Genau so sieht das erste Workout nach einer Neuinstallation aus, wodurch das ganze Feature kaputt wirkte. "Abgeschlossen heißt trainiert" ist außerdem die Regel, die der Streak schon benutzt. Nur negative Längen fallen raus (Uhr verstellt)
  - Laufende Workouts erscheinen nicht: sie haben noch keine Länge, und ein Kästchen, das sich unter dir weiter einfärbt, wäre unruhig
  - Tippen auf ein Kästchen nennt Tag und Dauer ("Today — 1 h 15 min trained" / "rest day"), nochmal tippen hebt die Auswahl auf. Ein Jahr Quadrate ohne Rückfragemöglichkeit ist ein Bild, kein Protokoll
  - **`CustomPainter` statt 371 Widgets** — ein Render-Objekt und ein Paint-Pass statt mehrerer hundert Layouts pro Scroll-Frame. Das ist die Stelle, an der es auf alter Android-Hardware sonst hakt
- [x] 📤 **Share a plan** — More → "Share a plan". Splits ankreuzen, dann **Send file** (`.gymfy`) oder **PDF**, plus **Import a plan**. Neuer Feature-Ordner `features/plan_share/`
  - **Nur Pläne.** Splits, Tage, Wochentags-Zuordnung, Übungen mit Sätzen/Reps/Aufwärmsätzen. Sessions, geloggte Sätze, Messungen und Fotos werden nicht gefiltert, sondern **gar nicht erst gelesen** — es gibt keinen Pfad, über den sie in die Datei kommen könnten. Ein Test prüft, dass weder Körpergewicht noch das beste Bankdrücken im Export auftauchen
  - Format: lesbares JSON mit `format`/`version`-Tag. Eine Datei aus einer neueren Version wird **abgelehnt statt geraten** — ein halb importierter Plan ist schlimmer als keiner
  - **Namenskollision → der Nutzer benennt um.** Dialog mit vorgeschlagenem freien Namen, Textfeld, und "Skip this one". Nie überschreiben, nie still "(2)" anhängen: dein Programm und seins heißen gleich, sind aber nicht dasselbe. Bei zwei gleichnamigen Splits in einer Datei wird zweimal gefragt, die zweite Frage kennt die erste Antwort
  - Import ist immer ein Insert. Der importierte Split wird **nicht aktiv** — er kann "heute" nicht übernehmen
  - Custom-Übungen des Absenders werden aus Name + Muskeln neu angelegt, sonst würden beim Import genau die Übungen verschwinden, die das Teilen lohnenswert machen. Eine bereits vorhandene Übung wird **nie** verändert — sein "Cable Fly" benennt deins nicht um
  - Übungen ohne `exerciseId` werden verworfen statt als namenlose Karteileiche in der Bibliothek zu landen
  - PDF: schwarz auf weiß, A4, mehrseitig, mit leerer **Weight**-Spalte zum Eintragen mit Bleistift. Gedankenstriche werden zu Bindestrichen — die eingebaute Helvetica kann kein Unicode, "8–12" wäre auf Papier "8 12"
  - Neue Pakete: `file_picker` (**≥ 12**), `pdf`, `printing` → **`flutter pub get` nötig**
  - **`share_plus` wieder rausgeflogen — Toolchain-Konflikt, nicht Geschmackssache.** AGP 9 / Gradle 9.1 / Kotlin 2.3.20 in diesem Projekt: `file_picker` 11 nagelt KGP 1.8.22 fest, das Gradle 9 nicht mehr ausführt → sein Kotlin wird nie kompiliert und `FilePickerPlugin` fehlt beim Java-Link. `file_picker` 12 baut sauber, braucht aber `win32 ^6` — jedes `share_plus` unter 13 nagelt `win32 ^5` fest, und `share_plus` 13.3 kompiliert sein eigenes Kotlin unter AGP 9 nicht (`Unresolved reference 'SharePlusPendingIntent'`). Beide zusammen gehen also nicht
  - Deshalb **"Save file" statt Share-Sheet**: `FilePicker.saveFile` deckt den Export mit ab, der Nutzer wählt den Ort und verschickt aus der Dateien-App weiter. PDFs gehen weiterhin über das System-Sheet von `printing`
- [ ]  **Filter by equipment** — narrow the library to what you actually own; the options adapt to what you've picked, so every combination on screen has results behind it
- [ ]  **Timed exercises** — planks, hangs, wall sits and loaded carries or cardio exercises are logged by time, not reps, with a work timer that counts the set itself (separate from the rest timer) and logs the time you actually held. They can carry weight too
- [x] **Foto-Vergleich als Überlagerung** statt nebeneinander — beide Fotos im selben Rahmen, ein Slider blendet vom alten zum neuen. Zwei kleine Bilder nebeneinander sind das falsche Werkzeug: echte Veränderung über acht Wochen sind ein paar Zentimeter, und die sieht man nur, wenn die Umrisse übereinander liegen
  - Start bei 50 % — sonst sähe es beim Öffnen aus, als würde ein Foto fehlen
  - Beide `contain` im selben Rahmen, damit die Körper gleich skaliert und auf denselben Punkt zentriert gezeichnet werden. Jeder andere Fit würde ein Foto gegen das andere verschieben und einen Unterschied erfinden, den es nicht gibt
  - Die beiden Deckkräfte ergeben immer zusammen 1 — sonst scheint mitten im Überblenden der Hintergrund durch und wäscht beide Körper aus
  - Deckkraft über `Image.opacity` statt eines `Opacity`-Widgets: letzteres erzwingt ein `saveLayer`, also einen Offscreen-Puffer in Fotogröße, jeden Frame den der Slider sich bewegt. Auf älteren Geräten der Unterschied zwischen flüssig und ruckelig
  - Datum + Notiz unter den Slider-Enden, beide antippbar zum Wechseln









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

### Phase 18 — Release 🔥
- [x] **Weibliche Muskelkarte** — `body_front_female.svg` / `body_back_female.svg`, erzeugt aus `woman-front`/`woman-back` desselben lizenzierten Packs. Die Auswahl kommt aus der Onboarding-Frage, umstellbar unter **Settings → You → Body diagram**
  - **Kein umgeformtes Männermodell.** Das Pack zeichnet andere Gruppen unter anderen Ids: vorne zusätzlich `breasts`/`subclavius`/`iliopsoas_hip_flexors`, hinten `gluteus_medius` statt `gluteus_medius2`, `hamstrings2` statt `hamstrings`, `trapezius` statt `trapezius_lower`. Also eigene Mapping-Tabelle je Figur, kein Dateinamen-Tausch
  - **`neck` fehlt auf der weiblichen Vorderansicht** — das Pack hat dort keinen `sternocleidomastoid`. Bleibt bewusst dunkel, statt auf einen Nachbarmuskel gefälscht zu werden. Ein Test hält genau diese eine Lücke fest; kommt ein neues Pack, muss die Liste schrumpfen
  - `breasts`/`subclavius` sind Anatomie, aber keine trainierten Muskeln → auf die Silhouette abgeflacht. Ohne das hätten sie den bunten Pack-Gradienten behalten und dauerhaft geleuchtet, als wären sie gerade trainiert worden
  - **Der Lendenbereich wird jetzt vermessen statt hartkodiert.** Das Pack hat gar keine Erector-Region, das Tool zeichnet sie selbst — und die alten Koordinaten waren auf die 248×558-Fläche des Mannes getunt. Auf 154×539 landen sie neben dem Körper. Jetzt aus Obliques-/Glutes-/Lats-Boxen des jeweiligen Blattes abgeleitet; beim Mann reproduziert das die handgetunten Werte auf ~3 Einheiten genau
  - **Seitenverhältnis pro Blatt** statt einer festen Konstante: Mann 248×558 beidseitig, Frau 172×546 und 154×539. Ein gemeinsamer Wert hat die weiblichen Figuren sichtbar gestaucht. Ein Test vergleicht das deklarierte Verhältnis mit der viewBox der Datei
  - Nebeneffekt: die Outline-Ersetzung greift jetzt per Muster statt auf `SVGID_1_` (die weiblichen Blätter nennen sie `SVGID_body_outline`), und ungenutzte `<linearGradient>`-Definitionen fliegen raus. **Alle vier Dateien zusammen sind kleiner als die zwei vorherigen**
  - `LifterSex` ist nach `shared/data/lifter_sex.dart` gezogen — Onboarding, Strength Rank *und* Muskelkarte lesen es. Vorher hätte die Körperkarte von den Kraftstandards abhängen müssen
- [x] **Geschlechts-Frage im Onboarding**, auf derselben Seite wie der Name — es ist dieselbe Frage ("wer bist du"). Dritte Option **"Rather not say"**: Überspringen muss etwas sein, das man *drücken* kann, sonst ist es nicht von "noch nicht dazu gekommen" zu unterscheiden. Nicht beantwortet → nichts gespeichert, keine Ränge, männliche Karte als Rückfall (umstellbar). Ein erfundenes "male" würde still Körperkarte *und* Kraftstandards festlegen
- [x] **Strength Rank auf 20 Übungen** (vorher 6) — alle Langhantel- und Kabelzug-Lifts mit echten veröffentlichten Tabellen: Incline/Decline/Close-Grip Bench, Push Press, Front Squat, Sumo Deadlift, Good Morning, Hip Thrust, Power Clean, Lat Pulldown, Seated Cable Row, Shrug, Upright Row, Curl, Preacher Curl, Skull Crusher
  - **Drei Gruppen bleiben bewusst draußen**, jeweils mit Test:
    - **Körpergewichtsübungen** (Klimmzug, Dip, Liegestütz) — die App loggt Zusatzgewicht, ein strikter Klimmzug ist 0 kg. Ein Verhältnis von 0.0 hieße für immer "Beginner", egal wie viele. Das braucht erst ein anderes Lastmodell
    - **Kurzhantel-Übungen** — veröffentlichte Tabellen gelten *pro Hantel*, und die App weiß nicht, ob eine oder das Paar eingetragen wurde. Falsch geraten ist Faktor zwei: der Unterschied zwischen Novice und Elite
    - **Scheibenmaschinen** (Leg Press, Hack Squat, Pec Deck) — unbekanntes Schlittengewicht, andere Hebel je Gerät. Dieselbe Begründung wie bei `isPlateLoaded`
  - Isolationsübungen an Stange oder Zug sind **drin**: der Einwand gegen einen gerankten Cable Fly war nie, dass er klein ist, sondern dass niemand veröffentlicht hat, was ein guter ist
- [x] **Übungs-Animationen — alle 78 drin.** GIF, 360×360, ~295 KB pro Datei, **22,5 MB gesamt**. Quelle: [ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB), geholt von `tool/fetch_exercise_gifs.dart --gif`
  - **Volle Auflösung bewusst gewählt.** Das Repo hat beides: 360er GIFs und dieselbe Schleife als 128er animiertes WebP (1,4 MB gesamt, Faktor 16 kleiner, aber groß gezeichnet weich). Der Zweck des Screens ist, eine Bewegung *anzusehen* — dafür ist Schärfe das Geld wert. Die 22,5 MB zahlt jeder Nutzer bei der Erstinstallation, eine local-first App hat keinen Server zum Nachladen
  - `filterQuality: medium` bleibt drin: skaliert auch 360 px sauber in die Karte, und trägt automatisch, falls später doch kleinere Dateien kommen
  - **Die Endung wird beim Laden aufgelöst** (`previewCandidates`), nicht in den Seed-Daten festgeschrieben. Die deklarieren weiter `.gif`; WebP gewinnt wenn beides da ist. Sonst müssten 78 Seed-Einträge umgeschrieben werden, sobald man das Format nochmal überdenkt
  - **Zuordnung von Hand**, nicht per Namensabgleich: die Schemata widersprechen sich echt (`barbell_row` → `barbell-bent-over-row`, `pec_deck` → `lever-seated-fly`). Ein Fuzzy-Matcher, der 80 von 100 trifft, legt still bei 20 Übungen die falsche Animation an — und eine falsche Demonstration ist schlimmer als der Platzhalter, weil sie richtig aussieht
  - Vier Einträge sind **markierte Substitute**, im Tool dokumentiert: Hip Thrust → Glute Bridge (das Dataset hat gar keinen Hip Thrust), Bulgarian Split Squat → Single-Leg Split Squat (hinterer Fuß nicht erhöht), Face Pull → Cable Rear-Delt Row with Rope, Plank → Weighted Front Plank
  - `test/exercise_preview_test.dart` prüft: jede Datei gehört zu einer echten Übung, jede hat einen echten Bild-Header (kein 404-Rumpf, kein abgebrochener Download — das schreibt eine Datei, die existiert, plausibel groß ist und als Nichts rendert), und die Gesamtgröße bleibt unter 30 MB. Kein Limit zum Anwachsen, sondern ein Stolperdraht: eine versehentliche Neuholung in größer oder ein paar Mehrfach-MB-Dateien fallen sonst niemandem auf
  - **Herkunft: unsauber, bewusst so entschieden.** Das Upstream-Repo hat keine LICENSE und der Autor schreibt selbst *"No poseo los derechos de autor sobre esas imágenes"*. Er hat per Mail zugestimmt — das deckt, was er vergeben *kann*, und das ist nach eigener Aussage die Organisationsschicht, nicht die Bilder. Vergleichbare Datensätze führen zu Gym Visual, die eine Lizenz ausdrücklich für Android-/iOS-Apps verkaufen. Das Restrisiko ist ein Takedown vom echten Rechteinhaber, nicht vom Autor
  - **Der Ausweg ist vorbereitet und klein:** Gym-Visual-Paket kaufen, Dateien unter denselben Namen ablegen, `tool/fetch_exercise_gifs.dart` löschen. Sonst weiß nichts in der App, woher die Dateien kommen. Die vollständige Herkunftsnotiz steht im Kopf dieses Tools
  - Credit auf dem Help-Screen: **"Exercise animations · ExerciseGymGifsDB · used with permission"**
- [x] **Vorschaubild statt Icon in der Übungsliste** — jede Zeile zeigt jetzt ein **Standbild** der Bewegung im 42px-Quadrat statt achtundsiebzig Mal derselben Hantel. Eine Übung an ihrer Form zu erkennen geht schneller als ihren Namen zu lesen, und genau dafür ist die Liste da
  - **Bewusst nicht animiert.** Der Detail-Screen spielt die Schleife; eine Liste würde 78 gleichzeitig dekodieren und bei jedem Scroll-Frame neu zusammensetzen — der zuverlässigste Weg, die App auf alter Android-Hardware ruckeln zu lassen
  - Flutter kann von einem GIF kein Standbild anfordern: `Image.asset` spielt es ab, es gibt keinen Schalter dagegen. Also eigener `ImageProvider` (`FirstFrame`), der Frame 1 über `dart:ui` dekodiert. Als ImageProvider geschrieben statt als `FutureBuilder` mit eigenem Cache, damit Flutters `ImageCache` die Arbeit macht: LRU, Eviction bei Speicherdruck, Deduplizierung zwischen Zeilen — und ein weggescrolltes Bild wird beim Zurückscrollen nicht neu dekodiert
  - **Beim Bauen gefunden: `targetWidth` wird bei animierten Quellen ignoriert.** 126 angefordert, 360 bekommen — jede Zeile hätte in voller Größe im Cache gelegen, ~40 MB über die Bibliothek. Wird jetzt nach dem Dekodieren über eine `PictureRecorder`-Canvas herunterskaliert, das Vollbild direkt danach verworfen. Ein Test prüft die tatsächliche Pixelbreite; ohne ihn wäre das nie aufgefallen, weil auf dem Bildschirm alles richtig aussieht
  - Fallback aufs Icon bei Übungen ohne Animation und bei Custom-Übungen (deren Bild ist eine Datei des Nutzers, kein Bundle-Asset). Bei Mehrfachauswahl weicht das Bild dem Haken — die Zeile muss lauter "ausgewählt" sagen als "welche Übung"
  - `AppTile` hat dafür ein optionales `leading` bekommen, das den `AppGlyph` ersetzt
  - [ ] **Optional, falls die Downloadgröße stört:** die vorhandenen GIFs auf ~256 px WebP umkodieren → ca. 4–5 MB bei nahezu gleicher Qualität. Weil WebP beim Auflösen gewinnt, reicht das Ablegen der konvertierten Dateien; sonst ändert sich nichts. Braucht `ffmpeg` (nicht installiert), Befehl steht in `assets/exercises/README.md`

- [x] **Daten-Export** — More → Settings → **Data → "Export data"**, CSV *und* JSON, gespeichert über `FilePicker.saveFile`. Nichts wird hochgeladen. In Settings statt auf dem More-Tab: Exportieren macht man einmal vor einem Handywechsel, nicht mitten im Training wie den Scheibenrechner
  - **CSV**: eine Zeile pro Satz, flach und sortierbar — was man in eine Tabellenkalkulation kippt. Spalte heißt `weight_kg`, nicht `weight`: die App speichert immer Kilogramm, und eine Zahl ohne Einheit ist außerhalb der App wertlos. Volumen wird mitgerechnet
  - **JSON**: Sätze bleiben in ihren Sessions verschachtelt (die Struktur, die die Daten wirklich haben), dazu Körpermaße und Kalorien-Log
  - **RFC-4180-Escaping**, mit Tests. Eine Session namens "Push, heavy" hätte unquoted jede folgende Spalte um eins verschoben — eine Datei, die sich sauber öffnet und trotzdem komplett falsch ist. Muskeln werden mit Semikolon verbunden, nicht mit Komma
  - Aufwärmsätze sind **drin und markiert** (`warmup`/`working`). Das sind deine Daten; ein Export, der entscheidet was du sehen darfst, ist einer dem man nicht trauen kann
  - Unfertige Sessions bleiben draußen — gleiche Regel wie Streak und Recap
  - Leerer Log → Hinweis statt Datei-Dialog mit anschließender Kopfzeile ohne Inhalt
  - **Kein Backup, und das steht auch so auf dem Screen**: es gibt keinen Importer, Fotos sind nicht dabei
- [x] **Feedback** — **More → Help → "Send feedback"**, öffnet die Mail-App an `gymfy.dev@gmail.com` mit fertigem Betreff und Textkörper. Entschieden für `mailto:`: ein Formular bräuchte ein Backend und würde genau den einen Satz kaputtmachen, den die Datenschutzerklärung sagen darf; ein GitHub-Issues-Link würde von jemandem, der nur einen Absturz melden will, einen Account verlangen
  - **Komponiert, nie gesendet.** Die Mail liegt im Mail-Programm des Nutzers, er liest sie, ändert sie, schickt sie selbst ab. Die App verschickt nichts
  - Angehängt sind **genau zwei Zeilen**: App-Version und Plattform + OS-Version. Dazu ein Satz, dass man sie löschen darf. Der Untertitel auf dem Screen sagt vorher, was mitgeht — ein Test prüft, dass Name, Körpergewicht und Einheiten nicht im Textkörper landen können
  - Version als **Konstante** in `features/help/data/feedback_mail.dart` statt über `package_info_plus`. Zwei Builds sind in diesem Projekt schon an Plugins gescheitert, die ihr eigenes Gradle festnageln, und ein Plugin für eine Zeichenkette ist es nicht wert. Ein Test liest `pubspec.yaml` und schlägt fehl, sobald beide auseinanderlaufen
  - Textkörper beginnt mit Leerzeilen, damit der Cursor **über** den Details steht; Query von Hand gebaut statt über `queryParameters`, das Leerzeichen als `+` kodiert — Mail-Clients zeigen das wörtlich an
  - Androids OS-Version ist ein ganzes Build-Banner: nur die erste Zeile, auf 60 Zeichen geklemmt
  - Kein Mail-Programm installiert → Snackbar mit der Adresse und einem **Copy**-Button, statt "hat nicht geklappt". Die Adresse ist der ganze Zweck des Buttons
  - Eigene **Version**-Zeile auf dem Help-Screen. Die erste Rückfrage zu jedem Bugreport ist "welcher Build?", und aus einem Store-Eintrag kann man das nicht ablesen
  - **`<queries>` im AndroidManifest ergänzt** (`SENDTO`/`mailto` + `VIEW`/`https`). Ab Android 11 sieht eine App nicht mehr, wer einen Link öffnen kann, wenn sie es nicht vorher deklariert — der Start scheitert dann still. Das betraf **auch den GitHub-Button aus der letzten Session**, der ohne diesen Eintrag ebenfalls nichts getan hätte. Es ist eine Deklaration, keine Berechtigung: nichts wird zugänglich, nichts wird angezeigt, nichts muss im Store angegeben werden
- [ ] ~~Crash Reporting~~ — **für v1 bewusst nicht gebaut.** Nichts verlässt das Gerät, damit bleibt die Datenschutzerklärung ein ehrlicher Absatz und beide Store-Formulare sagen "keine Daten erhoben". Bugs kommen über Feedback rein. Später nachrüstbar, dann als Opt-in
- [x] **Buy me a coffee — über den Umweg GitHub.** **More → Help → "Developer · Joshynaldo on GitHub"**, öffnet `https://github.com/Joshynaldo` im echten Browser (nicht im In-App-Webview: das ist fremde Seite). Der Coffee-Link lebt auf dem GitHub-Profil, nicht in der App
  - Eigener Help-Screen unter More statt Abschnitt unten in den Settings: Settings ist für Dinge, die man *ändert*; das hier liest man. Unter acht Reihen Einstellungen war es praktisch unsichtbar
  - Bewusst **nicht** als "Support me"-Button beschriftet: Apples Richtlinie 3.1.1 zielt auf *Handlungsaufforderungen*, die Nutzer zu Zahlungswegen außerhalb des In-App-Kaufs lotsen. Ein schlichter Link auf das Entwicklerprofil ist das, was Open-Source-Apps seit jeher mitliefern; ein als Trinkgeld-Button getarnter Link wäre Umgehung. Die Formulierung ist hier der ganze Unterschied
  - Ein Test prüft, dass das Ziel `github.com/Joshynaldo` ist und nicht eine Bezahlseite. Ein späteres stilles Umbiegen auf den Coffee-Link wäre ein App-Store-Problem, kein kosmetisches
  - Neues Paket `url_launcher` (First-Party) → **`flutter pub get` nötig**
  - **Noch offen, auf deiner Seite:** den Buy-Me-a-Coffee-Link (`buymeacoffee.com/joshua.dev`) auf dem GitHub-Profil hinterlegen — ohne den führt der Button ins Leere
- [x] **UI-Politur** — Richtung festgelegt: **Tiefe und Hierarchie**. Flaches dunkles Design bleibt, aber gruppierte Karten mit Abschnittsüberschriften, klarere Typo-Hierarchie, großzügigere Abstände, Ebenen durch Flächen statt durch Schatten
  - [x] **Gemeinsame Kartenoptik** in `shared/widgets/app_card.dart` — `AppCard`, `AppTile`, `AppGlyph`, `AppSectionHeader`. Ein Widget statt drei Kopien: drei Listen, die fast-aber-nicht-ganz gleich aussehen, war genau der Zustand, aus dem das hier rausführen soll
    - **Optik komplett aus `cardTheme`** — Fläche, Radius und Rand wie auf dem Home-Tab, inklusive der Regel, dass nur flache Paletten (AMOLED, High Contrast) überhaupt einen Rand bekommen. `AnimatedContainer` statt `Card`, nur damit die Auswahl einblenden kann; ein `Card` springt
    - Ausgewählt: Rand in der **Akzentfarbe**. Meist der einzige Rand, den ein Theme zeichnet — dadurch heißt er "das hier hast du gewählt" und ist nicht Deko, die jede Karte trägt
    - Nur die Akzentfarbe. Zwei Zwischenstände wurden verworfen: **klebende** Überschriften (wirkten wie ein Collapse-/Summary-Element) und Einfärbung nach Muskelfarben (zu bunt)
  - [x] **Exercises-Tab** — jede Übung eine eigene Karte, **kategorisiert nach Körperregion** mit einfachen, *nicht* klebenden Überschriften samt Zähler. Eingeordnet nach dem ersten Muskel: Bankdrücken steht einmal unter Chest, nicht dreimal. Suchfeld als Pille mit Clear-Button
  - [x] **Progress-Tab** — dieselben Karten, Chart-Icon statt Chevron: es sagt, was ein Tippen bringt
  - [x] **More-Tab** — dieselben Karten statt `ListTile` + `Divider`
  - [x] **Theme-Auswahl als Dropdown** — sieben gestapelte Zeilen waren das Höchste in den Settings und zeigten sechs Optionen, die man *nicht* benutzt, um über die eine zu informieren, die man benutzt. Zugeklappt bleiben aktuelles Theme und Swatch sichtbar. Der Swatch skaliert jetzt über `FittedBox`: seine Balken sind wenige Pixel hoch, und ein Dropdown gibt seinen Zeilen die Höhe, die es will — ungeschützt gab das einen gelb-schwarzen Overflow-Balken
  - [x] **`AppPanel`** in `shared/widgets/app_card.dart` — das Gegenstück zu `AppTile` für Karten, die *Inhalt* tragen statt einer Zeile: Chart, Formular, Ergebnis. Optionale Überschrift mit Icon, Untertitel und einem Element rechts. Grund: **fünf Screens hatten sich je eine eigene Version gebaut** (`Container` + `surfaceContainerHighest` + selbst gewählter Radius) — also eine Karte, die das Theme ignoriert. Auf AMOLED behielt sie eine graue Fläche, die der Rest der App längst abgelegt hatte, auf High Contrast fehlte ihr der Rand, den jede andere Karte zeichnet. Läuft jetzt durch `AppCard`, damit es **eine** Antwort auf "wie sieht hier eine Fläche aus" gibt
    - `AppCard` hat dafür ein `margin`-Argument bekommen (vorher fest verdrahtet). Screens, deren Liste schon horizontales Padding hatte, verdoppelten es sonst und ihre Karten waren sichtbar schmaler als die auf den Haupt-Tabs
  - [x] **Unterseiten auf dieselbe Optik gezogen** — zehn Screens: Export, Wochenübersicht, Strength Rank, Plate Calculator, 1RM-Rechner, Kalorien-Log, Messungen, Fortschrittsfotos, Übungsdetail, Plan teilen. Überall `AppPanel`/`AppTile`/`AppSectionHeader` statt handgebauter Container und `ListTile`, plus `FadeSlideIn` beim Öffnen
    - **Plate Calculator**: Gesamtgewicht steht jetzt **oben** und in Display-Größe — es ist die Zahl, die man vor dem Heben prüft, und stand vorher ganz unten unter Diagramm und Chips. Ziel und Stange in *einer* Karte: das ist eine Frage, keine zwei
    - **Plan teilen**: die Splits sind `AppTile`s mit `selected` statt `CheckboxListTile`. Die Karte sagt "das hier ist ausgewählt" bereits app-weit — Akzentrand, getönte Fläche, Haken statt Icon — eine Checkbox wäre eine zweite, konkurrierende Sprache für dieselbe Sache. Abschnitte **Send** / **Receive**
    - **1RM**: die hervorgehobene Zeile der Prozenttabelle bekommt ein getöntes Band statt nur farbigem Text — in zehn Zeilen übersieht man eine umgefärbte leicht
    - **Fortschrittsfotos** sind ein Grid, kein Listen-Screen: dort wurde der harte schwarze Balken unter jedem Bild durch einen Verlauf ersetzt (der Balken schnitt eine graue Linie durch jedes Foto und ließ das Grid wie eine Dateiliste aussehen), und die Notiz steht jetzt mit im Bild — "front relaxed" ist der Unterschied zwischen zwei Fotos vom selben Tag
    - **Messungen** haben pro Feld ein eigenes Glyph statt sechs identischer Quadrate untereinander
  - [x] **Kleine Animationen** — `shared/widgets/fade_slide_in.dart`: 200 ms Fade plus 8 px Anheben. Listenzeilen in Exercises/Progress/More kommen an, während man sie erreicht, More staffelt zusätzlich leicht, Settings blendet als Ganzes ein. Bewusst kurz: alles Längere macht aus dem Scrollen eine Diashow
- [ ] **iOS** — Vorbereitung von Windows aus erledigt, Bauen/Signieren/Einreichen passiert auf dem Mac mini
  - [x] **Bundle-ID** `com.example.gymfy` → `de.kopten.gymfy` (aus der E-Mail-Domain abgeleitet — **vor der ersten Einreichung prüfen**, danach ist sie unveränderlich)
  - [x] **`NSPhotoLibraryUsageDescription`** ergänzt. Fehlte komplett: iOS beendet die App beim ersten Foto-Zugriff sofort, und App Review lehnt den Build schon davor ab. Kein `NSCameraUsageDescription` — die App öffnet nirgends die Kamera, und eine Berechtigung zu erklären die nie angefragt wird ist selbst ein Review-Flag
  - [x] **Deployment Target 13.0 → 14.0.** `file_picker` 12 verlangt 14.0; mit 13.0 wäre der Build auf dem Mac direkt gescheitert
  - [x] **Notifications waren rein Android.** `InitializationSettings` hatte gar keinen Darwin-Eintrag → der Plugin wäre auf iOS nie initialisiert worden und *jeder* Aufruf hätte still nichts getan. Jetzt: `DarwinInitializationSettings`, iOS-Zweig in `requestPermission`, `DarwinNotificationDetails` auf beiden Alerts
    - Der laufende Countdown wird auf iOS **bewusst nicht** angezeigt: es gibt dort kein Gegenstück zum Android-Chronometer, eine Notification mit stehender Zeit sähe kaputt aus und müsste von Hand weggewischt werden. Der geplante "Rest over"-Alert feuert weiterhin und trägt das Feature dort allein
  - [x] Icons + Splash für iOS generiert. `remove_alpha_ios: true` — der App Store lehnt Icons mit Alphakanal ab; auf `#151821` geflacht statt auf Weiß, damit das iOS-Icon aussieht wie das Android-Icon
  - [x] Orientierung **nicht** eingeschränkt — Android tut es auch nicht, und das still auf einer Plattform zu ändern wäre eine Verhaltensänderung ohne Anlass
  - [ ] **Auf dem Mac:** `flutter pub get` → `cd ios && pod install`. Falls CocoaPods über das Deployment Target meckert: `platform :ios, '14.0'` in `ios/Podfile` setzen (die Datei entsteht erst beim ersten Build). Dann Signing Team in Xcode wählen und auf dem iPhone starten
  - [ ] Apple Developer Program (99 $/Jahr) für TestFlight und den Store. Zum reinen Testen auf dem eigenen iPhone reicht ein kostenloser Account (Provisioning läuft dann nach 7 Tagen ab)

### Phase 13 — Polish & Release
- [x] App Icon + Splash Screen
- [x] Onboarding Flow — Name, Körpergewicht, Akzentfarbe (persistent)
- [x] Settings Screen — Akzentfarbe, Name, Rest Timer
- [x] Einheiten kg/lbs — Storage bleibt immer kg
- [x] Rest Timer mit Notification — Schema v10, `flutter_local_notifications`
- [ ] ~~Daten-Export~~ / ~~Crash Reporting~~ — nach Phase 18 verschoben, dort mit den offenen Entscheidungen
- [ ] Play Store Listing — Screenshots, Beschreibung, Datenschutzerklärung. Die Datenschutzerklärung hängt an der Crash-Reporting-Entscheidung: ohne Crash Reporting ist sie ein Absatz ("nichts verlässt das Gerät"), mit deutlich mehr

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
