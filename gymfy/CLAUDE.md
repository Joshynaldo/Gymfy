# Gymfy — Claude Code Instructions

## Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

* State your assumptions explicitly. If uncertain, ask.
* If multiple interpretations exist, present them - don't pick silently.
* If a simpler approach exists, say so. Push back when warranted.
* If something is unclear, stop. Name what's confusing. Ask.

## Goal-Driven Execution

**Define success criteria. Loop until verified.**
Transform tasks into verifiable goals:
* "Add validation" → "Write tests for invalid inputs, then make them pass"
* "Fix the bug" → "Write a test that reproduces it, then make it pass"
* "Refactor X" → "Ensure tests pass before and after"
For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.


## Who you are working with
Solo beginner developer. Understands concepts but has limited hands-on Flutter experience.
- Always write **full, working, copy-paste-ready code** — no pseudocode, no placeholders
- When creating a file, always state exactly where it goes in the folder structure
- If there are multiple valid approaches, pick the best one and briefly say why
- After adding any new package, remind the developer to run `flutter pub get`
- Flag anything that could cause performance issues on older Android hardware
- Keep code readable — prefer clarity over cleverness

## App overview
**Gymfy** — A Flutter gym tracking app inspired by StrengthLog and Strong.
- Platform: Android (primary), WearOS + home screen widgets (later)
- Local-first: all data stored on device (no backend for MVP)
- State management: Riverpod
- Database: Drift (SQLite)
- Navigation: go_router

## Design system
- Dark mode first, customizable accent color (user picks from settings)
- Minimal and clean — mix of Strong (simplicity) and StrengthLog (data density)
- Flat surfaces, subtle contrast, no heavy gradients
- Accent color drives CTAs, highlights, active states, and chart colors
- Never hardcode hex values in widgets — always pull from theme

## Folder structure
```
lib/
  main.dart
  app/
    theme/           # ThemeData, color scheme, accent color provider
    router/          # go_router setup
  features/
    workout/         # splits, workout days, exercise logging
    muscle_map/      # SVG heatmap visualization
    exercises/       # exercise library, GIF previews, seed data
    calories/        # calorie + habit tracking
    progress/        # measurements, photos, charts
    calculator/      # 1RM, strength rank
  shared/
    widgets/         # reusable UI components
    models/          # data models (Drift table definitions)
    database/        # Drift database setup
assets/
  exercises/         # GIF files per exercise
  svg/               # muscle map SVG files (front + back)
```

## Current MVP scope (build in this order)
1. [ ] Project setup — theme, router, Drift database shell
2. [ ] Exercise library — seed data with muscleIds, GIF preview
3. [ ] Workout builder — create splits, days, add exercises
4. [ ] Workout logging — start session, log sets/reps/weight, complete
5. [ ] Muscle map — SVG heatmap driven by logged volume
6. [ ] Progress charts — per exercise weight/reps over time

## Post-MVP features (do not build yet)
- Calories + habit tracker
- Body measurements + progress photos
- 1RM calculator (Epley: weight × (1 + reps/30))
- Strength rank per exercise
- Android home screen widgets (Glance API)
- WearOS companion app

## Muscle map pipeline
- Each exercise in seed data has a `muscleIds` list e.g. `["chest", "front_deltoid", "tricep"]`
- muscleIds match SVG path IDs on the body map
- After logging a workout: sum volume per muscleId (sets × weight)
- Normalize to 0.0–1.0 intensity → apply as opacity on SVG path fill
- Two views: current workout + weekly summary

## Licensing constraint — Gymfy must stay free
- The muscle-map body diagrams are derived from a purchased Envato item under a **Regular License**, which covers the end product **only while it is distributed free of charge** (clauses 5 and 7).
- So: **no app price, no paid tier, no in-app purchase of any kind** without first buying an Extended License for that item. This is invisible in the code and nothing will warn you — see `assets/musclemap/README.md`.
- `assets/musclemap/source/` is the unmodified purchased pack. It must never be bundled into the app (`test/muscle_map_licence_test.dart` enforces this) and must never be published — the repository is private, and that is what keeps clause 8 satisfied.

## Key conventions
- Use `freezed` for immutable data models
- Use `Riverpod` with code generation (`@riverpod`)
- Drift tables in `shared/models/`, database class in `shared/database/`
- One feature = one folder with its own providers, widgets, and screens
- Accent color: `final accent = ref.watch(accentColorProvider)` — never Theme.of(context) for accent

## When Claude Code should ask before proceeding
- Before installing any paid or proprietary package
- Before making changes outside the current feature folder
- Before changing the database schema (it requires a migration)
- If a feature seems to conflict with existing code

## Session workflow
At the start of each session Claude Code should:
1. Read this file
2. Read `/TODO.md` to see what's next
3. Confirm the current task with the developer
4. Build it, update TODO.md when done

