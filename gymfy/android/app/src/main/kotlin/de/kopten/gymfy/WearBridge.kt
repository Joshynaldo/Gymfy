package de.kopten.gymfy

import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Pushes the live workout to the watch.
 *
 * Deliberately a hand-written platform channel rather than a pub package.
 * This project has lost days to plugins that pin their own Gradle
 * (`share_plus` x `file_picker` x AGP 9), it is past release, and the whole
 * surface here is one call. The CSV reader was written by hand for the same
 * reason.
 *
 * The rule from the deleted home-screen widgets applies unchanged: **the
 * watch never reads the database.** Dart formats the strings and sends them;
 * the Kotlin side knows nothing about sets, units or schema versions. Schema
 * knowledge stays in one language, and the cost is that the watch shows the
 * last state that was pushed rather than the truth as of this millisecond —
 * which for a wrist display is the right trade.
 *
 * A DataItem rather than a Message: DataItems are persisted and replayed by
 * the Data Layer, so a watch that was out of range or asleep gets the latest
 * state when it comes back. A Message needs both ends connected at the
 * instant it is sent, and the moment you look at your wrist is exactly the
 * moment the phone might be in a locker.
 */
object WearBridge {
    private const val TAG = "GymfyWear"
    private const val CHANNEL = "de.kopten.gymfy/wear"

    /** The Data Layer path the watch listens on. */
    const val WORKOUT_PATH = "/gymfy/workout"

    /**
     * The path the watch sends *commands* back on.
     *
     * A Message, not a DataItem, and the distinction is the point. State is
     * a DataItem because the watch should see the latest workout even if it
     * was asleep when it changed. A command is the opposite: "skip this
     * rest" means *now* or not at all. Replaying it twenty minutes later
     * when the watch reconnects would skip a rest nobody asked about.
     *
     * Messages are also only delivered while both ends are up, which here
     * is exactly right — there is no rest timer to control if the phone app
     * is not running.
     */
    const val COMMAND_PATH = "/gymfy/command"

    fun register(engine: FlutterEngine, context: android.content.Context) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

        // The watch talking back. Registered for as long as the engine is
        // alive, which is the only window in which a rest timer exists.
        Wearable.getMessageClient(context).addListener { message ->
            if (message.path == COMMAND_PATH) {
                val command = String(message.data)
                Log.i(TAG, "command from watch: $command")
                // onto the platform thread — this callback is not it.
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    channel.invokeMethod("watchCommand", command)
                }
            }
        }

        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "pushWorkout" -> {
                        @Suppress("UNCHECKED_CAST")
                        val fields = call.arguments as? Map<String, Any?>
                        if (fields == null) {
                            result.error("bad_args", "expected a map", null)
                        } else {
                            push(context, fields, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun push(
        context: android.content.Context,
        fields: Map<String, Any?>,
        result: MethodChannel.Result,
    ) {
        val request = PutDataMapRequest.create(WORKOUT_PATH).apply {
            for ((key, value) in fields) {
                when (value) {
                    null -> dataMap.remove(key)
                    is String -> dataMap.putString(key, value)
                    // Every integer crosses as a Long, including the ones
                    // that arrive as Int.
                    //
                    // Flutter's standard codec picks the narrowest type that
                    // fits, so the *same field* arrives as Integer when it is
                    // 0 and as Long when it holds an epoch millisecond. Stored
                    // faithfully, the watch's getLong then threw
                    // ClassCastException on exactly the frames where nothing
                    // was happening — caught only by reading logcat on the
                    // device, because it is a warning inside the Data Layer,
                    // not a crash.
                    //
                    // One rule instead of a per-key table: widen here, narrow
                    // on the watch. Keeps the bridge free of schema knowledge.
                    is Int -> dataMap.putLong(key, value.toLong())
                    is Long -> dataMap.putLong(key, value)
                    is Boolean -> dataMap.putBoolean(key, value)
                    // Anything else is a Dart type nobody agreed on. Failing
                    // loudly here beats a watch that silently shows a stale
                    // field forever.
                    else -> {
                        result.error(
                            "bad_value",
                            "unsupported type for '$key': ${value.javaClass.name}",
                            null,
                        )
                        return
                    }
                }
            }
        }

        Wearable.getDataClient(context)
            .putDataItem(
                request
                    // Without this, an identical payload is not re-delivered
                    // and the watch never hears about a change that happens
                    // to serialise the same — such as a rest timer restarted
                    // at the same duration.
                    .setUrgent()
                    .asPutDataRequest(),
            )
            .addOnSuccessListener {
                // One line per push, and pushes are throttled to real changes, so
                // this is a handful per workout rather than a stream. Worth it:
                // the failure mode of this whole feature is "the watch stays
                // blank and nothing anywhere says why".
                Log.i(
                    TAG,
                    "pushed active=${fields["active"]} " +
                        "workout=${fields["workout"]} " +
                        "rest=${fields["restEndsAtMs"]}",
                )
                result.success(null)
            }
            .addOnFailureListener {
                Log.w(TAG, "push failed", it)
                result.error("push_failed", it.message, null)
            }
    }
}
