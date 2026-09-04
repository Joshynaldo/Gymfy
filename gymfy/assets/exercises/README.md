# Exercise animations

One animation per exercise, named after the exercise's `id` (the slug in
`lib/features/exercises/data/exercise_seed_data.dart`), e.g.
`barbell_bench_press.webp`.

Either `.webp` or `.gif` works. Seed data declares `.gif`, but the extension is
resolved at load — see `previewCandidates` in
`lib/features/exercises/data/exercise_preview.dart` — so the format can change
without touching 78 seed entries. WebP wins when both are present.

An exercise with no file shows a "Preview coming soon" placeholder, so a
partial folder is a working state.

## What ships today

78 GIFs, 360×360, ~295 KB each, **22.5 MB total**. Fetched from
[ExerciseGymGifsDB](https://github.com/JahelCuadrado/ExerciseGymGifsDB) by
`tool/fetch_exercise_gifs.dart`, which holds the id-to-source mapping and the
provenance note. Credited on the Help screen.

Upstream also has the same loops as 128×128 animated WebP — 1.4 MB for the set,
a sixteenth of the size, but soft when drawn large. Full resolution was chosen
deliberately: the whole point of the screen is watching how a movement looks.
`tool/fetch_exercise_gifs.dart` without `--gif` fetches those instead.

Keep in mind the 22.5 MB is paid by every user on first install — a local-first
app has no server to stream from.

## Getting most of the sharpness back for a fifth of the size

Re-encoding these 360 px GIFs to ~256 px WebP lands around 4–5 MB for the set
at close to current quality. Because WebP wins the extension race, dropping the
converted files in is enough — nothing else changes. Needs a tool this machine
doesn't have yet:

```bash
winget install Gyan.FFmpeg
```

Then convert what's already here:

```bash
for f in assets/exercises/*.gif; do ffmpeg -y -i "$f" -vf scale=256:-1 -loop 0 -quality 70 "${f%.gif}.webp" && rm "$f"; done
```

`dart run tool/check_exercise_gifs.dart` reports coverage, total size, and any
file whose name matches no exercise — that last one is the failure worth
catching, because a misnamed file looks present on disk and is invisible in the
app. `test/exercise_preview_test.dart` enforces the same rules in CI.

## Older hardware

Every visible animation decodes continuously. One at a time on the detail
screen is fine; 78 on a scrolling list is not, which is why the exercise
library uses a static icon.
