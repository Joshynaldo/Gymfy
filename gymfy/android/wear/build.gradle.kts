// The Wear OS companion, as its OWN module.
//
// This is the difference from Phase 11, which was deleted. Those home-screen
// widgets put Kotlin/Glance and the Compose compiler inside `:app`, so every
// phone build compiled Compose and the cold build went from ~11s to ~94s.
// Nothing here is on `:app`'s compile path — `flutter run` does not build this
// module at all. See TODO.md, Phase 12, for the measurements.

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "de.kopten.gymfy.wear"
    compileSdk = 36

    defaultConfig {
        // Deliberately the SAME applicationId as the phone app. Play pairs a
        // watch APK with its phone app by package name and signature; a
        // different id would publish as an unrelated app that happens to look
        // similar.
        applicationId = "de.kopten.gymfy"

        // Wear OS 3 and up. Wear 2 uses a different, older app model, and the
        // watch on the wrist here is the thing worth supporting.
        minSdk = 30
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    buildTypes {
        release {
            // Same story as the phone app: signed with the debug key until
            // android/key.properties exists. A watch APK must be signed with
            // the SAME key as the phone app or Play will not pair them.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2026.05.00"))
    implementation("androidx.wear.compose:compose-material3:1.5.6")
    implementation("androidx.wear.compose:compose-foundation:1.5.6")
    implementation("androidx.activity:activity-compose:1.12.0")
    implementation("androidx.core:core-ktx:1.17.0")
    // Phone ↔ watch messaging. Present from the start because the whole point
    // of stage 1 is the phone pushing the live workout across.
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}
