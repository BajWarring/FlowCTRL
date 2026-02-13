package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context

class FlowAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        // SCREAM that we are alive so the UI hears it
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // 1. RE-CONFIRM "ALIVE" STATUS (Fixes the persistent popup bug)
        // Every time an event happens, we remind Flutter we are here.
        if (!prefs.getBoolean("flutter.service_active", false)) {
            prefs.edit().putBoolean("flutter.service_active", true).apply()
        }

        // 2. CHECK BLOCKING STATUS
        val isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
        if (!isBlockingEnabled) return

        // 3. CHECK PACKAGE
        if (event?.packageName?.toString() != "com.google.android.youtube") return

        // 4. SCAN FOR SHORTS
        val rootNode = rootInActiveWindow ?: return
        if (isShortsPlayer(rootNode)) {
            performGlobalAction(GLOBAL_ACTION_BACK)
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY: Check for specific Shorts UI elements
        
        // 1. "reel_recycler" is the main container for Shorts
        val reelRecycler = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelRecycler != null && !reelRecycler.isEmpty()) return true

        // 2. "reel_player_view" is the video player
        val reelPlayer = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_player_view")
        if (reelPlayer != null && !reelPlayer.isEmpty()) return true

        // 3. Fallback: Text detection (Nuclear option for different YT versions)
        val shortsText = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsText != null && !shortsText.isEmpty()) {
            // Confirm it's the player by looking for "Like" button nearby
            val likeBtn = root.findAccessibilityNodeInfosByText("Like")
            val commentBtn = root.findAccessibilityNodeInfosByText("Comment")
            
            if ((likeBtn != null && !likeBtn.isEmpty()) || (commentBtn != null && !commentBtn.isEmpty())) {
                return true
            }
        }
        return false
    }

    override fun onInterrupt() {}
    
    override fun onUnbind(intent: android.content.Intent?): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", false).apply()
        return super.onUnbind(intent)
    }
}
