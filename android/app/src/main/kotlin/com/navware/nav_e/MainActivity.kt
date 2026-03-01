package com.navware.nav_e

import android.content.Intent
import android.net.Uri
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var wearBridge: WearBridge? = null
    private var routeImportChannel: MethodChannel? = null

    /** URI from VIEW/SEND intent when user opens or shares a GPX file. Consumed by Flutter. */
    private var pendingImportUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wearBridge = WearBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        wearBridge?.attach()

        routeImportChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "org.navware.nav_e/route_import",
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingImportUri" -> {
                        val uri = pendingImportUri
                        pendingImportUri = null
                        result.success(uri)
                    }
                    "readFileFromUri" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID_ARGS", "uri required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriStr)
                            val bytes = when (uri.scheme) {
                                "content" -> contentResolver.openInputStream(uri)?.use { it.readBytes() }
                                "file" -> uri.path?.let { java.io.File(it).readBytes() }
                                else -> contentResolver.openInputStream(uri)?.use { it.readBytes() }
                            }
                            if (bytes != null && bytes.isNotEmpty()) {
                                result.success(Base64.encodeToString(bytes, Base64.NO_WRAP))
                            } else {
                                result.error("IO", "Could not open URI", null)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "readFileFromUri failed", e)
                            result.error("IO", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureImportUri(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        captureImportUri(intent)
    }

    private fun captureImportUri(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.toString()?.let { pendingImportUri = it }
            Intent.ACTION_SEND -> {
                @Suppress("DEPRECATION")
                (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: intent.getParcelableExtra(Intent.EXTRA_STREAM))?.toString()?.let {
                    pendingImportUri = it
                }
            }
        }
    }

    override fun onDestroy() {
        routeImportChannel?.setMethodCallHandler(null)
        routeImportChannel = null
        wearBridge?.detach()
        wearBridge = null
        super.onDestroy()
    }
}
