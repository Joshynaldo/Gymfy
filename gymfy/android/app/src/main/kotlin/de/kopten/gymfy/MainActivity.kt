package de.kopten.gymfy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WearBridge.register(flutterEngine, applicationContext)
        // The activity rather than the application context: the share sheet
        // is a screen, and starting one from outside an activity needs
        // NEW_TASK and opens it as a task of its own.
        ShareBridge.register(flutterEngine, this)
    }
}
