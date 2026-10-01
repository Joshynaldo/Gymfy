package de.kopten.gymfy

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.ChecksSdkIntAtLeast
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine

/**
 * The Dart side's way into Health Connect: availability, permissions,
 * writing finished workouts, reading bodyweight.
 *
 * A hand-written platform channel rather than a pub package, for the reason
 * WearBridge gives: this project has lost days to plugins that pin their own
 * Gradle (`share_plus` x `file_picker` x AGP 9), and the surface needed here
 * is a handful of calls. Same rule as the watch, too — **Kotlin knows nothing
 * about sessions, sets or units.** Dart decides which workouts to write and
 * which weigh-ins to keep; this file only moves plain values across.
 *
 * Health Connect is on-device IPC to the Health Connect app (or, from Android
 * 14, to the system). Nothing here opens a connection, and the app still has
 * no INTERNET permission.
 *
 * **Never touches the library below Android 8.** connect-client declares
 * minSdk 26 and the app runs from 24, which the manifest's
 * `tools:overrideLibrary` allows only because every path into the library
 * goes through [supported] first. The library lives behind [HealthConnectOps]
 * so that not even its classes are loaded on a phone that cannot run them.
 *
 * An instance per activity rather than an `object` like WearBridge: asking
 * for permissions needs the activity itself, and an object holding one would
 * outlive it.
 */
class HealthConnectBridge(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())

    /** Waiting for the permission screen to come back, if it is open. */
    private var pendingPermissions: MethodChannel.Result? = null

    /**
     * One client for the activity's lifetime rather than one per call: on
     * Android 13 and below each client binds to the Health Connect app.
     * Lazy, so nothing of the library is loaded until a call has passed the
     * version check. The application context, so it holds no activity.
     */
    private val ops by lazy { HealthConnectOps(activity.applicationContext) }

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        // Availability is the one question with an answer on every phone:
        // "no" is a fine answer, and the settings screen shows it.
        if (call.method == "availability") {
            result.success(
                if (supported) HealthConnectOps.availability(activity) else "unsupported",
            )
            return
        }
        if (call.method == "openStore") {
            result.success(openStore())
            return
        }

        // Everything else needs Health Connect to actually be there. Checked
        // here as well as in Dart, because a call from a stale screen (the
        // user uninstalled Health Connect a minute ago) must fail as an error
        // rather than throw inside the library.
        if (!supported || HealthConnectOps.availability(activity) != "available") {
            result.error("unavailable", "Health Connect is not available", null)
            return
        }

        when (call.method) {
            "grantedPermissions" -> runAsync(result) { ops.grantedPermissions().toList() }
            "requestPermissions" -> requestPermissions(call, result)
            "writeSessions" -> {
                val sessions = call.arguments as? List<*>
                if (sessions == null) {
                    result.error("bad_args", "expected a list of sessions", null)
                } else {
                    runAsync(result) {
                        ops.writeSessions(sessions.filterIsInstance<Map<*, *>>())
                        null
                    }
                }
            }
            "deleteSessions" -> {
                val ids = (call.arguments as? List<*>)?.filterIsInstance<String>()
                if (ids == null) {
                    result.error("bad_args", "expected a list of client record ids", null)
                } else {
                    runAsync(result) {
                        ops.deleteSessions(ids)
                        null
                    }
                }
            }
            "readWeights" -> {
                val start = call.argument<Number>("startMs")?.toLong()
                val end = call.argument<Number>("endMs")?.toLong()
                if (start == null || end == null || end <= start) {
                    result.error("bad_args", "expected startMs < endMs", null)
                } else {
                    runAsync(result) { ops.readWeights(start, end) }
                }
            }
            "openHealthConnect" -> result.success(launch(ops.manageDataIntent()))
            else -> result.notImplemented()
        }
    }

    /**
     * Opens Health Connect's own permission screen.
     *
     * startActivityForResult rather than the AndroidX result API: FlutterActivity
     * is a plain Activity, not a ComponentActivity, so there is no
     * registerForActivityResult to call. The contract still builds the intent
     * and parses the answer — which differ between the Health Connect app on
     * Android 13 and below and the system on 14 and up — so none of that
     * difference leaks into this file.
     */
    private fun requestPermissions(call: MethodCall, result: MethodChannel.Result) {
        val asked = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet()
        // Only ever the permissions the manifest declares. Anything else is a
        // Dart typo, and Health Connect would silently drop it from the screen.
        val wanted = asked?.intersect(HealthConnectOps.PERMISSIONS)
        if (wanted.isNullOrEmpty()) {
            result.error("bad_args", "no known permissions requested", null)
            return
        }
        if (pendingPermissions != null) {
            result.error("busy", "a permission request is already open", null)
            return
        }
        pendingPermissions = result
        try {
            activity.startActivityForResult(ops.permissionIntent(wanted), REQUEST_PERMISSIONS)
        } catch (e: ActivityNotFoundException) {
            pendingPermissions = null
            result.error("unavailable", "Health Connect cannot ask for permissions", null)
        }
    }

    /** Forwarded from MainActivity. True when the result was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PERMISSIONS) return false
        val result = pendingPermissions ?: return true
        pendingPermissions = null
        // The contract reports what was granted on *that* screen, which can
        // leave out a permission granted earlier. Asking afresh gives the
        // whole picture, which is what the settings screen draws.
        if (!supported || HealthConnectOps.availability(activity) != "available") {
            result.success(emptyList<String>())
            return true
        }
        runAsync(result) { ops.grantedPermissions().toList() }
        return true
    }

    /**
     * Sends the user to the Play Store page for Health Connect, which is
     * where both "install" and "update" happen on Android 13 and below.
     *
     * The Play Store app does the downloading. Gymfy only hands it an intent,
     * the same way Help hands a link to the browser.
     */
    private fun openStore(): Boolean {
        val uri = Uri.parse(
            "market://details?id=$PROVIDER_PACKAGE&url=healthconnect%3A%2F%2Fonboarding",
        )
        return launch(
            Intent(Intent.ACTION_VIEW, uri).setPackage("com.android.vending"),
        )
    }

    private fun launch(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        Log.w(TAG, "nothing to open ${intent.action}", e)
        false
    }

    /**
     * Runs a suspend call and answers [result] on the main thread.
     *
     * Started with the standard library's startCoroutine rather than
     * kotlinx.coroutines, so this file adds no dependency of its own beyond
     * connect-client. Nothing here needs cancelling: every call is one short
     * IPC round trip, and Dart is awaiting the answer.
     */
    private fun <T> runAsync(result: MethodChannel.Result, block: suspend () -> T) {
        block.startCoroutine(
            Continuation(EmptyCoroutineContext) { outcome ->
                // Health Connect answers on its own threads; a channel result
                // has to go back on the main one.
                main.post {
                    outcome.fold(
                        onSuccess = { result.success(it) },
                        onFailure = {
                            // One line per failure. The failure mode of this
                            // whole feature is "nothing shows up in Health
                            // Connect and nothing says why".
                            Log.w(TAG, "health connect call failed", it)
                            result.error(
                                "failed",
                                it.message ?: it.javaClass.simpleName,
                                it.javaClass.simpleName,
                            )
                        },
                    )
                }
            },
        )
    }

    companion object {
        private const val TAG = "GymfyHealth"
        private const val CHANNEL = "de.kopten.gymfy/health_connect"
        private const val REQUEST_PERMISSIONS = 0x4843

        /** The Health Connect app on Android 13 and below. */
        const val PROVIDER_PACKAGE = "com.google.android.apps.healthdata"

        /**
         * Whether this phone may load the library at all — its own minSdk.
         * Health Connect itself needs Android 9, which [HealthConnectOps.availability]
         * reports as "unsupported" on 8.x.
         */
        val supported: Boolean
            @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.O)
            get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }
}
