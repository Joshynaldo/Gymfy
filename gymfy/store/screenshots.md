# Store graphics — what to capture

The only part of the listing that needs your phone. Everything else in
`store/` is ready to paste.

## What Play requires

| Asset | Spec | Required |
|---|---|---|
| App icon | 512 × 512 PNG, no alpha channel | Yes |
| Feature graphic | 1024 × 500 PNG or JPG, no alpha | Yes |
| Phone screenshots | 2–8, PNG or JPG, 9:16, 1080 × 1920 or larger | Yes (min 2) |
| 7" / 10" tablet screenshots | — | Only if you want the app listed as tablet-ready |

The feature graphic is the wide banner at the top of the listing. It must not
contain a device frame and must not repeat the app name in tiny text — it is
shown small.

## Capture settings

Set these before the first shot and do not change them mid-set. A screenshot
set in three different accent colours looks like three different apps.

- **Theme:** Hyper. It is the one thing in this app nobody else's screenshots
  will have — a flat dark list looks identical to every other tracker on the
  page.
- **Accent:** one colour throughout.
- **Units:** kg.
- **Data:** log two or three weeks of realistic workouts first. Empty states
  and single-point charts are the most common reason a good app's listing
  looks unfinished.

Capture with the phone's own screenshot (power + volume down) at native
resolution. Do not upscale.

## The eight shots, in listing order

The first two are the only ones most people see, so they carry the pitch.

1. **Active workout, mid-set** — the set sheet open with the weight wheel and
   an overload suggestion visible. This is the screen the app exists for.
2. **Per-exercise progress chart** — an exercise with real history, so the
   line has a shape. This is the payoff, and it is what makes someone install
   a tracker.
3. **Muscle map** — the most visually distinct screen in the app and the one
   nothing on the listing page will look like.
4. **Plate calculator** — total weight large at the top, plates drawn below.
   Concrete and instantly understandable in a thumbnail.
5. **Split / day builder** — shows the app plans as well as logs.
6. **Rest timer running** — the ring mid-countdown, on the workout screen.
7. **Import screen with a preview loaded** — the migration pitch, and the
   thing that removes the reason not to switch.
8. **Home tab** — streak, weekly volume, next workout.

Skip Settings. Nobody installs an app for its settings screen.

## Captions

Play overlays nothing, so if you want text on the screenshots you have to
compose it in. Optional, but it roughly doubles how much a thumbnail
communicates. Keep each to four words or fewer, same position and same font on
every shot:

1. Log a set in seconds
2. Watch the numbers move
3. See what you trained
4. What to load, per side
5. Plan your split
6. Rest timer that finds you
7. Bring your history along
8. Your week at a glance

## Feature graphic

Simplest version that does not look cheap: the app's dark background with the
Hyper backdrop orbs, the Gymfy wordmark left of centre, and one line —
*"Offline workout tracker. No account, no ads."* No screenshots inside it, no
device frames.

## App icon

Already generated at `assets/icon/`. The 512 × 512 store version must have the
alpha channel flattened onto `#151821` — the same treatment the iOS icon got.
Play accepts alpha, but a transparent icon renders inconsistently across
launcher themes on the listing page.
