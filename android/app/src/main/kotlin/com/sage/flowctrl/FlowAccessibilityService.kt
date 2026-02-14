package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock
import android.graphics.Rect
import kotlin.math.abs

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
        // STRATEGY 1: The "Reels" Tab Selection
        // If the bottom bar "Reels" tab is selected, we are 100% in Reels.
        val reelsTabs = root.findAccessibilityNodeInfosByText("Reels")
        if (reelsTabs != null && !reelsTabs.isEmpty()) {
            for (node in reelsTabs) {
                if (node.isVisibleToUser && (node.isSelected || node.isChecked)) return true
                // Sometimes the parent container is the one marked selected
                if (node.parent != null && node.parent.isSelected) return true
            }
        }

        // STRATEGY 2: GEOMETRIC VERTICAL STACK CHECK
        // We look for "Like" and "Comment" buttons.
        // In Feed, they are Horizontal (Left to Right).
        // In Reels, they are Vertical (Top to Bottom).
        
        val likes = root.findAccessibilityNodeInfosByText("Like")
        val comments = root.findAccessibilityNodeInfosByText("Comment") // or "Comment..."

        if (likes != null && !likes.isEmpty() && comments != null && !comments.isEmpty()) {
            // Get the first visible Like button
            var likeNode: AccessibilityNodeInfo? = null
            for (node in likes) {
                if (node.isVisibleToUser) { likeNode = node; break }
            }

            // Get the first visible Comment button
            var commentNode: AccessibilityNodeInfo? = null
            for (node in comments) {
                if (node.isVisibleToUser) { commentNode = node; break }
            }

            if (likeNode != null && commentNode != null) {
                val likeRect = Rect()
                val commentRect = Rect()
                likeNode.getBoundsInScreen(likeRect)
                commentNode.getBoundsInScreen(commentRect)

                val xDiff = abs(likeRect.left - commentRect.left)
                val yDiff = abs(likeRect.top - commentRect.top)

                // LOGIC: 
                // If Y difference (Vertical) is bigger than X difference (Horizontal),
                // AND they are reasonably close to each other (not random buttons on screen),
                // THEN it is a Vertical Stack -> REELS.
                
                if (yDiff > xDiff && yDiff > 50) {
                     return true
                }
            }
        }

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
