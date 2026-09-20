package de.kopten.gymfy.wear

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * The rest countdown, drawn by the system instead of by us.
 *
 * ## Why this exists at all
 *
 * The in-app ring is only correct while the app is actually running, and on
 * a watch that is a much narrower window than it sounds. Logcat, during a
 * real rest:
 *
 *     D ActivityManager: freezing 17757 de.kopten.gymfy
 *
 * Once the wrist drops and the activity stops, Android freezes the process.
 * A frozen process runs nothing — the tick coroutine stops, recomposition
 * stops, and the display keeps whatever frame it had. The countdown appears
 * to stall, which is exactly the reported bug, and no amount of
 * FLAG_KEEP_SCREEN_ON fixes it because the problem is not the screen.
 *
 * A chronometer notification has none of that dependency: the system is
 * given a deadline once and renders the countdown itself, whether our
 * process is alive, frozen or dead. It also survives the app being closed,
 * which is the normal way to use a watch during a set.
 *
 * This is the same shape as the phone app's own rest notification, and the
 * same reason the payload carries a deadline rather than seconds remaining.
 */
object RestNotification {
    private const val CHANNEL_ID = "rest_timer"
    private const val NOTIFICATION_ID = 1

    fun ensureChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Rest timer",
            // High, because the whole point is that it reaches you when you
            // are not looking. Vibration is handled by the channel so the
            // buzz survives the app being frozen too.
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "The countdown between sets"
            enableVibration(true)
        }
        context.getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    private fun allowed(context: Context): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

    /** Shows a countdown that ends at [endsAtMs], for [exercise]. */
    fun show(context: Context, exercise: String, endsAtMs: Long) {
        if (!allowed(context)) return

        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(exercise.ifEmpty { "Rest" })
            // The three lines that make the system do the counting: `when` is
            // the deadline, the chronometer renders the difference, and
            // countDown makes it run towards zero rather than up from it.
            .setWhen(endsAtMs)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    /** Clears the countdown — no rest, or the rest is over. */
    fun clear(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
