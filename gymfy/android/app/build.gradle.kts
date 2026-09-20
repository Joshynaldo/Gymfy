import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key credentials, kept out of the repository. See android/key.properties.example.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties: Properties? = if (keystorePropertiesFile.exists()) {
    Properties().apply { keystorePropertiesFile.inputStream().use { load(it) } }
} else {
    null
}

android {
    namespace = "de.kopten.gymfy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications: it uses java.time APIs that
        // don't exist below API 26, and desugaring backports them.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Derived from the developer domain, matching the iOS bundle ID.
        // Locked in at first publish: Play and the App Store both treat it as
        // the app identity forever. It was still `com.example.gymfy`, which
        // Play rejects outright.
        applicationId = "de.kopten.gymfy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only wired up when android/key.properties exists. That file and
            // the .jks it points at are deliberately NOT in git: a leaked
            // upload key means someone else can push an update to this app.
            if (keystoreProperties != null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key so `flutter run --release` keeps
            // working on the bench. A debug-signed bundle is rejected by Play,
            // so the fallback is a convenience, never a shippable state — the
            // build prints a warning when it takes it.
            signingConfig = if (keystoreProperties != null) {
                signingConfigs.getByName("release")
            } else {
                println("WARNING Gymfy: no android/key.properties — signing release with the DEBUG key. This build cannot be uploaded to Play.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Backports java.time for API < 26. Paired with
    // isCoreLibraryDesugaringEnabled above; both are needed or neither works.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Phone side of the watch link. NOT Compose -- this is a plain Play
    // Services library, which is the whole reason it can live in :app when
    // Glance could not. Its cost to the phone build is measured in TODO.md.
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}

flutter {
    source = "../.."
}
