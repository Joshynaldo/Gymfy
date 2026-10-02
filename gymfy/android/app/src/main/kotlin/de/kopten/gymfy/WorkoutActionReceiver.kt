package de.kopten.gymfy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Receives the ongoing workout notification's button presses and hands them
 * to the running Flutter engine.
 *
 * Small on purpose. It knows nothing about what a command means — the
 * command string was written by Dart when the notification was posted, and
 * goes back to Dart unread, into the same handler the watch's commands use.
 */
class WorkoutActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val command = intent.getStringExtra(EXTRA_COMMAND) ?: return

        // Kept open until Dart says it is done. A tap that arrives while the
        // app is frozen in the background gets the process only for as long
        // as this broadcast lasts; finishing at once would let Android freeze
        // it again with the set half-written.
        val pending = goAsync()
        val finished = AtomicBoolean(false)
        val finish = {
            if (finished.compareAndSet(false, true)) pending.finish()
        }

        if (WearBridge.deliver(command) { finish() }) {
            // A guard, not the plan: Dart normally answers in milliseconds,
            // but an engine torn down mid-call never answers at all, and a
            // broadcast that never finishes is one Android eventually treats
            // as a hang.
            Handler(Looper.getMainLooper()).postDelayed({ finish() }, GIVE_UP_AFTER_MS)
            return
        }

        // Nobody to hand it to — the activity is gone, or this process was
        // started just now by the tap itself. Doing nothing would look like
        // a dead button, so the app is opened instead, and the notification
        // is switched to buttons that open it too.
        Log.i(TAG, "no engine for '$command' — opening the app instead")
        WorkoutNotification.detach(context)
        // Android 12 and later refuse an activity start from a receiver that
        // a notification started ("notification trampoline"), so there the
        // re-post above is the whole answer: the next tap opens the app
        // directly. Older versions allow it, and get the app at once.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            try {
                context.startActivity(WorkoutNotification.launchIntent(context))
            } catch (e: RuntimeException) {
                Log.w(TAG, "could not open the app", e)
            }
        }
        finish()
    }

    companion object {
        const val ACTION = "de.kopten.gymfy.WORKOUT_COMMAND"
        const val EXTRA_COMMAND = "command"

        private const val TAG = "GymfyWear"

        /** Inside the ten seconds a foreground broadcast may take. */
        private const val GIVE_UP_AFTER_MS = 8_000L
    }
}
