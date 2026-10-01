package de.kopten.gymfy

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * What Health Connect shows when the user taps "privacy policy" next to
 * Gymfy's permissions.
 *
 * Health Connect refuses to offer an app's permissions at all unless the app
 * has a screen for this (ACTION_SHOW_PERMISSIONS_RATIONALE on Android 13 and
 * below, the VIEW_PERMISSION_USAGE alias on 14 and up — both in the
 * manifest).
 *
 * A plain native screen rather than a route into the Flutter app: it has to
 * open from Health Connect's settings whether or not Gymfy is running, before
 * onboarding is finished, and without starting the whole app to show a page
 * of text. And it reads the words from strings.xml rather than a web page, so
 * it works with no connection and never makes Gymfy fetch anything.
 * The text is the Health Connect section of store/privacy-policy.md in short.
 */
class HealthPermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val gutter = dp(20)
        val title = TextView(this).apply {
            text = getString(R.string.health_rationale_title)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(0, 0, 0, dp(12))
        }
        val body = TextView(this).apply {
            text = getString(R.string.health_rationale_body)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setLineSpacing(0f, 1.3f)
            setTextIsSelectable(true)
        }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(gutter, gutter, gutter, gutter)
            addView(title)
            addView(body)
        }
        val scroll = ScrollView(this).apply {
            addView(column)
            // Edge to edge is enforced from Android 15, so keep the text out
            // from under the status and navigation bars ourselves.
            setOnApplyWindowInsetsListener { view, insets ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val bars = insets.getInsets(android.view.WindowInsets.Type.systemBars())
                    view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                }
                insets
            }
        }
        setContentView(scroll)
    }

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value.toFloat(),
        resources.displayMetrics,
    ).toInt()
}
