package com.sage.flowctrl

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sage.flowctrl/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // This is the "Bridge" listening for commands from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setTileEnabled") {
                // Flutter sent "true" or "false"
                val enable = call.argument<Boolean>("enabled") ?: true
                setTileState(enable)
                result.success(null)
            } else if (call.method == "isTileEnabled") {
                // Flutter wants to know the current state
                result.success(isTileEnabled())
            } else {
                result.notImplemented()
            }
        }
    }

    // The actual logic to HIDE/SHOW the tile in Android System
    private fun setTileState(enabled: Boolean) {
        val pm = packageManager
        val componentName = ComponentName(this, FlowTileService::class.java)
        
        val newState = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            // This makes the tile disappear from the Quick Settings edit menu completely
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }

        pm.setComponentEnabledSetting(
            componentName,
            newState,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun isTileEnabled(): Boolean {
        val pm = packageManager
        val componentName = ComponentName(this, FlowTileService::class.java)
        val state = pm.getComponentEnabledSetting(componentName)
        return state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED || 
               state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
    }
}
