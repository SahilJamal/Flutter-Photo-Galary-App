package com.webzworld.photo_gallery

import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts one small platform call that photo_manager doesn't offer: favouriting
 * many items with a single MediaStore.createFavoriteRequest, so the user
 * confirms once for a whole selection.
 */
class MainActivity : FlutterActivity() {
    private var pendingFavorite: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setFavorite" -> setFavorite(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun setFavorite(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.success(false)
            return
        }
        if (pendingFavorite != null) {
            result.error("busy", "A favourite request is already in progress", null)
            return
        }
        val favorite = call.argument<Boolean>("favorite") ?: true
        val items = call.argument<List<Map<String, Any>>>("items").orEmpty()
        val uris = items.mapNotNull { item ->
            val id = (item["id"] as? String)?.toLongOrNull() ?: return@mapNotNull null
            val base = if (item["video"] == true) {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            ContentUris.withAppendedId(base, id)
        }
        if (uris.isEmpty()) {
            result.success(true)
            return
        }
        try {
            val request = MediaStore.createFavoriteRequest(contentResolver, uris, favorite)
            pendingFavorite = result
            startIntentSenderForResult(request.intentSender, REQUEST_FAVORITE, null, 0, 0, 0)
        } catch (e: Exception) {
            pendingFavorite = null
            result.error("failed", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_FAVORITE) {
            pendingFavorite?.success(resultCode == Activity.RESULT_OK)
            pendingFavorite = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    companion object {
        private const val CHANNEL = "photo_gallery/media"
        private const val REQUEST_FAVORITE = 0x4f41
    }
}
