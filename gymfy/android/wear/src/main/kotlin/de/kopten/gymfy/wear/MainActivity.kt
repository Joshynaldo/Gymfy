package de.kopten.gymfy.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text

/// The watch app's entry point.
///
/// Deliberately empty of features right now. This exists so the module can be
/// built and the cold-build cost measured before anything depends on it —
/// Phase 11 was a finished, working feature that had to be deleted because
/// that number was only looked at afterwards.
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { WearApp() }
    }
}

@Composable
fun WearApp() {
    MaterialTheme {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            Text("Gymfy")
        }
    }
}
