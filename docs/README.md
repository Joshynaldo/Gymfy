# The Gymfy website

A single static page plus the privacy policy. No build step, no dependencies —
`index.html` is self-contained apart from the Google Fonts stylesheet.

```
docs/
  index.html           the landing page
  privacy-policy.html  a copy of gymfy/store/privacy-policy.html
  icon.png             the app icon, 1024px
  screenshots/         four slots — see screenshots/README.md
```

## Where the design rules came from

Built against skills from
[rshankras/claude-code-apple-skills](https://github.com/rshankras/claude-code-apple-skills):
`design/liquid-glass`, `design/typography` and `design/ux-writing`, read in
full rather than in summary. They are written for Apple platforms, so the
*principles* were applied and the SwiftUI APIs ignored.

**The visible ones — these are what make it look like the skill:**

- **One shape language.** *"Establish a shape language (all capsules, or all
  rounded rects)."* The page had six unrelated radii (14, 12, 13, 20, 38,
  999). Now: **controls are capsules**, which is what `.glassEffect()`
  defaults to; **containers are rounded rects**; anything nested inside a
  container is concentric with it. Three tokens, no loose numbers.
- **Buttons are glass, and interactive.** Buttons are floating controls, so
  unlike the content cards they are allowed the material. `.interactive()`
  in the skill means *"scale, bounce, and shimmer on touch or hover"* — all
  three are implemented: a lift and scale on hover, a compression on press,
  and a specular band that sweeps across. Without the shimmer a glass button
  is a translucent rectangle.
- **`.glass` vs `.glassProminent`.** The primary button is tinted glass with
  a specular inner highlight; the secondary is plain glass with no tint, so
  it never competes.
- **A soft scroll edge effect** under the header — the iOS default. A
  floating bar needs content to fade as it passes beneath rather than being
  cut by a hard line. One per edge, only where floating UI exists.

**The quieter ones:**

- **Glass is the navigation layer's material, never the content layer.** Nine
  feature cards and the privacy block were blurred glass. They are fills now;
  the sticky header is the only glass surface on the page. This also removes
  ten backdrop-filter passes from a scrolling page.
- **Tint only the primary action.** Nine accent-tinted icon squares were
  competing with the one button that matters. The icons are neutral; the
  accent now appears on the primary CTA and almost nowhere else.
- **No decorated bars.** The header's bottom border is gone — the material
  already separates it from what scrolls underneath.
- **Concentric corner radii.** The phone screen is 29px inside a 38px frame
  with 9px of bezel, not a rounded-off 30.
- **No hardcoded type sizes.** `body` was `17px`, which overrides the
  reader's own browser font-size setting. It is `1.0625rem` now — same size
  by default, scales when someone has asked for larger text.
- **Lead with the outcome, not the mechanism.** The hero opened on "no
  networking code"; it opens on "your training never leaves the phone" and
  keeps the mechanism as the evidence behind it.

**Two deliberate deviations**, so neither looks like an oversight:

- **`design/sf-symbols` is not used.** SF Symbols is licensed for Apple
  platforms; putting it on a website is not permitted. The icons are
  hand-written inline SVG.
- **Dark only.** The general checklist asks for light and dark. The app has
  no light theme for a stated reason, and a light landing page for a
  dark-only app is a promise the install does not keep.

## Every interactive element, and what it does

Checked rather than assumed — a button that loads *a* page is not the same as
a button that works.

| Element | Goes to | Real? |
|---|---|---|
| Nav · Features / Privacy | `#features`, `#privacy` | yes, both anchors exist |
| Nav · Developer | the developer's GitHub profile | yes |
| Hero · See what it does | `#features` | yes |
| Hero · Tell me when it launches | `mailto:` with a subject | yes |
| Privacy · Read the full privacy policy | `privacy-policy.html` | yes |
| Footer · Privacy / Developer / Features | as above | yes |
| Accent swatches | nothing — they are colour samples | **not controls**, so they are circles now; rounded squares the size of a button read as buttons |

**Removed: "View on GitHub."** It pointed at the developer's profile, which
loads — but Gymfy is not on it, because the repository is private. The button
promised source code and delivered a profile with two unrelated repos. It is
now *"Tell me when it launches"*, a `mailto:` using the same mechanism the app
itself uses for feedback: no backend, nothing to sign up to, and it does
exactly what it says. The two remaining profile links say **Developer**, which
is both accurate and the same wording the app's own Help screen uses.

## ⚠️ Where this can actually be hosted

**Not from this repository, as things stand.** GitHub's own wording:

> If the account that owns the repository uses GitHub Free … the repository
> must be public.

`Joshynaldo/Gymfy` is private, and it has to stay private: it contains the
purchased Envato muscle-map pack in `gymfy/assets/musclemap/source/`, whose
licence forbids redistributing the item with source files. See
`gymfy/assets/musclemap/README.md`.

So there are three ways forward, in the order they are worth considering:

**1. A separate public repository for the site — recommended.** Copy this
folder into a new public repo (`Joshynaldo.github.io` gives the shortest URL:
`https://joshynaldo.github.io/privacy-policy.html`). Free, nothing licensed
goes into it, and the app's source stays private. The only cost is that the
site is no longer versioned next to the code it describes.

**2. GitHub Pro.** Pages can then serve from `/docs` of a private repository.
Note the *site* is public either way — the plan governs the repository, not
the page.

**3. Make `Joshynaldo/Gymfy` public.** Only after rewriting history to remove
the Envato pack — deleting it in a new commit leaves it downloadable from
earlier ones. The command and its consequences are in
`gymfy/assets/musclemap/README.md`.

Whichever you pick, the resulting privacy-policy URL goes in the Play Console.
It has to stay reachable for as long as the app is listed.

## Keeping the policy in sync

`privacy-policy.html` is a copy of `gymfy/store/privacy-policy.html`. Edit the
one in `store/`, then:

```
cp gymfy/store/privacy-policy.html docs/privacy-policy.html
```

`gymfy/test/store_listing_test.dart` fails if the two drift apart — two copies
of a legal document is exactly the arrangement where the published one quietly
goes stale.

## Screenshots

There are none yet. Each slot renders an explanatory placeholder instead of a
broken image, so the page is presentable now and improves the moment you drop
files in. Names and capture notes: `screenshots/README.md`.
