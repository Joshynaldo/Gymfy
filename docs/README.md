# The Gymfy website

A single static page plus the privacy policy. No build step, no dependencies —
`index.html` is self-contained apart from the Google Fonts stylesheet.

```
docs/
  index.html           the landing page
  privacy-policy.html  a copy of gymfy/store/privacy-policy.html
  icon.png             the app icon, 1024px
```

## Every interactive element, and what it does

Checked rather than assumed — a button that loads *a* page is not the same as
a button that works.

| Element | Goes to | Real? |
|---|---|---|
| Nav · Features / Download / Privacy | `#features`, `#get`, `#privacy` | yes, all three anchors exist |
| Nav · Source | the `Joshynaldo/Gymfy` repository | yes |
| Hero · Download for Android | `releases/latest` on GitHub | yes, resolves to the newest release with the APK attached |
| Hero · See what it does | `#features` | yes |
| Get Gymfy · Latest release | `releases/latest` | yes |
| Get Gymfy · Build from source | the repository | yes |
| Get Gymfy · Google Play / App Store | nothing, marked "Coming soon" | not links until the listings exist |
| Privacy · Read the full privacy policy | `privacy-policy.html` | yes |
| Footer · Features / Download / Privacy / Source code | as above | yes |
| Tour steps (wide screens) | scrolling a step past the middle of the window puts the mockup on its screen | yes, no click needed |
| Tour steps · Show it in the preview (narrow screens) | switches the mockup to that screen and scrolls to it | yes; hidden on wide screens, where scrolling does it |
| Accent swatches | recolour the mockup | yes, real buttons with a pressed state |
| Mockup · tab bar, Start workout, Finish | switch the mockup's screen | yes |
| Mockup · Log set, number pad, Next / Save set, Repeat last set | log a sample set and restart the rest timer | yes |
| Mockup · +30s, dismiss | change or close the rest timer | yes |
| Mockup · Progress segments, Week / Month / Year | switch the view and re-draw the charts | yes |
| Mockup · search icon, More rows | nothing | drawn as in the design, not buttons, so they aren't in the tab order |

When the Play Store or App Store listing goes live, turn its card's badge into
`badge live` and add a link to the listing.

## Hosting

Served by GitHub Pages from the `/docs` folder of `Joshynaldo/Gymfy`. GitHub
Free only serves Pages from a public repository, so the repository is public;
the purchased Envato muscle-map pack was removed from the history before that
flip (see `gymfy/assets/musclemap/README.md`).

Settings → Pages → Source: *Deploy from a branch*, branch `main`, folder
`/docs`. The site is then at `https://joshynaldo.github.io/Gymfy/` and the
privacy policy at `https://joshynaldo.github.io/Gymfy/privacy-policy.html`.
That URL goes in the Play Console and has to stay reachable for as long as the
app is listed.

## Keeping the policy in sync

`privacy-policy.html` is a copy of `gymfy/store/privacy-policy.html`. Edit the
one in `store/`, then:

```
cp gymfy/store/privacy-policy.html docs/privacy-policy.html
```

`gymfy/test/store_listing_test.dart` fails if the two drift apart — two copies
of a legal document is exactly the arrangement where the published one quietly
goes stale.

## The app mockup

The phone under the hero is the "Gymfy Hyper" design from Claude Design
(`GymfyPhone.dc.html`), rebuilt as plain HTML, CSS and a small script at the
bottom of `index.html`, so the page still needs no runtime and no build step.
It replaced the four phone screenshots. The screens, glass styles and sample
data are the design's. A few things differ on purpose:

- The More list names today's tools (1,270 exercises, Programs, language in
  Settings) instead of the design's older ones.
- On the reps step, Save set has to be tapped, as in the app, rather than the
  first digit saving the set.
- The body diagrams are left out (the small map on Home and the map in
  Progress → Body). They come from a purchased pack licensed for use in the
  app (see `gymfy/assets/musclemap/README.md`), and a marketing page isn't the
  app.

The device is drawn at 413 × 872 px. Every colour that follows the accent
reads `--gf-accent`, which is how the swatches recolour it.

### The tour around it

On screens 1000 px and wider, the phone is pinned in the middle (`position:
sticky`) and nine steps scroll past on alternating sides. An
`IntersectionObserver` watches for the step crossing the middle of the window,
puts the phone on that step's scene (`data-scene`: `home`, `log`, `overload`,
`rest`, `trends`, `alltime`, `body`, `themes`, `more`) and dims the others. The
phone is scaled to fit the window's height, so it is whole on screen for the
length of the tour. Tapping the phone yourself takes over until the next step
arrives.

Narrower screens get the phone on top and the steps as panes underneath, each
with a "Show it in the preview" button. To add a step, add an `<article
class="step">` with the next `--row`, raise the phone's `grid-row` span, and,
if it needs a new scene, add a case to `scene()` in the script.
