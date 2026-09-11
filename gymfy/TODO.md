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

### Phase 19 — Hyper (Liquid Glass) 🔥
- [x] **Fundament gebaut und *gesehen*.** Vier Runden "Politur" davor wurden ausschließlich daran gemessen, ob sie kompilieren — das ist kein Verfahren, das zu etwas Schönem konvergiert. Jetzt: `lib/design_preview.dart` (Galerie aller Eingabe-Elemente, ohne Datenbank) → `flutter build web` → im Browser ansehen. Damit sind Änderungen erstmals *überprüfbar*
- [x] **`AppTheme.hyper`** — das einzige Theme, das eine *Konstruktion* ist statt einer Palette. Tiefes Indigo, damit der Blur Farbe aufnehmen kann; Oberflächen fast transparent, weil der Tint die Arbeit der Füllung übernimmt
- [x] **`GlassStyle` als `ThemeExtension`** statt `if (theme == hyper)` in dreißig Screens. Eine Karte fragt "wie sieht hier eine Fläche aus" und zeichnet das. Für alle flachen Themes ist `enabled: false` und `GlassSurface` fällt auf eine gewöhnliche undurchsichtige Box durch — die ganze Kompatibilitätsgeschichte in einem Feld
- [x] **`HyperBackdrop`** — drei langsam driftende Farborbs hinter der ganzen App. **Keine Deko:** Blur liest sich nur als Glas, wenn etwas dahinter ist, das sich verzerren lässt. Über flachem Schwarz ist eine transluzente Fläche bloß ein anderes Grau — genau so sah der erste Versuch aus. Ein Umlauf dauert zwei Minuten: schnell genug, um beim Zurückkommen nicht statisch zu wirken, langsam genug, um beim Lesen nicht zu stören. Als `CustomPainter` (ein Paint-Pass) statt drei geblurter Container, wegen der alten Android-Hardware
  - **Dabei einen echten Fehler gefunden:** der Ticker lief in `initState` los, also auf *jedem* Theme — nichts zu sehen, aber ein Aufwachen pro Frame den ganzen Tag, und ein Widget-Baum, der nie zur Ruhe kommt. Genau daran hing der Smoke-Test. Wird jetzt aus dem Theme heraus gestartet und gestoppt
- [x] `AppCard` rendert auf dem Glas-Theme als Pane (Tint, Kante, Specular-Highlight oben) und ist überall sonst unverändert. Ein Test prüft beides — dass Hyper Panes bekommt *und* dass die sechs anderen Themes weiterhin keinen einzigen Blur-Pass kosten
- [x] **Beim Ausrollen die teuerste Erkenntnis der Phase: Karten haben nie irgendetwas geblurrt.** Eine Karte liegt direkt auf dem Backdrop, hinter ihr ist also nur ein weiches Farbfeld — und ein geblurrtes weiches Farbfeld ist dasselbe weiche Farbfeld. Der `BackdropFilter` war ein Offscreen-Pass **pro Karte**, auf einer scrollenden Liste, für exakt null sichtbare Wirkung. `GlassSurface.blurs` entscheidet das jetzt bewusst: Blur nur für Flächen, die wirklich Inhalt verdecken (Sheets, Dialoge). Sichtbar ändert sich nichts, auf alter Hardware alles
- [x] **Motion-Sprache** (`app/theme/motion.dart`) — eine Datei statt einer Dauer, die an jeder Aufrufstelle neu geraten wird. Bewegung fühlt man, statt sie zu sehen, und sie wirkt nur dann beabsichtigt, wenn sich alles gleich bewegt
  - **`SpringCurve`** — Flutter liefert Spring-*Simulationen*, aber keine Spring-*Kurve*, und eine Kurve ist das, was die animierten Widgets nehmen. Löst dasselbe System analytisch über eine feste Sekunde
  - Vier Kurven mit klarer Aufgabe: `spring` (~9 % Überschwingen, für Ankommen und Loslassen), `settle` (kritisch gedämpft, für alles, dessen *Größe* sich ändert — Überschwingen hieße dort ein Frame lang Inhalt größer als seine Box, also Clipping), `emphasis` (die zwei, drei echten Momente), `exit` (Weggehen soll keine Aufmerksamkeit kosten)
  - Vier Dauern: `press` 90 ms, `quick` 170, `standard` 260, `slow` 380, `celebrate` 1100
  - **`motionOf(context, duration)` respektiert "Bewegung reduzieren"** — die Einstellung schalten Menschen ein, weil ihnen von Bewegung schlecht wird. Also *keine* Animation, nicht bloß eine schnellere
  - Tests prüfen die Eigenschaften, die eine gut gemeinte Konstanten-Änderung zerstört: dass die Feder überschwingt, dass `settle` es nie tut, und dass beide **vor** dem Zeitablauf zur Ruhe gekommen sind. `Curve.transform` gibt bei `t == 1` per Definition 1 zurück — eine schlecht abgestimmte Feder versteckt ihren Fehler also bis zum letzten Frame und springt dann
- [x] **Screen-Übergänge** — eine Zeile im Theme (`pageTransitionsTheme`), und jede gepushte Route in der App hat sie. Der ankommende Screen kommt ein Stück von rechts und blendet auf, der darunter driftet in die Gegenrichtung, dimmt und schrumpft leicht: **zwei Ebenen, die sich unterschiedlich schnell bewegen**, das ist der Teil, der als Tiefe liest
  - **iOS und macOS behalten bewusst Cupertino.** Dieser Builder installiert auch die Wisch-vom-Rand-Zurück-Geste; sie zu ersetzen hieße, eine schönere Animation gegen eine Navigationsgeste zu tauschen, die jeder iPhone-Nutzer in den Fingern hat. Ein Test hält das fest
- [x] **`Pressable`** — die Fläche gibt unter dem Finger nach und federt zurück. Ersetzt die Material-Welle auf Karten: eine Welle ist Licht, das *über* eine Fläche läuft, und sagt nichts darüber, dass die Fläche gedrückt wurde — auf einer transluzenten Pane liest sie sich ohnehin als Schmierer
  - Hängt an `InkWell.onHighlightChanged` statt an einem eigenen `GestureDetector`, gehorcht damit der Gesten-Arena: wer mit dem Finger auf einer Karte losscrollt, lässt die Karte los, statt sie gedrückt stehen zu lassen
  - **Dabei ein Absturz mit verwirrender Ursache:** der Controller wurde faul erzeugt, für eine nie gedrückte Karte war `dispose()` also das erste, was ihn anfasste — und einen `AnimationController` zu bauen braucht einen Lookup den Baum hinauf, der beim Abbau verboten ist. Jede Karte ohne `onTap` riss den Screen beim Verlassen mit. Regressionstest liegt bei
- [x] **`AnimatedCount`** — große Zahlen reisen zu ihrem neuen Wert, statt ihn zu ersetzen. Ziffern in `tabularFigures`, sonst verengt sich die Zahl beim Durchlaufen einer "1" sichtbar und alles daneben zuckt. Standardmäßig **nicht** beim ersten Bauen: von null hochzählen ist genau einmal schön und danach eine Belästigung — `from:` macht es zur bewussten Ausnahme (Workout-Zusammenfassung)
- [x] **`Celebration`** — ein Aufblühen aus Licht auf der Workout-Zusammenfassung. Kein Konfetti: eine Gym-App, die einem für drei geloggte Sätze Papier ins Gesicht wirft, entwertet genau den Moment, den sie markieren will, und man sähe es mehrmals pro Woche. Der Painter fliegt danach **aus dem Baum** — eine Feier, die eine repaintende Ebene zurücklässt, bezahlt man bis zum Ende der Session. Genau das prüft der Test
- [x] **Navigationsleiste als schwebende Pille** (`shared/widgets/glass_nav_bar.dart`) — die Änderung, die die App am meisten geschichtet wirken lässt: eine an den unteren Rand geschweißte Leiste ist Chrome, eine darüber schwebende ist ein Objekt vor dem Inhalt. Innen bleibt die echte `NavigationBar` — Indikator, Labelverhalten, Semantik und Barrierefreiheit gegen eine Form einzutauschen wäre ein schlechter Handel
  - Tab-Wechsel: haptischer Klick (die eine Bedienung, die man mitten im Satz ohne Hinsehen trifft) und ein kurzes Setzen des Inhalts statt eines Schnitts. Bewusst **nicht** aus dem Nichts aufgeblendet — das lässt den Screen bei jedem Tab-Druck dunkel blinken
- [x] **`GlassAppBar` auf allen 28 Screens** — auf den flachen Themes exakt die alte `AppBar`, auf Hyper eine Pane, durch die das driftende Feld scheint
  - **Der Tint ist absichtlich kräftiger als bei einer Karte.** Eine Karte wird gegen die Karten daneben gelesen, die Leiste gegen ein fast schwarzes Feld — dieselben paar Prozent Weiß sind dort unsichtbar. Der erste Versuch ergab eine Leiste, die man überhaupt nicht sah, und eine Liste, die an nichts abzuschneiden schien
  - **Und einen Fehler ohne Fehlermeldung:** die Pane war eine `DecoratedBox` ohne Kind, nimmt also die kleinste angebotene Größe — nämlich keine. Sie hat einen völlig korrekten Verlauf in eine Null-mal-Null-Box gemalt und sah aus, als hätte man gar keine Leiste geschrieben. Test prüft jetzt, dass die Pane eine Größe *hat*
- [x] **Inhalt scrollt jetzt wirklich unter den Leisten durch** — die eigentliche Liquid-Glass-Signatur, und der Punkt, an dem der Blur endlich Arbeit bekommt. Vorher filterten beide Leisten nur den weichen Farbverlauf des Backdrops und gaben exakt dieselben Pixel zurück; jetzt filtern sie die Liste, die darunter vorbeizieht
  - `GlassScaffold` setzt `extendBodyBehindAppBar`, die Navigations-Shell `extendBody` — beides **nur** auf dem Glas-Theme. Die sechs flachen Themes behalten ihr altes Layout unverändert
  - Die andere Hälfte ist `barInsets(context)`: Scaffold rechnet die Zahlen ohnehin aus und reicht sie dem Body als `MediaQuery.padding` — das liest sie zurück, damit eine Liste sie zu ihrem eigenen Padding addiert. Auf flachen Themes gibt es `EdgeInsets.zero` zurück, die Änderung ist dort also buchstäblich wirkungslos
  - Screens mit **festem Kopf** (Tages-Stepper, Suchfeld, Rest-Timer) halten diesen über `topBarInset` frei und lassen nur die Liste darunter durchlaufen. Ein halb lesbares Suchfeld hinter einem transluzenten Titel wäre schlimmer als gar kein Effekt
  - **Die Falle:** ein `SafeArea` dazwischen frisst genau die Insets, die die Liste braucht. Auf dem Stats-Screen war das der Fall — er hat sein oberes Padding verloren, bis das `SafeArea` raus war. Ein Test hält das fest, weil es lautlos passiert
  - Bewusst getestet statt begutachtet: der Fehlerfall sieht auf dem Screen, den man zufällig prüft, völlig richtig aus und versteckt auf einem anderen die letzte Zeile
- [x] **Dialoge** (`GlassDialog`, 13 Stück) — auf flachen Themes *ist* das ein `AlertDialog`, unverändert. Auf Hyper eine Pane über einer geblurrten Kopie des Bildschirms. Die zweite Fläche, bei der der Blur unstrittig ist: ein Dialog verdeckt echten Inhalt, das Filtern hält also die Wahrnehmung aufrecht, dass der Bildschirm noch da ist, ohne dass er mit der Frage konkurriert
  - Die Füllung ist **viel** kräftiger als bei einer Karte (Palette-Surface bei 82 % statt ein paar Prozent Weiß). Hier steht Text direkt drauf, über bewegtem Inhalt — Glas, durch das man einen Absatz lesen kann, ist ein Fenster
- [x] **Charts** teilen sich einen Stil (`shared/widgets/chart_style.dart`). Drei Charts hatten je eigene Gitterfarbe, eigene Achsenbeschriftung und eine eigene Vorstellung davon, wie stark unter einer Linie zu schattieren ist — nichts davon falsch, alles leicht verschieden, einen Screen voneinander entfernt
  - Gitter **gestrichelt** statt durchgezogen: ein Gitter ist da, um daran zu messen, nicht um es anzusehen. Achsenzahlen in `tabularFigures`, sonst steht eine Y-Achse von 100/110/120 auf drei minimal verschiedenen Einzügen. Füllung unter der Linie als **Verlauf** statt Fläche — eine flache Füllung liest sich als Form, die mit den Daten konkurriert
  - Punkte nur noch, solange man sie zählen kann (≤ 12); danach verschmelzen sie zu einer dicken, klumpigen Linie und sagen nichts mehr
  - **Bewusst weiterhin nicht gekurvt.** Eine geglättete Linie erfindet Gewichte zwischen den Punkten, die nie gehoben wurden — hübscher, aber gelogen
- [x] **Home-Karten** — Home war der letzte Tab, der seine Flächen selbst zeichnete: sechs rohe Material-`Card`s. Damit fehlten der Pane, die Druck-Skalierung und das obere Lichtband, die jede andere Karte der App hat. Jetzt alle über `AppCard`, zusammen mit den letzten zwei im Workout-Bereich
  - **Dabei ein Fehler, den der Umbau selbst verursacht hatte:** `Pressable` hat das `Material` nach *außen* verlegt, also fand ein `ListTile` in einer Karte zwischen sich und dem Material eine gefärbte Box — Flutter meldet zu Recht "background may be invisible". `_InkHost` setzt es wieder dorthin, wo der Inhalt es findet
- [x] **Bugfix: „die obere Leiste ist zu groß und verdeckt Inhalt".** Die Insets waren korrekt — nachgemessen, 100 px Leiste, 100 px Freiraum. Die Leiste war schlicht ein **dauerhaft helles Band über einem Sechstel des Bildschirms**, bezahlt egal ob sie gerade etwas tut oder nicht: am Listenanfang liegt nichts darunter, wovon der Titel getrennt werden müsste
  - Jetzt verdient sie ihre Präsenz. In Ruhe: **gar keine Leiste**, der Titel schwebt über dem driftenden Feld. Sobald Inhalt darunterfährt, blenden Scrim, Haarlinie und Blur gemeinsam ein — die Leiste erscheint genau dann, wenn es etwas zu verdecken gibt, und das ist auch der Moment, in dem sie überhaupt als Glas lesbar wird
  - Hängt am selben `ScrollNotificationObserver`, den `AppBar` intern benutzt (Scaffold installiert ihn über Leiste *und* Body — der einzige Grund, warum ein Widget in der AppBar etwas über eine Liste wissen kann, deren Vorfahre es nicht ist). Nur `depth == 0`, sonst lässt ein horizontaler Streifen in einer Karte den Titel beim Wischen flackern
  - **Nebenbei ein Blur-Pass gespart:** in Ruhe liegt nichts unter der Leiste, also wird der `BackdropFilter` gar nicht erst gebaut
- [x] **Bugfix: Fotovergleich lag hinter den Leisten.** Sein Body ist ein `Column`, das nicht scrollt — also hielt es sich auch nicht selbst frei: die Zeitspanne saß hinter der AppBar, die Regler hinter der Navigations-Pille. Ein festes Layout auf einem Glas-Screen muss `barInsets` selbst anwenden. Ein Test findet solche Screens jetzt an der Quelle
- [x] **Bugfix im eigenen Werkzeug: die Design-Vorschau simulierte ein Telefon, das es nicht gibt.** Ohne Statusleiste war die AppBar dort ~44 px kürzer als auf jedem echten Gerät — und die Höhe der Leiste war genau das, was beurteilt werden sollte. Die Vorschau fälscht jetzt Status- und Gestenleiste. Dieselbe Lehre wie beim Akzent: ein Werkzeug, mit dem man ein Design beurteilt, muss über die Bedingungen ehrlich sein, unter denen es ausgeliefert wird
- [x] **Motion in den Screens angekommen**
  - **Hero von der Übungsliste ins Detail** — das Standbild der Zeile fliegt in den Player. Beide Enden holen ihren Tag aus `exerciseHeroTag()`, statt ihn zweimal auszuschreiben: ein Hero, dessen Hälften sich um ein Zeichen unterscheiden, schlägt nicht fehl, er fliegt stillschweigend nicht mehr — nicht unterscheidbar davon, dass die Animation nie gebaut wurde. Nur die Bibliotheksliste trägt den Tag (Picker, Day Builder und laufendes Workout zeigen dieselben Übungen; zwei gleiche Tags gleichzeitig wären eine Assertion), und Übungen ohne Animation fliegen gar nicht — ein Icon, das in ein Video fliegt, wäre eine Lüge über das andere Ende
  - **Die Today-Karte morpht zwischen ihren vier Zuständen** statt sie zwischen zwei Frames auszutauschen. Sie ist das Erste auf dem Home-Tab und ändert sich unter einem: der Split lädt, ein Workout startet, der Tag kippt. Ein harter Austausch liest sich, als hätte der Bildschirm das Falsche gezeigt und sich korrigiert
  - **Geloggte Sätze kommen an, statt zu erscheinen** — pro Satz-ID gekeyt, damit nur die wirklich neue Zeile animiert (nach Position gekeyt würde jedes Hinzufügen die Ankunft aller Zeilen darunter neu abspielen und die Karte bei jedem Satz durchwellen). Die Karte wächst mit `AnimatedSize` mit, statt darunter zu springen. Das passiert vierzigmal pro Session mit dem Telefon am Rack
  - **All-Time-Zahlen zählen hoch**, wenn sie sich geändert haben. Der Stats-Tab bleibt hinter der Navigations-Shell am Leben, also ist die Rückkehr nach einer Session der eine Moment, den dieser Screen hat — eine Zahl, die sich stillschweigend ersetzt hat, sagt nichts
- [ ] **Offen: Parallaxe in den Listen.** Bewusst nicht gemacht: scroll-getriebene Effekte pro Zeile heißen Arbeit pro Frame pro sichtbarer Zeile, und das ist genau die Rechnung, die auf der alten Android-Hardware nicht aufgeht. Wenn, dann für eine einzelne, kurze Liste — nicht für die Bibliothek mit achtundsiebzig Einträgen
- [x] **Claude-Design-Vorlage eingelesen und das Material darauf umgestellt** (Projekt `Gymfy Hyper.dc.html` + `GymfyPhone.dc.html`, über die Design-MCP gelesen — `support.js` ist nur die Laufzeit der Design-Canvas, nichts Gestalterisches)
  - **Vier Flächen statt einer.** `GlassTier` in `app/theme/glass.dart`: `raised` (Karten — was man liest), `quiet` (Zeilen — was man trifft), `bar` (Navigations-Pille und AppBar-Schleier), `sheet` (Sheets und Dialoge). Vorher gab es *eine* Tönung, die überall benutzt wurde; eine Bibliothek mit achtundsiebzig gleich hellen Zeilen ist eine Liste ohne Hierarchie
  - **Füllung ist jetzt ein Verlauf mit drei Stopps**, nicht eine flache Tönung: 11,5 % Weiß oben, 5,2 % in der Mitte, 7,5 % unten. Der Einbruch und das Zurückkommen sind das, was das Auge als *Dicke* liest — eine flache Tönung irgendwo dazwischen sieht aus wie Plastik, egal wie stark der Blur ist
  - **Die Lichtkante wird gezeichnet, nicht überlagert.** Ein gestrichenes RRect mit vertikalem Verlauf (hell oben → normale Kante nach einem Drittel) statt Rahmen plus Highlight-Gradient: ein `BoxDecoration`-Rahmen *muss* mit Radius einheitlich sein, und ein Highlight als *Füllung* wäscht über den Inhalt der Karte. Jetzt folgt die Kante den Ecken, wie sie es soll
  - **Sättigung und Helligkeit hinter blurrenden Flächen** (1,85 / 1,08, als `ColorFilter.matrix` in denselben `ImageFilter` komponiert). Blur mittelt Farbe, und Mitteln zieht immer Richtung Grau — das ist der Grund, warum naives Glas wie Milchplastik aussieht. Kostet keinen zusätzlichen Pass, nur Matrixrechnung auf einem Puffer, den es ohnehin gab
  - **AppBar-Schleier ist jetzt die Grundfarbe, nicht Weiß** (`#07070F` bei 78 % → 62 %, Haarlinie 12 %). Eine Leiste über einer Liste muss den Inhalt *abziehen*, nicht Licht dazugeben: Weiß über laufendem Text lässt den Text lesbar durchscheinen, und das ist schlimmer als eine volle Leiste oder gar keine. Kurve dafür linear statt Feder — ein Crossfade hat keinen Ort, an dem er ankommt
  - **Navigations-Pille und Sheets haben einen undurchsichtigen Boden** (`rgba(11,11,21,0.68)` bzw. der Sheet-Verlauf bei 80–84 %). Blur allein mittelt den Text darunter zu einem Schleier, der immer noch, schwach, Text ist
  - **Kartenradius auf Hyper 16 → 24**, Zeilen 20. Eine durchscheinende Fläche wird über ihre Kante gelesen; bei 16 liest sich die Kante als Kasten mit abgerundeten Ecken, nicht als etwas Geformtes. Die sechs flachen Themes bleiben bei 16 — ein Test hält das fest
  - **`AppGlyph` auf Glas neutral, bis es ausgewählt ist.** Die Regel ist *ein* Akzent pro Screen, auf dem, was zählt — eine Spalte aus neun Akzent-Quadraten auf dem More-Tab bricht sie neunmal und gibt den Akzent ausgerechnet an den Teil der Zeile, den niemand liest
  - **Hintergrund-Orbs neu komponiert**: drei Anker statt drei Umlaufbahnen, jeder Orb atmet nur um seine Ecke. Die Komposition ist bei jedem Öffnen dieselbe, und was sich ändert, ist zu langsam, um es zu erwischen. Die Farben sind der Akzent und zwei Nachbarn davon (Hue ±) statt Akzent, Akzent, festes Blau — so nimmt der Grund nie einen Ton an, den die Oberfläche nicht verwenden kann
  - `test/glass_material_test.dart` (12 Tests) hält die Regeln fest, die sonst still verschwinden: Zeile dunkler als Karte, Lippe heller als Flanke, drei Stopps mit Einbruch, **nur die Flächen mit Inhalt dahinter blurren**, Boden vorhanden, flache Themes bekommen weiterhin nichts
- [x] **Schibsted Grotesk mitgeliefert** — vier statische Schnitte (400/500/600/700, zusammen ~380 KB) in `assets/fonts/`, in `pubspec.yaml` registriert, Lizenz (SIL OFL 1.1) liegt als `assets/fonts/OFL.txt` daneben. Bewusst **kein** `google_fonts`-Paket: das lädt beim ersten Benutzen über das Netz, und diese App muss im Kellerstudio ohne Empfang genauso aussehen wie sonst. Gesetzt wird sie **nur auf Hyper** (`fontFamily` hängt an `glass.enabled`) — die sechs flachen Themes behalten Roboto, eine Schrift ändert man nicht still mit
  - → **`flutter pub get` nötig** (ist gelaufen), und beim nächsten Release-Build wachsen die APKs um rund 0,4 MB
- [x] **Vier Tabs statt fünf** — Home · Workout · Progress · More. Jede zusätzliche Leiste nimmt jeder anderen Breite weg: bei sechs mussten die Beschriftungen schrumpfen, bei fünf waren die Ziele schmaler als ein Daumen
  - **Progress ist zurück in der Leiste.** Es war unter More gelandet, als die Leiste sechs Tabs trug; es ist die Hälfte der App, die nicht Loggen ist, und der Grund, warum überhaupt jemand loggt
  - **Bibliothek und Muskelkarte sind nach More gewandert.** Die Bibliothek schlägt man nach — beim Tag bauen, beim Bewegung prüfen —, und beides beginnt woanders in der App. **Die Pfade bleiben** (`/exercises/...`), nur der Branch ändert sich, also landet jeder bestehende Link weiter
  - `/more/progress/...` → `/progress/...` an sieben Stellen umgezogen; `router_links_test.dart` prüft weiterhin statisch, dass jedes `context.go` im ganzen `lib/` auf eine existierende Route zeigt
- [x] **Laufendes Workout neu gebaut** (`active_workout_screen.dart`) — **eine Übung ist die Karte, der Rest sind Zeilen unter "UP NEXT"**. Vorher bekam jede Übung des Tages eine identische Karte mit eigenen Knöpfen: fünf gleich laute Flächen, vier davon über etwas, das man gerade nicht tut. Mit dem Telefon am Rack hat der Screen eine Aufgabe, und das ist der Satz, den man gleich loggt
  - Die Karte steht automatisch auf der ersten Übung, der noch Arbeitssätze fehlen. **Eine Zeile antippen holt sie nach vorn** — die Bank ist besetzt, man macht die Flys zuerst, und der Screen besteht nicht auf einer Reihenfolge, die das Studio nicht interessiert
  - Zeilen tragen **einen Punkt pro geplantem Satz**, gefüllt was geloggt ist. Das sagt den Stand, ohne dass eine Zahl gelesen werden muss — mehr braucht man über etwas nicht, das man noch nicht tut
  - Der Knopf zählt mit: **"Log set 3"** statt "Add set". Die Zahl darauf ist die, die gleich entsteht
  - Der **Akzent gehört auf diesem Screen dem Rest-Timer** — der Log-Knopf ist bewusst weiß-auf-Glas. Zwei Akzentflächen hieße nachsehen, welche von beiden ruft
- [x] **Log-Sheet mit Zahlenpad** (`features/workout/widgets/log_set_sheet.dart`, neu) statt Dialog mit Textfeld. Beides folgt aus dem Ort: einhändig am Rack, Telefon tief. Ein Dialog setzt seine Eingaben in die Bildschirmmitte, wo der Daumen nicht hinkommt, und ein Textfeld holt die Systemtastatur — ein Raster aus vierzig kleinen Tasten, von denen achtunddreißig in keinem Gewicht vorkommen können
  - Zwei Schritte: **Gewicht (66 px) → "Next: reps" → Wiederholungen → "Save set"**. Der primäre Knopf bleibt an derselben Stelle, der Daumen geht zweimal dorthin
  - **Abweichung von der Vorlage, bewusst:** die Vorlage speicherte beim *ersten* Ziffernkontakt der Wiederholungen. Einen Tipp schneller — und zwölf Wiederholungen unmöglich, in einer App, deren eigene Ziele "6–8" und "12–15" heißen. Hier braucht es den Tipp auf "Save set"
  - Warm-up ist ein **Chip im Sheet**, nicht mehr ein zweiter Knopf auf der Karte: ob das ein Aufwärmsatz war, entscheidet sich oft erst, wenn die Stange in der Hand liegt. Der Satz wird danach gegen die Phase nummeriert, die **zurückkommt**, nicht gegen die, die der Knopf gemeint hat
  - "Repeat last set" übernimmt Gewicht *und* Wiederholungen — gerade Sätze sind damit ein Tipp pro Satz nach dem ersten. Plattenstapeln bleibt für Langhantelübungen erreichbar
  - Werte werden als **Text** gehalten, nicht als Zahl: ein Pad bearbeitet "10", "102", "102." — und eine Zahl kann weder einen offenen Dezimalpunkt halten noch leer von null unterscheiden
- [x] **Rest-Pane schwebt jetzt über dem Inhalt** statt im Fluss zu sitzen: 24er Radius, Akzent über dunklem Boden, 38-px-Ziffern, +30s, Fortschrittslinie am Fuß. Bei null verdoppelt sich die Akzentfüllung, die Ziffern werden zu **"Rest over"**, und +30s fällt weg — es gibt nichts mehr, worauf man dreißig Sekunden addieren könnte. Der Doppelpunkt ist **nicht** tabellarisch gesetzt: eine tabellarische Interpunktion wird auf Ziffernbreite gepolstert, und "1 : 07" steht dann auseinandergerissen in der Mitte der Zahl
  - Die Liste öffnet den Platz dafür animiert und schließt ihn wieder — wer ohne Timer loggt, zahlt keine 124 px Dauer-Chrome
  - Der Screen beobachtet den Timer nur als **Boolean** (`select((t) => t != null)`), sonst würde der Sekundentakt den ganzen Screen neu bauen — genau die Kosten, die das eigene Widget des Panes vermeidet
- [x] **`GlassSheet`** (`shared/widgets/glass_sheet.dart`, neu) — eine Hülle für alle Bottom Sheets. Vorher gab es zwei, jede mit eigenem Blur-Radius und eigener Vorstellung davon, wie undurchsichtig ein Sheet ist. `app_picker.dart` läuft jetzt darüber
- **Zwei Fehler, die nur der Browser gezeigt hat:** das Rückschritt-Zeichen U+232B hat in Schibsted Grotesk kein Glyph und kam als leeres Kästchen (jetzt ein Icon, mit Test), und "Repeat last set" neben "Next: reps" lief auf einem schmalen Telefon 37 px über den Rand (jetzt `FittedBox`)
- [x] **Der Fehler hinter "die Leiste geht nicht" — app-weit, und die Zahl war nie falsch.** Gemeldet als "das Suchfeld liegt hinter der Leiste und ich komme nicht ran". Ursache war nicht der Wert von `barInsets`, sondern **wo er gelesen wurde**: das Padding, das die AppBar mitzählt, existiert nur **unterhalb** des Scaffold. Scaffold reicht es an den Body; niemand darüber sieht es. Ein Screen, der sein Padding in seinem *eigenen* `build` ausrechnet, bekam also nur die Statusleiste — **44 statt 100** — und die restlichen 56 px der AppBar lagen auf allem, was der Screen oben festgenagelt hatte. Eine durchsichtige AppBar nimmt die Berührungen in ihrem Band trotzdem entgegen, also war das Suchfeld sichtbar und unerreichbar
  - Das betraf **jede Liste in der App**, nicht nur die Bibliothek: die ersten ~56 px jeder Liste lagen unter der Leiste — auch auf dem More-Tab. Nichts sah kaputt aus, auf den flachen Themes stimmte es sogar, und getestet war es auch: `glass_layout_test.dart` prüfte den *Helfer* (von innen, korrekt), nie die **Aufrufstellen**
  - **Fix: `GlassScaffold.body` nimmt jetzt einen Builder** statt eines Widgets (`body: (context) => …`). Das ist der Punkt: die Closure-Variable `context` verdeckt die des Screens, also ist die richtige die, die im Gültigkeitsbereich liegt — und die alte Antwort bekommt man nur noch, wenn man sich Mühe gibt. 33 Aufrufstellen in 28 Dateien umgestellt; der Compiler hat jede einzelne erzwungen
  - `test/fixed_header_test.dart` misst es am **echten** Bibliotheks-Screen in Pixeln: Oberkante Suchfeld gegen Unterkante AppBar. Gegengeprüft, dass er den Fehler auch fängt — mit der alten Schreibweise meldet er "starts 56.0, under a bar that ends 100.0"
- [x] **Zwei Bugs auf dem More-Tab**
  - **"Stats" sprang in den Progress-Tab.** Die Route lag noch im Progress-Branch, und `go` öffnet keinen Screen, es **schaltet die ganze Shell um**: die Zeile hat einen anderen Tab angeschaltet und den eigenen Platz weggeworfen. Route liegt jetzt im More-Branch
  - Die Zeile hieß **"Muscle map"** und öffnete einen Screen mit der Überschrift **"Stats"** — das liest sich jedes Mal wie ein Fehlgriff. Jetzt "Stats", Untertitel nennt die Muskelkarte
  - **Der More-Tab öffnete die Bibliothek statt der Übersicht.** Ein `StatefulShellBranch` ohne `initialLocation` startet bei der Route, die zufällig **zuerst** in ihm steht — und seit die Bibliothek in diesen Branch gezogen ist und über `/more` geschrieben stand, war das `/exercises`. Die Konfiguration war gültig, jede Route löste auf, die Übersicht war schlicht nicht erreichbar. Alle vier Branches nennen ihren Start jetzt ausdrücklich; das ist nichts, was man der Reihenfolge im Quelltext überlassen darf
  - `widget_test.dart` tippt jetzt jeden Tab an und prüft, wo der Router landet — nicht die Route-Tabelle, sondern das Verhalten. Gegengeprüft: ohne `initialLocation` meldet er `Actual: '/exercises'`. Bewusst über `matchedLocation` statt über den Titel im Screen: die meisten Tabs hängen ohne Datenbank am Ladekreis, aber *wohin* navigiert wurde, steht trotzdem fest
  - `router_links_test.dart` prüft das jetzt: jede More-Zeile muss im selben Branch liegen wie `/more`. **Die erste Fassung dieses Tests war wirkungslos** — sie suchte nach `.go('…')`-Literalen, und More navigiert über eine *Variable* (`context.go(tool.route)`), also fand sie nichts und bestand mit eingebautem Fehler. Sie liest jetzt die Routen-Tabelle des Screens, und es ist nachgewiesen, dass sie rot wird
- [x] **Typo-Skala der Vorlage übernommen** (`_hyperText` in `app_theme.dart`, nur Hyper) — elf Größen, und die Sprünge dazwischen sind der Punkt: 11, 12,5, 13, 15, 17, 19, 26, 34. Materials eigene Skala ist für eine Seite Fließtext gebaut und steigt sanft; diese steigt hart, weil hier auf jedem Screen eine Zahl steht, die man mit etwas in der anderen Hand im Vorbeigehen liest
  - **Großes wird enger getrackt** (bis -0,6 bei 34): ab 26 px liest sich Standardabstand löchrig und die Zahl hört auf, ein Objekt zu sein. **Kleine Versalien weiter** (11 px auf +1,1) — das ist der Label-Stil, auf dem die halbe Vorlage steht ("WEDNESDAY", "UP NEXT", "STEP 1 — WEIGHT")
  - AppBar-Titel ausdrücklich auf 19 gesetzt: Material 3 gibt ihm `titleLarge`, in dieser Skala die 26 px, die dem *Thema* eines Screens gehören. Ein Titel ist ein Schild, kein Inhalt
- [x] **`AppButton`** (`shared/widgets/app_button.dart`, neu) — die Aktion in der Form der Vorlage: 54 px hoch (sekundär 50), Radius 18, Akzentfüllung mit Lichtverlauf darüber und farbigem Schein darunter. Das ist es, was ihn *beleuchtet* statt bemalt aussehen lässt, und es ist dieselbe Behandlung wie bei den Glasflächen daneben. Drei Screens hatten sich je einen eigenen gebaut; jetzt einer
  - Glyph vor oder hinter der Beschriftung ist keine Deko: davor beschreibt er die Handlung ("Play" — starte das), dahinter zeigt er auf das, was als Nächstes kommt ("Next: reps ›"). Ein Chevron links hieße zurück
- [x] **Abstände nach Vorlage** — 16 px Bildschirmrand, **22 px zwischen Karten**, 10 zwischen Zeilen, 34 vor einer Abschnittsüberschrift. In `AppCard` als Vorgabe **pro Tier** (Karten atmen, Zeilen stehen Schlange) und **nur auf Hyper**: die sechs flachen Themes behalten ihre alten Ränder, denn Abstand ist eine genauso sichtbare Änderung wie Farbe
- [x] **Home nach Vorlage** — Tageskarte mit 32-px-Tagesnamen unter zwei getrackten Versalzeilen, Übungsliste mit Zielen, **54-px-"Start workout"** als einziger Akzent auf dem Tab. Danach die letzte Einheit mit ihrer Mini-Muskelkarte und **"This week"**: eine Zahl, sieben Balken (`week_card.dart`, neu). Die Balken sind weiß, nicht akzentfarben — es gibt einen Akzent auf diesem Tab, und der sitzt auf dem Knopf
- [x] **Progress hat die drei Segmente der Vorlage** (Trends / All-time / Body) und **hat Stats geschluckt**. Das waren vorher zwei Tabs und ein vergrabener Screen für dieselbe Frage in drei Reichweiten — welche Antwort man bekam, hing davon ab, durch welche Tür man kam
  - `AppSegmented` (`shared/widgets/app_segmented.dart`, neu): Schiene mit gleich breiten Segmenten, das gewählte in hellerer Füllung herausgehoben. Bewusst **nicht** akzentfarben — diese Dinger wählen eine *Ansicht*, und der Akzent gehört dem, was auf dem Screen zählt. Als `SegmentedBar` in der AppBar, damit es das Scrollen überlebt: ein Regler, der wegscrollt, nimmt den Rückweg mit
  - `stats_screen.dart` → `stats/widgets/stats_sections.dart` mit `RankSection`, `TotalsSection`, `BodyMapSection`; Progress setzt sie zusammen. Recap und Aktivitäts-Heatmap sind von `home/widgets/` nach `progress/widgets/` gezogen. Route `/stats` und die More-Zeile sind weg
  - Die beiden Stats-Tests zeigen jetzt direkt auf die Sections statt auf einen Screen, der sie besaß — näher an dem, was sie ohnehin prüfen
- [x] **Bibliothek: Suche und Filter sitzen in der Leiste** (`bottom:` der `GlassAppBar`), nicht mehr oben im Body. Zweierlei folgt daraus: der Schleier, der beim Scrollen einblendet, deckt das Suchfeld **mit** ab — die Liste zieht unter *einer* Fläche durch statt unter einem Titel und dann hinter einem schwebenden Kasten —, und das Feld kann nicht wegscrollen, was auf dem einen Screen, dessen ganzer Zweck Finden ist, der Regler wäre, für den man immer zurückmuss
  - **Fehler dabei gefunden und behoben:** die Muskel-Chips wurden im `data:`-Callback der Liste gesetzt, die AppBar wird aber *vorher* gebaut — also blieben sie leer, und nichts hätte das je korrigiert. Fünf Tests sind darüber gestolpert; die Liste kommt jetzt aus dem Provider im Screen-`build`
- [x] **Übungsdetail**: quadratische Standbild-Fläche mit 14 px Glas ringsum, damit die Animation Teil der Fläche ist statt ein Bild, das zufällig auf dem Screen liegt. Name in 26 (die Größe, die die Skala dem *Thema* eines Screens vorbehält), Muskeln als eine getrennte Zeile darunter
- [x] **Bugfix: "BOTTOM OVERFLOWED BY 2 PIXELS" auf Home.** Der Balkenbereich der Wochenkarte stand auf fest verdrahteten 76 px — der Summe aus 56er Balken, 8er Abstand und einer Beschriftung **in genau einer Schriftgröße**. Die Beschriftung ist aber keine feste Größe, sondern das, was die Schriftskalierung des Telefons daraus macht: 2 px zu viel bei 100 %, 6 px bei 130 %. Die feste Höhe ist raus, die Zeile misst sich selbst
  - **Der Test hat gleich einen zweiten gefunden**, den ich sonst ausgeliefert hätte: die Abschnittsüberschrift hatte zwei unbegrenzte `Text` in einer `Row`, was bei langer Überschrift, breiter Zahl, schmalem Telefon oder großer Schrift horizontal überläuft. Titel liegt jetzt in `Expanded` und kürzt
  - `test/overflow_test.dart` baut Wochenkarte, Navigations-Pille, Knopf und Segment-Regler bei **100 % und 130 %** auf und prüft, dass das Framework nichts gemeldet hat. Eine Überlaufmeldung ist eine Exception — das ist also messbar, nicht Ansichtssache
- [x] **Trends nach Vorlage** — der Zeitraum (Week/Month/Year) ist ein **volle Breite** `AppSegmented` statt eines `SegmentedButton`, der sich neben einer Überschrift "Recap" ein Drittel der Breite für drei Beschriftungen teilte (und die Überschrift benannte den Screen, auf dem man ohnehin stand)
  - **Volumen ist jetzt eine Linie** mit gefüllter Fläche und Punkten, nicht Balken: Volumen über Zeit ist ein *Verlauf* — die Frage ist, ob es nach oben geht —, und eine Reihe Balken verlangt, dafür Höhen zu vergleichen. Die Sitzungen bleiben Balken, denn "wie viele Einheiten in Woche drei" ist eine Menge, keine Richtung
- [x] **Rang-Karte im Vorlagen-Layout** — getrackte Versalien "STRENGTH RANK" links, Tier rechts in der Akzentfarbe, 6-px-Balken, darunter eine Zeile mit Verhältnis links und Abstand zur nächsten Stufe rechts. Kein Medaillen-Icon und keine getönte Kapsel mehr: beide sagten dasselbe wie das Tier daneben
  - **Gegen die Vorlage behalten:** das 1RM und ob es *getestet* oder *geschätzt* ist. Die Vorlage konnte nicht wissen, dass die App das unterscheidet, und "ist diese Zahl gemessen oder geraten" ist das Erste, was man braucht, um dem Rang zu trauen. Drei Tests sind über das Streichen gestolpert — zu Recht
- [x] **Streak-Karte** in All-time, wie in der Vorlage: aktuell und bestes Ever nebeneinander. `longestStreak()` in `shared/utils/dates.dart` ist neu (sechs Tests, u. a. über eine Monatsgrenze und mit unsortierter Eingabe — die Menge kommt aus einer Datenbankabfrage und hat keine Reihenfolge, auf die man sich verlassen darf)
  - Die beiden Zahlen zusammen sind der Punkt: ein aktueller Streak allein ist ein Urteil — "3 Tage" nach einer Pause liest sich als Versagen —, neben einem Bestwert von 23 liest sich dieselbe Zahl als "das hast du schon mal gemacht"
- [x] **Bugfix: die Navigations-Pille verdeckte jeden schwebenden Knopf.** "Add exercises" auf dem Day Builder war vollständig darunter — gezeichnet und unsichtbar. Die Pille gehört dem Scaffold der **Shell**, der Knopf dem des **Screens**, und keins der beiden weiß vom anderen: der innere Scaffold setzte seinen Knopf 16 px über den unteren Bildschirmrand, also mitten unter die Pille. Betraf **alle acht Screens mit einem FAB**
  - `GlassScaffold` hebt ihn jetzt um das Padding an, das die Shell herunterreicht. **Nicht** im FAB-Slot gelesen — dort ist es null, der innere Scaffold entfernt es —, sondern eine Ebene höher, im `build` von `GlassScaffold` selbst. Nachgemessen statt geraten: `test/fab_clearance_test.dart` meldete vorher "der Knopf endet bei 584, unter einer Pille, die bei 514 beginnt"
- [x] **Pille zeigt nur noch Icons.** Vier Beschriftungen quer über eine beidseitig eingerückte Pille sind vier Zeilen Kleinstschrift, die mit dem Screen darüber konkurrieren — und diese vier Ziele lernt man am ersten Tag. **Versteckt, nicht entfernt:** jedes Ziel trägt seinen Namen weiter, der Screenreader sagt ihn also an. Das ist der Unterschied zwischen einer gestalterischen und einer Barrierefreiheits-Entscheidung, und ein Test hält fest, dass das Erste nicht still zum Zweiten wird
- [x] **Heatmap ist zurück auf Home** — unter der Wochenkarte. Sie steht zusätzlich in Progress → All-time: dort ist sie der lange Blick zurück, hier der kurze
- [x] **Hintergrund kräftiger** — Orbs von 0,30 auf 0,46 Spitzenalpha, und die Farbe wird vor dem Malen um 25 % gesättigt. Letzteres ist der eigentliche Punkt: niedriges Alpha *ist* eine Mischung Richtung Grund, also kommt ein Orb in der Sättigung des Akzents grundsätzlich grauer an als der Akzent. Die Obergrenze ist nicht Geschmack, sondern Lesbarkeit — die Karten sind durchscheinend, und jenseits von etwa halbem Alpha drückt das Feld durch sie hindurch und konkurriert mit den Zahlen darauf
- [x] **Die Aktionen in die Form der Vorlage gebracht**
  - **"Start workout" steht jetzt oben im Screen**, volle Breite, in der Akzentfarbe — statt als Textknopf in der AppBar. Eine Textzeile oben rechts ist der Platz für eine Aktion, bei der man sich nicht sicher ist, ob sie jemand will; das hier ist der ganze Zweck des Day Builders
  - **"Add exercises" / "Add day" / "Add exercise" sitzen mittig unten** und tragen die Knopfform des Designs statt eines Material-FAB. Mittig, weil die Navigations-Pille darunter mittig ist — ein Knopf, der sich zwischen Inhalt und Pille in die rechte Ecke duckt, liest sich wie etwas Liegengelassenes. `AppButton` hat dafür `expand: false` bekommen: ein schwebender Knopf polstert seine Seiten selbst, ein Knopf im Fluss holt sich seine Breite aus dem Layout
  - `test/fab_clearance_test.dart` prüft jetzt auch, dass er mittig steht. **Der Test hat zuerst mein eigenes Gerüst gemessen** statt der App — er baute noch einen Material-FAB in der Ecke —, also misst er jetzt dieselbe Anordnung, die die Screens benutzen
- [x] **Hintergrund noch kräftiger** — 0,46 → **0,62** Spitzenalpha, Sättigung ×1,25 → **×1,45**. Bei 0,62 ist ein Orb, der hinter einer Karte vorbeizieht, *in* der Karte sichtbar — genau das ist der Effekt —, ohne dass die Zahlen darauf ihre Kante verlieren. Jenseits von etwa drei Vierteln fängt das an
  - **Noch offen aus der Vorlage:** die Rekord-Liste ("Records") bräuchte eine neue Abfrage über persönliche Bestleistungen — das ist Daten-, keine Gestaltungsarbeit. Und der More-Tab benutzt Material-Icons statt des gezeichneten Satzes der Vorlage

### Phase 18 — Release 🔥
- [x] **Bugfix: Stangenauswahl blieb wirkungslos** — man tippte eine andere Stange an, die Zahl bewegte sich nicht. Der `PlateStacker` hatte eine **Momentaufnahme** der Übung bekommen (beim Öffnen des Dialogs), also landete die Auswahl in der Datenbank und das Widget sah sie nie. Liest die Zeile jetzt **live** über `exerciseProvider`
  - Dabei eine Design-Frage entschieden: solange keine Scheibe angetippt wurde, wird der Stapel aus dem Zielgewicht *abgeleitet* — Stange auf "None" stellen hätte also 40/Seite still in 50/Seite umgerechnet, um bei 100 kg zu bleiben. Die Scheiben sind aber physisch, sie liegen am Gerät und sind nicht gewandert, weil man eine Einstellung korrigiert hat. Jetzt wird der angezeigte Stapel eingefroren und **die Summe** ändert sich — genau die Antwort, wegen der man hingegangen ist
  - Zwei Tests: die Zahl auf dem Bildschirm *und* der gemeldete Wert. Nur das eine zu prüfen hätte den Fall "richtig angezeigt, falsch geloggt" durchgelassen
- [x] **Ein Rad für die ganze App** — beim Ausrollen kam heraus, dass es **drei** Implementierungen gab: `shared/widgets/number_wheel.dart`, eine private Kopie im Sets-&-Reps-Dialog und eine dritte im neuen Picker-Sheet. Alle mit leicht anderer Elementhöhe, Highlight-Farbe und Polsterung
  - Kaputt war dadurch nichts — genau deshalb hat es überlebt. Drei Bedienelemente in einem Kostüm fallen erst auf, wenn zwei davon gleichzeitig auf dem Schirm sind
  - Jetzt eins, mit dem neuen Look: eigene abgerundete Fläche (wie `AppPickerField`), zentrierter Wert in der Akzentfarbe und fett, Nachbarn gedimmt. Sets, Reps, Rep Range, beide Gewichtsräder und die Picker-Sheets teilen es sich
  - **Feinschliff obendrauf:** das Rad wird an beiden Enden ausgeblendet (`ShaderMask`) statt hart abgeschnitten — eine harte Kante liest sich als beschnittene Liste, das Ausblenden macht daraus einen drehenden Zylinder. Highlight-Band zusätzlich umrandet (auf den dunklen Themes war 13 % Füllung allein kaum zu sehen), zentrierter Wert etwas größer, und **haptischer Klick pro Rastung** — das Gefühl einer vorbeiziehenden Kerbe ist im Studio das, was einem sagt, dass sich der Wert bewegt hat, ohne hinzusehen
  - Ziffern in `tabularFigures`, damit beim Drehen nichts seitlich springt
  - Das Sheet zeigt den gewählten Wert zusätzlich **groß über** der Walze: im Rad steht er klein zwischen seinen Nachbarn, hier ist er die Antwort
  - `AppPickerField` hat eine haarfeine Akzent-Umrandung und ein getöntes Glyph-Quadrat bekommen (dieselbe Form wie `AppGlyph` in den Kartenlisten) — ohne Rand verschmolz das Feld auf den flacheren Themes mit der Fläche dahinter, und ein Bedienelement, dessen Kante man nicht sieht, sieht nicht antippbar aus
  - `test/one_wheel_test.dart` liest den Quellcode und schlägt fehl, sobald irgendwo außer in `number_wheel.dart` wieder ein `ListWheelScrollView` gebaut wird — plus die Gegenprobe, dass das gemeinsame Rad auch wirklich von mehreren Stellen importiert wird. Eine Implementierung, die niemand benutzt, würde die erste Regel erfüllen und nichts bedeuten
- [x] **Gemeinsamer Picker-Stil** — `shared/widgets/app_picker.dart`: ein abgerundetes Feld (Label + aktuelle Antwort), das ein Sheet öffnet. `showNumberPicker` für Zahlen, `showOptionPicker` für Auswahl
  - Sheet statt Dropdown-Menü: die Listen hier sind lang (fünfzig Reps, hundertzehn Zentimeter), und ein Menü, das über den Bildschirmrand hinausläuft, ist schlimmer als eins, das gar nicht aufgeht. Ein Menü verankert sich außerdem am Auslöser und öffnet neben einem Element am Rand halb außerhalb
- [x] **Größe und Alter ergänzt** — im Onboarding auf der Gewichtsseite, änderbar unter **Settings → You**
  - **Keine Schema-Änderung nötig.** In der Frage hatte ich v23 angekündigt; Profilangaben passen aber in die vorhandene Key/Value-Settings-Tabelle, in der Name, Einheit und Akzent schon liegen — gleiches Ergebnis, kein Migrationsrisiko
  - **Alter wird als Geburtsjahr gespeichert, nie als Zahl.** Eine abgelegte "31" ist am nächsten Geburtstag falsch und nichts in der App würde es je merken. Ein Test rechnet nach, dass sich das Alter aus dem Jahr ableitet
  - Größe folgt der **Gewichtseinheit**: cm für kg-Nutzer, Fuß/Zoll für lbs-Nutzer. Wer in Pfund denkt, denkt in Fuß — eine zweite Einstellung dafür wären zwei Wege, dasselbe zu sagen. Ein Test läuft den ganzen Bereich ab und prüft, dass nie `12″` herauskommt
  - Werte außerhalb des Bereichs lesen sich als "nicht gesetzt" statt als Anzeige — eine handgeschriebene Datenbank soll keine 7 cm auf den Bildschirm bringen
- [x] **Rest-Timer moderner** — schwebende, abgerundete Karte statt vollbreiter Leiste mit eckigen Kanten. Er ist etwas Vorübergehendes *auf* der Session; angeschweißt an die AppBar las er sich wie feste Chrome
  - Countdown als **Ring** um sein eigenes Icon statt der 4-px-Linie am unteren Rand — die konnte man komplett übersehen, der Ring ist im selben Blick wie die Zahl. Voll (nicht leer) wenn die Pause vorbei ist: der geschlossene Ring ist die Ziellinie
  - Rand und Fläche leuchten am Ende in der Akzentfarbe auf, animiert, damit es auch registriert wird, wenn man eine Sekunde zu spät hinsieht. **+30s** als getönte Pille — das ist das Element, nach dem man mitten im Satz greift, oft ohne richtig hinzusehen
- [x] **Scheibenrechner: Stange pro Übung, "None" als echte Option** — Schema v22, `Exercises.barWeightKg` (nullable, in Kilogramm)
  - **"Plate-loaded" heißt nicht "an einer Langhantel".** Hackenschmidt, Beinpresse, plattenbeladene T-Bar: Scheiben drauf, aber da ist keine 20-kg-Stange — der Rechner hat trotzdem eine addiert, also war die Summe an genau diesen Geräten immer um eine Stange falsch
  - `null` = Gym-Standard, `0` = keine Stange. Die Unterscheidung trägt das ganze Feature
  - **Umgestellt wird dort, wo man es merkt:** im Plate Stacker beim Loggen eines Satzes, also vor dem Gerät stehend. Nicht mehr im Plate-Calculator-Tab — die Stange gehört zum Gerät, nicht zum Studio, und eine gemeinsame Einstellung konnte immer nur für eines von beiden stimmen
  - **`barWeightKg` steht bewusst nicht in den Seed-Companions.** `insertAllOnConflictUpdate` schreibt bei jedem Start jede eingebaute Zeile neu — aber nur die Spalten, die die Companions führen. Ein Test seedet zweimal nach dem Setzen und prüft, dass die Beinpresse nicht still wieder eine 20-kg-Stange bekommt
  - Beim Melden des Gewichts las `_update` noch den **globalen** Bar-Provider, während die Anzeige darüber schon den der Übung nutzte — das hätte ein um eine Stange abweichendes Gewicht geloggt. Beim Durchziehen gefunden
- [x] **Plate-Calculator-Eintrag unter More entfernt** (Kachel und Route). Erreichbar bleibt er, wo er gebraucht wird: Icon in der AppBar der laufenden Session und "What plates is that?" im 1RM-Rechner — beide pushen ihn, statt zu routen
- [x] **"Apply to every exercise" im Sets-&-Reps-Dialog** (Day Builder) — schreibt Sätze, Reps bzw. Rep Range *und* Aufwärmsätze auf alle Übungen des Tages. Genau der Fall, den der Dialog pro Übung am schlechtesten bedient: ein ganzer Tag auf 3×8, einzeln durchgeklickt
  - **Eigener Button** neben Save: `Cancel · Save to all 3 · Save`. Kein Zwischenschritt, ein Tap
  - Die **Zahl steht auf dem Button** ("Save to all 3"), weil das die einzige Bedienung hier ist, die Zeilen anfasst, die man nicht sieht — mehrere können aus dem Bild gescrollt sein. "Save to all" allein verschweigt, wie viel sich gleich ändert. Danach eine Snackbar mit dem, was wirklich passiert ist
  - Bewusst ein **TextButton** neben dem gefüllten Save: beide sind jetzt ein Tap, also hält den weitreichenderen nur noch davon ab, versehentlich getroffen zu werden, dass er sekundär aussieht und sagt was er tut
  - Bei **einer** Übung im Tag gar nicht erst angeboten: er täte exakt dasselbe wie Save und würde nur einen Moment Zweifel über den Unterschied säen
  - `updateAllPlannedExercises` ist **ein** SQL-Statement, keine Schleife über `updatePlannedExercise` — sonst existierte der Tag kurz halb aktualisiert und die beobachtende Liste würde sichtbar durchrieseln. Auf `dayId` begrenzt; ein Test hält fest, dass andere Tage desselben Splits unangetastet bleiben
  - **Dabei einen echten Layout-Fehler gefunden:** mit der zusätzlichen Zeile lief der Dialog um 22 px über — auf dem Telefon der gelb-schwarze Overflow-Balken. `AlertDialog` scrollt seinen Inhalt nicht von selbst, es beschneidet ihn. Jetzt in einer `SingleChildScrollView`, was auch bei großer System-Schriftgröße trägt
- [x] **Muscles-Tab → Stats-Tab** (`/stats`, `features/stats/`). Die Körperkarte bleibt, bekommt aber Gesellschaft: ein ganzer Bottom-Nav-Slot hat vorher *eine* Frage beantwortet, während das, was man von einem Stats-Screen erwartet — wie stark bin ich, wie viel habe ich gemacht — zwei Taps tief unter More lag
  - Reihenfolge bewusst: **Rang zuerst** (die Schlagzeile), **Karte danach** (das Bild), **Summen zuletzt** (der lange Blick zurück)
  - **Rang-Embleme, farbig** — gezeichnetes Sechseck pro Stufe (`rank_emblem.dart`, `CustomPainter`), kein Asset: nimmt die Stufenfarbe an, skaliert auf jede Größe, kostet nichts im APK
    - Farben in `tier_style.dart`, **fest kodiert und das ist hier richtig** — zusammen mit den Wettkampfscheiben die einzigen zwei Stellen. Eine Stufe ist eine Medaille: Bronze, Silber, Gold, Platin bedeuten etwas, bevor man das Label liest. Mit der Akzentfarbe eingefärbt hätten alle fünf denselben Farbton und wären damit genau das los, wofür sie da sind
    - **Beginner ist bewusst keine Medaille**, sondern neutrales Schiefergrau. Bronze zu erreichen soll sich wie der erste Schritt nach oben anfühlen, nicht wie der Verlust einer Farbe, die man schon hatte
    - Dazu **Pips**, eins bis fünf. Die Farben tragen die Reihenfolge für alle, die Medaillen kennen — aber "ist Platin über Gold?" ist eine echte Frage, und die Punkte beantworten sie ohne Legende
  - **Gesamt-Rang = der schwächste gerankte Lift, nicht der stärkste.** Ein starkes Kreuzheben darf niemanden zum "Advanced" krönen, während sein Überkopfdrücken "Novice" ist. Die ehrliche Ein-Wort-Antwort auf "wie stark bin ich" gibt der schwächste große Lift — und sie zeigt gleich, woran zu arbeiten ist. Der beste steht daneben
  - **Weitere Stats, all-time** (`training_totals.dart`): Workouts, Sätze, trainierte Zeit, bewegtes Volumen, Trainingstage, aktuelle Streak. **Nichts davon ist ein gespeicherter Zähler** — alles wird aus den geloggten Sätzen und den Aktivitätsminuten neu berechnet. Ein Zähler wäre eine weitere Sache, die man beim Löschen eines Workouts nachziehen muss, und er würde still auseinanderlaufen, wenn das mal schiefgeht
    - Beide Quellen werden ohnehin schon auf heißen Pfaden beobachtet (Recap-Join, Aktivitätsraster) → keine neue Datenbankarbeit
    - Eine Lebenszeit-Volumenzahl hat kein Gefühl — 184.000 kg sagen nichts. Darum ein Vergleich: "das sind 1,4× ein Londoner Bus". Unterhalb des kleinsten Vergleichs steht **nichts** statt "0,4 Konzertflügel"
    - Gar nichts geloggt → gar keine Kachel, statt einer Reihe Nullen als erster Eindruck
  - [x] **Fatigue ist jetzt fest rot**, nicht die Akzentfarbe. Beide Lesarten teilen sich eine Körperkarte — in derselben Farbe war es zweimal dasselbe Bild, und ein Blick konnte "das habe ich hart trainiert" nicht von "das ist noch nicht erholt" unterscheiden. Die Untertitel sagten es, aber niemand liest einen Untertitel, um eine Farbe zu deuten
    - Rot ist außerdem der eine Farbton, den man hier niemandem erklären muss: wund, nicht bereit, Finger weg
    - Keine der sechs Akzentoptionen ist rot, also liest es sich für die meisten klar anders. **Garantiert ist das nicht** — Pink und Orange sind die nächsten Nachbarn, und ein Theme kann einen eigenen Akzent vorschlagen. Wer Pink gewählt hat, bekommt zwei warme Töne statt zwei identischer; das ist der bessere Kompromiss, als ihm den gewählten Akzent zu verbieten
    - `tintMuscles`' Parameter heißt jetzt `heatColor` statt `accent` — er stimmte nicht mehr. Contrast-Modus ignoriert ihn weiterhin, sonst wäre er wieder eine Heatmap
    - Eigener Test: das ist ein Fehler, der **unsichtbar** wäre. Eine akzentfarbene Fatigue-Karte sieht für sich völlig richtig aus; falsch ist sie erst neben der Volumen-Karte
  - `MuscleMapScreen` gelöscht statt liegengelassen; sein Test zeigt jetzt auf `StatsScreen`. **Der Test lief zunächst nicht durch** — der neue Screen zeigt Gewichte, also liest er die Einheiten-Einstellung, also öffnete er eine Datenbank, also blieb ein Drift-Timer offen. Genau die Falle, vor der `support/default_accent.dart` warnt
- [x] **Navigationsleiste von sechs auf fünf Tabs** — **Progress ist unter More gezogen** (`/more/progress`, mitsamt Fotos, Messungen, Verlauf und Exercise-Charts). Sechs Ziele haben die Labels auf unlesbar zusammengedrückt; Progress ist von den sechsen das, was man *nachschaut* statt im Training zu greifen
  - Verlinkt von **More → Progress** (ganz oben in der Liste) und von einer Karte **unten auf dem Home-Tab** — nach Recap und Jahresraster, also genau an der Stelle, an der einem "zeig mir die echten Zahlen" einfällt
  - `go` statt Push für den Home-Link: der Screen gehört jetzt wirklich zum More-Branch, und ein Push darüber würde den falschen Tab markiert lassen
  - **Der Smoke-Test hat den Wegfall nicht bemerkt** — er suchte nach dem *Text* "Progress", und den liefert jetzt die neue Home-Karte. Liest die Destinations der `NavigationBar` direkt aus
  - Neuer `test/router_links_test.dart`: liest den Routenbaum des Routers aus und prüft **jedes `context.go('…')` im gesamten Quellcode** dagegen. Ein zurückgebliebener Pfad kompiliert sauber, besteht alle anderen Tests und fällt erst um, wenn ein Nutzer draufdrückt — go_router wirft zur Navigationszeit, nicht zur Bauzeit. Sechs Pfade auf einmal umzubenennen war genau der Anlass
- [x] **Übung im laufenden Workout antippbar** — öffnet denselben Detail-Screen wie die Bibliothek (Animation, Muskeln, Rang). Mitten im Satz ist genau der Moment, in dem man eine Bewegung nachschlagen will
  - **Gepusht, nicht geroutet** — `go('/exercises/<id>')` würde auf den Exercises-Tab wechseln und einen mitten im eigenen Workout stranden lassen. Gleiche Begründung wie beim Scheibenrechner; ein Test mit `NavigatorObserver` hält fest, dass es wirklich ein Push ist, weil man das auf dem Bildschirm nicht sieht
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
  - [x] **Überall wo Übungen gelistet werden**, nicht nur in der Bibliothek: Übungs-Picker (Day Builder), Day Builder selbst, aktives Workout und der Progress-Tab. Der Picker profitiert am meisten — dort sucht man eine Übung, die man schon im Kopf hat, und eine Form trifft man schneller als einen Namen
    - Nach `shared/widgets/exercise_thumbnail.dart` gezogen (mit `previewCandidates` nach `shared/utils/`), sobald drei Features es brauchten. `features/workout` hätte sonst `features/exercises` importieren müssen — gleiche Entscheidung wie vorher bei `LifterSex`
    - Die drei `CircleAvatar` in Workout-/Day-Builder-Screens sind damit zu abgerundeten Quadraten geworden. Bewusst: `AppGlyph` hat das abgerundete Quadrat app-weit als Form für führende Elemente gesetzt, und Kreise *und* Quadrate für dieselbe Sache nebeneinander ist genau die Uneinheitlichkeit, aus der `app_card.dart` rausführen sollte
    - Größe ist jetzt ein Parameter (`defaultThumbnailSize`, 42) statt einer Konstante, damit Radius und Icon mitskalieren
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
