package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock

class FlowAccessibilityService : AccessibilityService() {

    private val BACK_PRESS_COOLDOWN = 1500L // 1.5 Seconds Delay
    private var lastBackPressTime: Long = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // 1. Keep "Service Active" flag fresh (Fixes popup issues)
        if (!prefs.getBoolean("flutter.service_active", false)) {
            prefs.edit().putBoolean("flutter.service_active", true).apply()
        }

        // 2. Check if Blocker is Enabled globally
        if (!prefs.getBoolean("flutter.isBlockingEnabled", true)) return

        if (event == null || event.packageName == null) return
        val packageName = event.packageName.toString()

        // 3. Cooldown Check (1.5s)
        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        val rootNode = rootInActiveWindow ?: return

        // 4. Route to specific app logic
        if (packageName == "com.google.android.youtube") {
            if (detectYouTubeShorts(rootNode)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
                lastBackPressTime = SystemClock.elapsedRealtime()
            }
        } 
        else if (packageName == "com.instagram.android") {
            if (detectInstagramReels(rootNode)) {
                performGlobalAction(GLOBAL_ACTION_BACK)
                lastBackPressTime = SystemClock.elapsedRealtime()
            }
        }
    }

    // --- YOUTUBE SHORTS DETECTION ---
    private fun detectYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        // ID Check (Most accurate)
        if (hasId(root, "com.google.android.youtube:id/reel_recycler")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_player_view")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_touch_helper_0")) return true

        // Text Fallback
        val shortsText = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsText != null && !shortsText.isEmpty()) {
            // Confirm it's the player, not just a button on Home
            if (hasText(root, "Like") || hasText(root, "Dislike") || hasText(root, "Comment")) {
                return true
            }
        }
        return false
    }

    // --- INSTAGRAM REELS DETECTION ---
    private fun detectInstagramReels(root: AccessibilityNodeInfo): Boolean {
        // ID Strategy: Instagram uses "clips" in their IDs for Reels
        if (hasId(root, "com.instagram.android:id/clips_video_container")) return true
        if (hasId(root, "com.instagram.android:id/clips_viewer_root")) return true
        if (hasId(root, "com.instagram.android:id/reel_viewer_root")) return true
        
        // "Reels" specific tab container
        if (hasId(root, "com.instagram.android:id/reels_tab_toolbar_container")) return true

        // Description Strategy (Backup)
        // Instagram reels often have a content description "Reel by [user]"
        val reelsDesc = root.findAccessibilityNodeInfosByText("Reel by")
        if (reelsDesc != null && !reelsDesc.isEmpty()) {
             // Ensure we are in the viewer, look for the "Like" heart button or comments
            if (hasId(root, "com.instagram.android:id/row_feed_button_like") || 
                hasId(root, "com.instagram.android:id/row_feed_button_comment")) {
                return true
            }
        }
        return false
    }

    // --- HELPER FUNCTIONS ---
    private fun hasId(root: AccessibilityNodeInfo, id: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByViewId(id)
        return nodes != null && !nodes.isEmpty()
    }

    private fun hasText(root: AccessibilityNodeInfo, text: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByText(text)
        return nodes != null && !nodes.isEmpty()
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", false).apply()
        return super.onUnbind(intent)
    }
}
