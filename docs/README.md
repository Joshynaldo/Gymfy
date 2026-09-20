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

**"View on GitHub" became "Tell me when it launches."** The old button pointed
at the developer's profile while the repository was still private, so it
promised source code and delivered a profile page. Now that the repository is
public a source link would be legitimate again; for the moment the button is
a `mailto:` using the same mechanism the app itself uses for feedback: no
backend, nothing to sign up to, and it does exactly what it says. The two remaining profile links say **Developer**,
which is both accurate and the same wording the app's own Help screen uses.

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

## Screenshots

All four slots are filled with real phone captures, scaled to 720 px wide and
saved as JPEG so the page stays light. Names and capture notes:
`screenshots/README.md`.
