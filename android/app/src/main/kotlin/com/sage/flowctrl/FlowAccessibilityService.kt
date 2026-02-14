package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock

class FlowAccessibilityService : AccessibilityService() {

    private val BACK_PRESS_COOLDOWN = 1500L
    private var lastBackPressTime: Long = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        if (!prefs.getBoolean("flutter.service_active", false)) {
            prefs.edit().putBoolean("flutter.service_active", true).apply()
        }

        if (!prefs.getBoolean("flutter.isBlockingEnabled", true)) return

        if (event == null || event.packageName == null) return
        val packageName = event.packageName.toString()

        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        val rootNode = rootInActiveWindow ?: return

        // YOUTUBE
        if (packageName == "com.google.android.youtube") {
            if (prefs.getBoolean("flutter.isYouTubeBlocked", true)) {
                if (detectYouTubeShorts(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        } 
        // INSTAGRAM
        else if (packageName == "com.instagram.android") {
            if (prefs.getBoolean("flutter.isInstagramBlocked", true)) {
                if (detectInstagramReels(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        }
    }

    private fun detectYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        if (hasId(root, "com.google.android.youtube:id/reel_recycler")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_player_view")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_touch_helper_0")) return true
        
        val shortsText = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsText != null && !shortsText.isEmpty()) {
            if (hasText(root, "Like") || hasText(root, "Dislike") || hasText(root, "Comment")) return true
        }
        return false
    }

    private fun detectInstagramReels(root: AccessibilityNodeInfo): Boolean {
        // 1. Check for specific IDs
        if (hasId(root, "com.instagram.android:id/clips_video_container")) return true
        if (hasId(root, "com.instagram.android:id/clips_viewer_root")) return true
        if (hasId(root, "com.instagram.android:id/reel_viewer_root")) return true

        // 2. Check for "Reels" Tab being selected
        // This is often a frame layout with description "Reels, tab" or similar
        val reelsTab = root.findAccessibilityNodeInfosByText("Reels")
        if (reelsTab != null) {
            for (node in reelsTab) {
                if (node.isSelected) return true // You are ON the Reels tab
            }
        }

        // 3. Check for specific Content Descriptions inside the viewer
        // "Reel by [user]" is a common description
        val reelsBy = root.findAccessibilityNodeInfosByText("Reel by")
        if (reelsBy != null && !reelsBy.isEmpty()) return true

        return false
    }

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
