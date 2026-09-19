# Play Store listing — Gymfy

Everything Play asks for, written out. Copy each block into the Console.
Character limits are Play's; the counts in brackets are what these actually
are, checked by `test/store_listing_test.dart`.

---

## App name  *(max 30)*

```
Gymfy — Workout Tracker
```

## Short description  *(max 80)*

```
Log lifts, track progress, stay offline. No account, no ads, no data leaves.
```

## Full description  *(max 4000)*

```
Gymfy is a gym log for people who lift. Plan a split, log your sets, watch the
numbers move. Nothing else.

No account. No subscription. No ads. No internet connection — the app has no
networking code at all, so your training data physically cannot leave your
phone.


LOG A WORKOUT

• Big, thumb-sized controls built to be used mid-set, one-handed, with chalk
  on your hands
• Scroll wheels instead of a keyboard for every weight — 82.5 kg is two
  flicks, not four keystrokes
• Warm-up sets are marked as warm-ups and kept out of your records
• Rest timer with a countdown ring, a +30s button, and a notification for
  when you have already put the phone down
• Per-exercise notes: the bench setting, the grip width, what your back said
  last time


PROGRESSIVE OVERLOAD

Gymfy suggests your next weight from what you actually lifted, not from a
formula on a poster. Hit your target reps and the number goes up; miss it and
it holds. Rules are yours to set.


TIMED EXERCISES

Planks, dead hangs, loaded carries. Logged in minutes and seconds, charted by
duration, and given their own records — a plank's personal best is a time,
not a weight.


PLATE CALCULATOR

Tells you what to load, per side, from the plates your gym actually owns. Bar
weight is set per exercise, because the leg press does not have a 20 kg bar on
it and pretending otherwise made every number wrong.


SEE THE PROGRESS

• Per-exercise charts: top set, volume, estimated 1RM
• Personal records with the date you set them
• Muscle map — which muscles you have actually trained this week, and which
  ones you have been quietly avoiding
• Strength rank, bodyweight-relative, so the comparison is to people your size
• Body measurements and progress photos, stored on the phone


BRING YOUR HISTORY

Switching from Hevy, Strong or StrengthLog? Export a CSV there, import it
here. Gymfy reads the columns rather than one fixed format, creates the
exercises it does not know instead of dropping those sets, and will not add
anything twice if you import the same file again.


IT LOOKS THE WAY YOU WANT

Seven themes including AMOLED black, high contrast, and a glass theme that
actually uses depth. Pick any accent colour. Everything respects your system
reduce-motion setting.


YOUR DATA IS YOURS

Export everything to CSV or JSON whenever you want. It is a real export, not a
teaser: warm-ups included and labelled, weights in a column that says which
unit it is in.

Because nothing is on a server, there is also no backup. Export before you
change phones.


Built by one person. Feedback goes straight to a human:
gymfy.dev@gmail.com
```

---

## Categorisation

| Field | Value |
|---|---|
| App or game | App |
| Category | Health & Fitness |
| Tags | Workout & Exercise, Personal Fitness |
| Contact email | gymfy.dev@gmail.com |
| Website | https://github.com/Joshynaldo/Gymfy |
| Privacy policy URL | *(see below — must be live before submitting)* |

### Hosting the privacy policy

Play requires a public URL, not a file. The page is built and waiting in
`docs/privacy-policy.html`, alongside the landing page.

**It cannot be served from this repository as things stand.** GitHub Pages on
a free account requires the repository to be public, and `Joshynaldo/Gymfy`
has to stay private because it contains the purchased Envato muscle-map pack.
`docs/README.md` lays out the three ways round it; the recommended one is a
separate public repository holding only `docs/`, which gives
`https://joshynaldo.github.io/privacy-policy.html`.

Whichever route you take, the URL has to stay reachable for as long as the app
is listed — a dead privacy policy link is grounds for removal, not just
rejection.

---

## Data safety form

Play asks this as a questionnaire. The answers for Gymfy are unusually short
because the app collects nothing.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | *(not asked — nothing is transmitted)* |
| Do you provide a way for users to request that their data be deleted? | **No**, and the explanation is that data never leaves the device; uninstalling removes it |

**If the form pushes back** — it sometimes flags apps that hold personal data
locally — the distinction Play draws is *collected* (sent off the device or to
the developer) versus *stored on the device only*. Gymfy is entirely the
second. Name, bodyweight, height, birth year and photos are entered by the
user, written to app-private storage, and never transmitted. There is no
networking code in the app to transmit them with.

Do **not** tick "Data is encrypted in transit" as a reassurance. It implies
there is transit.

---

## Content rating questionnaire

| Question | Answer |
|---|---|
| Category | Utility, Productivity, Communication or Other |
| Violence, sexuality, language, controlled substances, gambling | No to all |
| Does the app share the user's location? | No |
| Does the app allow users to interact or exchange content? | No |
| Does the app allow purchase of digital goods? | No |
| Is there a link to an external website? | **Yes** — the developer's GitHub profile, from the Help screen |

Expected outcome: **PEGI 3 / ESRB Everyone**.

---

## Ads and in-app purchases

| Field | Value |
|---|---|
| Contains ads | No |
| In-app purchases | No |

The Help screen links to the developer's GitHub profile, which in turn links
to a donation page. That is a link to a profile, not a call to action inside
the app, and there is nothing to purchase in Gymfy — so both answers stay No.

**And they have to stay No.** The muscle-map artwork is licensed under an
Envato *Regular License*, which covers the end product only while it is
distributed free to end users. Setting a price, adding a paid tier or
introducing any in-app purchase requires buying an Extended License for that
item first. Details and the clause text: `assets/musclemap/README.md`.

Set the app's price to **Free** at publish, which the licence requires anyway.
Be aware that this is permanent: Play lets a paid app become free, but *never*
the reverse — "once your app has been offered for free, the app can't be
changed to paid… you need to create a new app with a new package name".

So charging for Gymfy later would take both a new package name and an Extended
License. Two one-way doors pointing the same way, which is fine — just know
the door is closing.

---

## Target audience

- Target age group: **18 and over**
- Not appealing to children: correct (no characters, no games, no bright
  cartoon styling)

Setting anything under 13 pulls the app into Families policy, which brings
requirements Gymfy has no reason to meet.

---

## App access

No login exists, so answer: **All functionality is available without special
access.** Do not leave this blank — a reviewer who cannot get in fails the
review regardless of the app.

---

## Release notes for 1.0.0  *(max 500 characters per language)*

```
First release.

Log workouts, plan splits, and track progress — fully offline, with no account
and no ads.

• Progressive overload suggestions from your own logged sets
• Timed exercises: planks, hangs, carries
• Plate calculator with per-exercise bar weight
• Muscle map, strength rank, per-exercise charts
• Import your history from Hevy, Strong or StrengthLog
• Export everything to CSV or JSON, any time
```
