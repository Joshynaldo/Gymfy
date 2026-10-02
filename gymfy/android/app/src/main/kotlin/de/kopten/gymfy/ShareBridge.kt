package de.kopten.gymfy

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The app's own FileProvider, so the share sheet can read a file from the
 * cache without the file being world-readable.
 *
 * A subclass rather than `androidx.core.content.FileProvider` named directly
 * in the manifest: two libraries declaring that same class with different
 * authorities is a manifest-merge failure, and a plugin added next year
 * should not be able to break the build by doing so.
 */
class ShareFileProvider : FileProvider()

/**
 * Hands a picture to Android's share sheet.
 *
 * A hand-written channel for the same reason as [WearBridge]: `share_plus`
 * cannot be built alongside `file_picker` on this toolchain, and the whole
 * surface needed here is one call. Dart renders the PNG and writes it into
 * the cache; this side only wraps it in a `content://` URI and fires
 * `ACTION_SEND`. Nothing is sent anywhere except by the app the user picks.
 */
object ShareBridge {
    private const val TAG = "GymfyShare"
    private const val CHANNEL = "de.kopten.gymfy/share"

    /**
     * Appended to the package name to make the provider's authority. Must
     * match `android:authorities` in AndroidManifest.xml.
     */
    const val AUTHORITY_SUFFIX = ".shareprovider"

    fun register(engine: FlutterEngine, activity: Activity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "expected a path", null)
                        } else {
                            share(
                                activity,
                                File(path),
                                call.argument<String>("mimeType") ?: "image/png",
                                call.argument<String>("title"),
                                result,
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun share(
        activity: Activity,
        file: File,
        mimeType: String,
        title: String?,
        result: MethodChannel.Result,
    ) {
        try {
            // Throws for a file outside the folders share_paths.xml lists —
            // which is what keeps this channel from handing out anything but
            // the pictures Dart put there for the purpose.
            val uri = FileProvider.getUriForFile(
                activity,
                activity.packageName + AUTHORITY_SUFFIX,
                file,
            )
            val send = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                // ClipData as well as the extra: the chooser's preview and
                // the receiving app read the grant from here on Android 10+.
                clipData = ClipData.newRawUri(null, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            activity.startActivity(Intent.createChooser(send, title))
            result.success(true)
        } catch (e: Exception) {
            // Dart falls back to the save dialog on any error, so a failure
            // here costs a tap rather than the picture.
            Log.w(TAG, "share failed", e)
            result.error("share_failed", e.message, null)
        }
    }
}
