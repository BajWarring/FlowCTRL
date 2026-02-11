package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.graphics.Rect

class FlowAccessibilityService : AccessibilityService() {

    private var isBlockingEnabled = true

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (!isBlockingEnabled || event == null) return

        if (event.packageName?.toString() == "com.google.android.youtube") {
            // We use the root node to find specific Shorts PLAYER elements
            val rootNode = rootInActiveWindow ?: return
            
            if (isShortsPlayer(rootNode)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY 1: Look for specific View IDs used only in the Shorts Player
        // YouTube uses 'reel' in their ID names for Shorts (e.g., reel_recycler, reel_player)
        // This usually does NOT appear on the Home Screen shelf.
        
        val reelNode = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelNode != null && reelNode.isNotEmpty()) {
            return true
        }

        val reelTouch = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_touch_helper_0")
        if (reelTouch != null && reelTouch.isNotEmpty()) {
            return true
        }

        // STRATEGY 2: Fallback - Strict Text Check
        // Only block if we see "Shorts" AND "Like" button implies we are in a player, not a shelf.
        // The Home screen shelf has "Shorts" but usually no visible "Like" button for the shelf itself.
        
        val hasShortsText = !root.findAccessibilityNodeInfosByText("Shorts").isNullOrEmpty()
        val hasLikeButton = !root.findAccessibilityNodeInfosByText("Like this video").isNullOrEmpty() 
                            || !root.findAccessibilityNodeInfosByContentDescription("Like this video").isNullOrEmpty()

        if (hasShortsText && hasLikeButton) {
            return true
        }

        return false
    }

    override fun onInterrupt() {
        // Required method
    }
}
