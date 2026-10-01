package de.kopten.gymfy

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var health: HealthConnectBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WearBridge.register(flutterEngine, applicationContext)
        health = HealthConnectBridge(this).also { it.register(flutterEngine) }
    }

    // Health Connect's permission screen answers here: FlutterActivity is a
    // plain Activity, so there is no activity-result API to receive it.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (health?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
