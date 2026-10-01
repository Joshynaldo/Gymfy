# Localisation (English + German)

**ARB key convention: `<area><Part><Purpose>`**, lowerCamelCase ASCII
(`l10n_test.dart` checks the shape).
- `<area>` is the `lib/features` folder in camelCase (`home`, `settings`,
  `muscleMap`, `planShare`, `workoutNotification` …); `shell` for `lib/app`
  (nav bar, router); `shared` for `lib/shared` widgets and utils; the type
  name for a shared enum or model (`muscle`, `equipment`, `setType`,
  `lifterSex`, `measurementField`, `goalKind`, `theme`, `bodyProfile`,
  `notification`); `common` only for words that mean exactly the same
  everywhere (`commonCancel`, `commonSave`, `commonDone`, `commonNotSet`,
  `commonToday` …).
- `<Part>` is the screen, widget or section, without `Screen`/`Card`:
  `homeToday…`, `homeLastWorkout…`, `settingsRestTimer…`.
- `<Purpose>`: `Title`, `Subtitle`, `Label`, `Hint`, `Tooltip`, `Message`,
  `Caption`, `Action`, `Semantics`, `…Failed` for errors. Examples:
  `homeTodayRestTitle`, `settingsDefaultRestSubtitle`,
  `muscleMapShowHeatmap`, `helpOpenLinkFailed`.
- Counts are one ICU plural named for what is counted (`homeWeekWorkouts`:
  `{count, plural, =1{1 workout} other{{count} workouts}}`); grammatical
  variants are an ICU select (`settingsBodyDiagramSubtitle`, because German
  declines "Männliches/Weibliches"). Never build a sentence by `+` or by
  splicing a translated word into another one.
- Every placeholder is declared with its type in `app_en.arb`. Numbers and
  dates that the app formats itself go in pre-formatted as `String`.

**Setup.** `l10n.yaml`, `lib/l10n/app_en.arb` (template — its values are the
English strings verbatim, so English widget tests keep finding them) and
`app_de.arb`. The generated `lib/l10n/app_localizations*.dart` are
**committed**, like every `.g.dart`; `flutter gen-l10n` regenerates them, and
`flutter pub get` / `test` / `build` do too (`generate: true`).
- Widgets: `context.l10n.someKey` (`lib/l10n/l10n.dart`). Never
  `AppLocalizations.of(context)!`: most widget tests pump a bare
  `MaterialApp` with no delegates, and `context.l10n` falls back to English
  there.
- No `BuildContext` (notifications, background sync): `ref.read(
  appLocalizationsProvider)` in `lib/l10n/app_language.dart`, or
  `englishLocalizations` for something that must stay English.
- Language: `app_language` setting, Settings → Language. `system` follows the
  phone (German phone → German, any unsupported language → English).
  `appLocaleProvider` feeds every `MaterialApp` in `main.dart`.
- Formatting: the helpers in `shared/utils/format.dart`, `units.dart`
  (`formatWeightUnit`, `formatWeightIn`, `formatLoggedSet`), `weekday.dart`
  and `home/data/recap.dart` (`bucketLabel`) take an optional `l10n:` — pass
  `context.l10n`. Without it they print the old English. German: dates from
  intl's CLDR data ("3. Okt. 2026", "Fr., 25. Sept."), numbers "62,5" and
  "41.040". Leave `l10n` off for files (CSV, backups) and for a value going
  back into a text field the user edits (`parseWeight` reads "1.040" as 1.04).
  `formatDuration` ("1 h 05 min") is the same in German and takes none.
- Enum labels: `.label` stays English (data, exports); on screen use
  `.localizedLabel(context.l10n)` — `Equipment`, `SetType`, `LifterSex`,
  `MeasurementField`, `GoalKind`, `RecapPeriod`, `AppTheme` (plus
  `localizedDescription`). Muscles: `muscleLabel(id, l10n: context.l10n)`;
  search: `matchesExerciseSearch(..., l10n: context.l10n)` so "Brust" finds
  chest work.
- Not translated, on purpose: exercise names (seed data), the editor theme
  names (Tokyo Night, Dracula, Catppuccin Mocha, Gruvbox, Hyper), the
  feedback mail's subject, units (`kg`, `lbs`, `cm`, `min`, `h`).
- Tests: `l10n_test.dart` fails on a key missing from either file, on
  mismatched placeholders and on a German value that is a copy of the
  English (add genuine ones to `_sameInGerman`). German widget test:
  `MaterialApp(locale: const Locale('de'), localizationsDelegates:
  AppLocalizations.localizationsDelegates, supportedLocales:
  AppLocalizations.supportedLocales)`; a pure unit test of German dates calls
  `initializeDateFormatting('de')` (`package:intl/date_symbol_data_local.dart`)
  first. Add your densest screens to `german_layout_test.dart`.

**Translated so far:** `lib/main.dart`, `lib/app`, `lib/shared` (widgets,
format/units/weekday helpers, enum and muscle labels, rest-timer
notifications), and the features `settings`, `more`, `help`, `onboarding`,
`home`, `muscle_map`, `workout`, `workout_notification`, `overload`,
`plates`, `plan_share`, `programs` and `exercises` (screens and widgets —
not the exercise names in the seed and catalogue data). That includes the
panels those features put on Settings (plates, overload, logging, rest
length) and onboarding's overload page. **Still English:** `backup`,
`calculator`, `calendar`, `calories`, `data_export`, `goals`,
`health_connect`, `import`, `progress`, `reviews`, `stats`, `wear`.

What the second batch added, for whoever translates the rest:
- More helpers take an optional `l10n:` and print the old English without
  it: `formatPercent` (German "72,5 %", with a no-break space),
  `formatPlate`/`formatBar` (leave `formatPlate` English for storage —
  `encodePlates` joins with commas), `formatRecordValue`/`describeRecord`,
  `describeSetPosition`/`describeNextNumbers` (the watch payload in
  `wear_sync.dart` still calls them without one), `programFacts`,
  `blockWeekLabel`, `exerciseTarget`, `filterOptionsFor` (pass the same
  `l10n` as `matchesExerciseSearch`, or a German query empties the chips),
  `buildPlanPdf`, `workoutNotificationFrom`.
- More enums gained `localizedLabel`: `RecordKind`, `OverloadMode`,
  `EffortRatingMode`, `ProgramLevel`, `MuscleGroup`. Bundled programmes have
  `localizedSummary`/`localizedDescription`; their names (which are also the
  split names inside the files) and the day names in the files stay English,
  like exercise names.
- `PlanFormatException` carries a `PlanFormatProblem` and words it with
  `describe(l10n)`; `message` is the English.
- The ongoing workout notification gets every word from Dart, button labels
  and channel name included (`WorkoutNotificationLabels`); Kotlin keeps only
  an English fallback. `WorkoutNotificationSync` watches
  `appLocalizationsProvider`, so a test container without a database must
  override it (`overrideWithValue(englishLocalizations)`).
- The keypad in the log sheet and the warm-up field show the language's
  decimal separator; the value typed stays a point internally.
- The printed plan uses the PDF's built-in Helvetica, which has Latin-1
  only: `planSharePdf…` messages may use umlauts and ß but no en dash or
  curly quotes (`localized_workout_test.dart` checks).
- German layout tests for these screens: `german_workout_layout_test.dart`.
  The test font draws every glyph a full em wide, so it overstates German
  widths — but four rows it flagged were fixed anyway rather than worked
  around: the warm-up button is capped so Log set keeps its room, the day
  builder's superset caption wraps, the plate total's label gives way to the
  number, and the training block sheet's buttons sit in an `OverflowBar`.

**German glossary** — du-form, the words German lifters use, the same word
everywhere: workout → Training (pl. Trainings) · set → Satz/Sätze · rep →
Wiederholung, short Wdh. · warm-up set → Aufwärmsatz · working set →
Arbeitssatz · drop set → Dropsatz · failure → Bis Versagen · rest → Pause ·
rest timer → Pausentimer · rest day → Ruhetag · exercise → Übung · exercise
library → Übungsbibliothek · split → Split · programme → Programm · plan →
Plan/Trainingsplan · weight → Gewicht · bodyweight → Körpergewicht · volume →
Volumen · PR → PR/Bestleistung · 1RM → 1RM · progressive overload →
Progressive Overload · deload → Deload · strength rank → Kraftlevel ·
strength standards → Kraftstandards · muscle map → Muskelkarte · body diagram
→ Körperdiagramm · plates → Hantelscheiben (short: Scheiben) · plate
calculator → Scheibenrechner · bar → Stange · log (verb) → loggen · theme →
Design · accent → Akzentfarbe · not set → Nicht angegeben · superset →
Supersatz · top set → Topsatz · rep range → Wiederholungsbereich · warm-up
ramp → Aufwärmschema · working weight → Arbeitsgewicht · RPE/RIR → RPE/RIR
· training block → Trainingsblock · deload week → Deload-Woche · beginner /
intermediate → Einsteiger / Fortgeschritten · equipment → Ausrüstung ·
custom (exercise) → Eigene · personal record → Bestleistung. Set-type
badges: A (Aufwärmsatz), D (Dropsatz), V (Versagen). English's spaced em
dash becomes a spaced en dash (" – ").

# Schema v26: what it added and the rules around it

Every schema change for backup, logging, sessions and programs landed in **one
migration (v25 → v26)**; the features themselves were then built without
touching a Drift table. All of it is merged now, and this file stays as
developer notes: what each new column means, which helpers to reuse, and the
rules that must keep holding. Any further schema change needs its own
migration and a `schemaVersion` bump, and the backup format follows it
(see `lib/features/backup/data/backup_format.dart`).
Small app-wide preferences go in the key-value `AppSettings` table, which needs
no migration (see "Settings keys" below).

## New and changed columns

### `logged_sets` (lib/shared/models/workout_log.dart)
| column | type | meaning |
|---|---|---|
| `set_type` | TEXT NOT NULL, default `'normal'` | `SetType` slug: `warmup`, `normal`, `drop`, `failure`. **Replaces `is_warmup`, which is gone.** v25 warm-ups became `warmup`, everything else `normal`. |
| `rpe` | REAL NULL | RPE, 1–10 in 0.5 steps. Null = not rated. |
| `rir` | INTEGER NULL | Reps in reserve. Null = not rated. Write only the one the user chose to log (RPE *or* RIR), never a derived guess at the other. |

### `workout_exercises` (lib/shared/models/workout_plan.dart)
| column | type | meaning |
|---|---|---|
| `superset_group` | INTEGER NULL | Same non-null value + adjacent in day order = one superset. Only equality within a day matters. Null = standalone. |
| `target_percent` | REAL NULL | Working-set target as % of estimated 1RM, 0–100 scale (75 = "@ 75 %"). Null = no % target. |
| `position` | (existing) | Now actually used: plan order is `position, id`. `watchDayExercises` and plan sharing already order this way; all old rows are 0, so old order = insertion order. Reordering writes `position`. |

### `splits`
| column | type | meaning |
|---|---|---|
| `block_weeks` | INTEGER NULL | Training weeks per block before one deload week. Null = no blocks. |
| `deload_percent` | REAL NULL | Deload-week load as % of working weight (0–100). Null = 90 (`defaultDeloadPercent`). |
| `block_started_at` | DATETIME NULL | Day week 1 of the block began. Null until a block is set up. |

### New table `session_exercises` (workout_log.dart)
A session's own running order. Columns: `id`, `session_id` (cascade delete),
`exercise_id`, `position` (sort, ties by id), `workout_exercise_id` (nullable
plan slot, **set null** when the slot is deleted).
- `SessionRepository.startSession(dayId:, name:)` copies the day's plan in
  (positions 0..n-1, linked to their slots) in the same transaction.
- `SessionRepository.startFreeSession(name:)` creates a session with
  `dayId == null` and no rows.
- The v26 migration backfilled rows only for **in-progress** sessions.
  Finished pre-v26 sessions have no rows; history is read from `logged_sets`.
- Targets for an entry come from `planned` (the linked `WorkoutExercise`); an
  added exercise has `planned == null` and needs UI defaults (3 sets × 10).
- A swap rewrites `exercise_id` and keeps `workout_exercise_id`, so targets
  carry over. "Save swap to plan" = also update that `workout_exercises` row.
- `ExerciseRepository.hasHistory` counts session_exercises, so a custom
  exercise in a running order is archived instead of deleted.

## Helpers added (use these, don't re-implement)
- `lib/shared/models/set_type.dart`: `enum SetType { warmup, normal, drop, failure }`
  with `label`, `countsTowardStrength`, `isWarmupPhase`, `SetType.parse(raw)`
  (unknown → `normal`), and `const strengthExcludedSetTypes = ['warmup', 'drop']`.
  Re-exported by `session_repository.dart`.
- `session_repository.dart`:
  - `isWorkingSet(LoggedSet)` → `set.type.countsTowardStrength`. The one rule.
  - `extension LoggedSetType on LoggedSet`: `type`, `isWarmup` (warm-up
    *phase* only, not drop), `effectiveRir` (rir, else `floor(10 - rpe)`, ≥ 0).
  - `logSet(..., SetType setType = SetType.normal, double? rpe, int? rir)`.
  - `setSetType(id:, type:)` (renumbers phases); `setWarmup` delegates to it.
  - `watchSessionExercises(sessionId)` → `List<SessionExerciseEntry>`
    (`row`, `exercise`, `planned?`), ordered by `position, id`.
- `lib/features/workout/data/supersets.dart`: `supersetBlocks(list, groupOf)`
  and `restsAfter(list, item, groupOf)` — generic, works for
  `PlannedExercise` (`(p) => p.entry.supersetGroup`) and `SessionExerciseEntry`
  (`(e) => e.planned?.supersetGroup`).
- `lib/features/overload/data/training_block.dart`: `trainingBlockWeek(...)`,
  `trainingBlockWeekForSplit(split, on)` → `TrainingBlockWeek(week, blockWeeks,
  cycle, isDeload)` or null; `deloadPercentFor(split)`; `defaultDeloadPercent`.

## Rules that must keep holding
- **Strength filter.** e1RM, PRs, progress charts, overload suggestions and live
  PR detection use only sets where `isWorkingSet` is true. SQL:
  `loggedSets.setType.isNotIn(strengthExcludedSetTypes)`. Never
  `setType.equals('normal')` (that would drop failure sets and unknown slugs).
- **Decision: drop sets are excluded like warm-ups** (they are lighter because
  you are fatigued, not because you got weaker). Failure sets count.
- Volume, muscle map, recap charts: count **every** set type.
  `muscle_fatigue_repository` keeps its old rule (excludes warm-ups only).
- Numbering: warm-ups numbered in their own phase; normal/drop/failure share
  the working phase (`isWarmup` decides). `_renumber` already does this.
- Plan sharing (`plan_share`) reads **only** plan tables. Adding
  `supersetGroup` / `targetPercent` to `PlanDocument` is expected (P2/P3), as
  optional JSON keys so older `.gymfy` files still import.
- No network packages, no INTERNET permission. Units: everything stored in kg.
- No hardcoded hex; accent via `ref.watch(accentColorProvider)`.
- Every new behaviour gets tests; `flutter analyze` clean, `flutter test` green.
- Commit messages: no Claude mention / co-author trailer.

## Settings keys (AppSettings)
- `app_language`: `system` (default; also what a missing row means) | `en` |
  `de` — see Localisation above.
- `effort_rating_mode`: `off` (default) | `rpe` | `rir`.
- `auto_backup_mode`: `off` (default) | `weekly` | `after_workout`;
  `auto_backup_folder` (path/URI); `auto_backup_last_at` (ISO-8601);
  `auto_backup_last_error` (last failed automatic backup, shown on the screen).
- Warm-up calculator ramp: `warmup_ramp_percents` (e.g. `40,60,80`).
- `workout_notification`: `true` (default) | `false` — the ongoing workout
  notification (Android only, `lib/features/workout_notification/`).
- Health Connect (`lib/features/health_connect/`, no schema change):
  `health_connect_write_workouts`, `health_connect_read_bodyweight`
  (`true`|`false`, both off by default); `health_connect_write_since`
  (ISO-8601, workouts finished after it are written automatically, older ones
  only by the backfill); `health_connect_written_sessions` (JSON
  `{sessionId: clientRecordId}`, how deletions find their record);
  `health_connect_weight_imports` (JSON `{"yyyy-mm-dd": {id, kg}}`, how a
  typed or edited bodyweight is told apart from an import);
  `health_connect_weight_checked_at` (ISO-8601); `health_connect_last_error`.
  These live in `app_settings`, so a backup restore brings back the ledgers
  of that moment: records written after the backup are not deleted from
  Health Connect by the restore.

## Feature areas and the files they touched
**P1 Backup & restore** — new `lib/features/backup/` (data: `backup_format.dart`,
`backup_repository.dart`; screen in More/Settings). Back up **every** table in
`AppDatabase.allTables` with ids, plus `schemaVersion` (26). Restore = one
transaction: validate version ≤ current, migrate older payloads (e.g. v25
`is_warmup` → `set_type`), delete all rows, insert with ids, foreign keys on.
Auto-backup writes `.gymfy-backup` into a user-picked folder (SAF / file
picker, no network). Touches settings_screen / more screen for entry points.
Optionally fix `data_export` CSV/JSON to emit the set type instead of a
warm-up bool (`ExportSet.isWarmup`), not required.

**P2 Logging** — `workout/widgets/log_set_sheet.dart` (set type picker
replacing the warm-up toggle, RPE/RIR input when `effort_rating_mode` ≠ off),
`workout/screens/active_workout_screen.dart` (switch the exercise list from
`dayExercisesProvider` to `watchSessionExercises`; add / swap / reorder /
remove; superset display; rest only when `restsAfter`; PR alert),
`workout/screens/workout_summary_screen.dart` (PR list),
`workout/screens/day_builder_screen.dart` (superset grouping, reorder),
`session_repository.dart` (session-exercise mutations: add, swap, move,
remove), `workout_repository.dart` (reorder, superset grouping, save swap to
plan), `overload/` (may read `effectiveRir`), new warm-up calculator under
`workout/` using `plates/data/plate_math.dart`, logging sets as
`SetType.warmup`. Free workout entry point: home / workout tab.
Active workout is the hotspot: keep edits there small and well-separated.

**P3 Programs** — `assets/programs/*.gymfy` (+ pubspec asset entry) and a
picker that feeds the existing plan import (`plan_share`); `plan_document.dart`
(optional `supersetGroup`, `targetPercent`); `day_builder_screen.dart`
(% of 1RM field); weight resolution = `target_percent / 100 ×` best e1RM
(`bestEstimatedOneRm` in progress_repository, or tested 1RM), rounded with the
existing plate rounding; split settings UI for `block_weeks`,
`deload_percent`, `block_started_at`; overload/active workout apply
`deloadPercentFor` during a deload week from `trainingBlockWeekForSplit`.

# Schema v27: goals

One new table, nothing else changed (`if (from < 27)` in app_database.dart,
transactional and safe to rerun like v26). Backups: `_from26` in
backup_format.dart adds an empty `goals` table to a v26 payload, because a
restore refuses a backup with a table missing.

### New table `goals` (lib/shared/models/goal.dart)
| column | type | meaning |
|---|---|---|
| `kind` | TEXT | `GoalKind` slug: `lift`, `frequency`, `bodyweight`. `GoalKind.parse` returns null for an unknown slug; such goals are skipped, never guessed. |
| `exercise_id` | TEXT NULL → exercises, **cascade** | Lift goals only. |
| `target` | REAL | kg for lift/bodyweight, workouts per week for frequency. |
| `start_value` | REAL NULL | Best working weight / latest bodyweight when the goal was set. Progress runs from here; for bodyweight it also decides cut vs gain. |
| `deadline` | DATETIME NULL | Midnight. Never set on frequency goals. |
| `created_at` | DATETIME | Bodyweight goals only count weigh-ins from this day on. |
| `celebrated_at` | DATETIME NULL | When the user dismissed the celebration. The only stored part of "reached". |
| `archived_at` | DATETIME NULL | Off Home and the active list, kept for the record. |

**Reached is derived, never stored** (`features/goals/data/goal_progress.dart`):
- Lift = heaviest *working* set at any rep count, or a tested 1RM. Not the
  estimated 1RM — "lift 100 kg" is about the bar.
- Bodyweight = first weigh-in on/after `created_at` crossing the target; stays
  reached if the scale bounces back.
- Frequency = completed workouts (recap rule: finished and with sets, free
  workouts included) in the current week, which starts on
  `firstWeekdayProvider` (device region, `firstWeekdayFor`). Celebrated once
  per week: `celebrate` compares `celebrated_at` with the moment this week's
  target was met.
- Editing a goal clears `celebrated_at`.

## Helpers added with v27 (reuse them)
- `shared/utils/dates.dart`: `startOfWeek(day, firstWeekday)`, `daysBetween`.
- `shared/utils/weekday.dart`: `firstWeekdayFor(Locale)` (CLDR table, by
  hand), `weekdaysFrom(first)`. `shared/data/week_start.dart`:
  `firstWeekdayProvider` (device region, not the app language: English on a
  German phone still starts on Monday).
- `shared/utils/format.dart`: `formatMonthName`, `formatMonthYear`,
  `formatDate` ("3 Oct 2026"; pass `l10n:` for "3. Okt. 2026", see
  Localisation above).
- `features/exercises/data/exercise_names.dart`: `exerciseNamesProvider`
  (id → name, archived included).
- `features/workout/data/personal_records.dart`: `recordCountsByWorkout` and
  `recordsByDayProvider` — the summary's record rules over the whole log in
  one pass. A month's count equals the sum of its summaries.
- `features/home/data/activity_repository.dart`: `allTrainingByDayProvider`
  (the heatmap's per-day minutes without the 53-week window).
- `features/reviews/data/image_share.dart`: `shareOrSaveImage` / `capturePng`;
  Kotlin half `ShareBridge.kt` (`de.kopten.gymfy/share`, provider
  `${applicationId}.shareprovider`, files only from `<cache>/share/`).
- Summary from history: `WorkoutSummaryScreen(fromHistory: true)` at
  `/progress/session/:id` (back arrow, Done pops).
