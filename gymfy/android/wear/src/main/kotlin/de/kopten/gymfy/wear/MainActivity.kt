package de.kopten.gymfy.wear

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.pm.PackageManager
import android.view.WindowManager
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ProgressIndicatorDefaults
import androidx.wear.compose.material3.Text
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.delay

/**
 * The watch face for a workout in progress.
 *
 * Stage 1 is read-only on purpose. The phone is the only writer, so there is
 * no sync conflict to resolve and no queue to replay — the hard half of a
 * watch companion is logging *from* the wrist, and that is stage 2.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keeps the ring live while you are actually looking at the app.
        //
        // Worth having, but it is NOT what makes the countdown reliable, and
        // believing it was cost a round trip: once the wrist drops Android
        // freezes the whole process ("freezing … de.kopten.gymfy" in
        // logcat), and a frozen process cannot redraw no matter what the
        // screen is doing. The countdown that survives that is the
        // chronometer notification — see RestNotification.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        RestNotification.ensureChannel(this)
        // Asked for plainly rather than gated behind a rationale screen: on
        // a watch the notification *is* the feature, so a refusal means the
        // in-app ring only.
        if (ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                1,
            )
        }

        setContent { WearApp(intent.getIntExtra("demoRestSeconds", 0)) }
    }
}

/**
 * Renders a fake rest for [demoRestSeconds], instead of listening to the
 * phone.
 *
 * A debug affordance, and it earns its keep: reproducing a real rest needs
 * a phone, a workout, a logged set and a wrist, and the interesting moment
 * lasts ninety seconds. Three rounds of "start a set and tell me what you
 * see" is a slow and unreliable way to look at a ring.
 *
 *     adb shell am start -n de.kopten.gymfy/de.kopten.gymfy.wear.MainActivity \
 *       --ei demoRestSeconds 60
 */
@Composable
fun WearApp(demoRestSeconds: Int = 0) {
    val context = LocalContext.current
    var state by remember {
        mutableStateOf(
            if (demoRestSeconds > 0) {
                WorkoutState(
                    active = true,
                    workout = "Demo",
                    exercise = "Bench Press",
                    sets = "3 sets logged",
                    restEndsAtMs = System.currentTimeMillis() + demoRestSeconds * 1000L,
                    restTotalSeconds = demoRestSeconds,
                )
            } else {
                WorkoutState()
            },
        )
    }

    DisposableEffect(context) {
        // The demo state is the point of the demo; letting the phone's real
        // payload land on top of it would defeat it.
        if (demoRestSeconds > 0) return@DisposableEffect onDispose { }

        val client = Wearable.getDataClient(context)

        // Read what is already there before listening for changes. DataItems
        // persist, so the current workout is usually sitting in the Data
        // Layer already — without this the watch shows an empty screen until
        // the phone happens to push again, which during a long set is a
        // while.
        Log.i(TAG, "listening on " + WORKOUT_PATH)

        client.dataItems.addOnSuccessListener { buffer ->
            buffer.forEach { item ->
                if (item.uri.path == WORKOUT_PATH) {
                    state = WorkoutState.from(DataMapItem.fromDataItem(item).dataMap)
                    Log.i(TAG, "restored " + state)
                }
            }
            buffer.release()
        }

        val listener = DataClient.OnDataChangedListener { events: DataEventBuffer ->
            events.forEach { event ->
                if (event.type == DataEvent.TYPE_CHANGED &&
                    event.dataItem.uri.path == WORKOUT_PATH
                ) {
                    state = WorkoutState.from(
                        DataMapItem.fromDataItem(event.dataItem).dataMap,
                    )
                    Log.i(TAG, "received " + state)
                }
            }
            events.release()
        }
        client.addListener(listener)

        onDispose { client.removeListener(listener) }
    }

    MaterialTheme {
        Box(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            contentAlignment = Alignment.Center,
        ) {
            // activeAt, not active: a state the phone stopped updating
            // hours ago is not a running workout. See WorkoutState.isStale.
            if (!state.activeAt(System.currentTimeMillis())) Idle() else Workout(state)
        }
    }
}

@Composable
private fun Idle() {
    Text(
        text = "No workout running",
        textAlign = TextAlign.Center,
        style = MaterialTheme.typography.bodyMedium,
    )
}

@Composable
private fun Workout(state: WorkoutState) {
    val context = LocalContext.current

    // Ticks locally off the deadline the phone sent. One message per rest
    // instead of one per second, and it keeps counting correctly even if the
    // phone goes out of range mid-rest.
    // Held as the State object, not just its delegated value: the progress
    // ring reads it *inside* its draw lambda, which is how that API is meant
    // to be used and the only way the arc re-reads it.
    val nowState = remember { mutableStateOf(System.currentTimeMillis()) }
    var now by nowState
    LaunchedEffect(state.restEndsAtMs) {
        while (state.resting) {
            now = System.currentTimeMillis()
            if (now >= state.restEndsAtMs) break
            delay(250)
        }
        now = System.currentTimeMillis()
    }

    val remaining = state.remainingSeconds(now)

    // Hand the deadline to the system, which renders the countdown and
    // fires the alert whether this process is alive, frozen or gone. This
    // is the part that keeps working when the wrist drops — the ring above
    // only survives while the app is foreground and unfrozen.
    LaunchedEffect(state.restEndsAtMs, state.exercise) {
        if (state.resting) {
            RestNotification.show(context, state.exercise, state.restEndsAtMs)
        } else {
            RestNotification.clear(context)
        }
    }

    // The in-app buzz, for when the app *is* foreground. The notification
    // channel covers the frozen case, so this is the redundant half rather
    // than the load-bearing one.
    LaunchedEffect(state.restEndsAtMs) {
        if (!state.resting) return@LaunchedEffect
        val wait = state.restEndsAtMs - System.currentTimeMillis()
        if (wait > 0) delay(wait)
        buzz(context)
    }

    if (state.resting || remaining > 0) {
        RestTimer(state = state, remaining = remaining, nowState = nowState)
    } else {
        Summary(state)
    }
}

@Composable
private fun RestTimer(
    state: WorkoutState,
    remaining: Int,
    nowState: androidx.compose.runtime.State<Long>,
) {
    // Falls back to the remaining time rather than to 1.
    //
    // `coerceAtLeast(1)` was the bug's amplifier: a missing total made the
    // denominator 1, every fraction clamped to 1.0, and the ring sat
    // permanently full — which looks like a broken widget rather than
    // missing data. Falling back to `remaining` makes an unknown total
    // render as a full ring that still empties, which is wrong but honest
    // and self-correcting on the next push.
    val total = state.restTotalSeconds
        .coerceAtLeast(remaining)
        .coerceAtLeast(1)
    Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
        CircularProgressIndicator(
            // Empties as the rest runs down, rather than filling up.
            //
            // Two reasons, and the first is the reported bug. Filling meant
            // progress started at 1 - 59/60 = 0.017: a ring with essentially
            // nothing drawn for the first stretch of every rest, which reads
            // as "the ring does not work" because there is nothing there to
            // watch. Depleting starts full, so it is visible from the first
            // frame and obviously moving.
            //
            // Second, the phone's bar depletes. The same event running in
            // opposite directions on two screens is a thing you have to
            // stop and translate mid-set.
            // Reads `nowState` INSIDE the lambda, rather than closing over an
            // already-computed Int.
            //
            // This is the whole bug. A lambda capturing a plain value hands
            // the draw a dead snapshot: the text beside it recomposed every
            // second while the arc kept whatever it drew first. Proved with
            // a probe — a constant 0.25f rendered a correct quarter, so the
            // widget was fine and the value was fine; only the *subscription*
            // was missing. Reading state here makes the draw scope observe it
            // and invalidate on every change, which is why these APIs take a
            // lambda instead of a Float in the first place.
            progress = {
                (state.remainingSeconds(nowState.value).toFloat() / total)
                    .coerceIn(0f, 1f)
            },
            // Explicit stroke and inset rather than the defaults.
            //
            // At fillMaxSize() the ring lands within a few pixels of a
            // *round* display's edge, where this watch's bezel and corner
            // darkening eat it, and the default stroke is thin enough that
            // there was nothing left to notice. Neither is wrong on a
            // rectangle, which is where the default was chosen.
            modifier = Modifier.fillMaxSize().padding(6.dp),
            strokeWidth = 10.dp,
            // Explicit colours, because the defaults made the ring look
            // broken in a very specific way: indicator and track were close
            // enough in tone that a 46%-complete arc over a full track read
            // as one unbroken ring. Two screenshots 45 seconds apart showed
            // the number going 1:56 -> 0:55 with the ring *pixel-identical*
            // — it was updating the whole time, just invisibly.
            //
            // The track has to stay visible rather than go to zero alpha:
            // an unlit arc on a black screen is just a shorter arc, and you
            // cannot tell a third left from a third used. Same reasoning as
            // the phone bar's track.
            colors = ProgressIndicatorDefaults.colors(
                indicatorColor = Color(0xFF7C6BFF),
                trackColor = Color(0x33FFFFFF),
            ),
        )
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = if (remaining > 0) formatRest(remaining) else "Rest over",
                style = MaterialTheme.typography.displaySmall,
            )
            if (state.exercise.isNotEmpty()) {
                Text(
                    text = state.exercise,
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun Summary(state: WorkoutState) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = state.workout,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.titleMedium,
        )
        Text(
            text = state.sets,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

/** A double tap, distinct from a notification's single buzz. */
private fun buzz(context: Context) {
    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val manager =
            context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
        manager?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }
    vibrator?.vibrate(
        VibrationEffect.createWaveform(longArrayOf(0, 180, 120, 180), -1),
    )
}
