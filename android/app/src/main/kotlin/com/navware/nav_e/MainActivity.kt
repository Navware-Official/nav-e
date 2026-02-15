package com.navware.nav_e

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var wearBridge: WearBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wearBridge = WearBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        wearBridge?.attach()
    }

    override fun onDestroy() {
        wearBridge?.detach()
        wearBridge = null
        super.onDestroy()
    }
}
