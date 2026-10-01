# Privacy Policy — Gymfy

**Last updated: 2 October 2026**

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
on your device. Other apps cannot read it. It is never transmitted. Other apps
see only what you choose to hand them: what you share through Health Connect,
and the files and pictures described under "When data leaves the app", both
below.

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
while you are in another app or the screen is off, and for the workout
notification. While a workout is running, that notification shows the
workout's name, the exercise, which set you are on, the next set's weight and
reps and the rest countdown, with buttons to log that set, add 30 seconds or
skip the rest. It shows on the lock screen too — unless you have set Android
to hide sensitive notification content there, in which case the locked
screen shows only "Workout in progress" and the countdown, with no buttons.
You can switch the workout notification off under Settings → Rest timer. The
app asks for the permission when you start a workout, or the first time you
start a timer. If you decline, the app still works; you just get the
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

These features can move data off the device. Each one is started by you —
automatic backups by you switching them on — and the result goes only where
you send it: a file you save, a folder you pick or an app you choose.

**Export** (Settings → Data → Export data) writes your logged data to a CSV or
JSON file at a location you pick. Where the file goes afterwards is up to you.

**Backup** (Settings → Data → Backup & restore) writes everything in Gymfy —
every logged entry, your settings, your progress photos and the pictures of
your own exercises — into one backup file. "Save a backup" writes it to a
location you pick. Automatic backup, off until you turn it on, writes one
weekly or after each workout into a folder you pick and keeps the ten most
recent there. Backup files are not encrypted: anyone, and any app, that can
open the folder they are in can read them, and where they go afterwards is up
to you — if you keep them in a folder another app syncs to the cloud, that
app uploads them. Restoring reads a backup file you choose; the Health
Connect switches are this phone's and are never taken from a backup.

**Share a plan** exports a training plan as a file or PDF through the system
share sheet. It contains the plan only — no logged sets, measurements or
photos.

**Share a review** (the share button on a monthly review or the Year in
Training) turns that review into a picture and hands it to the app you pick
in the system share sheet. The picture shows what the review shows: the
number of workouts, volume lifted, time trained, days trained and longest
streak, top exercises, records and most-trained muscles, set against the
period before. Nothing else is attached. Where sharing is not available,
Gymfy offers to save the picture to a location you pick instead.

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
stay in Health Connect when you switch writing off or uninstall Gymfy, until
you delete them there. Restoring a backup never switches either one on: both
switches keep the setting they have on this phone. Workouts Gymfy wrote there
that the restored backup does not contain are deleted from Health Connect the
next time Gymfy writes to it, as if you had deleted them in Gymfy. Weigh-ins
already imported are part
of your measurements in Gymfy and can be deleted there.

## Deleting your data

Uninstalling Gymfy deletes the database and every photo it holds. The only
copies left are the ones you made yourself — exports, backup files, and plans
or reviews you shared — and workouts you chose to write to Health Connect,
which stay there until you delete them (see Health Connect above). Gymfy has
no copy anywhere, so there is nothing to request and nobody to request it
from. Individual entries can be deleted inside the app at any time.

Because there is no server, **nothing is backed up for you**. To keep a copy,
or to move to a new phone, make a backup file (see Backup above) and restore
it there.

## Children

Gymfy is not directed at children under 13 and collects no data from anyone.

## Changes to this policy

If a future version of Gymfy ever collects anything, this page will be updated
before that version ships, and the change will be described in the release
notes rather than made quietly.

## Contact

gymfy.dev@gmail.com
