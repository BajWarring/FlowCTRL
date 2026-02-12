package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock

class FlowAccessibilityService : AccessibilityService() {

    private var isBlockingEnabled = true
    private var lastBackPressTime: Long = 0
    private val BACK_PRESS_COOLDOWN = 1500L 

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Tell UI we are alive
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()
        
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", false).apply()
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // 1. Basic Checks
        if (!isBlockingEnabled || event == null) return
        if (event.packageName?.toString() != "com.google.android.youtube") return

        // 2. Cooldown
        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        // 3. Sync Settings
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", true)

        if (isBlockingEnabled) {
            val rootNode = rootInActiveWindow ?: return
            
            // Double check we are still in YouTube
            if (rootNode.packageName?.toString() == "com.google.android.youtube") {
                 if (isShortsPlayer(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        }
    }

    private fun isShortsPlayer(root: AccessibilityNodeInfo): Boolean {
        // STRATEGY 1: Internal View IDs (Fastest & Most Accurate)
        // These IDs are specific to the Shorts Player UI
        val reelRecycler = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_recycler")
        if (reelRecycler != null && !reelRecycler.isEmpty()) return true

        val reelTouch = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_touch_helper_0")
        if (reelTouch != null && !reelTouch.isEmpty()) return true

        val reelPlayer = root.findAccessibilityNodeInfosByViewId("com.google.android.youtube:id/reel_player_view")
        if (reelPlayer != null && !reelPlayer.isEmpty()) return true

        // STRATEGY 2: Contextual Text Check (The "Nuclear" Option)
        // If we can't find the IDs, we look for the "Shorts" text.
        // BUT, to avoid closing the Home Screen, we ONLY block if we ALSO see engagement buttons.
        
        val shortsTextNodes = root.findAccessibilityNodeInfosByText("Shorts")
        val hasShortsText = shortsTextNodes != null && !shortsTextNodes.isEmpty()

        if (hasShortsText) {
            // We found "Shorts". Now, is this a player?
            // A player ALWAYS has "Like", "Dislike", or "Comment" buttons visible.
            // The Home Screen shelf usually does not have these text labels exposed in the same way.

            val likeNodes = root.findAccessibilityNodeInfosByText("Like")
            val commentNodes = root.findAccessibilityNodeInfosByText("Comment")
            val dislikeNodes = root.findAccessibilityNodeInfosByText("Dislike")
            val subscribeNodes = root.findAccessibilityNodeInfosByText("Subscribe")

            val hasEngagement = (likeNodes != null && !likeNodes.isEmpty()) ||
                                (commentNodes != null && !commentNodes.isEmpty()) ||
                                (dislikeNodes != null && !dislikeNodes.isEmpty()) ||
                                (subscribeNodes != null && !subscribeNodes.isEmpty())

            if (hasEngagement) {
                // High probability this is the Shorts Player
                return true
            }
        }

        return false
    }

    override fun onInterrupt() {}
}
