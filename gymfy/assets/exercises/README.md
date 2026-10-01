# Exercise animations

One animation per exercise, named after the exercise's `id`, e.g.
`barbell_bench_press.webp`.

Either `.webp` or `.gif` works. Seed data declares `.gif`, but the extension is
resolved at load (see `previewCandidates` in
`lib/shared/utils/exercise_preview.dart`), so the format can change without
touching the seed entries. WebP wins when both are present.

An exercise with no file shows a "Preview coming soon" placeholder, so a
partial folder is a working state.

## What ships today

About 1,270 animated WebPs, 128×128, ~18 KB each, **about 23 MB in total**:
one for every built-in exercise. They come from
[ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB) and are
fetched by `tool/sync_exercise_db.dart`, which also generates the exercise list
and holds the provenance note. Credited on the Help screen.

Upstream also has each loop as a 360px GIF, which is sharper but about 300 KB
each, roughly 380 MB for the whole library. A local-first app has no server to
stream from, so every byte here is paid by every user at install time. That's
why the small previews were chosen.

## Refreshing

```bash
dart run tool/sync_exercise_db.dart
```

Regenerates `lib/features/exercises/data/exercise_catalog_data.dart` and
downloads any missing preview. `--force` downloads everything again;
`--no-media` only regenerates the list. Previews whose exercise no longer
exists are deleted.

`dart run tool/check_exercise_gifs.dart` reports coverage, total size, and any
file whose name matches no exercise. That last case is the one worth catching:
a misnamed file looks present on disk but never shows up in the app.
`test/exercise_preview_test.dart` enforces the same rules and a 30 MB budget.

## Older hardware

Every visible animation decodes continuously. One at a time on the detail
screen is fine, but a scrolling list of them is not, so the lists show only
each preview's first frame, decoded at the size it's drawn.
