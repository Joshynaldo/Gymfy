# Gymfy

A gym tracker for Android that keeps everything on your phone.

No account, no backend, no sync. You log a set and it goes into a SQLite file on
your device — that's the whole data story. Gymfy is built around the idea that a
training log is a personal record, not a product surface: it works the same in a
basement gym with no signal as it does anywhere else, and nothing leaves the
phone unless you deliberately export it.

Built with Flutter, for one person's training. Released as an APK.

---

## What it does

**Plan.** Build splits out of workout days, assign days to weekdays, and fill
each day with exercises, target sets and rep ranges. One split is *active*; the
Workout tab opens straight onto it rather than onto a list you have to walk
through.

**Log.** Start a session, log sets as you go, and let the rest timer count you
down between them (with a notification and an optional vibration, so you can put
the phone away). Warm-up sets are tagged separately and deliberately stay out of
the numbers they'd distort — your estimated 1RM, your PRs, the progress chart,
and the next overload suggestion — while still counting toward session volume
and the muscle map, because they're work you actually did.

**See it.** A body diagram tinted by the volume you've put through each muscle
this week, with a second reading for fatigue — what's still sitting on you,
decayed on a 48-hour half-life. A GitHub-style activity heatmap for the year.
Volume, workout-frequency and per-muscle charts over a week, a month or a year.
Per-exercise progress curves.

**Work out what to lift.** A progressive-overload suggestion per exercise, a 1RM
estimator, a strength rank that puts your big lifts against your bodyweight, and
a plate calculator that knows which plates your gym actually owns.

**Everything else.** 78 built-in exercises tagged to 18 muscle groups, plus your
own; optional GIF previews; body measurements and progress photos; a calorie and
macro log; data export; and plan sharing — send your splits as a `.gymfy` file
or as a printable PDF, or import someone else's. Plan sharing reads *only* plan
tables, so there is no path by which a session, a measurement or a photo could
end up in the file. A test enforces that.

---

## Design

Dark-mode first, with a user-chosen accent colour that drives every CTA,
highlight, active state and chart series. Eight themes ship:

| | |
|---|---|
| **Dark** | The default. Near-black with soft grey cards. |
| **AMOLED black** | True black, so a black pixel is an off pixel. |
| **High contrast** | White text, brighter secondary text, visible borders. |
| **Tokyo Night**, **Dracula**, **Catppuccin Mocha**, **Gruvbox** | The editor palettes, using each project's own published values. |
| **Hyper** | The glass one. |

Hyper is the only theme that's a *construction* rather than a palette. Every
surface is translucent and blurs what's behind it, which only works because
there's something behind it to blur: the app paints a slow atmospheric field
under the whole screen. Glass over a flat black background is just a slightly
different grey — the backdrop isn't decoration, it's the half of the effect that
makes the other half read.

The seven flat themes are unaffected by any of it, which is enforced by tests
rather than by hoping.

---

## Getting started

You'll need [Flutter](https://docs.flutter.dev/get-started/install) **3.44.7 or
newer** (Dart SDK `^3.12.2`) and an Android device or emulator on **Android 7.0
(API 24)** or above.

The Flutter app lives in the `gymfy/` subdirectory, not at the repo root.

```bash
git clone https://github.com/Joshynaldo/Gymfy.git
cd Gymfy/gymfy
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The `build_runner` step is not optional: Riverpod providers, Drift's database
code and Freezed models are all generated, and the project will not compile
without it. Re-run it after touching a `@riverpod` provider, a Drift table or a
Freezed class — or leave `dart run build_runner watch --delete-conflicting-outputs`
running while you work.

### Tests

```bash
flutter test
```

Around 990 tests across 95 files. They're the main reason the app can be
refactored at all: as well as the usual unit coverage, there are widget tests
for every screen, layout tests that fail on a pixel of overflow, and a couple
that rasterise a widget and read the pixels back — because "the card looks
black" turned out to be a question about paint order that the widget tree
answered incorrectly for three rounds.

### Other platforms

Android is the target. The `ios/`, `macos/`, `linux/`, `windows/` and `web/`
directories are Flutter's defaults and are not maintained — Drift runs on native
platforms only, so the web build in particular can't reach the database at all.

---

## Project layout

```
gymfy/
  lib/
    main.dart
    app/
      router/            go_router, with a StatefulShellRoute per tab
      theme/             ThemeData, the glass material, accent provider
    features/            one folder per feature: providers, widgets, screens
      calculator/          1RM estimates and strength rank
      calories/            calorie and macro log
      data_export/         export everything to a file
      exercises/           library, seed data, GIF previews
      help/                about the app
      home/                today's workout, streak, activity heatmap
      more/                the fourth tab's index
      muscle_map/          the body diagram and its two readings
      onboarding/          first-run questions
      overload/            progressive-overload suggestions
      plan_share/          .gymfy and PDF export, and import
      plates/              plate calculator and plate inventory
      progress/            measurements, photos, per-exercise charts
      settings/            accent, themes, units, rest timer
      stats/               the panels Progress is assembled from
      workout/             splits, days, sessions, set logging
    shared/
      data/                cross-feature providers
      database/            the Drift database
      models/              Drift tables
      utils/               formatting, search, units
      widgets/             the shared UI vocabulary
  assets/
    exercises/           one GIF per exercise, named <id>.gif
    fonts/               Schibsted Grotesk (the Hyper theme's typeface)
    icon/                launcher icon and splash source art
    musclemap/source/    the licensed anatomy pack the diagrams come from
    svg/                 muscle map body diagrams, paths tagged per muscle
  test/
  tool/                  one-off generators, not shipped in the APK
```

Four tabs — **Home**, **Workout**, **Progress**, **More** — each with its own
navigation stack, so switching tabs never loses where you were in another one.

### Conventions

- One feature, one folder, with its own providers, widgets and screens.
- Riverpod with code generation (`@riverpod`); Drift tables in `shared/models/`.
- The accent comes from `ref.watch(accentColorProvider)` — never
  `Theme.of(context).colorScheme.primary`, because the accent and the theme are
  independent by design.
- Widgets never hardcode a hex value. Colours come from the theme or the accent
  provider. `app/theme/` is the one place raw hex is allowed, because that file
  *is* the theme.
- The database schema is versioned (currently v22) and every change ships a
  migration. Existing logs are never dropped.

---

## Tooling

Scripts in `gymfy/tool/`, run with `dart run tool/<name>.dart`:

| Script | What it does |
|---|---|
| `build_muscle_map.dart` | Generates the tagged body SVGs from the licensed source pack. |
| `check_exercise_gifs.dart` | Reports which seeded exercises are still missing a GIF. |
| `fetch_exercise_gifs.dart` | Fetches and names GIFs to match the seed ids. |
| `generate_icon.dart` | Produces the launcher-icon and splash source artwork. |

Icons and the splash screen are regenerated with `dart run flutter_launcher_icons`
and `dart run flutter_native_splash:create`.

## Releases

`.github/workflows/release-apk.yml` builds a release APK and attaches it to a
GitHub release. It's triggered manually, and takes an optional tag, release
notes and a pre-release flag; with no tag it uses the version from
`pubspec.yaml`.

---

## Third-party assets

- **Schibsted Grotesk** — SIL Open Font License 1.1. The licence text ships
  alongside the files in `assets/fonts/OFL.txt`. Bundled rather than fetched
  through `google_fonts` so the app looks the same offline.
- **Body diagrams** — `assets/svg/body_*.svg` are generated by
  `tool/build_muscle_map.dart` from a licensed anatomy pack, not drawn for this
  project. They are what the muscle map feature stands on; see `gymfy/TODO.md`
  for the open question about redistributing them.

The project itself does not currently carry a licence file.
