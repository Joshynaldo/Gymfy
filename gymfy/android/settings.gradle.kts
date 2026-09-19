pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Kotlin 2.x ships the Compose compiler as its own plugin. Declared here,
    // applied only by :wear — :app must never pick it up, which is exactly
    // what made Phase 11's widgets unaffordable.
    id("org.jetbrains.kotlin.plugin.compose") version "2.3.20" apply false
}

include(":app")

// The Wear OS companion. Built on demand (`gradlew :wear:assembleDebug`),
// never by `flutter run` — see wear/build.gradle.kts.
include(":wear")
