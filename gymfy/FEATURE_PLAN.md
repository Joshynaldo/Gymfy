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
- `effort_rating_mode`: `off` (default) | `rpe` | `rir`.
- `auto_backup_mode`: `off` (default) | `weekly` | `after_workout`;
  `auto_backup_folder` (path/URI); `auto_backup_last_at` (ISO-8601);
  `auto_backup_last_error` (last failed automatic backup, shown on the screen).
- Warm-up calculator ramp: `warmup_ramp_percents` (e.g. `40,60,80`).

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
