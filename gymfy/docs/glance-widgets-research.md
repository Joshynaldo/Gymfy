# Phase 11 research — Jetpack Glance vs. this project's toolchain

Researched 26 Jul 2026. Answers one question: **can we build Android home screen
widgets on the toolchain Gymfy already has, and what does it cost?**

Short answer: **yes, it's compatible — but it is native Kotlin work, not Dart.**

## What this project is running

| Piece | Version | Where |
|---|---|---|
| Flutter | 3.44.7 (stable) | `flutter --version` |
| Dart | 3.12.2 | ” |
| Android Gradle Plugin | **9.0.1** | `android/settings.gradle.kts:22` |
| Kotlin Gradle Plugin | 2.3.20 (declared, `apply false`) | `android/settings.gradle.kts:23` |
| Gradle | 9.1.0 | `gradle/wrapper/gradle-wrapper.properties:5` |
| JDK used for builds | OpenJDK 21 (Android Studio JBR) | `flutter doctor -v` |
| compileSdk / targetSdk | 36 | Flutter default (`FlutterExtension.kt:23,34`) |
| minSdk | **24** | Flutter default (`FlutterExtension.kt:26`) |
| Java source/target | 17 | `app/build.gradle.kts:13-14` |

Note: `java -version` on PATH reports Java 8. That is irrelevant — Flutter uses
Android Studio's bundled JDK 21 for Gradle. Don't "fix" it.

## Compatibility findings

### 1. minSdk clears the bar

Glance moved its default `minSdk` from API 21 to **API 23** in 1.2.0-beta01. We
are on **24**. No conflict, nothing to raise.

### 2. AGP 9 already put us on the good side of the big 2026 breaking change

AGP 9.0 **removed support for applying the Kotlin Gradle Plugin** — built-in
Kotlin is now the default, and applying `org.jetbrains.kotlin.android` is a build
failure. This broke a large share of pub.dev plugins during 2026.

Gymfy is already in the migrated shape: `app/build.gradle.kts` applies only
`com.android.application` and `dev.flutter.flutter-gradle-plugin`, and sets the
JVM target through the modern `kotlin { compilerOptions { … } }` block. The KGP
entry in `settings.gradle.kts` is `apply false`, so it is declared but never
applied — harmless.

**Consequence for us:** every new dependency has to be AGP-9-clean. That is the
real compatibility risk in Phase 11, not Glance itself.

### 3. Glance version to use: 1.2.0-rc01, not the "stable" 1.1.1

- Latest **stable** is `1.1.1` — October 2024, ~21 months old, built in the
  Kotlin 1.9 era.
- Latest **RC** is `1.2.0-rc01` — December 2025.
- Latest **alpha** is `1.3.0-alpha02` — July 2026.

The nominally-stable 1.1.1 is the *riskier* choice here: its bundled Compose
runtime predates Kotlin 2.x, and the Compose compiler refuses runtimes older
than it expects. 1.2.0-rc01 is the version aligned with a Kotlin 2.x toolchain.
So the "safe" label is misleading — we want the RC.

### 4. Compose has to be turned on explicitly

Glance is Compose-based, so the widget module needs both:

```kotlin
android { buildFeatures { compose = true } }
```

and the Compose compiler plugin applied — `org.jetbrains.kotlin.plugin.compose`,
version-matched to Kotlin (2.3.20). Since Kotlin 2.0 the Compose compiler ships
inside Kotlin itself, so it is always compatible with the same-version Kotlin;
there is no separate compatibility table to chase and **no**
`composeOptions { kotlinCompilerExtensionVersion = … }` any more — that DSL is
gone.

### 5. The Dart↔widget bridge: `home_widget` 0.9.3

- Latest `0.9.3`, published ~June 2026 — actively maintained.
- Android + iOS. (iOS irrelevant to us.)
- **It has been explicitly fixed for our toolchain:** 0.9.2 shipped
  "Support Android Gradle Plugin 9.x", and 0.9.2+1 added "Apply kotlin plugin
  when not built in" — i.e. it detects built-in Kotlin instead of blindly
  applying KGP. This is exactly the AGP 9 hazard, already handled.

This is the one genuinely load-bearing external dependency and it checks out.

## What Phase 11 actually involves

Not Dart. The widget UI is **Kotlin** under
`android/app/src/main/kotlin/`, plus XML widget metadata under
`android/app/src/main/res/xml/`, plus manifest receiver entries. Concretely:

1. Add `home_widget` to `pubspec.yaml`, add Glance + Compose to
   `android/app/build.gradle.kts`.
2. Write a `GlanceAppWidget` subclass per widget in Kotlin.
3. Register each as an `AppWidgetProvider` receiver in `AndroidManifest.xml`.
4. On the Dart side, push data via `HomeWidget.saveWidgetData` +
   `HomeWidget.updateWidget` when a workout is completed.
5. Test on a **physical device** — hot reload does not touch a home screen
   widget. Every change is a full rebuild plus re-adding the widget.

### Cost and risk, honestly

- **Build times.** Enabling Compose in the app module adds the Compose compiler
  to every Android build. Expect noticeably slower cold builds.
- **APK size.** Glance pulls in Compose runtime + Glance itself. Meaningful
  growth for a widget most users may never add.
- **Older Android hardware** (a stated project concern): widget *rendering* is
  RemoteViews, so it stays cheap at display time. The cost is install size and
  the background work that refreshes data, not runtime jank.
- **No test coverage.** Nothing in Phase 11 is reachable from
  `flutter test`. Every one of the 161 existing tests stays green and none of
  them will cover this. Verification is manual, on-device, only.
- **Data access from Kotlin.** The widgets must not read the Drift/SQLite
  database directly — schema knowledge would then live in two languages. Push
  pre-computed values from Dart into `home_widget`'s shared prefs instead. This
  means a widget shows *last known* data, refreshed when the app writes.

## Recommendation

Technically green: nothing in the toolchain blocks this, and the one third-party
bridge is already AGP-9-clean. Versions to pin:

- `androidx.glance:glance-appwidget:1.2.0-rc01`
- `org.jetbrains.kotlin.plugin.compose` version `2.3.20`
- `home_widget: ^0.9.3`

Sequencing opinion: Phase 11 is the first work in this project with **no test
safety net and a manual-only verification loop**, and it needs a physical device
in hand for every iteration. Phase 13 (app icon, onboarding, settings screen —
already supported by the `AppSettings` table added in Phase 10) is testable,
lower-risk, and gets the app closer to installable. Doing 13 first costs
nothing and de-risks 11.
