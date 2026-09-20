package de.kopten.gymfy.wear

import com.google.android.gms.wearable.DataMap

/**
 * What the phone last told us about the workout.
 *
 * Strings, already formatted. The watch deliberately knows nothing about
 * sets, units or schema versions — that rule is the reason the deleted
 * home-screen widgets were the one Kotlin surface in this project that never
 * broke when the database changed.
 */
data class WorkoutState(
    val active: Boolean = false,
    val workout: String = "",
    val exercise: String = "",
    val sets: String = "",
    /** Epoch millis when the rest ends, or 0 when nothing is resting. */
    val restEndsAtMs: Long = 0,
    val restTotalSeconds: Int = 0,
    /** Epoch millis of the push, so staleness can be shown rather than hidden. */
    val updatedAtMs: Long = 0,
    /** The last working set, ready to draw. Empty when there is none. */
    val lastSet: String = "",
) {
    val resting: Boolean get() = restEndsAtMs > 0

    /**
     * Whether this is old enough to be disbelieved.
     *
     * The watch only ever knows what it was last told, and the phone can
     * stop telling it — Android kills the app, the battery dies, the process
     * is swapped out mid-workout. When that happens the DataItem keeps
     * saying `active = true` forever and the watch shows a workout that
     * ended hours ago as though it were still running. That is the reported
     * "it still thinks the workout is going" and no amount of correctness on
     * the phone side fixes it, because the phone is not there.
     *
     * Six hours, deliberately generous: a long session plus a long break is
     * still a real workout, and wrongly blanking a live one is worse than
     * showing a stale one a while longer. A rest timer is exempt — it
     * carries its own deadline and expires on its own.
     */
    fun isStale(now: Long): Boolean =
        updatedAtMs > 0 && now - updatedAtMs > STALE_AFTER_MS

    /** As above, but already resolved — what the UI should actually show. */
    fun activeAt(now: Long): Boolean = active && !isStale(now)

    /**
     * Seconds left at [now], never negative.
     *
     * Computed here rather than sent, so the countdown stays correct while
     * the watch is out of range. The phone sends one deadline per rest
     * instead of one message per second.
     */
    fun remainingSeconds(now: Long): Int {
        if (!resting) return 0
        val left = (restEndsAtMs - now) / 1000
        return if (left < 0) 0 else left.toInt()
    }

    companion object {
        /**
         * Reads a number that may have been written as either width.
         *
         * Flutter's codec picks the narrowest type that fits, so the phone
         * side widens everything to Long before storing — but a *phone on an
         * older build* still writes Int, and then `getLong` throws
         * ClassCastException inside DataMap, logs a warning nobody reads,
         * and hands back the default.
         *
         * That failure is silent and its symptom is absurd: a zero
         * `restTotalSeconds` makes the progress denominator 1, every
         * fraction clamps to 1.0, and the ring renders permanently full.
         * "It does not shrink and it is all one colour" is what a divide-by
         * -one looks like.
         *
         * Two apps that update independently will be out of step sometimes —
         * a watch app is installed separately from its phone app and can
         * trail it for weeks. Reading both widths costs one try/catch and
         * removes the whole class.
         */
        private fun DataMap.number(key: String): Long =
            try {
                getLong(key, 0)
            } catch (_: ClassCastException) {
                getInt(key, 0).toLong()
            }

        fun from(map: DataMap): WorkoutState = WorkoutState(
            active = map.getBoolean("active", false),
            workout = map.getString("workout", ""),
            exercise = map.getString("exercise", ""),
            sets = map.getString("sets", ""),
            restEndsAtMs = map.number("restEndsAtMs"),
            // getLong, then narrowed: the phone widens every integer to Long
            // because Flutter's codec would otherwise send this field as Int
            // sometimes and Long other times. See WearBridge.push.
            restTotalSeconds = map.number("restTotalSeconds").toInt(),
            updatedAtMs = map.number("updatedAtMs"),
            lastSet = map.getString("lastSet", ""),
        )
    }
}

/** Formats seconds as m:ss, the way the phone app shows a rest. */
fun formatRest(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%d:%02d".format(m, s)
}

/**
 * The Data Layer path the phone writes to.
 *
 * Must match `WearBridge.WORKOUT_PATH` on the phone side. A mismatch is
 * silent — the watch simply never hears anything — so the two constants are
 * pinned by `wear_bridge_test.dart`, which reads both source files.
 */
const val WORKOUT_PATH = "/gymfy/workout"

/** Logcat tag, same on both sides: `adb logcat -s GymfyWear`. */
const val TAG = "GymfyWear"

/** How long a pushed state stays believable. See [WorkoutState.isStale]. */
const val STALE_AFTER_MS = 6L * 60 * 60 * 1000

/**
 * The path commands travel back to the phone on.
 *
 * Must match `WearBridge.COMMAND_PATH`. Pinned by `wear_bridge_test.dart`,
 * which reads both files — a mismatch here is silent in both directions.
 */
const val COMMAND_PATH = "/gymfy/command"

/** Commands the phone understands. Must match `WearBridge` in Dart. */
const val COMMAND_ADD_THIRTY = "rest.add30"
const val COMMAND_SKIP_REST = "rest.skip"

/** Log another set the same as the last. Must match `WearBridge` in Dart. */
const val COMMAND_REPEAT_SET = "set.repeat"
