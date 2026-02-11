package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context

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
            val rootNode = rootInActiveWindow ?: return
            
            if (isShortsPlayer(rootNode)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY 1: Look for specific View IDs used only in the Shorts Player
        // YouTube uses 'reel' IDs for Shorts (e.g., reel_recycler)
        val reelNode = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelNode != null && !reelNode.isEmpty()) {
            return true
        }

        // STRATEGY 2: Fallback - Strict Text Check
        // We removed the broken 'ByContentDescription' method.
        // Instead, we check if "Shorts" text exists alongside "Like" or "Comment" text.
        // This combination usually only happens in the full player, not on the home shelf.
        
        val shortsList = root.findAccessibilityNodeInfosByText("Shorts")
        val likeList = root.findAccessibilityNodeInfosByText("Like")
        val commentList = root.findAccessibilityNodeInfosByText("Comment")
        val subscribeList = root.findAccessibilityNodeInfosByText("Subscribe")

        val hasShortsText = shortsList != null && !shortsList.isEmpty()
        
        // If we see "Shorts" AND ("Like" OR "Comment" OR "Subscribe") -> It is a Player
        val hasEngagementButtons = (likeList != null && !likeList.isEmpty()) || 
                                   (commentList != null && !commentList.isEmpty()) || 
                                   (subscribeList != null && !subscribeList.isEmpty())

        if (hasShortsText && hasEngagementButtons) {
            return true
        }

        return false
    }

    override fun onInterrupt() {
        // Required method
    }
}
