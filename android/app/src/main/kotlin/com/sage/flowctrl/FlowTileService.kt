package com.sage.flowctrl

import android.content.Context
import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class FlowTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTileUi()
    }

    override fun onClick() {
        super.onClick()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Read current state
        val currentState = prefs.getBoolean("flutter.isBlockingEnabled", true)
        // Toggle
        val newState = !currentState
        prefs.edit().putBoolean("flutter.isBlockingEnabled", newState).apply()
        
        // Update UI
        updateTileUi()
    }

    private fun updateTileUi() {
        val tile = qsTile ?: return
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        // ALWAYS use the same icon (ic_qs_logo)
        tile.icon = Icon.createWithResource(this, R.drawable.ic_qs_logo)

        if (isBlockingEnabled) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "FlowCTRL" // Simple label
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "FlowCTRL"
        }
        tile.updateTile()
    }
}
