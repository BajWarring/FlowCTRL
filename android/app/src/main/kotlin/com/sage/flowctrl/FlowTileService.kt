package com.sage.flowctrl

import android.content.Context
import android.content.SharedPreferences
import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

class FlowTileService : TileService() {

    // Called when the user pulls down the notification shade and the tile is visible.
    // We use this to ensure the UI shows the correct current state.
    override fun onStartListening() {
        super.onStartListening()
        updateTileUi()
    }

    // Called when the user taps the tile.
    override fun onClick() {
        super.onClick()

        // 1. Get current state
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Note: We must use the "flutter." prefix that Flutter adds automatically
        val currentState = prefs.getBoolean("flutter.isBlockingEnabled", true)

        // 2. Toggle state
        val newState = !currentState

        // 3. Save new state. The Accessibility Service will pick this up automatically.
        prefs.edit().putBoolean("flutter.isBlockingEnabled", newState).apply()

        // 4. Update tile UI immediately
        updateTileUi()
    }

    private fun updateTileUi() {
        val tile = qsTile ?: return

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (isBlockingEnabled) {
            // STATE: ON
            tile.state = Tile.STATE_ACTIVE
            // Use the solid shield icon we created
            tile.icon = Icon.createWithResource(this, R.drawable.ic_qs_blocked)
            tile.label = "FlowCTRL: On"
        } else {
            // STATE: OFF
            tile.state = Tile.STATE_INACTIVE
            // Use the outline icon we created
            tile.icon = Icon.createWithResource(this, R.drawable.ic_qs_unblocked)
            tile.label = "FlowCTRL: Off"
        }

        // Apply changes
        tile.updateTile()
    }
}
