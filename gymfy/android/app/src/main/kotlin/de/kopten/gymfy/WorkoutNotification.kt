package de.kopten.gymfy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle

/**
 * The running workout as one ongoing notification: the exercise, the set,
 * the rest countdown, and buttons to log the set and steer the rest.
 *
 * Built by hand rather than through flutter_local_notifications, which posts
 * the rest timer's own notifications. That plugin routes a button press into
 * a *background* Flutter engine of its own, with none of the running
 * workout's state; these buttons have to reach the engine that is already
 * running, so they are broadcasts to [WorkoutActionReceiver], which hands
 * them to [WearBridge.deliver] — the same door, and on the Dart side the same
 * handler, as a command from the watch.
 *
 * Same rule as the watch, too: Dart decides every word, in the app's language
 * — the button labels and the channel's name included. This side draws what
 * it is given and knows nothing about sets or units; the English it holds is
 * only a fallback for a field that did not arrive, and "+30 s", which reads
 * the same in every language the app speaks.
 */
object WorkoutNotification {
    /** Method names on the channel. Must match `WorkoutNotificationBridge` in Dart. */
    const val SHOW_METHOD = "showWorkoutNotification"
    const val CLEAR_METHOD = "clearWorkoutNotification"

    private const val CHANNEL_ID = "workout_in_progress"

    /**
     * Not 1: flutter_local_notifications posts the rest timer's countdown and
     * its "rest over" alert under id 1, and the alert has to be able to
     * appear without replacing this.
     */
    private const val NOTIFICATION_ID = 2

    /** Commands the rest buttons send. Must match `WearBridge` in Dart. */
    const val COMMAND_ADD_THIRTY = "rest.add30"
    const val COMMAND_SKIP_REST = "rest.skip"

    /**
     * Where the "tap to open" line rides along on the notification itself, so
     * [detach] can still say it in the app's language once nothing in Dart is
     * running to ask.
     */
    private const val EXTRA_TAP_TO_OPEN = "de.kopten.gymfy.TAP_TO_OPEN"

    // One request code per button, so their PendingIntents are three distinct
    // ones rather than one that each re-post overwrites.
    private const val REQUEST_LOG = 1
    private const val REQUEST_ADD_THIRTY = 2
    private const val REQUEST_SKIP = 3
    private const val REQUEST_OPEN = 4

    /**
     * Posts or updates the notification from the fields Dart sent: `title`,
     * `text`, `bigText`, `subText`, `restEndsAtMs` and `logCommand`, plus the
     * fixed words — `logLabel`, `skipRestLabel`, `tapToOpenLabel`,
     * `channelName` and `channelDescription`.
     *
     * Does nothing without notification permission, or with this one channel
     * switched off in the system settings. The app works the same without it,
     * and asking is Dart's job, at a moment that makes sense.
     *
     * Returns whether it is actually on screen, because Dart moves the rest
     * countdown in here when it is — and has to keep the rest timer's own
     * countdown when it is not, or there would be none at all.
     */
    fun show(context: Context, fields: Map<String, Any?>): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        if (!manager.areNotificationsEnabled()) return false
        ensureChannel(
            manager,
            name = fields["channelName"] as? String ?: "Workout in progress",
            description = fields["channelDescription"] as? String
                ?: "The current set and rest, with buttons to log and skip",
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL_ID)?.importance ==
            NotificationManager.IMPORTANCE_NONE
        ) {
            return false
        }

        val title = fields["title"] as? String ?: ""
        val text = fields["text"] as? String ?: ""
        val bigText = fields["bigText"] as? String ?: ""
        val subText = fields["subText"] as? String ?: ""
        // Number, not Long: the codec sends a small value as an Int.
        val restEndsAtMs = (fields["restEndsAtMs"] as? Number)?.toLong() ?: 0L
        val logCommand = fields["logCommand"] as? String ?: ""
        val logLabel = fields["logLabel"] as? String ?: "Log set"
        val skipRestLabel = fields["skipRestLabel"] as? String ?: "Skip rest"
        val tapToOpenLabel = fields["tapToOpenLabel"] as? String ?: "Tap to open Gymfy"
        val resting = restEndsAtMs > 0

        val builder = newBuilder(context)
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(title)
            .setContentText(text)
            // Tapping the body always opens the app, engine or no engine.
            .setContentIntent(openApp(context))
            // A workout in progress is not a message to swipe away. It goes
            // when the workout does.
            .setOngoing(true)
            // Updated after every set and every rest: none of that may buzz.
            .setOnlyAlertOnce(true)
            // On the lock screen in full, because that is where the buttons
            // are worth most — the phone on the bench, locked, between sets.
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .addExtras(Bundle().apply { putString(EXTRA_TAP_TO_OPEN, tapToOpenLabel) })
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setCategory(Notification.CATEGORY_WORKOUT)
        }
        if (bigText.isNotEmpty()) builder.setStyle(Notification.BigTextStyle().bigText(bigText))
        if (subText.isNotEmpty()) builder.setSubText(subText)

        if (resting) {
            // The three lines that make the system do the counting, as in the
            // watch's RestNotification: `when` is the deadline, the
            // chronometer renders the difference, and countDown runs it
            // towards zero. It keeps moving while this process is frozen,
            // which is the normal state of an app in a pocket.
            builder
                .setWhen(restEndsAtMs)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
        }

        if (logCommand.isNotEmpty()) {
            builder.addAction(action(context, logLabel, command(context, REQUEST_LOG, logCommand)))
        }
        // Only while there is a rest to extend or skip: a dead button is
        // worse than an absent one — the same call the watch makes.
        if (resting) {
            builder.addAction(
                action(context, "+30 s", command(context, REQUEST_ADD_THIRTY, COMMAND_ADD_THIRTY)),
            )
            builder.addAction(
                action(context, skipRestLabel, command(context, REQUEST_SKIP, COMMAND_SKIP_REST)),
            )
        }

        manager.notify(NOTIFICATION_ID, builder.build())
        return true
    }

    /** Removes the notification — the workout finished or was discarded. */
    fun clear(context: Context) {
        context.getSystemService(NotificationManager::class.java)?.cancel(NOTIFICATION_ID)
    }

    /**
     * Re-posts the notification with every button opening the app.
     *
     * For when there is no engine left to hand a command to: the activity was
     * destroyed, or Android killed the process and a button press started a
     * fresh one. Rebuilt from the notification that is actually showing
     * rather than from anything kept in memory, because in the second case
     * there is no memory — this process has never seen it.
     *
     * The buttons stay where they were, so the thumb that reaches for "Log
     * set" still finds it; it now opens Gymfy, which posts a live one again
     * as soon as it is running.
     */
    fun detach(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val showing = manager.activeNotifications
            .firstOrNull { it.id == NOTIFICATION_ID }
            ?.notification ?: return

        val open = openApp(context)
        val actions = (showing.actions ?: emptyArray())
            .map { Notification.Action.Builder(it.getIcon(), it.title, open).build() }
            .toTypedArray()
        val builder = Notification.Builder.recoverBuilder(context, showing)
            .setActions(*actions)
            // The one line Dart cannot write at the time, since nothing in
            // Dart is running: worded when the notification was last posted.
            .setSubText(showing.extras.getString(EXTRA_TAP_TO_OPEN) ?: "Tap to open Gymfy")
        manager.notify(NOTIFICATION_ID, builder.build())
    }

    /**
     * Creates the channel, or renames it. Android keeps everything else the
     * user changed about an existing channel and only takes the new name and
     * description — which is what lets it follow the app's language.
     */
    private fun ensureChannel(manager: NotificationManager, name: String, description: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            name,
            // Low: it sits in the shade and on the lock screen without ever
            // making a sound. The rest timer's "rest over" alert is the one
            // that interrupts, on its own channel.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            this.description = description
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun newBuilder(context: Context): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

    private fun action(context: Context, label: String, intent: PendingIntent) =
        Notification.Action.Builder(
            Icon.createWithResource(context, R.drawable.ic_launcher_monochrome),
            label,
            intent,
        ).build()

    /** A broadcast carrying [command] to [WorkoutActionReceiver]. */
    private fun command(context: Context, request: Int, command: String): PendingIntent {
        val intent = Intent(context, WorkoutActionReceiver::class.java)
            .setAction(WorkoutActionReceiver.ACTION)
            .putExtra(WorkoutActionReceiver.EXTRA_COMMAND, command)
        // UPDATE_CURRENT so a re-post replaces the extras: the log command
        // carries a new id every time the notification changes.
        return PendingIntent.getBroadcast(
            context,
            request,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Brings Gymfy to the front, the way the launcher icon does. */
    fun openApp(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            launchIntent(context),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    /**
     * MAIN/LAUNCHER, so an existing task comes to the front instead of a
     * second activity being stacked on top of it.
     */
    fun launchIntent(context: Context): Intent =
        Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
}
