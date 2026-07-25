# Gymfy — Build TODO

Track progress here. Update after each session.

## 🔴 Not started

### Phase 7 — Calories & Habit Tracker
- [ ] Weekly overview: calories + habit completion rate chart (fl\_chart)

### Phase 8 — Body Measurements & Progress Photos
- [ ] Define BodyMeasurement model (weight, chest, waist, hips, arms, legs + date)
- [ ] Build measurements input screen (update any field, auto-timestamp)
- [ ] Build measurements timeline chart per body part (fl\_chart)
- [ ] Build progress photos screen (pick from gallery, store local path + date)
- [ ] Build photo comparison view (side-by-side before/after)

### Phase 9 — 1RM Calculator
- [ ] Build 1RM calculator screen (input: weight + reps)
- [ ] Implement Epley formula: `1RM = weight × (1 + reps / 30)`
- [ ] Show results for all major formulas (Epley, Brzycki, Lander) with comparison
- [ ] Add "estimated 1RM" badge on exercise progress charts using best logged set
- [ ] Allow manual 1RM entry per exercise for users who test true max

### Phase 10 — Strength Rank per Exercise
- [ ] Define strength standard tables per exercise (Beginner / Novice / Intermediate / Advanced / Elite)
- [ ] Base rank on bodyweight ratio (lifted weight ÷ bodyweight)
- [ ] Build strength rank screen — shows rank per exercise with progress bar to next tier
- [ ] Show rank badge on exercise detail screen
- [ ] Prompt user to enter bodyweight if not set (link to measurements)

### Phase 11 — Android Home Screen Widgets
- [ ] Research Glance API compatibility with current Flutter version
- [ ] Build "Today's Workout" widget — shows split name + exercises for today
- [ ] Build "Weekly Volume" widget — total sets/weight this week
- [ ] Build "Streak" widget — current gym habit streak
- [ ] Test on physical device, handle widget refresh on workout completion

### Phase 12 — WearOS Companion App
- [ ] Set up WearOS module in project (separate Flutter app targeting Wear)
- [ ] Build active workout screen for watch (current exercise, set counter, rest timer)
- [ ] Sync active session between phone and watch via local broadcast / Wearable Data Layer
- [ ] Build quick log screen on watch (log set with weight + reps via scroll wheel)
- [ ] Build rest timer with haptic feedback on watch
- [ ] Build daily step / heart rate glance screen (if WearOS health APIs available)

### Phase 13 — Polish & Release
- [ ] App icon + splash screen
- [ ] Onboarding flow (first launch: set name, bodyweight, pick accent color)
- [ ] Settings screen (accent color picker, units kg/lbs, notification preferences)
- [ ] Rest timer with notification (configurable per exercise)
- [ ] Data export (CSV of all logged workouts)
- [ ] Play Store listing — screenshots, description, privacy policy
- [ ] Crash reporting (Firebase Crashlytics or Sentry)

## 🟡 In progress
<!-- Move tasks here when actively working on them -->

## 🟢 Done

### Phase 7 — Calories & Habit Tracker (in progress)
- [x] Define CalorieEntry and HabitEntry models in Drift
- [x] Build daily calorie log screen (add meals, track total vs. goal)
- [x] Build macro breakdown view (protein / carbs / fat)
- [x] Build habit tracker screen (daily checklist, streak counter)

### Phase 6 — Progress ✅
- [x] Build per-exercise progress chart (fl_chart)
- [x] Show personal records (PR) per exercise

### Phase 5 — Muscle map ✅
- [x] Source/create SVG body map (front + back) with named paths per muscle group
- [x] Build muscle map widget (flutter_svg + dynamic color intensity)
- [x] Wire up volume calculation from logged sets → intensity map
- [x] Build workout muscle map view + weekly muscle map view

### Phase 4 — Workout logging ✅
- [x] Define WorkoutSession, LoggedSet models
- [x] Build active workout screen (start session, log sets live)
- [x] Build workout completion summary screen
- [x] Persist all logged data to Drift

### Phase 3 — Workout builder ✅
- [x] Define Split, WorkoutDay, WorkoutExercise models
- [x] Build split creation screen
- [x] Build workout day builder (add/remove exercises, set default sets/reps)
- [x] Build split overview screen

### Phase 2 — Exercise library ✅
- [x] Define Exercise model (id, name, muscleIds, gifPath, category)
- [x] Create exercise seed data (20–30 exercises with muscleIds pre-assigned)
- [x] Build exercise list screen with search + filter by muscle group
- [x] Build exercise detail screen with GIF preview

### Phase 1 — Project foundation ✅
- [x] Initialize Flutter project (`flutter create gymfy`)
- [x] Add dependencies to pubspec.yaml (riverpod, drift, go_router, freezed, flutter_svg)
- [x] Set up dark theme + accent color system in `app/theme/`
- [x] Set up go_router with placeholder routes in `app/router/`
- [x] Set up Drift database shell in `shared/database/`
