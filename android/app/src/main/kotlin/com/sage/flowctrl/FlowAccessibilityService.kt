package com.sage.flowctrl

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.SharedPreferences
import android.content.Context
import android.os.SystemClock
import android.graphics.Rect
import android.util.DisplayMetrics

class FlowAccessibilityService : AccessibilityService() {

    private val BACK_PRESS_COOLDOWN = 1500L
    private var lastBackPressTime: Long = 0
    private var screenWidth: Int = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.service_active", true).apply()
        
        // Get Screen Width for Geometric Calculation
        val metrics = DisplayMetrics()
        val windowManager = getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
        windowManager.defaultDisplay.getMetrics(metrics)
        screenWidth = metrics.widthPixels
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // 1. Keep Service Alive Flag
        if (!prefs.getBoolean("flutter.service_active", false)) {
            prefs.edit().putBoolean("flutter.service_active", true).apply()
        }

        // 2. Master Switch Check
        if (!prefs.getBoolean("flutter.isBlockingEnabled", true)) return

        if (event == null || event.packageName == null) return
        val packageName = event.packageName.toString()

        // 3. Cooldown (Prevent Spamming Back Button)
        if (SystemClock.elapsedRealtime() - lastBackPressTime < BACK_PRESS_COOLDOWN) {
            return
        }

        val rootNode = rootInActiveWindow ?: return

        // 4. ROUTER
        if (packageName == "com.google.android.youtube") {
            if (prefs.getBoolean("flutter.isYouTubeBlocked", true)) {
                if (detectYouTubeShorts(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        } 
        else if (packageName == "com.instagram.android") {
            if (prefs.getBoolean("flutter.isInstagramBlocked", true)) {
                if (detectInstagramReels(rootNode)) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    lastBackPressTime = SystemClock.elapsedRealtime()
                }
            }
        }
    }

    // =========================================================
    // INSTAGRAM DETECTION STRATEGY (The "Nuclear" Option)
    // =========================================================
    private fun detectInstagramReels(root: AccessibilityNodeInfo): Boolean {
        
        // LAYER 1: The "Right-Side" Rule (Geometric)
        // In Feed, "Like" button is on the LEFT.
        // In Reels, "Like" button is on the RIGHT.
        val likes = root.findAccessibilityNodeInfosByText("Like")
        if (likes != null && !likes.isEmpty()) {
            for (node in likes) {
                if (node.isVisibleToUser) {
                    val rect = Rect()
                    node.getBoundsInScreen(rect)
                    
                    // If the Like button is on the right 30% of the screen, IT IS A REEL.
                    // (Reels buttons are stacked on the right edge)
                    if (rect.left > (screenWidth * 0.7)) {
                        return true 
                    }
                }
            }
        }

        // LAYER 2: The "Reels" Tab Selection
        // Check if the bottom tab bar says "Reels" and is SELECTED.
        val reelsTabs = root.findAccessibilityNodeInfosByText("Reels")
        if (reelsTabs != null) {
            for (node in reelsTabs) {
                // Check direct node or its parent (sometimes the container is selected)
                if ((node.isSelected || (node.parent != null && node.parent.isSelected))) {
                    return true
                }
            }
        }

        // LAYER 3: "Reel by" Text (English specific, but very common)
        // Screen readers read "Reel by [username]" for every reel.
        val reelsBy = root.findAccessibilityNodeInfosByText("Reel by")
        if (reelsBy != null && !reelsBy.isEmpty()) {
            return true
        }

        // LAYER 4: Legacy ID Check (Backup)
        if (hasId(root, "com.instagram.android:id/clips_video_container")) return true
        if (hasId(root, "com.instagram.android:id/clips_viewer_root")) return true
        if (hasId(root, "com.instagram.android:id/reel_viewer_root")) return true

        return false
    }

    // =========================================================
    // YOUTUBE DETECTION STRATEGY
    // =========================================================
    private fun detectYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        if (hasId(root, "com.google.android.youtube:id/reel_recycler")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_player_view")) return true
        if (hasId(root, "com.google.android.youtube:id/reel_touch_helper_0")) return true
        
        val shortsText = root.findAccessibilityNodeInfosByText("Shorts")
        if (shortsText != null && !shortsText.isEmpty()) {
            // Confirm it's the player by looking for controls
            if (hasText(root, "Like") || hasText(root, "Dislike")) return true
        }
        return false
    }

    // =========================================================
    // HELPERS
    // =========================================================
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
