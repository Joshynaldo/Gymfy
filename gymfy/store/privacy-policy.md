# Privacy Policy — Gymfy

**Last updated: 1 October 2026**

Gymfy is a workout tracker for Android. It has no account, no server and no
internet connection.

## The short version

**Nothing you enter into Gymfy ever leaves your phone.** The app contains no
networking code of any kind. It cannot upload your data, because it cannot
talk to anything.

## What Gymfy stores, and where

Everything you log or import — workouts, sets, weights, exercises, notes, body
measurements, progress photos, calorie entries, your name, bodyweight, height
and birth year — is written to a database inside the app's own private storage
on your device. Other apps cannot read it. It is never transmitted. The one
thing other apps can see is what you choose to share through Health Connect,
described below.

There is no user account, no sign-in, and no identifier of any kind is created
for you.

## What Gymfy does *not* do

- No analytics, telemetry or usage statistics
- No crash reporting
- No advertising and no ad identifiers
- No third-party SDKs that collect data
- No tracking across apps or websites
- No data sold or shared with anyone

## Permissions, and why each one exists

**Notifications** — so the rest timer can alert you when a set's rest is over
while you are in another app or the screen is off. The app asks the first time
you start a timer. If you decline, the app still works; you just get the
on-screen countdown only.

**Run at startup (`RECEIVE_BOOT_COMPLETED`)** — so a rest alert that is already
scheduled survives the phone restarting mid-workout. Gymfy does not run in the
background otherwise.

**Photos** — only when you add a progress photo, and only for the picture you
pick. The chosen image is copied into the app's own private storage so your
photo stays in Gymfy even if you later delete the original from your gallery.
Photos are never uploaded. Gymfy never opens the camera.

**Health Connect — write exercise, read weight** — only if you switch Health
Connect on in Settings, and each one only for its own switch. See Health
Connect below.

## When data leaves the app — always because you asked

Three features can move data off the device. Each one is started by you, shows
you what it will do, and hands the result to another app of your choosing.

**Export** (Settings → Data → Export data) writes your logged data to a CSV or
JSON file at a location you pick. Where the file goes afterwards is up to you.

**Share a plan** exports a training plan as a file or PDF through the system
share sheet. It contains the plan only — no logged sets, measurements or
photos.

**Send feedback** (Help → Send feedback) opens *your* mail app with a draft
message. Gymfy does not send it; you read it, edit it and send it yourself. The
draft includes exactly two technical lines — the app version and your Android
version — and says so on screen. You can delete them before sending. No
personal data from the app is attached.

## Import

Importing a history file (More → Import a history) reads a CSV you choose from
your own device. The file is parsed on the phone and nothing is uploaded.

## Health Connect (Android, optional)

Health Connect is Android's store for health and fitness data, kept on your
phone. Gymfy reads from it or writes to it only if you turn that on under
Settings → Health Connect. There are two switches, both off until you turn
them on, and each asks Health Connect for its own permission.

**Write workouts** (permission: write exercise). When you finish a workout,
Gymfy writes one exercise session to Health Connect: the type "strength
training", the start and end time, and the workout's name. Nothing else —
no sets, weights, reps, notes, measurements or photos. Workouts you finished
before turning this on are written only if you tap "Write past workouts". A
workout whose length was never recorded (some imported ones) is not written.
While writing is switched on, deleting a workout in Gymfy also deletes the
session Gymfy wrote for it.

**Read bodyweight** (permission: read weight). When you open Gymfy, or come
back to it, it reads the weight records of the last 30 days (further back if
you have not opened Gymfy for longer than that) and adds them to your body
measurements: one per day, the first weigh-in of that day, and only on days
where you have not entered a weight yourself. A weight you typed is never
replaced, a value you change or clear afterwards is left alone, and the same
record is never imported twice. Gymfy reads nothing else from Health Connect.

**It stays on your device.** Gymfy reads and writes Health Connect through
Android on the phone itself; it still has no internet access and sends
nothing anywhere. Other apps that *you* allow to read exercise data from
Health Connect can see the workouts Gymfy wrote there; what they do with
them is covered by their own privacy policies.

**Stopping and deleting.** Turn either switch off and Gymfy stops at once.
To revoke its permissions or delete what it wrote, tap "Manage in Health
Connect" in Gymfy's settings, or open Health Connect yourself (from Android
14, it is in Android's settings) and choose Gymfy. Workouts already written
stay in Health Connect when you switch writing off, restore an older backup
or uninstall Gymfy, until you delete them there. Weigh-ins already imported
are part of your measurements in Gymfy and can be deleted there.

## Deleting your data

Uninstalling Gymfy deletes the database and every photo it holds. There is no
copy anywhere else — except workouts you chose to write to Health Connect,
which stay there until you delete them (see Health Connect above) — so there
is nothing to request and nobody to request it from. Individual entries can
be deleted inside the app at any time.

Because the data lives only on your phone, **Gymfy has no backup**. If you
want a copy, use Export before changing devices.

## Children

Gymfy is not directed at children under 13 and collects no data from anyone.

## Changes to this policy

If a future version of Gymfy ever collects anything, this page will be updated
before that version ships, and the change will be described in the release
notes rather than made quietly.

## Contact

gymfy.dev@gmail.com
